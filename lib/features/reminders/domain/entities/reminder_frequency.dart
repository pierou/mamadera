import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_frequency.freezed.dart';

/// Frequency types for periodic reminders (daily vitamins, weekly checks, etc.).
@freezed
sealed class ReminderFrequency with _$ReminderFrequency {
  const factory ReminderFrequency.daily() = Daily;
  const factory ReminderFrequency.weekly({required int dayOfWeek}) = Weekly;
  const factory ReminderFrequency.monthly({required int dayOfMonth}) = Monthly;
  const factory ReminderFrequency.customInterval({@Default(7) int days}) =
      CustomInterval;

  /// A **single occurrence**, on [date] — B33's "one time" (D-R5 form 1).
  ///
  /// [date] is a calendar date at midnight: the *occurrence day*, never an end.
  /// A series that stops on a day is the `end_date` column (D-R5 form 2) — a
  /// different concept with a different column, deliberately not merged here.
  ///
  /// `date == null` exists for exactly one reason: D-R8's tolerant read of a
  /// stored `frequency = 'one_time'` whose `frequency_date` is null or
  /// unparseable. Such a one-shot is **due now** (D-R7's catch-up), because the
  /// codec's first rule is that a reminder never silently disappears, and the
  /// choice was "ask the parent" versus "silently off". A *written* one-shot
  /// always has a date: the picker requires one (D-R5, write-strict) and so does
  /// the importer.
  const factory ReminderFrequency.oneTime({DateTime? date}) = OneTime;
}

/// Whether [a] and [b] fall on the same calendar day (device-local).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Fixed epoch anchoring the weekly period key: Monday 3 January 2000, in UTC.
///
/// UTC is deliberate: the difference between two UTC midnights is always an
/// exact multiple of 24 hours, so DST transitions cannot shift a week boundary.
final DateTime _weeklyEpoch = DateTime.utc(2000, 1, 3);

/// Monotonic index of the Monday-anchored (ISO, Monday→Sunday) week containing
/// [date]; consecutive weeks get consecutive integers.
///
/// Built from the calendar fields of [date] only (never from wall-clock
/// arithmetic), so two dates in the same ISO week always share a key and dates
/// in later weeks always score higher. Dates before [_weeklyEpoch] truncate
/// toward zero, which is irrelevant here: no baby event predates the epoch.
int weekIndex(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day)
        .difference(_weeklyEpoch)
        .inDays ~/
    7;

/// Monotonic index of the calendar month containing [date] (2025-01 → 24301).
int monthIndex(DateTime date) => date.year * 12 + date.month;

/// [dayOfMonth] clamped to the length of the month containing [date] (28-31 days),
/// so a reminder configured for the 31st still fires in shorter months.
int clampedDayOfMonth(DateTime date, int dayOfMonth) {
  // Day 0 of the next month is the last day of this one (Dart normalises it).
  final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
  return dayOfMonth > lastDayOfMonth ? lastDayOfMonth : dayOfMonth;
}

/// The last instant at which a reminder ended on [endsAt] may still fire: the end of that
/// calendar day, inclusive (D-R5).
DateTime seriesEndExpiry(DateTime endsAt) =>
    DateTime(endsAt.year, endsAt.month, endsAt.day, 23, 59, 59, 999);

/// Whether [now] is past the last moment a reminder with this series end may
/// fire. The single cutoff check for every frequency — never re-derived per
/// variant, which is what D-R5's "one cutoff code path" means.
bool isPastSeriesEnd(DateTime now, DateTime? endsAt) =>
    endsAt != null && now.isAfter(seriesEndExpiry(endsAt));

/// Extension that provides `isDue` on [ReminderFrequency] using freezed's generated `map()`.
extension ReminderFrequencyIsDue on ReminderFrequency {
  /// Whether this reminder is due at [now], given it was last completed at
  /// [lastCompleted] (null when it was never completed — always due).
  ///
  /// Semantics per variant:
  /// - [Daily]: due on any calendar day other than the day of [lastCompleted].
  /// - [Weekly]: due when the ISO week (Monday→Sunday) containing [now] differs
  ///   from the ISO week containing [lastCompleted] — compared by monotonic
  ///   week index, never by weekday equality or a rolling 7-day window.
  ///   Completing the reminder therefore suppresses it for the *rest of that
  ///   week* (it can never fire twice in one week) and makes it due again the
  ///   first time it is opened in the next week, whenever that is. The
  ///   configured [Weekly.dayOfWeek] records the day of the week the user aims
  ///   for; it deliberately does not gate the check, otherwise a reminder
  ///   completed on another day of the week could stay silent for weeks.
  /// - [Monthly]: due from [Monthly.dayOfMonth] (clamped to the length of the
  ///   month containing [now]) of a calendar month *later* than the one
  ///   containing [lastCompleted]. The month of [lastCompleted] owns that
  ///   occurrence, and a new month does not make the reminder due before its
  ///   configured day has been reached.
  /// - [CustomInterval]: unchanged rolling behaviour — due once at least
  ///   [CustomInterval.days] whole days have elapsed since [lastCompleted].
  /// - [OneTime] (B33, D-R7): due on its date and **until it is settled** — a
  ///   passed date stays due (catch-up, not expiry) and once completed it is
  ///   **never due again**, because a one-shot has no next occurrence. A
  ///   dateless one-shot (D-R8's tolerant read) is due now.
  ///
  /// The **end of a series** (D-R5's `end_date` / `end_age_months`) is not
  /// decided here: an end belongs to the reminder, not to its rhythm, and
  /// folding it into each variant is precisely what D-R5 rejects. Consumers that
  /// have it check [isPastSeriesEnd] alongside this call.
  bool isDue(DateTime now, DateTime? lastCompleted) => map(
        daily: (_) => lastCompleted == null || !isSameDay(now, lastCompleted),
        weekly: (_) {
          if (lastCompleted == null) return true;
          // Different ISO week => due; same week => suppressed.
          return weekIndex(now) > weekIndex(lastCompleted);
        },
        monthly: (freq) {
          if (lastCompleted == null) return true;
          // Same month (or clock skew backwards) — this month's occurrence is done.
          if (monthIndex(now) <= monthIndex(lastCompleted)) return false;
          // Later month, but not before the configured day of that month.
          return now.day >= clampedDayOfMonth(now, freq.dayOfMonth);
        },
        customInterval: (freq) {
          if (lastCompleted == null) return true;
          final diff = now.difference(lastCompleted).inDays;
          return diff >= freq.days;
        },
        oneTime: (freq) {
          // Settled ⇒ done for good. That is the whole point of the one-shot:
          // what used to be a monthly vitamin K must not come back next month.
          if (lastCompleted != null) return false;
          final date = freq.date;
          return date == null || !date.isAfter(now);
        },
      );
}

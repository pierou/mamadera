import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_frequency.freezed.dart';

/// Frequency types for periodic reminders (daily vitamins, weekly checks, etc.).
@freezed
sealed class ReminderFrequency with _$ReminderFrequency {
  const factory ReminderFrequency.daily() = Daily;
  const factory ReminderFrequency.weekly({required int dayOfWeek}) = Weekly;
  const factory ReminderFrequency.monthly({required int dayOfMonth}) = Monthly;
  const factory ReminderFrequency.customInterval({@Default(7) int days}) = CustomInterval;
}

/// Private helper: compare two dates for same calendar day.
bool _isSameDay(DateTime a, DateTime b) =>
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
int _weekIndex(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(_weeklyEpoch).inDays ~/ 7;

/// Monotonic index of the calendar month containing [date] (2025-01 → 24301).
int _monthIndex(DateTime date) => date.year * 12 + date.month;

/// [dayOfMonth] clamped to the length of the month containing [date] (28-31 days),
/// so a reminder configured for the 31st still fires in shorter months.
int _clampedDayOfMonth(DateTime date, int dayOfMonth) {
  // Day 0 of the next month is the last day of this one (Dart normalises it).
  final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
  return dayOfMonth > lastDayOfMonth ? lastDayOfMonth : dayOfMonth;
}

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
  bool isDue(DateTime now, DateTime? lastCompleted) => map(
    daily: (_) => lastCompleted == null || !_isSameDay(now, lastCompleted),
    weekly: (_) {
      if (lastCompleted == null) return true;
      // Different ISO week => due; same week => suppressed.
      return _weekIndex(now) > _weekIndex(lastCompleted);
    },
    monthly: (freq) {
      if (lastCompleted == null) return true;
      // Same month (or clock skew backwards) — this month's occurrence is done.
      if (_monthIndex(now) <= _monthIndex(lastCompleted)) return false;
      // Later month, but not before the configured day of that month.
      return now.day >= _clampedDayOfMonth(now, freq.dayOfMonth);
    },
    customInterval: (freq) {
      if (lastCompleted == null) return true;
      final diff = now.difference(lastCompleted).inDays;
      return diff >= freq.days;
    },
  );
}

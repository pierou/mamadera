import '../entities/reminder_frequency.dart';
import '../entities/reminder_item.dart';

/// Wall-clock instant (device-local) at which a notification for [item] should
/// fire, assuming no state change before then. Contract:
///
/// - `result <= now` ⇒ the item is due RIGHT NOW — the caller converts this to
///   the D3 catch-up (one notification ~60 s later);
/// - `result  > now` ⇒ wait until `result`.
///
/// All comparisons are device-local wall clock. [lastDismissal] suppression is
/// `lastDismissal + dismissalWindow` (24 h default, mirroring the
/// RemindersService.dismissalWindow constant); a completion today suppresses
/// until the end of today. The window applies to every variant exactly as `isDue`
/// applies the dismissal window — a snoozed item is silent in the OS as in
/// the app.
///
/// Pure function: no Flutter, no IO, no `DateTime.now()` — [now] is injected
/// (tests use fixed instants).
// Lint note: the plan's §3.2 signature listed the two nullable lookups in
// the middle; always_put_required_named_parameters_first forces required
// parameters first, so the order here is a cosmetic re-ordering only.
DateTime nextDueAt(
  ReminderItem item, {
  required DateTime now,
  required Duration dismissalWindow,
  required int preferredHour,
  required int preferredMinute,
  DateTime? lastCompleted,
  DateTime? lastDismissal,
}) {
  final suppressedUntil =
      _suppressedUntil(now, lastCompleted, lastDismissal, dismissalWindow);
  var candidate = _naturalCandidate(
    item.frequency,
    now: now,
    lastCompleted: lastCompleted,
    preferredHour: preferredHour,
    preferredMinute: preferredMinute,
  );
  // Bounded: a 24 h window plus end-of-today ⇒ at most ~3 iterations.
  while (candidate.isBefore(suppressedUntil)) {
    candidate = _advancePeriod(
      item.frequency,
      from: candidate,
      lastCompleted: lastCompleted,
      suppressedUntil: suppressedUntil,
      preferredHour: preferredHour,
      preferredMinute: preferredMinute,
    );
  }
  // The due window is open and the fire moment passed while the app was
  // closed ⇒ due now (D3 catch-up, scheduled by the caller ~60 s out).
  return candidate.isBefore(now) || candidate.isAtSameMomentAs(now)
      ? now
      : candidate;
}

/// `max(end-of-today if completed today, lastDismissal + window, epoch)`.
DateTime _suppressedUntil(
  DateTime now,
  DateTime? lastCompleted,
  DateTime? lastDismissal,
  Duration dismissalWindow,
) {
  var suppressed = DateTime.fromMillisecondsSinceEpoch(0);
  if (lastCompleted != null && isSameDay(now, lastCompleted)) {
    suppressed = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }
  if (lastDismissal != null) {
    final until = lastDismissal.add(dismissalWindow);
    if (until.isAfter(suppressed)) suppressed = until;
  }
  return suppressed;
}

/// Identifies the **due period** [item] is currently in, as a local calendar
/// day (the time of day is stripped — a period is a day/week/month boundary,
/// not an instant).
/// The scheduler remembers catch-up nudges against this key (D3): two syncs
/// inside the same period must produce the same key, so an overdue item is
/// nudged once and not every 5-minute tick, while every *later* period of the
/// same item still gets its own nudge. Deriving it from the natural candidate
/// (not from `now`) is what makes that true for weekly and monthly items.
DateTime duePeriodStart(
  ReminderItem item, {
  required DateTime now,
  DateTime? lastCompleted,
}) {
  final candidate = _naturalCandidate(
    item.frequency,
    now: now,
    lastCompleted: lastCompleted,
    preferredHour: 0,
    preferredMinute: 0,
  );
  return DateTime(candidate.year, candidate.month, candidate.day);
}

/// The next moment [frequency] would fire if nothing were suppressed (step 1
/// of the §3.4 two-step contract).
DateTime _naturalCandidate(
  ReminderFrequency frequency, {
  required DateTime now,
  required int preferredHour,
  required int preferredMinute,
  DateTime? lastCompleted,
}) =>
    frequency.map(
      daily: (_) =>
          _at(now.year, now.month, now.day, preferredHour, preferredMinute),
      weekly: (freq) {
        // The ISO week (Monday→Sunday) strictly after lastCompleted's week, or
        // the current week when never completed — the same week-keying isDue
        // uses, so the scheduler and the pill can never disagree about weeks.
        final dueWeek = lastCompleted == null
            ? weekIndex(now)
            : weekIndex(lastCompleted) + 1;
        final mondayOfNow =
            DateTime(now.year, now.month, now.day - (now.weekday - 1));
        final monday = DateTime(mondayOfNow.year, mondayOfNow.month,
            mondayOfNow.day + 7 * (dueWeek - weekIndex(now)));
        return _at(
          monday.year,
          monday.month,
          monday.day + (freq.dayOfWeek - 1),
          preferredHour,
          preferredMinute,
        );
      },
      monthly: (freq) {
        // The calendar month strictly after lastCompleted's month (or the
        // current one when never completed), on the configured day clamped to
        // that month's length — the month of lastCompleted owns its occurrence.
        final monthStart = lastCompleted == null
            ? DateTime(now.year, now.month)
            : DateTime(lastCompleted.year, lastCompleted.month + 1);
        return _at(
          monthStart.year,
          monthStart.month,
          clampedDayOfMonth(monthStart, freq.dayOfMonth),
          preferredHour,
          preferredMinute,
        );
      },
      customInterval: (freq) {
        // Never completed ⇒ as soon as possible (`now`; the universal
        // resolution pushes it to suppressedUntil while a snooze is open).
        // Completed ⇒ the next n-day boundary at the preferred time of day.
        if (lastCompleted == null) return now;
        return _at(
          lastCompleted.year,
          lastCompleted.month,
          lastCompleted.day + freq.days,
          preferredHour,
          preferredMinute,
        );
      },
    );

/// One period later (step 2 of the §3.4 universal resolution): a day for
/// [Daily], the same target in the next week for [Weekly], the next eligible
/// month for [Monthly], the next n-day boundary for [CustomInterval].
DateTime _advancePeriod(
  ReminderFrequency frequency, {
  required DateTime from,
  required DateTime? lastCompleted,
  required DateTime suppressedUntil,
  required int preferredHour,
  required int preferredMinute,
}) =>
    frequency.map(
      daily: (_) => _at(
          from.year, from.month, from.day + 1, preferredHour, preferredMinute),
      weekly: (_) => _at(
          from.year, from.month, from.day + 7, preferredHour, preferredMinute),
      monthly: (freq) {
        final nextMonth = DateTime(from.year, from.month + 1);
        return _at(
          nextMonth.year,
          nextMonth.month,
          clampedDayOfMonth(nextMonth, freq.dayOfMonth),
          preferredHour,
          preferredMinute,
        );
      },
      customInterval: (freq) => lastCompleted == null
          ? // Snoozed before it ever completed: fire as soon as the snooze
          // window closes — exactly like the pill, not n days later.
          suppressedUntil
          : _at(from.year, from.month, from.day + freq.days, preferredHour,
              preferredMinute),
    );

/// [hour]:[minute] on the given calendar day. If the instant does not exist
/// (a DST spring-forward gap) or is ambiguous (a fall-back repeat), the
/// platform's constructor returns the next valid / first occurrence — drift ≤
/// 1 h, no crash (see the DST rows of reminder_scheduling_test).
DateTime _at(int year, int month, int day, int hour, int minute) =>
    DateTime(year, month, day, hour, minute);

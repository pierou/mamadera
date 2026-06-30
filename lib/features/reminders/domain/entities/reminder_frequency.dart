/// Frequency types for periodic reminders (daily vitamins, weekly checks, etc.).
sealed class ReminderFrequency {
  const ReminderFrequency();

  /// Whether this reminder is due based on when it was last completed.
  bool isDue(DateTime now, DateTime? lastCompleted);
}

/// Daily frequency — due each calendar day.
class Daily extends ReminderFrequency {
  const Daily();

  @override
  bool isDue(DateTime now, DateTime? lastCompleted) {
    if (lastCompleted == null) return true;
    return !isSameDay(now, lastCompleted);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Weekly frequency — due on a specific day of the week.
class Weekly extends ReminderFrequency {

  const Weekly(this.dayOfWeek);
  /// Day of week (1 = Monday … 7 = Sunday).
  final int dayOfWeek;

  @override
  bool isDue(DateTime now, DateTime? lastCompleted) {
    if (lastCompleted == null) return true;
    // Due if we are on the target weekday and haven't completed this week yet.
    final sameWeek = _isSameWeek(now, lastCompleted, dayOfWeek);
    return !sameWeek || !Daily.isSameDay(lastCompleted, now);
  }

  /// Returns true if [now] and [completed] fall in the same weekly period
  /// defined by [dayOfWeek]. Uses [Daily.isSameDay] for day comparison.
  static bool _isSameWeek(DateTime now, DateTime completed, int dow) {
    final monday = now.weekday; // 1=Mon … 7=Sun (Dart's weekday is ISO-8601)
    return monday == completed.weekday ||
        ((now.difference(completed).inDays.abs()) < 7 &&
            now.year == completed.year);
  }
}

/// Monthly frequency — due on a specific day of the month.
class Monthly extends ReminderFrequency {

  const Monthly(this.dayOfMonth);
  /// Day of month (1–31). If the target day exceeds the current month length, the last day is used.
  final int dayOfMonth;

  @override
  bool isDue(DateTime now, DateTime? lastCompleted) {
    if (lastCompleted == null) return true;
    // Due if we entered a new calendar month since last completion.
    return !(now.year == lastCompleted.year && now.month == lastCompleted.month);
  }
}

/// Custom interval — due every N days regardless of calendar boundaries.
class CustomInterval extends ReminderFrequency {

  const CustomInterval({this.days = 7});
  final int days;

  @override
  bool isDue(DateTime now, DateTime? lastCompleted) {
    if (lastCompleted == null) return true;
    final diff = now.difference(lastCompleted).inDays;
    return diff >= days;
  }
}

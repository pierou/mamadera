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

/// Returns true if [now] and [completed] fall in the same weekly period
/// defined by [dow].
bool _isSameWeek(DateTime now, DateTime completed, int dow) {
  final monday = now.weekday; // 1=Mon … 7=Sun (Dart's weekday is ISO-8601)
  return monday == completed.weekday ||
      ((now.difference(completed).inDays.abs()) < 7 &&
          now.year == completed.year);
}

/// Extension that provides `isDue` on [ReminderFrequency] using freezed's generated `map()`.
extension ReminderFrequencyIsDue on ReminderFrequency {
  /// Whether this reminder is due based on when it was last completed.
  bool isDue(DateTime now, DateTime? lastCompleted) => map(
    daily: (_) => lastCompleted == null || !_isSameDay(now, lastCompleted),
    weekly: (freq) {
      if (lastCompleted == null) return true;
      final sameWeek = _isSameWeek(now, lastCompleted, freq.dayOfWeek);
      return !sameWeek || !_isSameDay(lastCompleted, now);
    },
    monthly: (freq) {
      if (lastCompleted == null) return true;
      // Due if we entered a new calendar month since last completion.
      return !(now.year == lastCompleted.year && now.month == lastCompleted.month);
    },
    customInterval: (freq) {
      if (lastCompleted == null) return true;
      final diff = now.difference(lastCompleted).inDays;
      return diff >= freq.days;
    },
  );
}

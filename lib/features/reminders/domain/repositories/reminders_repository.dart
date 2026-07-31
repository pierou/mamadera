import '../entities/reminder_item.dart';

/// Repository interface for reminder persistence and queries.
abstract class RemindersRepository {
  /// Returns the timestamp of the last tracked event for [item], regardless of date.
  /// Used by rolling-interval reminders (e.g. Vitamin K every 30 days) to determine
  /// whether the due period has elapsed since last completion.
  Future<DateTime?> getLastCompleted(ReminderItem item);

  /// Persists when a user dismissed a reminder (for cooldown tracking).
  Future<void> saveDismissalTime(String itemId, DateTime time);

  /// Returns the last dismissal timestamp for [itemId], or null if never dismissed.
  Future<DateTime?> getDismissalTime(String itemId);
}

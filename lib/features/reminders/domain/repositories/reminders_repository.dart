import '../entities/reminder_item.dart';

/// Repository interface for reminder persistence and queries.
abstract class RemindersRepository {
  /// Returns the timestamp of today's last matching event, or null if not completed yet.
  Future<DateTime?> getLastCompletedToday(ReminderItem item);

  /// Persists when a user dismissed a reminder (for cooldown tracking).
  Future<void> saveDismissalTime(String itemId, DateTime time);

  /// Returns the last dismissal timestamp for [itemId], or null if never dismissed.
  Future<DateTime?> getDismissalTime(String itemId);
}

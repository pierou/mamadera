import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/repositories/reminders_repository.dart';

/// Simple in-memory mock of [RemindersRepository] for unit tests.
class MockRemindersRepository implements RemindersRepository {
  /// Maps item ID → last completed DateTime (simulates tracking event).
  final Map<String, DateTime?> lastCompletedByItem = {};

  /// Maps item ID → dismissal time (simulates cooldown dismissals).
  final Map<String, DateTime> dismissalTimeById = {};

  @override
  Future<DateTime?> getLastCompleted(ReminderItem reminder) async {
    return lastCompletedByItem[reminder.id];
  }

  @override
  Future<void> saveDismissalTime(String reminderId, DateTime time) async {
    dismissalTimeById[reminderId] = time;
  }

  @override
  Future<DateTime?> getDismissalTime(String reminderId) async {
    return dismissalTimeById[reminderId];
  }
}

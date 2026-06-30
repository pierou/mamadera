import 'reminder_item.dart';

/// Status of a single reminder item — whether it is due and when it was last dismissed.
class ReminderStatus {

  const ReminderStatus({
    required this.item,
    this.lastDismissedAt,
  });
  final ReminderItem item;
  /// When the user last dismissed this reminder (for cooldown tracking).
  final DateTime? lastDismissedAt;
}

/// Sealed state for the reminders system.
sealed class RemindersState {}

/// Some reminders are currently due.
class RemindersDue extends RemindersState {
  RemindersDue({required this.items});

  /// List of reminder items that are currently due (not completed today and past cooldown).
  final List<ReminderStatus> items;
}

/// All reminders have been completed for the current period.
class RemindersAllCompleted extends RemindersState {
  RemindersAllCompleted();
}

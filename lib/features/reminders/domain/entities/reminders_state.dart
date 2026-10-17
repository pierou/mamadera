import 'package:freezed_annotation/freezed_annotation.dart';

import 'reminder_item.dart';

part 'reminders_state.freezed.dart';

/// Status of a single reminder item — whether it is due and when it was last
/// tracked. (The `lastDismissedAt` field was removed in version 1.1.1 with the...)
/// cooldown without a trigger — see `RemindersService.checkDue`.)
@freezed
abstract class ReminderStatus with _$ReminderStatus {
  const factory ReminderStatus({
    required ReminderItem item,
    DateTime? lastEventAt,
  }) = _ReminderStatus;
}

/// Sealed state for the reminders system.
@freezed
sealed class RemindersState with _$RemindersState {
  const factory RemindersState.due({required List<ReminderStatus> items}) = RemindersDue;
  const factory RemindersState.allCompleted() = RemindersAllCompleted;
}

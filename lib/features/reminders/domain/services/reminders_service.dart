import '../entities/reminder_frequency.dart';
import '../entities/reminder_item.dart';
import '../entities/reminders_state.dart';
import '../repositories/reminders_repository.dart';

/// Pure business logic for determining which reminders are due.
class RemindersService {
  RemindersService({required this.items, required this.repository});

  /// Cooldown period after dismissing a reminder before it reappears.
  static const Duration cooldownPeriod = Duration(hours: 4);

  final List<ReminderItem> items;
  final RemindersRepository repository;

  /// Returns the list of reminders that are currently due.
  ///
  /// [babyId] scopes completion lookups to the active baby (see
  /// [RemindersRepository.getLastCompleted]); pass null when no baby profile
  /// exists yet. Dismissal cooldowns are not baby-scoped — see
  /// [RemindersRepository.saveDismissalTime].
  Future<RemindersState> checkDue({String? babyId}) async {
    final now = DateTime.now();
    final dueItems = <ReminderStatus>[];

    for (final item in items) {
      // Get timestamp of last tracked event (any date), then check frequency logic.
      final lastCompleted = await repository.getLastCompleted(item, babyId: babyId);
      if (!item.frequency.isDue(now, lastCompleted)) continue;

      // Check cooldown — was the reminder recently dismissed?
      final lastDismissedAt = await repository.getDismissalTime(item.id);
      if (lastDismissedAt != null && now.difference(lastDismissedAt) < cooldownPeriod) {
        // Still within cooldown window — skip this reminder for now
        continue;
      }

      dueItems.add(ReminderStatus(
        item: item,
        lastDismissedAt: lastDismissedAt,
      ));
    }

    return dueItems.isEmpty ? const RemindersState.allCompleted() : RemindersState.due(items: dueItems);
  }

  /// Dismiss a reminder — saves the current time as its dismissal timestamp.
  Future<void> dismiss(String itemId) async {
    await repository.saveDismissalTime(itemId, DateTime.now());
  }
}

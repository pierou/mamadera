import '../../../../data/local/db_constants.dart' as db_const;
import '../entities/reminder_frequency.dart';
import '../entities/reminder_item.dart';
import '../entities/reminders_state.dart';
import '../repositories/reminders_repository.dart';

/// The window during which a dismissal ("ignore") silences a reminder, shared
/// by the in-app pill ([RemindersService]) and the OS scheduler
/// (`ReminderScheduler`) — one constant, so a snoozed reminder can never be
/// silent in one and loud in the other.
const Duration defaultDismissalWindow = Duration(hours: 24);

/// Pure business logic for determining which reminders are due.
class RemindersService {
  RemindersService({
    required this.items,
    required this.repository,
    this.dismissalWindow = defaultDismissalWindow,
  });

  final List<ReminderItem> items;
  final RemindersRepository repository;

  /// The duration during which an "ignore" action removes the reminder from the list.
  /// of the due list without marking it done: after [dismissalWindow] the reminder
  /// It reappears automatically. D3: 24 hours by default, can be injected for testing.
  final Duration dismissalWindow;

  /// Returns the list of reminders that are currently due.
  ///
  /// [babyId] scopes all lookups to the active baby (see
  /// [RemindersRepository.getLastCompleted]); pass null when no baby profile
  /// exists yet.
  ///
  /// The choice of "action" depends on [ReminderItem.completionSource]: a...
  /// Note: The `manual` command only reads the log file for manual completions.
  /// nevertheless, even positive events (invariant D2) — and everything else...
  /// The rest of the text continues to describe the subsequent events as before.
  Future<RemindersState> checkDue({String? babyId}) async {
    final now = DateTime.now();
    final dueItems = <ReminderStatus>[];

    for (final item in items) {
      // A recent "dismiss" (less than [dismissalWindow] ago) removes the...
      // Remind the user of the list without marking any items as complete.
      final lastDismissal =
          await repository.getLastDismissal(item.id, babyId: babyId);
      if (lastDismissal != null &&
          now.difference(lastDismissal) < dismissalWindow) {
        continue;
      }

      final lastCompleted = item.completionSource == db_const.completionManual
          ? await repository.getLastManualCompletion(item.id, babyId: babyId)
          : await repository.getLastCompleted(item, babyId: babyId);

      if (!item.frequency.isDue(now, lastCompleted)) continue;

      dueItems.add(ReminderStatus(item: item));
    }

    return dueItems.isEmpty
        ? const RemindersState.allCompleted()
        : RemindersState.due(items: dueItems);
  }
}

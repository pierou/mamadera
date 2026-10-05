import '../../../../data/local/db_constants.dart' as db_const;
import '../entities/reminder_frequency.dart';
import '../entities/reminder_item.dart';
import '../entities/reminders_state.dart';
import '../repositories/reminders_repository.dart';

/// Pure business logic for determining which reminders are due.
class RemindersService {
  RemindersService({
    required this.items,
    required this.repository,
    this.dismissalWindow = const Duration(hours: 24),
  });

  final List<ReminderItem> items;
  final RemindersRepository repository;

  /// Fenêtre pendant laquelle un « ignorer » supprime le rappel de la liste
  /// des dus sans le marquer fait : au bout de [dismissalWindow] le rappel
  /// reparaît tout seul. D3 : 24 h par défaut, injectable pour les tests.
  final Duration dismissalWindow;

  /// Returns the list of reminders that are currently due.
  ///
  /// [babyId] scopes all lookups to the active baby (see
  /// [RemindersRepository.getLastCompleted]); pass null when no baby profile
  /// exists yet.
  ///
  /// Le choix de « fait » dépend de [ReminderItem.completionSource] : un
  /// rappel `manual` ne lit que le journal des complétions manuelles —
  /// jamais les événements, même du bon type (invariant D2) — et tout le
  /// reste lit les événements de suivi comme avant.
  Future<RemindersState> checkDue({String? babyId}) async {
    final now = DateTime.now();
    final dueItems = <ReminderStatus>[];

    for (final item in items) {
      // Un « ignorer » récent (moins de [dismissalWindow] plus tôt) retire le
      // rappel de la liste sans le marquer fait.
      final lastDismissal = await repository.getLastDismissal(item.id, babyId: babyId);
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

    return dueItems.isEmpty ? const RemindersState.allCompleted() : RemindersState.due(items: dueItems);
  }
}

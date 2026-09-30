import '../entities/reminder_frequency.dart';
import '../entities/reminder_item.dart';
import '../entities/reminders_state.dart';
import '../repositories/reminders_repository.dart';

/// Pure business logic for determining which reminders are due.
class RemindersService {
  RemindersService({required this.items, required this.repository});

  final List<ReminderItem> items;
  final RemindersRepository repository;

  /// Returns the list of reminders that are currently due.
  ///
  /// [babyId] scopes completion lookups to the active baby (see
  /// [RemindersRepository.getLastCompleted]); pass null when no baby profile
  /// exists yet.
  ///
  /// Il n'y a plus de cooldown ici : v1.1.0 livrait un `dismiss()` sans aucun
  /// déclencheur dans l'interface, donc une promesse de « ne plus me
  /// re-réveiller pendant 4 h » qu'aucun parent ne pouvait activer. La table
  /// `reminder_dismissals` reste en base (les sauvegardes importées en
  /// contiennent des lignes) et sera rebaptisée à la portée bébé en v1.2.0,
  /// avec l'affichage des rappels dus sur l'accueil.
  Future<RemindersState> checkDue({String? babyId}) async {
    final now = DateTime.now();
    final dueItems = <ReminderStatus>[];

    for (final item in items) {
      // Get timestamp of last tracked event (any date), then check frequency logic.
      final lastCompleted = await repository.getLastCompleted(item, babyId: babyId);
      if (!item.frequency.isDue(now, lastCompleted)) continue;

      dueItems.add(ReminderStatus(item: item));
    }

    return dueItems.isEmpty ? const RemindersState.allCompleted() : RemindersState.due(items: dueItems);
  }
}

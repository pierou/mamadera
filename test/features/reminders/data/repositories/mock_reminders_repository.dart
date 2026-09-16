import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/repositories/reminders_repository.dart';

/// Simple in-memory mock of [RemindersRepository] for unit tests.
class MockRemindersRepository implements RemindersRepository {
  /// Maps item ID → last completed DateTime (simulates tracking event).
  final Map<String, DateTime?> lastCompletedByItem = {};

  /// Maps item ID → dismissal time (simulates cooldown dismissals).
  final Map<String, DateTime> dismissalTimeById = {};

  /// Maps item ID → persisted enabled flag (absent = jamais touché = activé).
  final Map<String, bool> enabledById = {};

  /// Nombre d'appels à [setEnabled] (pour vérifier qu'un toggle écrit bien en base).
  int setEnabledCallCount = 0;

  /// Nombre de recherches de dernière complétion — prouve qu'un rappel éteint
  /// n'est plus du tout interrogé, et qu'un toggle provoque bien un nouveau scan.
  int completedLookupCount = 0;

  /// Identifiants effectivement interrogés par [getLastCompleted].
  final Set<String> lookedUpItemIds = {};

  /// Baby the most recent [getLastCompleted] call was scoped to (null = unscoped).
  String? lastCompletedBabyId;

  /// Rappels personnalisés en mémoire, indexés par leur identifiant auto-incrémenté.
  final Map<int, CustomReminder> customRemindersById = {};

  /// Nombre d'appels reçus pour chaque écriture — pas de succès : prouver qu'une
  /// écriture a été tentée, et une seule.
  int insertCustomCallCount = 0;
  int editCustomCallCount = 0;
  int deleteCustomCallCount = 0;

  /// Quand vrai, créer/modifier un rappel personnalisé échoue comme l'écriture
  /// d'un stockage refusé (carte pleine, ligne rejetée), pour tester le retour
  /// visible au parent.
  bool failCustomWrites = false;

  /// Idem pour la suppression : une suppression qui échoue ne doit rien emporter.
  bool failCustomDelete = false;

  int _nextCustomId = 1;

  @override
  Future<DateTime?> getLastCompleted(ReminderItem reminder, {String? babyId}) async {
    lastCompletedBabyId = babyId;
    completedLookupCount++;
    lookedUpItemIds.add(reminder.id);
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

  @override
  Future<Map<String, bool>> getEnabledByItemId() async => Map.of(enabledById);

  @override
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    setEnabledCallCount++;
    enabledById[itemId] = enabled;
  }

  @override
  Future<List<CustomReminder>> getCustomReminders() async {
    // Ordre d'insertion = ordre des identifiants, comme `ORDER BY id` en base.
    return customRemindersById.values.toList(growable: false);
  }

  @override
  Future<int> insertCustomReminder(CustomReminder reminder) async {
    insertCustomCallCount++;
    if (failCustomWrites) throw StateError('stockage refusé');
    final id = _nextCustomId++;
    customRemindersById[id] = reminder.copyWith(id: id);
    return id;
  }

  @override
  Future<void> updateCustomReminder(CustomReminder reminder) async {
    editCustomCallCount++;
    if (failCustomWrites) throw StateError('stockage refusé');
    final id = reminder.id;
    if (id == null || !customRemindersById.containsKey(id)) {
      throw StateError('Rappel personnalisé inexistant: $id');
    }
    customRemindersById[id] = reminder;
  }

  @override
  Future<void> deleteCustomReminder(int id) async {
    // Le compteur compte les demandes reçues, pas les succès : un test qui
    // refuse l'écriture doit pouvoir prouver que l'app a bien essayé.
    deleteCustomCallCount++;
    if (failCustomDelete) throw StateError('stockage refusé');
    customRemindersById.remove(id);
    // Comme la vraie implémentation : supprimer le rappel emporte son
    // extinction et son rang, sinon un fantôme survit à chaque export.
    final key = '${CustomReminderPresets.customIdPrefix}$id';
    enabledById.remove(key);
    dismissalTimeById.remove(key);
  }
}

import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/repositories/reminders_repository.dart';

/// Simple in-memory mock of [RemindersRepository] for unit tests.
class MockRemindersRepository implements RemindersRepository {
  /// Maps item ID → last completed DateTime (simulates tracking event).
  final Map<String, DateTime?> lastCompletedByItem = {};

  /// Maps item ID → last manual completion DateTime (simulates the
  /// `reminder_completions` log).
  final Map<String, DateTime?> manualCompletedByItem = {};

  /// Maps item ID → last "ignore" DateTime (simulates `reminder_dismissals`).
  final Map<String, DateTime?> dismissedById = {};

  /// Maps item ID → persisted enabled flag (absent = never accessed = enabled).
  final Map<String, bool> enabledById = {};

  /// Number of calls to [setEnabled] (to verify that the toggle switch is correctly written to the database).
  int setEnabledCallCount = 0;

  /// Number of recent searches – indicates that a reminder has been dismissed.
  /// It is no longer being queried at all, and toggling the switch does indeed trigger a new scan.
  int completedLookupCount = 0;

  /// Identifiers actually queried by [getLastCompleted].
  final Set<String> lookedUpItemIds = {};

  /// Baby the most recent [getLastCompleted] call was scoped to (null = unscoped).
  String? lastCompletedBabyId;

  /// Baby the most recent [getLastManualCompletion] call was scoped to.
  String? lastManualCompletedBabyId;

  /// Baby the most recent [getLastDismissal] call was scoped to.
  String? lastDismissalBabyId;

  /// Baby the most recent [getEnabledByItemId] call was scoped to.
  String? lastGetEnabledBabyId;

  /// Baby the most recent [setEnabled] call was scoped to.
  String? lastEnabledBabyId;

  /// Personalized reminders are stored in memory and indexed by their automatically incrementing identifier.
  final Map<int, CustomReminder> customRemindersById = {};

  /// Number of calls received for each entry – no success: unable to prove that a...
  /// An attempt at writing has been made, and only one.
  int insertCustomCallCount = 0;

  /// Number of handwritten records received ([recordCompletion]) and the baby to whom they pertain.
  /// The last one was scoped (`null` = not scoped).
  int recordCompletionCallCount = 0;
  String? lastRecordCompletionBabyId;

  /// Number of ignored reminders ([dismissReminder]) and the baby to whom the last reminder was sent.
  /// The writing has been scoped (`null` = not scoped).
  int dismissCallCount = 0;
  String? lastDismissBabyId;
  int editCustomCallCount = 0;
  int deleteCustomCallCount = 0;

  /// When true, creating or modifying a custom reminder fails, similar to writing.
  /// due to a storage failure (full card, rejected line), to test the feedback mechanism.
  /// visible au parent.
  bool failCustomWrites = false;

  /// The same applies to deletion: a failed deletion should not remove anything.
  bool failCustomDelete = false;

  int _nextCustomId = 1;

  @override
  Future<DateTime?> getLastCompleted(ReminderItem reminder,
      {String? babyId}) async {
    lastCompletedBabyId = babyId;
    completedLookupCount++;
    lookedUpItemIds.add(reminder.id);
    // Faithful to the implementation (D2 invariant): an item without a subtype is...
    // Not determined by any specific event.
    if (reminder.subtypeValue == null) return null;
    return lastCompletedByItem[reminder.id];
  }

  @override
  Future<DateTime?> getLastManualCompletion(String itemId,
      {String? babyId}) async {
    lastManualCompletedBabyId = babyId;
    lookedUpItemIds.add(itemId);
    return manualCompletedByItem[itemId];
  }

  @override
  Future<DateTime?> getLastDismissal(String itemId, {String? babyId}) async {
    lastDismissalBabyId = babyId;
    return dismissedById[itemId];
  }

  @override
  Future<void> recordCompletion(String itemId,
      {String? babyId, DateTime? at}) async {
    recordCompletionCallCount++;
    lastRecordCompletionBabyId = babyId;
    manualCompletedByItem[itemId] = at ?? DateTime.now();
  }

  @override
  Future<void> dismissReminder(String itemId,
      {String? babyId, DateTime? at}) async {
    dismissCallCount++;
    lastDismissBabyId = babyId;
    dismissedById[itemId] = at ?? DateTime.now();
  }

  @override
  Future<Map<String, bool>> getEnabledByItemId({String? babyId}) async {
    lastGetEnabledBabyId = babyId;
    return Map.of(enabledById);
  }

  @override
  Future<void> setEnabled(String itemId,
      {required bool enabled, String? babyId}) async {
    setEnabledCallCount++;
    lastEnabledBabyId = babyId;
    enabledById[itemId] = enabled;
  }

  @override
  Future<List<CustomReminder>> getCustomReminders({String? babyId}) async {
    // Insertion order = the order of identifiers, similar to `ORDER BY id` in a database.
    return customRemindersById.values.toList(growable: false);
  }

  @override
  Future<int> insertCustomReminder(CustomReminder reminder,
      {String? babyId}) async {
    insertCustomCallCount++;
    if (failCustomWrites) throw StateError('stockage refusé');
    final id = _nextCustomId++;
    customRemindersById[id] = reminder.copyWith(id: id);
    return id;
  }

  @override
  Future<void> updateCustomReminder(CustomReminder reminder,
      {String? babyId}) async {
    editCustomCallCount++;
    if (failCustomWrites) throw StateError('stockage refusé');
    final id = reminder.id;
    if (id == null || !customRemindersById.containsKey(id)) {
      throw StateError('Rappel personnalisé inexistant: $id');
    }
    customRemindersById[id] = reminder;
  }

  @override
  Future<void> deleteCustomReminder(int id, {String? babyId}) async {
    // The counter tracks the number of requests received, not the number of successful operations: a test that...
    // If an application is rejected, the system must be able to demonstrate that the application was indeed processed.
    deleteCustomCallCount++;
    if (failCustomDelete) throw StateError('stockage refusé');
    customRemindersById.remove(id);
    // Like the actual implementation: removing a callback also removes its associated priority level.
    // (and its `reminder_dismissals` line, in the database), otherwise a ghost record persists.
    // For each export.
    final key = '${CustomReminderPresets.customIdPrefix}$id';
    enabledById.remove(key);
  }
}

/// [MockRemindersRepository] where the "ignore" functionality is specific to each baby.
/// like in the base (a `reminder_dismissals` row has a `baby_id`):
/// A suppression for baby A never obscures the reminder for baby B.
class ScopedDismissalRemindersRepository extends MockRemindersRepository {
  final Map<String, DateTime?> _dismissedByKey = {};

  /// Implement a time-based deletion (24-hour window tests).
  void seedDismissal(String itemId, {String? babyId, required DateTime at}) {
    _dismissedByKey['$itemId@${babyId ?? 'all'}'] = at;
  }

  @override
  Future<DateTime?> getLastDismissal(String itemId, {String? babyId}) async {
    lastDismissalBabyId = babyId;
    return _dismissedByKey['$itemId@${babyId ?? 'all'}'];
  }

  @override
  Future<void> dismissReminder(String itemId,
      {String? babyId, DateTime? at}) async {
    dismissCallCount++;
    lastDismissBabyId = babyId;
    _dismissedByKey['$itemId@${babyId ?? 'all'}'] = at ?? DateTime.now();
  }
}

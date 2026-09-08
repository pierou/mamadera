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
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../domain/entities/custom_reminder.dart';
import 'reminder_providers.dart';

/// Reminders created by the parent, as recorded.
///
/// It **only** contains personalized reminders; the four presets remain.
/// in `dynamicRemindersProvider`, because they don't exist in the database and are...
/// They are reconstructing the baby's profile based on the available data. The `enabledRemindersProvider` function adds...
/// Both are subject to the same regulations, and the extinction rules apply identically to both.
/// familles.
final customRemindersProvider =
    AsyncNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>(
  CustomRemindersNotifier.new,
);

class CustomRemindersNotifier extends AsyncNotifier<List<CustomReminder>> {
  @override
  Future<List<CustomReminder>> build() async {
    // ref.watch: A reset of the database from the menu should clear the...
    // list of personalized reminders, but do not display older items. The...
    // Please note: only entries from the active profile are displayed.
    // "Profileless" porting is only used when no profile exists.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getCustomReminders(babyId: profile?.id);
  }

  /// Writes [reminder] and returns the `custom_<id>` key to be used in.
  /// `reminder_settings` - this is the key that the switch on the Settings screen controls.
  /// manipulate, but never misrepresent.
  Future<String> create(CustomReminder reminder) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    final id =
        await repository.insertCustomReminder(reminder, babyId: profile?.id);
    await _refreshAfterWrite();
    return '${CustomReminderPresets.customIdPrefix}$id';
  }

  /// Delete the identifier reminder [CustomReminder.id].
  ///
  /// `edit` instead of `update`: `AsyncNotifier` already has an `update` function that...
  /// It replaces the entire state and the shadowing of a method within the framework with a single entity.
  /// a "business verb" is a source of silent bugs.
  Future<void> edit(CustomReminder reminder) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.updateCustomReminder(reminder, babyId: profile?.id);
    await _refreshAfterWrite();
  }

  /// Removes the [id] reminder and, along with it, its expiration date and priority.
  ///
  /// The `reminderSettingsProvider` is invalidated here, not just expired.
  /// The line `custom_<id>` has just been deleted from the database, and we need to keep it in memory.
  /// would leave behind a "ghost" of `false` – harmless today, but destined to...
  /// Survive each export as long as the table hasn't been reviewed.
  Future<void> remove(int id) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.deleteCustomReminder(id, babyId: profile?.id);
    ref.invalidate(reminderSettingsProvider);
    await _refreshAfterWrite();
  }

  /// Refresh the list.
  ///
  /// The welcome messages automatically guide you: the reminder notification system.
  /// It reactively depends on the recall chain activated → service (see).
  /// [RemindersNotifier.build]), so a new reminder is created, and a reminder...
  /// deleted: disappears completely and instantly, without any errors or issues.
  /// a stalled reassessment, stuck on a temporary interpretation of the...
  /// service autoDispose que l'ancienne `ref.invalidate` provoquait.
  Future<void> _refreshAfterWrite() async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    state = AsyncData(await repository.getCustomReminders(babyId: profile?.id));
  }
}

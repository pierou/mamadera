import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../domain/entities/custom_reminder.dart';
import 'reminder_providers.dart';
import 'reminder_sync_notifier.dart';

/// The reminders created by the parent, as recorded in the database.
///
/// It contains **only** the personalized ones; the presets live in
/// `dynamicRemindersProvider` because they do not exist in the database — they
/// are reconstructed from the baby profile. `enabledRemindersProvider` merges
/// both; the enable/disable rules apply identically to each family.
final customRemindersProvider =
    AsyncNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>(
  CustomRemindersNotifier.new,
);

class CustomRemindersNotifier extends AsyncNotifier<List<CustomReminder>> {
  @override
  Future<List<CustomReminder>> build() async {
    // ref.watch: a database reset from the menu must clear the list without
    // showing stale items, and only the active profile's rows are visible —
    // the profileless scope is used only while no profile exists.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getCustomReminders(babyId: profile?.id);
  }

  /// Write [reminder] and return the `custom_<id>` key that `reminder_settings`
  /// uses for it — the key the settings-screen switch manipulates.
  Future<String> create(CustomReminder reminder) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    final id =
        await repository.insertCustomReminder(reminder, babyId: profile?.id);
    await _refreshAfterWrite();
    return '${CustomReminderPresets.customIdPrefix}$id';
  }

  /// Update the reminder with [CustomReminder.id].
  ///
  /// `edit` rather than `update`: `AsyncNotifier` already has an `update`
  /// method that replaces the whole state; shadowing a framework method with
  /// a business verb is a source of silent bugs.
  Future<void> edit(CustomReminder reminder) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.updateCustomReminder(reminder, babyId: profile?.id);
    await _refreshAfterWrite();
  }

  /// Remove the reminder with [id], along with its settings row.
  ///
  /// `reminderSettingsProvider` is invalidated (not merely refreshed): the
  /// `custom_<id>` row was just deleted from the database, and keeping the
  /// in-memory map would leave a ghost `false` — harmless today but destined
  /// to survive every export until the table is next reviewed.
  Future<void> remove(int id) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.deleteCustomReminder(id, babyId: profile?.id);
    ref.invalidate(reminderSettingsProvider);
    await _refreshAfterWrite();
  }

  /// Refresh the list after a write.
  ///
  /// The home pills follow automatically: the reminders service reactively
  /// depends on this provider through the enabled-reminders → service chain
  /// (see [RemindersNotifier.build]), so a created or removed reminder
  /// appears or disappears there without a stalled re-evaluation — the
  /// failure mode the old `ref.invalidate` of the `autoDispose` service
  /// caused.
  /// The OS schedule is re-reconciled as well (D2): a custom reminder is a
  /// schedulable item, and its label travels into the notification text.
  Future<void> _refreshAfterWrite() async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    state = AsyncData(await repository.getCustomReminders(babyId: profile?.id));
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }
}

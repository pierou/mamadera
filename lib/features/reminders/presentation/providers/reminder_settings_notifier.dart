import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminder_item_setting.dart';
import '../../domain/services/notification_time.dart';
import 'reminder_providers.dart';
import 'reminder_sync_notifier.dart';

/// What the parent stored for each reminder of the active scope, as
/// `item_id → row` (the switch and the per-reminder hour, B30).
///
/// Only rows that exist are in the map. A missing key means "never touched",
/// which resolves to the item's own `ReminderItem.enabledByDefault` (B6): eye
/// and face care and vitamin K are on from the first launch, vitamin D is off
/// for a baby created on 1.4.0 or later and on for one carried over from
/// 1.3.x (the v14 seed, PLAN-v1.4.0 D-R1). Off-by-default is still **visible**
/// in the list — the switch shows it, which is the point of the decision.
///
/// This is the single read of `reminder_settings`: the switches, the hour
/// subtitles and the due list all project from here, so two surfaces of the same
/// reminder can never disagree (the B31 defect class).
final reminderSettingsProvider = AsyncNotifierProvider<ReminderSettingsNotifier,
    Map<String, ReminderItemSetting>>(
  ReminderSettingsNotifier.new,
);

class ReminderSettingsNotifier
    extends AsyncNotifier<Map<String, ReminderItemSetting>> {
  @override
  Future<Map<String, ReminderItemSetting>> build() async {
    // ref.watch: a system reset from the menu rebuilds this provider against the
    // now-empty `reminder_settings` table, and switching babies must re-read the
    // other baby's row (or the profileless `''` scope until a profile exists) —
    // so the switches and the hours always reflect the current scope.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getSettingsByItemId(babyId: profile?.id);
  }

  /// Persist the toggle and update local state — the switch does not flicker
  /// waiting for a round trip to re-read the data.
  ///
  /// The home pills update on their own: the reminders service reactively
  /// depends on this provider through the settings → enabled-reminders → service
  /// chain (see [RemindersNotifier.build]), so a disabled reminder disappears
  /// from the pills without this method invalidating anything. The OS schedule is
  /// re-reconciled too: a disabled item must stop producing notifications (D2).
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setEnabled(itemId, enabled: enabled, babyId: profile?.id);

    _put(itemId, (current) => current.copyWith(enabled: enabled),
        whenAbsent: () => ReminderItemSetting(enabled: enabled));
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Give one reminder its **own** notification hour (B30), then re-reconcile the
  /// OS schedule — the plan entry moves to the new hour on the next diff, by id
  /// (the hour changes `at`, and `at` is already compared).
  ///
  /// Takes the [item] rather than an id because creating a row needs the item's
  /// own default: picking an hour for vitamin D is not consent to switch it on
  /// (B6).
  Future<void> setTime(ReminderItem item,
      {required int hour, required int minute}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    final stored = formatNotificationTime(hour: hour, minute: minute);
    await repository.setItemTime(
      item.id,
      timeOfDay: stored,
      enabledIfNew: item.enabledByDefault,
      babyId: profile?.id,
    );

    _put(
      item.id,
      (current) => current.copyWith(timeOfDay: stored),
      whenAbsent: () => ReminderItemSetting(
        enabled: item.enabledByDefault,
        timeOfDay: stored,
      ),
    );
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Back to the global hour for one reminder (B30's "inherit"): the stored hour
  /// becomes NULL, the switch and the rest of the row are untouched.
  Future<void> useGlobalTime(ReminderItem item) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.clearItemTime(item.id, babyId: profile?.id);

    final current =
        (state.value ?? const <String, ReminderItemSetting>{})[item.id];
    if (current != null) {
      _put(item.id, (row) => row.copyWith(timeOfDay: null));
    }
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Update one entry of the cached map without a re-read, keeping the columns
  /// this method does not own exactly as they are.
  void _put(
    String itemId,
    ReminderItemSetting Function(ReminderItemSetting current) update, {
    ReminderItemSetting Function()? whenAbsent,
  }) {
    final current = state.value ?? const <String, ReminderItemSetting>{};
    final row = current[itemId];
    if (row == null && whenAbsent == null) return;
    state = AsyncData({
      ...current,
      itemId: row == null ? whenAbsent!() : update(row),
    });
  }
}

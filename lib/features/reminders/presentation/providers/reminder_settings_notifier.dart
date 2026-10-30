import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import 'reminder_providers.dart';
import 'reminder_sync_notifier.dart';

/// Status (enabled/disabled) of the reminders, as a map `item_id → enabled`.
///
/// A missing key means "never touched", which is **enabled**: disabling is an
/// opt-out, not a subscription. A parent who never opens this screen still
/// sees Vitamin D, Vitamin K, eye and face care — the switches only hide what
/// is already there.
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, Map<String, bool>>(
  ReminderSettingsNotifier.new,
);

class ReminderSettingsNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    // ref.watch: a system reset from the menu rebuilds this provider against
    // the now-empty `reminder_settings` table, and switching babies must
    // re-read the other baby's row (or the profileless `''` scope until a
    // profile exists) — so the switches always reflect the current scope.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getEnabledByItemId(babyId: profile?.id);
  }

  /// Persist the toggle and update local state — the switch does not flicker
  /// waiting for a round trip to re-read the data.
  ///
  /// The home pills update on their own: the reminders service reactively
  /// depends on this provider through the settings → enabled-reminders →
  /// service chain (see [RemindersNotifier.build]), so a disabled reminder
  /// disappears from the pills without this method invalidating anything.
  /// The OS schedule is re-reconciled too: a disabled item must stop
  /// producing notifications (D2).
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setEnabled(itemId, enabled: enabled, babyId: profile?.id);

    final current = state.value ?? const <String, bool>{};
    state = AsyncData({...current, itemId: enabled});
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }
}

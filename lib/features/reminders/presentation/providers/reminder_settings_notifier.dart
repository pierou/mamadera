import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import 'reminder_providers.dart';

/// Status (enabled/disabled) of the preset reminders, in the format `item_id → enabled`.
///
/// A missing key indicates "never touched," therefore it is **enabled**: the shutdown is...
/// An opt-out option, not a subscription. A parent who never uses this...
/// The screen continues to display information about Vitamin D, Vitamin K, eye care, and facial care products.
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, Map<String, bool>>(
  ReminderSettingsNotifier.new,
);

class ReminderSettingsNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    // ref.watch: After resetting the system from the menu, this...
    // The provider is being rebuilt and is re-reading an empty `reminder_settings` table.
    // The adjustment is made for each baby individually: the displayed value corresponds to the settings for the currently active profile, and...
    // sharing (`''`) until a profile exists — a baby's transition.
    // Therefore, please reload the switches on the page.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getEnabledByItemId(babyId: profile?.id);
  }

  /// It saves the selected option and then updates the local state – the switch will not...
  /// Don't blink, you don't have time to re-examine the data.
  ///
  /// The welcome message automatically updates: the reminder notification system.
  /// It reactively depends on the settings chain: settings → reminders activated → service.
  /// (see [RemindersNotifier.build]), therefore, the deactivation of a reminder.
  /// It propagates to all the pills without invalidating them all at once.
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setEnabled(itemId, enabled: enabled, babyId: profile?.id);

    final current = state.value ?? const <String, bool>{};
    state = AsyncData({...current, itemId: enabled});
  }
}

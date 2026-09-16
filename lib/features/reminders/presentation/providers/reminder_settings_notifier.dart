import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_providers.dart';

/// État activé/désactivé des rappels préréglés, sous la forme `item_id → activé`.
///
/// Une clé absente signifie « jamais touché », donc **activé** : l'extinction est
/// une option de retrait, pas une adhésion. Un parent qui n'ouvre jamais cet
/// écran continue de recevoir Vit. D, Vit. K, Yeux et Visage.
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, Map<String, bool>>(
  ReminderSettingsNotifier.new,
);

class ReminderSettingsNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    // ref.watch : après une réinitialisation de la base depuis le menu, ce
    // provider est reconstruit et relit une table `reminder_settings` vide.
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getEnabledByItemId();
  }

  /// Enregistre le choix, puis rafraîchit les pastilles de l'accueil.
  ///
  /// L'état local est mis à jour immédiatement — le switch ne clignote pas le
  /// temps de relire la base — et [reminderNotifierProvider] est invalidé : sans
  /// ça, un rappel que l'on vient d'éteindre resterait affiché sur l'accueil
  /// jusqu'au prochain sondage de cinq minutes.
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setEnabled(itemId, enabled: enabled);

    final current = state.value ?? const <String, bool>{};
    state = AsyncData({...current, itemId: enabled});
    ref.invalidate(reminderNotifierProvider);
  }
}

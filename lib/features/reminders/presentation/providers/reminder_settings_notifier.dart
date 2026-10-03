import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
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
    // Le réglage est par bébé : la ligne lue est celle du profil actif, et
    // le partage ('') tant qu'aucun profil n'existe — un basculement de bébé
    // recharge donc les switches de la page.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getEnabledByItemId(babyId: profile?.id);
  }

  /// Enregistre le choix, puis met à jour l'état local — le switch ne
  /// clignote pas le temps de relire la base.
  ///
  /// L'accueil, lui, se met à jour tout seul : le notifieur de rappels
  /// dépend réactivement de la chaîne réglages → rappels activés → service
  /// (voir [RemindersNotifier.build]), donc l'extinction d'un rappel
  /// propage jusqu'aux pastilles sans invalidation en une fois.
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setEnabled(itemId, enabled: enabled, babyId: profile?.id);

    final current = state.value ?? const <String, bool>{};
    state = AsyncData({...current, itemId: enabled});
  }
}

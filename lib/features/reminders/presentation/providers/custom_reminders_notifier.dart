import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../domain/entities/custom_reminder.dart';
import 'reminder_providers.dart';

/// Rappels inventés par le parent, tels qu'enregistrés.
///
/// Ne contient **que** les rappels personnalisés : les quatre préréglages restent
/// dans `dynamicRemindersProvider`, parce qu'ils n'existent pas en base et se
/// reconstruisent depuis le profil du bébé. `enabledRemindersProvider` additionne
/// les deux, et c'est là que l'extinction s'applique, à l'identique pour les deux
/// familles.
final customRemindersProvider =
    AsyncNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>(
  CustomRemindersNotifier.new,
);

class CustomRemindersNotifier extends AsyncNotifier<List<CustomReminder>> {
  @override
  Future<List<CustomReminder>> build() async {
    // ref.watch : une réinitialisation de la base depuis le menu doit vider la
    // liste des rappels personnalisés, pas servir les anciens objets. Le
    // rappel est porté par la ligne : on ne lit que ceux du profil actif, plus
    // le portage partagé hérité d'une installation sans profil.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getCustomReminders(babyId: profile?.id);
  }

  /// Écrit [reminder] et renvoie la clé `custom_<id>` à utiliser dans
  /// `reminder_settings` — c'est cette clé que le switch de l'écran Réglages
  /// manipule, jamais le libellé.
  Future<String> create(CustomReminder reminder) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    final id = await repository.insertCustomReminder(reminder, babyId: profile?.id);
    await _refreshAfterWrite();
    return '${CustomReminderPresets.customIdPrefix}$id';
  }

  /// Écrase le rappel d'identifiant [CustomReminder.id].
  ///
  /// `edit` et non `update` : `AsyncNotifier` possède déjà un `update` qui
  /// remplace l'état complet, et le shadowing d'une méthode du framework par un
  /// verbe métier est une source de bugs silencieux.
  Future<void> edit(CustomReminder reminder) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.updateCustomReminder(reminder, babyId: profile?.id);
    await _refreshAfterWrite();
  }

  /// Supprime le rappel [id] et, avec lui, son extinction et son rang.
  ///
  /// `reminderSettingsProvider` est invalidé et pas seulement expiré ici : la
  /// ligne `custom_<id>` vient d'être effacée en base, et la garder en mémoire
  /// laisserait un `false` fantôme — inoffensif aujourd'hui, mais condamné à
  /// survivre à chaque export tant qu'on ne relit pas la table.
  Future<void> remove(int id) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.deleteCustomReminder(id, babyId: profile?.id);
    ref.invalidate(reminderSettingsProvider);
    await _refreshAfterWrite();
  }

  /// Recharge la liste.
  ///
  /// Les pastilles d'accueil suivent tout seules : le notifieur de rappels
  /// dépend réactivement de la chaîne rappels activés → service (voir
  /// [RemindersNotifier.build]), donc un rappel créé apparaît et un rappel
  /// supprimé disparaît sans invalidation en une fois — et sans le risque
  /// d'une réévaluation orpheline bloquée sur une lecture transitoire du
  /// service autoDispose que l'ancienne `ref.invalidate` provoquait.
  Future<void> _refreshAfterWrite() async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    state = AsyncData(await repository.getCustomReminders(babyId: profile?.id));
  }
}

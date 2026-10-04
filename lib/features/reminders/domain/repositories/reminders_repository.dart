import '../entities/custom_reminder.dart';
import '../entities/reminder_item.dart';

/// Contract de persistance pour les rappels.
abstract class RemindersRepository {
  /// Renvoie la date de l'événement de suivi le plus récent pour l'item donné.
  ///
  /// [babyId] restreint la recherche aux événements du bébé : `null` (pas de
  /// profil actif) = uniquement les événements posés sans profil
  ///
  /// Un item sans [ReminderItem.subtypeValue] est détaché d'un soin : renvoie
  /// toujours `null`, il ne se règle que par [getLastManualCompletion]
  /// (invariant D2).
  Future<DateTime?> getLastCompleted(ReminderItem item, {String? babyId});

  /// Renvoie la date de la complétion manuelle la plus récente de [itemId].
  ///
  /// C'est la seule lecture des lignes de `reminder_completions` : elle règle
  /// les items dont [ReminderItem.completionSource] vaut 'manual'. Lecture
  /// strictement scopée au portage : la ligne de l'état sans profil ('')
  /// n'applique à aucun bébé réel.
  Future<DateTime?> getLastManualCompletion(String itemId, {String? babyId});

  /// Renvoie la date de l'ignorer (« cacher ») la plus récente de [itemId].
  ///
  /// Lecture strictement scopée au portage : un « ignorer » fait sans profil
  /// ('') n'applique à aucun bébé réel, seulement à l'état sans profil.
  Future<DateTime?> getLastDismissal(String itemId, {String? babyId});

  /// Enregistre une complétion manuelle de [itemId] (colonne du bébé [babyId]).
  ///
  /// Ajoute une ligne à `reminder_completions` ; [at] par défaut est « maintenant ».
  Future<void> recordCompletion(String itemId, {String? babyId, DateTime? at});

  /// Enregistre un « ignorer » de [itemId] (colonne du bébé [babyId]).
  ///
  /// Upsert sur (baby_id, item_id) dans `reminder_dismissals` : une seule
  /// ligne par bébé et par item, rafraîchie à chaque « ignorer ».
  Future<void> dismissReminder(String itemId, {String? babyId, DateTime? at});

  /// Renvoie l'état activé/désactivé par identifiant d'item.
  ///
  /// L'absence de clé signifie « activé par défaut ». Lecture strictement
  /// scopée au portage : la ligne '' (état sans profil) n'applique à aucun
  /// bébé réel — un bébé nouveau part donc des défauts.
  Future<Map<String, bool>> getEnabledByItemId({String? babyId});

  /// Met à jour ou crée la ligne activé/désactivé pour [itemId] (colonne du
  /// bébé [babyId]).
  Future<void> setEnabled(String itemId, {required bool enabled, String? babyId});

  /// Renvoie les rappels personnalisés du portage de [babyId] (la ligne ''
  /// n'étant visible que sans profil), triés par id d'insertion.
  Future<List<CustomReminder>> getCustomReminders({String? babyId});

  /// Insère un rappel personnalisé (colonne du bébé [babyId]).
  ///
  /// Renvoie l'identifiant de la ligne insérée.
  Future<int> insertCustomReminder(CustomReminder reminder, {String? babyId});

  /// Met à jour un rappel personnalisé existant (la colonne du bébé [babyId]
  /// n'est pas réécrite : un renommage ne change pas le propriétaire).
  Future<void> updateCustomReminder(CustomReminder reminder, {String? babyId});

  /// Supprime un rappel personnalisé et purge ses lignes de réglage et
  /// d'ignorer (tous bébés : la clé d'item meurt avec la ligne).
  Future<void> deleteCustomReminder(int id, {String? babyId});
}

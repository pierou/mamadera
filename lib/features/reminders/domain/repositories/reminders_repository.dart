import '../entities/custom_reminder.dart';
import '../entities/reminder_item.dart';

/// Repository interface for reminder persistence and queries.
abstract class RemindersRepository {
  /// Returns the timestamp of the last tracked event for [item], regardless of date.
  /// Used by rolling-interval reminders (e.g. Vitamin K every 30 days) to determine
  /// whether the due period has elapsed since last completion.
  ///
  /// When [babyId] is non-null the lookup is restricted to events belonging to that
  /// baby, so completing a care routine for one baby does not suppress the same
  /// reminder for a sibling. When [babyId] is null the lookup spans every baby —
  /// the historical behaviour, kept deliberately for a fresh install where the
  /// profile has not been created yet: with nothing to attribute an event to, the
  /// safe outcome is to treat any matching event as a completion rather than fire a
  /// reminder the parent already did.
  Future<DateTime?> getLastCompleted(ReminderItem item, {String? babyId});

  /// Persists when a user dismissed a reminder (for cooldown tracking).
  ///
  /// NOTE: dismissals are global across babies by design-at-v1. `reminder_dismissals`
  /// keys rows by a unique `item_id` and has no baby column (and no FK to
  /// `baby_profiles`), so one dismissal mutes the item for every baby until the
  /// cooldown expires. Scoping a dismissal per baby would mean rebuilding that table
  /// (composite key + migration), which is out of scope here — unlike tracking
  /// events, a dismissal is a short-lived "not now" (4 h cooldown), not user data.
  Future<void> saveDismissalTime(String itemId, DateTime time);

  /// Returns the last dismissal timestamp for [itemId], or null if never dismissed.
  ///
  /// NOTE: global across babies by design-at-v1 — see [saveDismissalTime] for why
  /// the value cannot be scoped to a baby without rebuilding `reminder_dismissals`.
  Future<DateTime?> getDismissalTime(String itemId);

  /// Enabled flag persisted for every reminder item id.
  ///
  /// A missing id means the reminder was never touched: it is **enabled**. The
  /// presets are opt-out, not opt-in — a parent who installs the app must get the
  /// vitamin D reminder without having to discover a settings screen first.
  Future<Map<String, bool>> getEnabledByItemId();

  /// Persists whether [itemId] should fire, so a reminder nobody wants can be
  /// switched off without deleting it (the preset list stays intact).
  Future<void> setEnabled(String itemId, {required bool enabled});

  /// Tous les rappels personnalisés, dans l'ordre de création.
  Future<List<CustomReminder>> getCustomReminders();

  /// Écrit [reminder] et renvoie son identifiant attribué, dont la couche
  /// présentation fait la clé `custom_<id>` des réglages.
  Future<int> insertCustomReminder(CustomReminder reminder);

  /// Écrase la ligne d'identifiant [CustomReminder.id].
  Future<void> updateCustomReminder(CustomReminder reminder);

  /// Supprime le rappel **et** ses lignes de réglage et de rang.
  ///
  /// Un identifiant de préréglage reparaît à chaque lancement, ses lignes
  /// doivent donc survivre à une extinction ; un `custom_<id>` supprimé ne renaît
  /// jamais, et laisser derrière lui un `enabled = false` le rendrait éternel
  /// dans chaque sauvegarde JSON.
  Future<void> deleteCustomReminder(int id);
}

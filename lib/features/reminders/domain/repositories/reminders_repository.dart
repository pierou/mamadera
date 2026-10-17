import '../entities/custom_reminder.dart';
import '../entities/reminder_item.dart';

/// Persistence contract for reminders.
abstract class RemindersRepository {
  /// Returns the date of the most recent follow-up event for the given item.
  ///
  /// [babyId] restricts the search to events related to the baby: `null` (no filter).
  /// (active profile) = only events without a profile assigned.
  ///
  /// An item without a [ReminderItem.subtypeValue] is detached from a care plan: returns.
  /// It is always `null` and is only adjusted by [getLastManualCompletion].
  /// (invariant D2).
  Future<DateTime?> getLastCompleted(ReminderItem item, {String? babyId});

  /// Returns the date of the most recent manual completion for [itemId].
  ///
  /// This is the only way to read the `reminder_completions` data: it resolves the issue.
  /// The items for which the `completionSource` property of the `ReminderItem` is set to 'manual'. Reading.
  /// strictly limited to carrying: the "state" line without a profile ('').
  /// It does not apply to any real baby.
  Future<DateTime?> getLastManualCompletion(String itemId, {String? babyId});

  /// Returns the most recent "ignore" date for the specified item [itemId].
  ///
  /// Strictly scoped reading for data transfer: an "ignore" action performed without a profile.
  /// (`''`) does not apply to any real baby, only to the state without a profile.
  Future<DateTime?> getLastDismissal(String itemId, {String? babyId});

  /// Records a manual completion of [itemId] (column for baby [babyId]).
  ///
  /// Adds a line to `reminder_completions`; the default value is "now".
  Future<void> recordCompletion(String itemId, {String? babyId, DateTime? at});

  /// Records a "dismiss" action for item [itemId] (column for baby [babyId]).
  ///
  /// Upsert (insert or update) the (baby_id, item_id) pair in the `reminder_dismissals` table: only one entry.
  /// For each baby and each item, the list is displayed line by line and updates with every "ignore" action.
  Future<void> dismissReminder(String itemId, {String? babyId, DateTime? at});

  /// Returns the enabled/disabled status by item ID.
  ///
  /// The absence of a key indicates "default enabled." Read-only access.
  /// scoped to the carrier: the `''` (unspecified state) setting does not apply to any.
  /// Real baby – a newborn baby, therefore, has imperfections.
  Future<Map<String, bool>> getEnabledByItemId({String? babyId});

  /// Updates or creates the "enabled/disabled" flag for [itemId] (column in the...).
  /// baby [babyId].
  Future<void> setEnabled(String itemId, {required bool enabled, String? babyId});

  /// Returns the personalized reminders for the care of [babyId] (the line `''` ).
  /// They are only visible without a profile, and are sorted by insertion ID.
  Future<List<CustomReminder>> getCustomReminders({String? babyId});

  /// Insert a personalized reminder (baby ID column [babyId]).
  ///
  /// Returns the identifier of the inserted row.
  Future<int> insertCustomReminder(CustomReminder reminder, {String? babyId});

  /// Updates an existing personalized reminder (the baby's ID [babyId] column).
  /// It is not rewritten: renaming does not change the owner).
  Future<void> updateCustomReminder(CustomReminder reminder, {String? babyId});

  /// Removes a custom reminder and clears its associated settings.
  /// (For all babies: the item key is deleted along with the line.)
  Future<void> deleteCustomReminder(int id, {String? babyId});
}

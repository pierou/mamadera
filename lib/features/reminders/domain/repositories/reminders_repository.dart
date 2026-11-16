import '../entities/custom_reminder.dart';
import '../entities/reminder_item.dart';
import '../entities/reminder_item_setting.dart';

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

  /// Returns the stored state of every `(baby_id, item_id)` row of one scope,
  /// keyed by item ID: the switch **and** the per-reminder hour (B30), from one
  /// query per scope — never one query per item.
  ///
  /// The absence of a key indicates "never touched", which the callers resolve
  /// to the item's own defaults (B6's `enabledByDefault`) — not a blanket
  /// "enabled". Read-only access, scoped to the carrier: the `''` (no profile)
  /// settings never apply to a real baby, and a new baby has no row of its own
  /// yet.
  Future<Map<String, ReminderItemSetting>> getSettingsByItemId(
      {String? babyId});

  /// Updates or creates the "enabled/disabled" flag for [itemId] (column for baby [babyId]).
  ///
  /// Touches that one column and nothing else: the row may already carry the
  /// reminder's own hour (B30) or, from M4, its overrides and its removal state,
  /// and flipping a switch must never erase them.
  Future<void> setEnabled(String itemId,
      {required bool enabled, String? babyId});

  /// Writes the per-reminder notification hour of [itemId] (B30).
  ///
  /// [timeOfDay] is a `'HH:mm'` string; only that column is written, so the
  /// switch and every other column of the row keep their value.
  ///
  /// When the scope has no row for [itemId] yet, one is created with
  /// [enabledIfNew] — the item's own `enabledByDefault`. That matters for
  /// vitamin D: choosing an hour is not consent to switch the reminder on, so
  /// an hour written on a default-off item must leave it off (B6).
  Future<void> setItemTime(
    String itemId, {
    required String timeOfDay,
    required bool enabledIfNew,
    String? babyId,
  });

  /// Back to **inherit the global hour** (B30): the `time` column is set to NULL
  /// and the row is kept, so the switch and the rest of the row survive.
  ///
  /// A no-op when the scope has no row at all — absence already means inherited.
  Future<void> clearItemTime(String itemId, {String? babyId});

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

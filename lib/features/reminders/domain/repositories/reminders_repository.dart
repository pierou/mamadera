import '../entities/custom_reminder.dart';
import '../entities/reminder_frequency.dart';
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

  // ── The other columns of the same row (B33, D-R2) ──────────────────────
  //
  // One method per decision, each touching **only its own columns** on conflict —
  // the rule M2 learned the hard way (`setEnabled` used to delete the row and
  // re-insert it, which erased the hour). A writer that overwrote a neighbour's
  // column would produce a row whose meaning depends on the order the parent
  // tapped in, and no test would notice until a rename ate an end date.
  //
  // [enabledIfNew] is needed because `enabled` is NOT NULL and an insert branch
  // must answer it: pass the item's own `enabledByDefault`, never a literal —
  // choosing a rhythm or an end for a default-off reminder must not switch it on
  // (B6: an edit is not consent).

  /// Rename a **preset** for this scope (D-R6). `null` = back to the app's name.
  ///
  /// Never used for a custom reminder: its label is its own column, and a second
  /// source of truth for the same name is how a tile and a notification end up
  /// calling one reminder by two names.
  Future<void> setItemLabel(
    String itemId, {
    required String? label,
    required bool enabledIfNew,
    String? babyId,
  });

  /// Give a preset a rhythm of its own (B33). `null` = the preset's own.
  ///
  /// Writes the frequency *and its parameter together* — `interval_days` for
  /// `every_n_days`, `frequency_date` for `one_time` — and clears the parameter
  /// that does not belong to the new code, plus any stored end when the new
  /// rhythm is a one-shot (D-R5: a one-shot carries an occurrence, not an end;
  /// an end set before the switch is dropped, not kept dormant).
  ///
  /// Throws [ArgumentError] for a `one_time` without a date: the picker requires
  /// one, and a dateless one-shot is only ever a *read* shape (D-R8).
  Future<void> setItemFrequency(
    String itemId, {
    required ReminderFrequency? frequency,
    required bool enabledIfNew,
    String? babyId,
  });

  /// Program an end (D-R5 forms 2 and 3). Both `null` = no end any more.
  ///
  /// At most one of [endDate] / [endAgeMonths] may be given, and neither may be
  /// set on a row whose frequency is `one_time` — the exclusivity is enforced
  /// here, at the write, because the schema only has the columns.
  ///
  /// [endAgeMonths] is stored as canonical whole months (0-180) and is resolved
  /// against the baby's birthdate **at read time**, which is what lets a
  /// corrected birthdate move the end with nothing to invalidate.
  Future<void> setItemEnd(
    String itemId, {
    required bool enabledIfNew,
    DateTime? endDate,
    int? endAgeMonths,
    String? babyId,
  });

  /// The third state (D-R2/D-R4): hidden everywhere and unscheduled, but kept —
  /// a removed preset is restorable with one tap, so removal must not destroy the
  /// row or its `enabled` value.
  ///
  /// Restoring writes `removed = 0` and leaves every other column as it was: the
  /// hour, the label, the rhythm and the end the parent set before removing it are
  /// all still there, because removal was a visibility decision, not a reset.
  Future<void> setItemRemoved(
    String itemId, {
    required bool removed,
    required bool enabledIfNew,
    String? babyId,
  });

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

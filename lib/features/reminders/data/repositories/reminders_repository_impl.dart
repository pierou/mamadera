import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/utils/calendar_date.dart' show formatCalendarDate;
// Alias for drift-generated row types (distinct from domain entities)
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/db_constants.dart' as db_const;
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_frequency.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminder_item_setting.dart';
import '../../domain/repositories/reminders_repository.dart';
import '../../domain/services/notification_time.dart';
import '../../domain/services/reminder_end.dart' show maxReminderEndAgeMonths;
import '../../domain/services/reminder_frequency_codec.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  /// Explicit injection — no fallback singleton.
  const RemindersRepositoryImpl({
    required this.database,
  });

  final db_app.AppDatabase database;
  static final Logger _logger = appLogger();

  /// Effective transfer of records: the requested baby, or otherwise, the security guard.
  /// The `null` state – it is here, at the boundary, that "null" becomes an empty string.
  /// The requests from lower levels only see concrete, tangible results.
  String _scope(String? babyId) => babyId ?? db_const.sharedBabyId;

  /// Visible babywearing for easy reading: **just the baby, nothing else.**
  ///
  /// "Sentinel" refers to the process of installing the software without a profile, and it does not...
  /// This applies to no real babies; applying it to all (legacy v10) used to.
  /// leak the extinction, ignore, and manual adjustment of a baby's settings on the...
  /// following, including a baby born later, who would inherit a predetermined condition.
  /// Before its existence, there were flaws. A newborn baby starts with imperfections.
  List<String> _visibleScopes(String? babyId) =>
      babyId == null ? const [db_const.sharedBabyId] : [babyId];

  @override
  Future<DateTime?> getLastCompleted(ReminderItem item,
      {String? babyId}) async {
    try {
      // Invariant D2: An item without a [ReminderItem.subtypeValue] is considered detached.
      // of a delicate nature — no event can resolve it, not even a perfectly executed `sante`."
      // type. Its completion is only achieved through [getLastManualCompletion].
      // (The old `Constant(true)` fallback matcher would match anything.)
      // health event and would address this recall at the initial consultation.
      // poids venue.)
      final subtypeValue = item.subtypeValue;
      if (subtypeValue == null) return null;

      // Query tracking_events for events matching this reminder's type (+ subtype for health).
      final scope = _scope(babyId);

      // Get most recent event — no date restriction, returns last completed ever.
      // Scoped to the active baby when one is known (see interface dartdoc).
      // The stateless profile only reads events that are posted **without** a profile.
      // (`baby_id IS NULL`): An event related to a baby no longer triggers the recall.
      // de l'autre.
      final q = (database.select(database.trackingEvents)
        ..where((t) {
          final exp = t.type.equals(item.trackingType.name) &
              t.subtype.equals(subtypeValue) &
              (scope == db_const.sharedBabyId
                  ? t.babyId.isNull()
                  : t.babyId.equals(scope));
          return exp;
        })
        ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
        ..limit(1));

      final results = await q.get();
      if (results.isEmpty) return null;

      _logger.d(
          'getLastCompleted(${item.id}) — found: ${results.first.timestamp}');
      return results.first.timestamp;
    } catch (e, stack) {
      _logger.e(
        'getLastCompleted error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastManualCompletion(String itemId,
      {String? babyId}) async {
    try {
      // Append-only journal: reading always displays the most recent entry.
      // of the baby — nothing else, the `''` character represents the state without...
      // profile (same format as [getLastCompleted] for events).
      final scopes = _visibleScopes(babyId);
      final q = database.select(database.reminderCompletions)
        ..where((t) => t.itemId.equals(itemId) & t.babyId.isIn(scopes))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
        ..limit(1);
      final row = await q.getSingleOrNull();
      if (row == null) return null;
      _logger.d('getLastManualCompletion($itemId) — found: ${row.completedAt}');
      return row.completedAt;
    } catch (e, stack) {
      _logger.e(
        'getLastManualCompletion error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastDismissal(String itemId, {String? babyId}) async {
    try {
      // Only one line per carrier: the most recent baby carrier.
      final scopes = _visibleScopes(babyId);
      final q = database.select(database.reminderDismissals)
        ..where((t) => t.itemId.equals(itemId) & t.babyId.isIn(scopes))
        ..orderBy([(t) => OrderingTerm.desc(t.dismissedAt)])
        ..limit(1);
      final row = await q.getSingleOrNull();
      return row?.dismissedAt;
    } catch (e, stack) {
      _logger.e(
        'getLastDismissal error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> recordCompletion(String itemId,
      {String? babyId, DateTime? at}) async {
    try {
      final scope = _scope(babyId);
      final completedAt = at ?? DateTime.now();
      await database.into(database.reminderCompletions).insert(
            db_app.ReminderCompletionsCompanion.insert(
              babyId: Value(scope),
              itemId: itemId,
              completedAt: completedAt,
            ),
          );
      _logger.d('recordCompletion($itemId, $scope)');
    } catch (e, stack) {
      _logger.e(
        'recordCompletion error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> dismissReminder(String itemId,
      {String? babyId, DateTime? at}) async {
    try {
      final scope = _scope(babyId);
      final dismissedAt = at ?? DateTime.now();

      // Upsert (baby_id, item_id) within a transaction: a disconnection between the...
      // The deletion and insertion would ensure that the recall is "never overlooked."
      // pendant un instant, et l'index composite exigerait un aller-retour de
      // to be able to observe it.
      await database.transaction(() async {
        await (database.delete(database.reminderDismissals)
              ..where((t) => t.babyId.equals(scope) & t.itemId.equals(itemId)))
            .go();
        await database.into(database.reminderDismissals).insert(
              db_app.ReminderDismissalsCompanion.insert(
                babyId: Value(scope),
                itemId: itemId,
                dismissedAt: dismissedAt,
              ),
            );
      });
      _logger.d('dismissReminder($itemId, $scope)');
    } catch (e, stack) {
      _logger.e(
        'dismissReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, ReminderItemSetting>> getSettingsByItemId(
      {String? babyId}) async {
    try {
      final scopes = _visibleScopes(babyId);
      final rows = await (database.select(database.reminderSettings)
            ..where((t) => t.babyId.isIn(scopes)))
          .get();
      // An empty table is the normal state (nobody has chosen anything yet): not
      // an error, and the caller reads the absence of a key as "the item's own
      // defaults" (B6) — never as "on". One row per item, so there is nothing to
      // merge and nothing to arbitrate between.
      return {
        for (final row in rows)
          row.itemId: ReminderItemSetting(
            enabled: row.enabled,
            timeOfDay: row.time,
            // Read straight through, unresolved on purpose: an age-end needs the
            // scope's birthdate, which belongs to the caller (`_buildPlan` has
            // the profile, M4's effective-item function will too).
            endDate: row.endDate,
            endAgeMonths: row.endAgeMonths,
            label: row.label,
            frequency: row.frequency,
            intervalDays: row.intervalDays,
            frequencyDate: row.frequencyDate,
            removed: row.removed,
          ),
      };
    } catch (e, stack) {
      _logger.e(
        'getSettingsByItemId error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> setEnabled(String itemId,
      {required bool enabled, String? babyId}) async {
    try {
      final scope = _scope(babyId);
      _logger.d('setEnabled($itemId, $enabled, $scope)');

      // Upsert on (baby_id, item_id) that writes **only** `enabled`.
      //
      // This was a DELETE + INSERT, which is harmless while the row has one
      // column and is a silent data-loss the moment it has more: flipping a
      // switch would erase the reminder's own notification hour (B30) and, from
      // M4, its label override, frequency override, end and removal state. The
      // switch owns one column, so it writes one column — and the atomicity the
      // transaction used to buy now comes from the upsert itself.
      await database.into(database.reminderSettings).insert(
            db_app.ReminderSettingsCompanion.insert(
              babyId: Value(scope),
              itemId: itemId,
              enabled: enabled,
            ),
            onConflict: DoUpdate(
              (_) => db_app.ReminderSettingsCompanion.custom(
                enabled: Variable(enabled),
              ),
            ),
          );
    } catch (e, stack) {
      _logger.e(
        'setEnabled error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> setItemTime(
    String itemId, {
    required String timeOfDay,
    required bool enabledIfNew,
    String? babyId,
  }) async {
    try {
      final scope = _scope(babyId);
      // Write-strict, on the write side of the split `notification_time.dart`
      // documents: junk here would schedule a notification for a time of day
      // that does not exist. The picker cannot produce it and the importer
      // refuses it; reaching this line with it is a programming error.
      if (!isValidNotificationTime(timeOfDay)) {
        throw ArgumentError.value(
            timeOfDay, 'timeOfDay', 'not a valid HH:mm time');
      }

      // Only `time` is written on conflict. On the insert branch the row is
      // created with [enabledIfNew] — the item's own default, so picking an hour
      // for a default-off reminder does not switch it on (B6: an hour is not
      // consent).
      await database.into(database.reminderSettings).insert(
            db_app.ReminderSettingsCompanion.insert(
              babyId: Value(scope),
              itemId: itemId,
              enabled: enabledIfNew,
              time: Value(timeOfDay),
            ),
            onConflict: DoUpdate(
              (_) => db_app.ReminderSettingsCompanion.custom(
                time: Variable(timeOfDay),
              ),
            ),
          );
      _logger.d('setItemTime($itemId, $timeOfDay, $scope)');
    } catch (e, stack) {
      _logger.e(
        'setItemTime error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearItemTime(String itemId, {String? babyId}) async {
    try {
      final scope = _scope(babyId);
      // UPDATE only, never an insert: no row already *means* "inherited", and
      // creating one here would have to invent an `enabled` to satisfy NOT NULL.
      await (database.update(database.reminderSettings)
            ..where((t) => t.babyId.equals(scope) & t.itemId.equals(itemId)))
          .write(
        const db_app.ReminderSettingsCompanion(time: Value(null)),
      );
      _logger.d('clearItemTime($itemId, $scope)');
    } catch (e, stack) {
      _logger.e(
        'clearItemTime error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ── The rest of the row (B33, D-R2) ────────────────────────────────────

  /// Insert-with-default / update-own-columns: the shape M2 established for
  /// `time`. On conflict this writes **only** the columns the decision owns, so
  /// writing one never erases another (a writer that overwrote a neighbour's
  /// column would make the row's meaning depend on the order the parent tapped
  /// in — a rename eating an end date, no test noticing until a year later).
  ///
  /// The insert branch has to answer the NOT NULL `enabled`: the caller's
  /// the item's own default, never a literal — choosing a rhythm, a name or an end
  /// for a default-off reminder must not switch it on (B6: an edit is not consent).
  Future<void> _upsertOwnColumns(
    String itemId,
    String scope, {
    required Insertable<db_app.ReminderSetting> insert,
    required Insertable<db_app.ReminderSetting> update,
    required String operation,
  }) async {
    await database.into(database.reminderSettings).insert(
          insert,
          onConflict: DoUpdate((_) => update),
        );
    _logger.d('$operation($itemId, $scope)');
  }

  @override
  Future<void> setItemLabel(
    String itemId, {
    required String? label,
    required bool enabledIfNew,
    String? babyId,
  }) async {
    try {
      final scope = _scope(babyId);
      String? stored;
      if (label != null) {
        stored = label.trim();
        if (stored.isEmpty || stored.length > _maxLabelLength) {
          throw ArgumentError.value(label, 'label',
              'A reminder name is 1..$_maxLabelLength characters.');
        }
      }
      await _upsertOwnColumns(
        itemId,
        scope,
        insert: db_app.ReminderSettingsCompanion.insert(
          babyId: Value(scope),
          itemId: itemId,
          enabled: enabledIfNew,
          label: Value(stored),
        ),
        update: db_app.ReminderSettingsCompanion.custom(
          label: Variable(stored),
        ),
        operation: 'setItemLabel',
      );
    } catch (e, stack) {
      _logger.e('setItemLabel error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> setItemFrequency(
    String itemId, {
    required ReminderFrequency? frequency,
    required bool enabledIfNew,
    String? babyId,
  }) async {
    try {
      final scope = _scope(babyId);
      String? code;
      int? intervalDays;
      String? frequencyDate;
      if (frequency != null) {
        final stored = encodeFrequency(frequency);
        code = stored.code;
        intervalDays = stored.intervalDays;
        frequencyDate = stored.occurrenceDate;
        if (code == db_const.freqOneTime && frequencyDate == null) {
          // D-R5/D-R8 write-strict: a one-shot without a day is not a rhythm but
          // a bug, and the picker is the thing that must not produce it.
          throw ArgumentError.value(frequency, 'frequency',
              'A one-time reminder needs the day it happens on.');
        }
      }
      final clearsEnd = code == db_const.freqOneTime;

      // D-R5's exclusivity at the write, in one transaction: a row carries at most
      // one of {`one_time` + its date, `end_date`, `end_age_months`}, so switching
      // **to** a one-shot drops any stored end (it is not kept dormant — a
      // one-shot has an occurrence, not an end), and switching **away** already
      // drops the stale occurrence date, because [frequencyDate] is null then.
      await database.transaction(() async {
        await _upsertOwnColumns(
          itemId,
          scope,
          insert: db_app.ReminderSettingsCompanion.insert(
            babyId: Value(scope),
            itemId: itemId,
            enabled: enabledIfNew,
            frequency: Value(code),
            intervalDays: Value(intervalDays),
            frequencyDate: Value(frequencyDate),
          ),
          update: db_app.ReminderSettingsCompanion.custom(
            frequency: Variable(code),
            intervalDays: Variable(intervalDays),
            frequencyDate: Variable(frequencyDate),
          ),
          operation: 'setItemFrequency',
        );
        if (clearsEnd) {
          await (database.update(database.reminderSettings)
                ..where(
                    (t) => t.babyId.equals(scope) & t.itemId.equals(itemId)))
              .write(const db_app.ReminderSettingsCompanion(
            endDate: Value(null),
            endAgeMonths: Value(null),
          ));
        }
      });
    } catch (e, stack) {
      _logger.e('setItemFrequency error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> setItemEnd(
    String itemId, {
    required bool enabledIfNew,
    DateTime? endDate,
    int? endAgeMonths,
    String? babyId,
  }) async {
    try {
      final scope = _scope(babyId);
      if (endDate != null && endAgeMonths != null) {
        throw ArgumentError(
            'A reminder ends on a date or at an age, never both (D-R5).');
      }
      if (endAgeMonths != null &&
          (endAgeMonths < 0 || endAgeMonths > maxReminderEndAgeMonths)) {
        throw ArgumentError.value(
            endAgeMonths, 'endAgeMonths', '0..$maxReminderEndAgeMonths months');
      }
      final stored = endDate == null ? null : formatCalendarDate(endDate);

      final existing = await (database.select(database.reminderSettings)
            ..where((t) => t.babyId.equals(scope) & t.itemId.equals(itemId)))
          .getSingleOrNull();
      if (existing?.frequency == db_const.freqOneTime &&
          (stored != null || endAgeMonths != null)) {
        // The picker clears the one-shot first (D-R5 makes the exclusivity
        // structural); this is the write-side backstop, because the alternative is
        // a row whose meaning depends on which column a later reader trusts.
        throw ArgumentError(
            'A one-time reminder has an occurrence, not an end (D-R5).');
      }

      await _upsertOwnColumns(
        itemId,
        scope,
        insert: db_app.ReminderSettingsCompanion.insert(
          babyId: Value(scope),
          itemId: itemId,
          enabled: enabledIfNew,
          endDate: Value(stored),
          endAgeMonths: Value(endAgeMonths),
        ),
        update: db_app.ReminderSettingsCompanion.custom(
          endDate: Variable(stored),
          endAgeMonths: Variable(endAgeMonths),
        ),
        operation: 'setItemEnd',
      );
    } catch (e, stack) {
      _logger.e('setItemEnd error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> setItemRemoved(
    String itemId, {
    required bool removed,
    required bool enabledIfNew,
    String? babyId,
  }) async {
    try {
      final scope = _scope(babyId);
      // `enabled` is deliberately untouched: D-R2 keeps it as stored while the row
      // is removed, so a restore comes back exactly as it was left — the switch,
      // the hour, the name, the rhythm and the end all survive a removal, because
      // removal was a visibility decision, not a reset.
      await _upsertOwnColumns(
        itemId,
        scope,
        insert: db_app.ReminderSettingsCompanion.insert(
          babyId: Value(scope),
          itemId: itemId,
          enabled: enabledIfNew,
          removed: Value(removed),
        ),
        update: db_app.ReminderSettingsCompanion.custom(
          removed: Variable(removed),
        ),
        operation: 'setItemRemoved',
      );
    } catch (e, stack) {
      _logger.e('setItemRemoved error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ── Personalized Reminders ──────────────────────────────────────────

  /// Maximum label length: `withLength(max: 60)` for the table, aligned with
  /// the form's `maxLength`.
  static const int _maxLabelLength = 60;

  /// The frequency codec lives in the domain
  /// (`reminder_frequency_codec.dart`) because `effectiveItemsForScope` reads the
  /// same columns for a preset override; these two wrappers exist so the data
  /// layer and the domain cannot drift apart on what a stored code means.
  ({String code, int? intervalDays, String? occurrenceDate}) _encodeFrequency(
          ReminderFrequency frequency) =>
      encodeFrequency(frequency);

  ReminderFrequency _decodeFrequency(
    String code,
    int? intervalDays, {
    String? occurrenceDate,
  }) =>
      decodeFrequency(code, intervalDays, occurrenceDate: occurrenceDate);

  CustomReminder _toDomain(db_app.CustomReminder row) => CustomReminder(
        id: row.id,
        label: row.label,
        subtypeValue: row.subtypeValue,
        // As it was originally written: "This column is the definitive source of information about who [or what] it concerns."
        // The recall setting is adjusted, and there are never any recalculated defects here.
        completionSource: row.completionSource,
        frequency: _decodeFrequency(
          row.frequency,
          row.intervalDays,
          occurrenceDate: row.frequencyDate,
        ),
      );

  /// The label is the only free-text field on this page: it has been cleaned, verified, and...
  /// It's never written in a log – it's parent text, not a key.
  String _validatedLabel(String raw) {
    final label = raw.trim();
    if (label.isEmpty) {
      throw ArgumentError.value(raw, 'label', 'Un rappel doit avoir un nom.');
    }
    if (label.length > _maxLabelLength) {
      // The length, not the text itself: this exception was noted and then recorded.
      // It uses a `catch` element at the top, and a reminder name is taken from the parent text.
      throw ArgumentError.value(
        label.length,
        'label',
        'Nom de rappel trop long (max $_maxLabelLength caractères).',
      );
    }
    return label;
  }

  @override
  Future<List<CustomReminder>> getCustomReminders({String? babyId}) async {
    try {
      // The key feature is this: designed for a baby, it only makes a sound when...
      // for him. The "porting" (installation without a profile) method no longer works.
      // without a profile.
      final scopes = _visibleScopes(babyId);
      final rows = await (database.select(database.customReminders)
            ..where((t) => t.babyId.isIn(scopes))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();
      return [for (final row in rows) _toDomain(row)];
    } catch (e, stack) {
      _logger.e(
        'getCustomReminders error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<int> insertCustomReminder(CustomReminder reminder,
      {String? babyId}) async {
    try {
      final scope = _scope(babyId);
      final (
        code: code,
        intervalDays: intervalDays,
        occurrenceDate: occurrenceDate
      ) = _encodeFrequency(reminder.frequency);

      final id = await database.into(database.customReminders).insert(
            db_app.CustomRemindersCompanion.insert(
              label: _validatedLabel(reminder.label),
              subtypeValue: Value(reminder.subtypeValue),
              // The core principle, established here at the very beginning of the writing process, is a reminder without...
              // The care cannot be excluded from the events; it should be included in the calculation.
              // The first health event that came to mind.
              completionSource: Value(
                reminder.subtypeValue == null
                    ? db_const.completionManual
                    : db_const.completionFromEvents,
              ),
              babyId: Value(scope),
              frequency: code,
              intervalDays: Value(intervalDays),
              frequencyDate: Value(occurrenceDate),
            ),
          );
      _logger.d('insertCustomReminder(id: $id, $scope)');
      return id;
    } catch (e, stack) {
      _logger.e(
        'insertCustomReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCustomReminder(CustomReminder reminder,
      {String? babyId}) async {
    try {
      final id = reminder.id;
      if (id == null) {
        // Value: `reminder.toString()` contains the label of the parent, and...
        // This exception is logged in the `catch` block below.
        throw ArgumentError(
          'Un rappel à mettre à jour doit avoir un identifiant.',
        );
      }
      final (
        code: code,
        intervalDays: intervalDays,
        occurrenceDate: occurrenceDate
      ) = _encodeFrequency(reminder.frequency);
      // Carrying (or "slinging") isn't about rewriting the rules: it's about renaming or adjusting the pace of something.
      // The recall does not change the baby to whom it belongs.

      final updated = await (database.update(database.customReminders)
            ..where((t) => t.id.equals(id)))
          .write(
        db_app.CustomRemindersCompanion(
          label: Value(_validatedLabel(reminder.label)),
          subtypeValue: Value(reminder.subtypeValue),
          // The same principle applies as before: switch from a detached state to a linked state.
          // (or vice versa) the change that determines when it is complete.
          completionSource: Value(
            reminder.subtypeValue == null
                ? db_const.completionManual
                : db_const.completionFromEvents,
          ),
          frequency: Value(code),
          intervalDays: Value(intervalDays),
          // Written on every update, including as `null`: leaving a stale date
          // behind when the frequency moves off `one_time` would leave a
          // half-changed frequency in the row (D-R5's exclusivity applies to the
          // write, not just to the picker).
          frequencyDate: Value(occurrenceDate),
        ),
      );
      _logger
          .d('updateCustomReminder($id, ${_scope(babyId)}) — rows: $updated');
    } catch (e, stack) {
      _logger.e(
        'updateCustomReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomReminder(int id, {String? babyId}) async {
    try {
      final itemKey = '${CustomReminderPresets.customIdPrefix}$id';

      // Transaction: Four hands are involved. One card has been cut in half.
      // It would leave an orphaned setting in each backup, and that's...
      // That is precisely what this method is designed to prevent.
      await database.transaction(() async {
        await (database.delete(database.customReminders)
              ..where((t) => t.id.equals(id)))
            .go();
        // The settings, ignoring them, and the final touches are all being handled by **all the babies**.
        // The `custom_<id>` key is unique to each row; it is deleted when the row is deleted, and...
        // A single, orphaned line of code, imported through a different mechanism, would survive the export process.
        await database.customStatement(
          'DELETE FROM reminder_settings WHERE item_id = ?',
          [itemKey],
        );
        await database.customStatement(
          'DELETE FROM reminder_dismissals WHERE item_id = ?',
          [itemKey],
        );
        // A surviving component would be exported (the entire table would be included in the...).
        // backup (without filtering), restored, and may resolve a future recall.
        // It was taken up again after being restored.
        await database.customStatement(
          'DELETE FROM reminder_completions WHERE item_id = ?',
          [itemKey],
        );
      });
      _logger.d('deleteCustomReminder($id, ${_scope(babyId)})');
    } catch (e, stack) {
      _logger.e(
        'deleteCustomReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

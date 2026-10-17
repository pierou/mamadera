import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
// Alias for drift-generated row types (distinct from domain entities)
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/db_constants.dart' as db_const;
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_frequency.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/reminders_repository.dart';
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
  Future<DateTime?> getLastCompleted(ReminderItem item, {String? babyId}) async {
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

      _logger.d('getLastCompleted(${item.id}) — found: ${results.first.timestamp}');
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
  Future<DateTime?> getLastManualCompletion(String itemId, {String? babyId}) async {
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
  Future<void> recordCompletion(String itemId, {String? babyId, DateTime? at}) async {
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
  Future<void> dismissReminder(String itemId, {String? babyId, DateTime? at}) async {
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
  Future<Map<String, bool>> getEnabledByItemId({String? babyId}) async {
    try {
      final scopes = _visibleScopes(babyId);
      final rows = await (database.select(database.reminderSettings)
            ..where((t) => t.babyId.isIn(scopes)))
          .get();
      // An empty table is the normal state (no one has selected anything yet):
      // It's not a mistake, and the caller interprets the lack of a response as "activated."
      // Only one line per transfer, eliminating any need for merging or resolving conflicts.
      return {for (final row in rows) row.itemId: row.enabled};
    } catch (e, stack) {
      _logger.e(
        'getEnabledByItemId error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> setEnabled(String itemId, {required bool enabled, String? babyId}) async {
    try {
      final scope = _scope(babyId);
      _logger.d('setEnabled($itemId, $enabled, $scope)');

      // Transaction: The upsert operation (baby_id, item_id) must be atomic; otherwise...
      // A break between the deletion and insertion would leave the recall incomplete.
      // "Enabled by default" - and the parent's choice would be lost each time.
      // baby rollover.
      await database.transaction(() async {
        await (database.delete(database.reminderSettings)
              ..where((t) => t.babyId.equals(scope) & t.itemId.equals(itemId)))
            .go();
        await database.into(database.reminderSettings).insert(
          db_app.ReminderSettingsCompanion.insert(
            babyId: Value(scope),
            itemId: itemId,
            enabled: enabled,
          ),
        );
      });
    } catch (e, stack) {
      _logger.e(
        'setEnabled error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ── Personalized Reminders ──────────────────────────────────────────

  /// Codes written in the `custom_reminders.frequency` field.
  ///
  /// Defined in `db_constants.dart`: renaming them would change their meaning.
  /// existing installation, and the importer of record must verify these.
  /// The same codes can be used without relying on that class. The `every_n_days` function is written in...
  /// all letters because the column is read exactly as is within a JSON structure.
  /// sauvegarde.
  static const String _freqDaily = db_const.freqDaily;
  static const String _freqWeekly = db_const.freqWeekly;
  static const String _freqMonthly = db_const.freqMonthly;
  static const String _freqEveryNDays = db_const.freqEveryNDays;

  /// Maximum label length: `withLength(max: 60)` for the table, aligned.
  /// regarding the `maxLength` setting of the form.
  static const int _maxLabelLength = 60;

  /// Weekday schedule, designed for a weekly routine.
  ///
  /// `isDue` is never used (to complete a weekly reminder).
  /// (postponed to the following ISO week, regardless of the day): we will.
  /// Record it on Monday so that the line remains legible when written by hand.
  static const int _weeklyStoredDayOfWeek = 1;

  /// Invalid value for `interval_days`: the value could not be read.
  static const int _defaultIntervalDays = 7;

  ({String code, int? intervalDays}) _encodeFrequency(
          ReminderFrequency frequency) =>
      frequency.map(
        daily: (_) => (code: _freqDaily, intervalDays: null),
        weekly: (_) => (code: _freqWeekly, intervalDays: null),
        // The day of the month is not stored; instead, it represents the baby's date of birth.
        // active, and reviewed each time the list is created – like vitamin K.
        monthly: (_) => (code: _freqMonthly, intervalDays: null),
        customInterval: (f) =>
            (code: _freqEveryNDays, intervalDays: f.days),
      );

  /// Tolerant decoding: an unknown code — manually restored JSON, version.
  /// the future of the format – it's becoming a **daily** reminder rather than...
  /// to disappear. A reminder that once something is gone, it can no longer be corrected.
  ReminderFrequency _decodeFrequency(String code, int? intervalDays) {
    if (code == _freqWeekly) {
      return const ReminderFrequency.weekly(
        dayOfWeek: _weeklyStoredDayOfWeek,
      );
    }
    if (code == _freqMonthly) {
      return const ReminderFrequency.monthly(
        dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
      );
    }
    if (code == _freqEveryNDays) {
      // A negative or zero value would result in a perpetual outstanding balance.
      final days = intervalDays == null || intervalDays < 1
          ? _defaultIntervalDays
          : intervalDays;
      return ReminderFrequency.customInterval(days: days);
    }
    return const ReminderFrequency.daily();
  }

  CustomReminder _toDomain(db_app.CustomReminder row) => CustomReminder(
        id: row.id,
        label: row.label,
        subtypeValue: row.subtypeValue,
        // As it was originally written: "This column is the definitive source of information about who [or what] it concerns."
        // The recall setting is adjusted, and there are never any recalculated defects here.
        completionSource: row.completionSource,
        frequency: _decodeFrequency(row.frequency, row.intervalDays),
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
  Future<int> insertCustomReminder(CustomReminder reminder, {String? babyId}) async {
    try {
      final scope = _scope(babyId);
      final (code: code, intervalDays: intervalDays) =
          _encodeFrequency(reminder.frequency);

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
  Future<void> updateCustomReminder(CustomReminder reminder, {String? babyId}) async {
    try {
      final id = reminder.id;
      if (id == null) {
        // Value: `reminder.toString()` contains the label of the parent, and...
        // This exception is logged in the `catch` block below.
        throw ArgumentError(
          'Un rappel à mettre à jour doit avoir un identifiant.',
        );
      }
      final (code: code, intervalDays: intervalDays) =
          _encodeFrequency(reminder.frequency);
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
        ),
      );
      _logger.d('updateCustomReminder($id, ${_scope(babyId)}) — rows: $updated');
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
      final itemKey =
          '${CustomReminderPresets.customIdPrefix}$id';

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

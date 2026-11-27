part of 'import_repository_impl.dart';

// ── Restore inserts ──────────────────────────────────────────────────────
//
// Per-table insert loops lifted out of `restore` so that function stays
// inside the complexity budget (lizard length 150, `make check-complexity`).
// Same library, same transaction: callers run these inside their
// `database.transaction` — a helper that opened its own transaction would
// break the all-or-nothing restore contract.

/// Re-inserts `reminder_completions` rows (format ≥ 2).
Future<void> _insertReminderCompletions(
  db_app.AppDatabase database,
  List<ImportedReminderCompletion> completions,
) async {
  for (final completion in completions) {
    await database.into(database.reminderCompletions).insert(
          db_app.ReminderCompletionsCompanion.insert(
            babyId: Value(completion.babyId),
            itemId: completion.itemId,
            completedAt: completion.completedAt,
          ),
        );
  }
}

/// Re-inserts `app_settings` rows (format ≥ 4) — the notification
/// preferences, restored as written; the D8 de-opt repairs an opt-in whose
/// OS permission did not survive the phone swap.
Future<void> _insertAppSettings(
  db_app.AppDatabase database,
  List<ImportedAppSetting> settings,
) async {
  for (final setting in settings) {
    await database.into(database.appSettings).insert(
          db_app.AppSettingsCompanion.insert(
            key: setting.key,
            value: setting.value,
          ),
        );
  }
}

/// Re-inserts `reminder_settings` rows, plus the one thing a **pre-format-5**
/// document cannot carry: B6's vitamin D seed.
///
/// In the pre-5 vocabulary an absent vitamin D row meant "on", and a restore
/// deletes every row before inserting. Replaying such a file without the seed
/// would therefore switch the reminder off on a parent who never turned it off —
/// the one outcome PLAN-v1.4.0 D-R1 forbids — so the statement is the very one
/// the v14 migration runs (`db_const.vitaminDSeedInsert`): INSERT-only,
/// `NOT EXISTS`-guarded, never an UPDATE, idempotent.
///
/// Format 5 and above needs nothing: that export writes every row that exists,
/// so an absent row genuinely means "new scope, item default".
Future<void> _insertReminderSettings(
  db_app.AppDatabase database,
  List<ImportedReminderSetting> settings,
  int formatVersion,
) async {
  for (final setting in settings) {
    await database.into(database.reminderSettings).insert(
          db_app.ReminderSettingsCompanion.insert(
            // The `babyId` column has a default value defined: the parameter.
            // The `insertion` option is optional, so we enclose it in parentheses.
            babyId: Value(setting.babyId),
            itemId: setting.itemId,
            enabled: setting.enabled,
            // The document's key is `timeOfDay`, the column is `time` (B30
            // named the column, the export speaks camelCase). `Value(null)` when
            // the key was absent: inherit the installation-wide hour.
            time: Value(setting.timeOfDay),
            // B33: the rest of the row, written as written. A restore that
            // replayed `enabled` and `timeOfDay` but dropped the nickname, the
            // rhythm, the end and the removal would turn a tuned installation
            // back into four stock reminders — a quieter kind of data loss than a
            // missing table, and harder to notice.
            label: Value(setting.label),
            frequency: Value(setting.frequency),
            intervalDays: Value(setting.intervalDays),
            frequencyDate: Value(setting.frequencyDate),
            endDate: Value(setting.endDate),
            endAgeMonths: Value(setting.endAgeMonths),
            removed: Value(setting.removed),
          ),
        );
  }

  if (formatVersion < 5) {
    await database.customStatement(db_const.vitaminDSeedInsert);
  }
}

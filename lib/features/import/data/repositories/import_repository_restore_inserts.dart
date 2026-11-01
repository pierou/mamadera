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

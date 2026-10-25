/// Repository for app-level key/value settings (the `app_settings` table,
/// schema v13 — roadmap item 12).
///
/// The settings are not scoped to any baby: one row per key per installation.
/// The valid keys are the `settingsKey*` constants in `db_constants.dart`;
/// the repository itself is key-agnostic and stores any non-empty string.
abstract class AppSettingsRepository {
  /// Returns the value stored for [key], or null when no row exists.
  Future<String?> get(String key);

  /// Inserts or updates the row for [key] with [value] (upsert).
  Future<void> set(String key, String value);

  /// Deletes every row. Called only by the restore path (import) and by the
  /// full data reset — never by normal app flow.
  Future<void> deleteAll();

  /// Returns every row as a `key → value` map (unfiltered read — used by the
  /// export).
  Future<Map<String, String>> getAll();
}

/// Repository for app-level key/value settings (the `app_settings` table,
/// schema v13 — roadmap item 12).
///
/// The settings are not scoped to any baby: one row per key per installation.
/// The valid keys are the `settingsKey*` constants declared next to this
/// contract — the keys are this feature's vocabulary, not a storage detail,
/// so they live with the contract and not in `data/local`; the repository
/// itself is key-agnostic and stores any non-empty string.
library;

/// Opt-in flag for system notifications: `'1'` = enabled, `'0'` (or a
/// missing row) = disabled. A missing row always reads as disabled.
const String settingsKeyNotificationsOptIn = 'notifications_opt_in';

/// Preferred time of day for reminder notifications, `'HH:mm'` (24-hour,
/// device-local). A missing row reads as `defaultNotificationTime`.
const String settingsKeyNotificationTime = 'notification_time_of_day';

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

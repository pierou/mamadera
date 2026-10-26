/// The `notification_time_of_day` codec (schema v13, item 12).
///
/// Lives in the domain so the three places that touch the stored value — the
/// sync notifier that schedules, the settings notifier that edits, and the
/// importer that refuses a malformed backup — share one definition of what a
/// valid time is. They must not each own a regex.
library;

import '../../../../data/local/db_constants.dart';

/// The default time of day, read from [defaultNotificationTime].
///
/// Derived rather than re-typed on purpose: there must not be a second
/// hard-coded 09:00 that can drift from the constant. If the constant is ever
/// changed to junk, this throws at the first call rather than hiding it.
({int hour, int minute}) notificationTimeDefaults() {
  final parts = defaultNotificationTime.split(':');
  return (
    hour: int.parse(parts.first),
    minute: int.parse(parts.last),
  );
}

/// True when [stored] is a wall-clock time this app can honour.
///
/// Strictly: exactly two digits, a colon, exactly two digits, hour 0–23,
/// minute 0–59. Both halves matter:
///
/// * a **shape** check alone (`^[0-2][0-9]:[0-5][0-9]$`) accepts `24:00`,
///   because `4` matches the digit class the tens-of-hours class allows — an
///   hour that does not exist, in a file the importer would then restore;
/// * a **numeric** check alone accepts `0830` as the integer 830, and an hour
///   of 830 does not fail either — it silently schedules a notification for a
///   time of day that has never existed.
bool isValidNotificationTime(String stored) {
  final parts = stored.split(':');
  if (parts.length != 2) return false;
  if (parts.first.length != 2 || parts.last.length != 2) return false;
  final hour = int.tryParse(parts.first);
  final minute = int.tryParse(parts.last);
  if (hour == null || minute == null) return false;
  return hour <= 23 && minute <= 59;
}

/// Parses the stored `HH:mm`, falling back to [notificationTimeDefaults] on
/// anything that is not [isValidNotificationTime].
///
/// The fallback rather than a throw is deliberate here: this is the *read*
/// side, on a device that is already configured, and a reminder nobody can see
/// can never be fixed — while a notification at the default hour is what the
/// parent would have got anyway. The **write** side of that same trust boundary
/// (the importer) refuses the identical value instead: a file is a one-shot
/// restore, and a wrong value there is data, not a nuisance.
({int hour, int minute}) parseNotificationTime(String stored) {
  if (!isValidNotificationTime(stored)) return notificationTimeDefaults();
  final parts = stored.split(':');
  return (
    hour: int.parse(parts.first),
    minute: int.parse(parts.last),
  );
}

/// The stored form of a picked time: zero-padded `HH:mm`, never `8:7`.
String formatNotificationTime({required int hour, required int minute}) =>
    '${hour.toString().padLeft(2, '0')}:'
    '${minute.toString().padLeft(2, '0')}';

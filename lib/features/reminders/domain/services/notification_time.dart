/// The `notification_time_of_day` codec (schema v13, item 12).
///
/// Lives in the domain so the two readers of the stored value — the sync
/// notifier that schedules and the settings notifier that edits — share one
/// parser and one writer, and neither has to import the other.
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

/// Parses the stored `HH:mm`, falling back to [notificationTimeDefaults] on
/// anything malformed.
///
/// The strictness is deliberate: `'0830'` parses as the integer 830, and an
/// hour of 830 does not fail — it silently schedules a notification for a
/// wall-clock time that does not exist. The settings UI cannot write that, but
/// a hand-edited or corrupted row can, and the schedule must not inherit it.
({int hour, int minute}) parseNotificationTime(String stored) {
  final parts = stored.split(':');
  if (parts.length != 2) return notificationTimeDefaults();
  final hour = int.tryParse(parts.first);
  final minute = int.tryParse(parts.last);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return notificationTimeDefaults();
  }
  return (hour: hour, minute: minute);
}

/// The stored form of a picked time: zero-padded `HH:mm`, never `8:7`.
String formatNotificationTime({required int hour, required int minute}) =>
    '${hour.toString().padLeft(2, '0')}:'
    '${minute.toString().padLeft(2, '0')}';

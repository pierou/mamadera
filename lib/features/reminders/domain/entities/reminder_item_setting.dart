import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_item_setting.freezed.dart';

/// What the parent stored for one `(baby, item)` pair — the `reminder_settings`
/// row, in domain shape.
///
/// One row now carries several independent decisions (B6's switch, B30's hour,
/// and from M4 the label/frequency overrides, the end and the removal), so
/// consumers read **the row** instead of a bare `bool`: the switch, the hour and
/// the removal state of the same reminder must never come from three queries that
/// can disagree — that is the B31 defect class, and it is what a parent sees as
/// "the switch says off and it still rings".
///
/// A key missing from a map of these means the parent **never touched** that
/// reminder, which resolves to the item's own defaults
/// (`ReminderItem.enabledByDefault`), not to a blanket "on".
@freezed
abstract class ReminderItemSetting with _$ReminderItemSetting {
  const factory ReminderItemSetting({
    /// The switch. Once a row exists it means exactly what it says; absence is
    /// what `enabledByDefault` is for (B6).
    required bool enabled,

    /// Per-reminder notification hour, `'HH:mm'` (B30).
    ///
    /// `null` means **inherit the global hour**
    /// (`app_settings.notification_time_of_day`), not "has no hour". Read lax:
    /// a stored string that is not a valid `HH:mm` is treated as "inherit" by
    /// the scheduler rather than falling back to the app default — the global
    /// hour is the closer promise, and it is the one the parent can still see
    /// and fix. Written strict (`isValidNotificationTime` at the picker; the
    /// importer refuses the same value outright): the split documented in
    /// `notification_time.dart`.
    String? timeOfDay,
  }) = _ReminderItemSetting;
}

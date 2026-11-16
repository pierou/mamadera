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

    /// End of the series, `'yyyy-MM-dd'` (D-R5 form 2). `null` = no stored date.
    ///
    /// One of the two ways a reminder can end; **at most one** of
    /// [endDate]/[endAgeMonths] is ever set (D-R5's mutual exclusivity, enforced
    /// at write and at import — the schema only has the columns). Read it through
    /// `reminderEndFor`, never by parsing this field in place: the age form has
    /// to be resolved against the baby's birthdate, and a row that somehow holds
    /// both has to resolve to one answer.
    String? endDate,

    /// End of the series as the baby's age in whole months, 0-180 (D-R5 form 3).
    ///
    /// Stored as *months*, never as the date it implies: a corrected birthdate
    /// then moves the end by itself, because the date is computed at read time
    /// (`reminderEndFor`) and there is no stored value to go stale.
    int? endAgeMonths,
  }) = _ReminderItemSetting;
}

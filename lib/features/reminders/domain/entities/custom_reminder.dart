import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import 'reminder_frequency.dart';
import 'reminder_item.dart';

part 'custom_reminder.freezed.dart';

/// A reminder created by the parent: "Apply ointment to the umbilical cord stump every 2 days."
///
/// It only describes *when* to make a claim; [completionSource] specifies who makes the decision.
/// It is triggered by a specific event related to healthcare. It is executed as soon as a "health" event occurs.
/// A [subtypeValue] of this type exists within the period (`isDue` of [ReminderFrequency]).
/// - It is this connection that distinguishes it from an alarm system, and which requires the user to wear a...
/// This is more of an existing feature than a free-form text field for tracking purposes. Detached.
/// If `subtypeValue` is null, it is only completed with the word "Done."
/// de l'utilisateur.
@freezed
abstract class CustomReminder with _$CustomReminder {
  const factory CustomReminder({
    /// Free-text input from the parent, displayed exactly as entered (never translated).
    required String label,

    /// Requested frequency: [ReminderFrequency.monthly] is stored without a specific day.
    /// precise: the date refers to the baby's actual date of birth, as recorded at the time of birth.
    /// building the list – just like with vitamin K.
    required ReminderFrequency frequency,

    /// Value of the `HealthSubtype` field; its absence triggers a reminder.
    ///
    /// `null` = detached reminder (D2): no care is associated with it; it's just a notification.
    /// "Completed" (completion source: manual). Invariant:
    /// `subtypeValue == null` if and only if `completionSource == manual` — a detached reminder.
    /// The `left_in_`from_events`` field would match *any* `sante` event.
    String? subtypeValue,

    /// Who decides that the reminder has been sent: [completionFromEvents] — the absence.
    /// of an event related to "health" with the subtype "[subtypeValue]" that occurred within the specified time period.
    /// like the presets—or [completionManual]—only the "Done" button.
    /// It completes the task via `reminder_completions`.
    ///
    /// Invariant D2 : `subtypeValue == null` ⟺ [completionSource] vaut
    /// [completionManual] - a separate reminder left in [completionFromEvents].
    /// It would match *any* health-related event.
    @Default(completionFromEvents) String completionSource,

    /// The `custom_reminders` key is set to `null` until the reminder is saved.
    int? id,
  }) = _CustomReminder;
}

/// Conversion to [ReminderItem] and shared table keys.
extension CustomReminderPresets on ReminderItem {
  /// Prefix used for the key in `reminder_settings` and...
  /// `reminder_dismissals` for a personalized reminder.
  ///
  /// The prefix is a namespace: a custom ID can never...
  /// override the settings of a predefined configuration (e.g., `vitamin_d`, ...), overwriting the existing lines.
  /// Written works must endure.
  static const String customIdPrefix = 'custom_';

  /// The day of the month used by [ReminderFrequency.monthly] when there is no baby.
  /// is active: on the 1st of the month, to ensure that the monthly reminder remains monthly.
  static const int monthlyFallbackDay = 1;

  /// The "welcome reminder" view displays a recorded reminder.
  ///
  /// [monthlyDay] is the baby's date of birth; it is only read for...
  /// A monthly schedule is used, and [monthlyFallbackDay] is applied when no specific profile is available.
  /// The key is the stable identifier `custom_<id>` – never the label, which is only used by the parent element.
  /// It can rename its settings and settlement tiers without causing them to become orphaned.
  /// [CustomReminder.completionSource] is passed along unchanged: it is this value that...
  /// "Indicate which newspaper to read to find the conclusion."
  static ReminderItem forCustom(
    CustomReminder reminder, {
    int? monthlyDay,
  }) {
    return ReminderItem(
      id: '$customIdPrefix${reminder.id}',
      labelKey: reminder.label,
      frequency: switch (reminder.frequency) {
        Monthly() => ReminderFrequency.monthly(
            dayOfMonth: monthlyDay ?? monthlyFallbackDay,
          ),
        final ReminderFrequency frequency => frequency,
      },
      trackingType: TrackingType.sante,
      // The detail here is still missing: it's [reminder.completionSource] that...
      // It says which rule applies, and if you try to create a subtype for it, it will revert to the original.
      // health event (invariant D2).
      subtypeValue: reminder.subtypeValue,
      completionSource: reminder.completionSource,
    );
  }
}

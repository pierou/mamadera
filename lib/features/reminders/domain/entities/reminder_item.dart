import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/date_arithmetic.dart';
import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/baby_profile.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import 'reminder_frequency.dart';

part 'reminder_item.freezed.dart';

/// A reminder to display until the associated treatment has been entered.
///
/// The [id] is a stable key (not a UUID): it indexes the rows of
/// `reminder_settings` and `reminder_dismissals`, so it must never change.
@freezed
abstract class ReminderItem with _$ReminderItem {
  const factory ReminderItem({
    required String id,
    required String labelKey,
    required ReminderFrequency frequency,
    required TrackingType trackingType,

    /// Related care (a subtype of the [trackingType] domain) when the
    /// reminder is settled by a specific recorded event.
    ///
    /// `null`: a standalone reminder — its completion is decided by the user
    /// and never inferred from an event (invariant D2).
    String? subtypeValue,

    /// The baby that owns this reminder, when applicable.
    ///
    /// `null` in the presets: the scope is supplied by the row. The
    /// `baby_id` is always used as the scope and never derived from the
    /// item itself.
    String? babyId,

    /// Whether the reminder is on when the parent has **never** set its state,
    /// i.e. when no `reminder_settings` row exists for `(baby, id)`.
    ///
    /// Item identity, not per-scope data — which is why it lives here in code
    /// (`static const` values) and never in a column. `true` everywhere except
    /// vitamin D (BACKLOG B6: WHO 2022 Rec 36 treats vitamin D supplementation
    /// as research-only, so a new baby starts with the reminder **off but
    /// visible**; existing installs keep it through the v14 seed, D-R1).
    ///
    /// Every read of `reminder_settings` must fall back to this field. There
    /// are four such reads (providers, the two settings switches, the
    /// scheduler's enabled filter): honour it on three of four and the OS
    /// notification still fires for a reminder the app displays as off.
    @Default(true) bool enabledByDefault,

    /// The parent's own wording for this reminder, from
    /// `reminder_settings.label` (B33/D-R6). `null` = the preset's localized name.
    ///
    /// Derived data, never item identity: the preset's `labelKey` stays what it
    /// is, because the key is what localizes the *care* elsewhere. Every surface
    /// that names a reminder must resolve through the one override helper — a site
    /// that reads `labelKey` alone shows a name the parent renamed, which is the
    /// B31 defect class wearing a friendlier face.
    String? labelOverride,

    /// The last day this reminder may still fire (D-R5). `null` = no end.
    ///
    /// **Resolved at read time**, never stored as a date: `end_date` is stored as
    /// a date and `end_age_months` as months, and the age is resolved against the
    /// scope's birthdate by `effectiveItemsForScope`. That is what lets a
    /// corrected birthdate move the end with nothing to invalidate.
    DateTime? endsAt,

    /// What settles this reminder:
    /// - [completionFromEvents]: a [trackingType] event with [subtypeValue]
    ///   (its due date applies to the completion);
    /// - [completionManual]: a `reminder_completions` row written by the
    ///   user — nothing else settles it (invariant D2).
    ///
    /// `null` is read as [completionFromEvents].
    String? completionSource,
  }) = _ReminderItem;
}

/// Presets v1.
extension ReminderItemPresets on ReminderItem {
  /// Vitamin D — daily, settled by a `vitamine_d` health event.
  ///
  /// The only preset that is off by default ([enabledByDefault], BACKLOG B6).
  static const vitaminD = ReminderItem(
    id: 'vitamine_d',
    labelKey: 'reminderVitaminD',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_d',
    babyId: null,
    completionSource: completionFromEvents,
    enabledByDefault: false,
  );

  /// Vitamin K — **the profileless shape**: a static 30-day cycle, kept exactly
  /// as it was (D-R10). A scope with no birthdate cannot place a one-shot, and
  /// dropping the reminder there would remove a clinical prompt from precisely
  /// the installs the B31 self-heal still serves.
  ///
  /// `buildForBaby` replaces it with the real cadence: **one occurrence** at the
  /// baby's first month (B33 Part 1).
  static const vitaminK = ReminderItem(
    id: 'vitamine_k',
    labelKey: 'reminderVitaminK',
    frequency: CustomInterval(days: 30),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_k',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Eye cleaning — daily, settled by the `eye_cleaning` health event.
  static const eyeCleaning = ReminderItem(
    id: 'eye_cleaning',
    labelKey: 'reminderEyeCleaning',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_yeux',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Face cleaning — daily, settled by the `face_cleaning` health event.
  static const faceCleaning = ReminderItem(
    id: 'face_cleaning',
    labelKey: 'reminderFaceCleaning',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_visage',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// The preset list for one baby profile.
  ///
  /// Only the vitamin K cadence changes, and it changes in **kind**, not in
  /// length: a `OneTime` occurrence at the baby's first month (B33 Part 1),
  /// which settles when the dose is recorded and then never returns — instead of
  /// the monthly cycle that kept asking for a dose that had long been given.
  /// The date is the birthdate plus one month with B18's clamped anniversary
  /// ([addMonthsClamped]), so a baby born on 31 January is prompted on 28/29
  /// February, never on a day that does not exist (D-R10: the same month
  /// arithmetic as the age label, never a second one).
  ///
  /// The rest of the list is verbatim.
  static List<ReminderItem> buildForBaby(BabyProfile profile) {
    final vitaminK = ReminderItem(
      id: ReminderItemPresets.vitaminK.id,
      frequency: ReminderFrequency.oneTime(
        date: addMonthsClamped(profile.birthDate, 1),
      ),
      labelKey: ReminderItemPresets.vitaminK.labelKey,
      trackingType: ReminderItemPresets.vitaminK.trackingType,
      subtypeValue: ReminderItemPresets.vitaminK.subtypeValue,
      completionSource: ReminderItemPresets.vitaminK.completionSource,
    );

    return [
      vitaminD,
      vitaminK,
      eyeCleaning,
      faceCleaning,
    ];
  }
}

/// The item set for one scope, single-sourced with the UI.
///
/// With a [profile] ⇒ [ReminderItemPresets.buildForBaby] (vitamin K as a
/// one-shot at the baby's first month). Without ⇒ the profileless fallback:
/// Vitamin D daily plus Vitamin K on the static 30-day interval — deliberately
/// unchanged, since a one-shot needs a birthdate to be placed (D-R10). `dynamicRemindersProvider`
/// and the notification scheduler both call this, so the in-app list and the
/// OS schedule can never disagree about which items exist.
List<ReminderItem> reminderItemsFor(BabyProfile? profile) => profile == null
    ? [ReminderItemPresets.vitaminD, ReminderItemPresets.vitaminK]
    : ReminderItemPresets.buildForBaby(profile);

import 'package:freezed_annotation/freezed_annotation.dart';

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
  static const vitaminD = ReminderItem(
    id: 'vitamine_d',
    labelKey: 'reminderVitaminD',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_d',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Vitamin K — without a birth date on hand, the static 30-day cycle.
  /// `buildForBaby` swaps it for the baby's birth day (monthly).
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
  /// Only the vitamin K cadence changes: monthly on the baby's birth day,
  /// instead of the preset's static 30-day cycle. The rest is verbatim.
  static List<ReminderItem> buildForBaby(BabyProfile profile) {
    final vitaminK = ReminderItem(
      id: ReminderItemPresets.vitaminK.id,
      frequency: Monthly(dayOfMonth: profile.birthDate.day),
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
/// With a [profile] ⇒ [ReminderItemPresets.buildForBaby] (vitamin K on the
/// baby's own birth day). Without ⇒ the profileless fallback: Vitamin D daily
/// plus Vitamin K on the static 30-day interval. `dynamicRemindersProvider`
/// and the notification scheduler both call this, so the in-app list and the
/// OS schedule can never disagree about which items exist.
List<ReminderItem> reminderItemsFor(BabyProfile? profile) => profile == null
    ? [ReminderItemPresets.vitaminD, ReminderItemPresets.vitaminK]
    : ReminderItemPresets.buildForBaby(profile);

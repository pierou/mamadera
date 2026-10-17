import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/baby_profile.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import 'reminder_frequency.dart';

part 'reminder_item.freezed.dart';

/// A reminder to display until the associated treatment has been entered.
///
/// The identifier is a stable key (not a UUID): it indexes the rows of...
/// `reminder_settings` et `reminder_dismissals`.
@freezed
abstract class ReminderItem with _$ReminderItem {
  const factory ReminderItem({
    required String id,
    required String labelKey,
    required ReminderFrequency frequency,
    required TrackingType trackingType,

    /// Related care (a subtype of the [trackingType] domain), when the...
    /// The reminder is set based on a specific event that is recorded.
    ///
    /// `null`: A standalone reminder for a medical procedure – its completion is not yet determined.
    /// by the user, and never inferred from an event (invariant D2).
    String? subtypeValue,

    /// Baby, the owner of the recall, when applicable.
    ///
    /// `null` in the presets: the handover is managed by the line.
    /// The `baby_id` is always used as the base, and never derived from the item itself.
    String? babyId,

    /// Here's what triggers this reminder:
    /// - [completionFromEvents]: an event that triggers completion.
    /// [trackingType] with [subtypeValue] (its validity date applies to the...).
    /// completion);
    /// - `[completionManual]`: a line from the `reminder_completions` table.
    /// written by the user — without [subtypeValue], nothing else.
    /// It can be adjusted (D2 invariant).
    ///
    /// `null` se lit comme [completionFromEvents].
    String? completionSource,
  }) = _ReminderItem;
}

/// Presets v1.
extension ReminderItemPresets on ReminderItem {
  /// Vitamin D — the daily dosage is determined by monitoring your health data related to "vitamin_d."
  static const vitaminD = ReminderItem(
    id: 'vitamine_d',
    labelKey: 'reminderVitaminD',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_d',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Vitamin K – a starting point without a birth date: rotating stock.
  /// of 30 days. `buildForBaby` sets it to the baby's date of birth.
  /// profil actif.
  static const vitaminK = ReminderItem(
    id: 'vitamine_k',
    labelKey: 'reminderVitaminK',
    frequency: CustomInterval(days: 30),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_k',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Eye cleaning — daily, controlled by the `eye_cleaning` setting.
  static const eyeCleaning = ReminderItem(
    id: 'eye_cleaning',
    labelKey: 'reminderEyeCleaning',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_yeux',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Facial cleansing — daily, controlled by the `facial_cleansing` setting.
  static const faceCleaning = ReminderItem(
    id: 'face_cleaning',
    labelKey: 'reminderFaceCleaning',
    frequency: Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_visage',
    babyId: null,
    completionSource: completionFromEvents,
  );

  /// Build the list of preset reminders based on the active profile.
  ///
  /// Only the vitamin K dosage changes; it is adjusted based on the baby's date of birth.
  /// profile (monthly), instead of the 30-day cycle of the preset setting.
  /// static. The rest is reproduced as is.
  static List<ReminderItem> buildForBaby(BabyProfile profile) {
    final vitaminK = ReminderItem(
      id: ReminderItemPresets.vitaminK.id,
      frequency: Monthly(dayOfMonth: profile.birthDate.day),
      labelKey: ReminderItemPresets.vitaminK.labelKey,
      trackingType: ReminderItemPresets.vitaminK.trackingType,
      subtypeValue: ReminderItemPresets.vitaminK.subtypeValue,
      // The item ID (babyId) is not the same as the item's ID; it is stored within the...
      // baseline, which share the same ID.
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

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/domain/entities/baby_profile.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

import 'reminder_frequency.dart';

part 'reminder_item.freezed.dart';

/// Configuration for a single periodic reminder.
@freezed
abstract class ReminderItem with _$ReminderItem {
  const factory ReminderItem({
    required String id,
    required String labelKey,
    required ReminderFrequency frequency,
    required TrackingType trackingType,
    String? subtypeValue,
  }) = _ReminderItem;
}

/// Preset factory methods and static helpers for ReminderItem.
extension ReminderItemPresets on ReminderItem {
  /// Preconfigured daily Vitamin D reminder.
  static const vitaminD = ReminderItem(
    id: 'vitamine_d',
    labelKey: 'reminderVitaminD',
    frequency: ReminderFrequency.daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_d',
  );

  /// Preconfigured Vitamin K reminder — every 30 days (rolling interval).
  ///
  /// This is the calendar-less fallback used before a baby profile exists;
  /// [ReminderItemPresets.buildForBaby] replaces the rolling interval with a
  /// birth-date-anchored monthly schedule for the same item id.
  static const vitaminK = ReminderItem(
    id: 'vitamine_k',
    labelKey: 'reminderVitaminK',
    frequency: ReminderFrequency.customInterval(days: 30),
    trackingType: TrackingType.sante,
    subtypeValue: 'vitamine_k',
  );

  /// Preconfigured daily eye cleaning reminder.
  static const eyeCleaning = ReminderItem(
    id: 'eye_cleaning',
    labelKey: 'reminderEyeCleaning',
    frequency: ReminderFrequency.daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_yeux',
  );

  /// Preconfigured daily face cleaning reminder.
  static const faceCleaning = ReminderItem(
    id: 'face_cleaning',
    labelKey: 'reminderFaceCleaning',
    frequency: ReminderFrequency.daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'nettoyage_visage',
  );

  /// Build the list of reminders anchored to an active baby profile.
  ///
  /// Item **ids never change**: they are the key of `reminder_settings` and
  /// `reminder_dismissals` rows, so a new id would orphan existing data. Only the
  /// *frequency* is derived from [profile].
  ///
  /// Birth-date anchoring is applied to the monthly Vitamin K preset: it repeats
  /// on the baby's day of birth each month, i.e. `dayOfMonth = profile.birthDate.day`
  /// (values above the month length — a 29/30/31 birthday — are clamped by `isDue`
  /// and still fire in February, April, …). The remaining presets are daily care
  /// routines with no sensible birth-date anchor — they repeat every day whatever
  /// the birth date is — so they are returned as the static constants.
  static List<ReminderItem> buildForBaby(BabyProfile profile) => [
        vitaminD,
        vitaminK.copyWith(
          frequency: ReminderFrequency.monthly(dayOfMonth: profile.birthDate.day),
        ),
        eyeCleaning,
        faceCleaning,
      ];
}

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

  /// Build a dynamic list of reminders based on an active baby profile's birth date.
  static List<ReminderItem> buildForBaby(BabyProfile profile) => [
        vitaminD,
        vitaminK,
        eyeCleaning,
        faceCleaning,
      ];
}

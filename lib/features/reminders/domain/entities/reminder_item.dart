import '../../../../shared/domain/entities/baby_profile.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

import 'reminder_frequency.dart';

/// Configuration for a single periodic reminder.
class ReminderItem {

  const ReminderItem({
    required this.id,
    required this.labelKey,
    required this.frequency,
    required this.trackingType,
    this.subtypeValue,
  });

  /// Preconfigured daily Vitamin D reminder.
  factory ReminderItem.vitaminD() => const ReminderItem(
        id: 'vitamine_d',
        labelKey: 'reminderVitaminD',
        frequency: Daily(),
        trackingType: TrackingType.sante,
        subtypeValue: 'vitamine_d',
      );

  /// Preconfigured monthly Vitamin K reminder — uses day-of-month from birth date.
  factory ReminderItem.vitaminK({int? dayOfMonth}) => ReminderItem(
        id: 'vitamine_k',
        labelKey: 'reminderVitaminK',
        frequency: dayOfMonth != null ? Monthly(dayOfMonth) : const Daily(),
        trackingType: TrackingType.sante,
        subtypeValue: 'vitamine_k',
      );

  /// Preconfigured daily eye cleaning reminder.
  factory ReminderItem.eyeCleaning() => const ReminderItem(
        id: 'eye_cleaning',
        labelKey: 'reminderEyeCleaning',
        frequency: Daily(),
        trackingType: TrackingType.sante,
        subtypeValue: 'nettoyage_yeux',
      );

  /// Preconfigured daily face cleaning reminder.
  factory ReminderItem.faceCleaning() => const ReminderItem(
        id: 'face_cleaning',
        labelKey: 'reminderFaceCleaning',
        frequency: Daily(),
        trackingType: TrackingType.sante,
        subtypeValue: 'nettoyage_visage',
      );
  /// Unique identifier (e.g., `'vitamine_d'`).
  final String id;

  /// Human-readable label for display in UI.
  final String labelKey;

  /// How often this reminder should recur.
  final ReminderFrequency frequency;

  /// The tracking type this reminder is associated with.
  final TrackingType trackingType;

  /// Optional subtype value to match against when checking completion.
  /// For health events, this would be the HealthSubtype.value (e.g., `'vitamine_d'`).
  final String? subtypeValue;

  /// Build a dynamic list of reminders based on an active baby profile's birth date.
  /// Vitamin K uses Monthly frequency aligned to the day of birth; others are daily.
  static List<ReminderItem> buildForBaby(BabyProfile profile) => [
        ReminderItem.vitaminD(),
        ReminderItem.vitaminK(dayOfMonth: profile.birthDayOfMonth),
        ReminderItem.eyeCleaning(),
        ReminderItem.faceCleaning(),
      ];
}

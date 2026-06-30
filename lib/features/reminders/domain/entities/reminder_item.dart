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

  /// Preconfigured daily Vitamin K reminder.
  factory ReminderItem.vitaminK() => const ReminderItem(
        id: 'vitamine_k',
        labelKey: 'reminderVitaminK',
        frequency: Daily(),
        trackingType: TrackingType.sante,
        subtypeValue: 'vitamine_k',
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
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../domain/entities/reminder_frequency.dart';

/// Rhythm label, for both the preset list and the grid tiles.
/// Personalized reminders.
///
/// A single location: a preset and a personalized reminder must be described.
/// Using the same words, or at least the same phrasing, it displays "Every 30 days."
/// on one side and "Every 4 weeks" on the other.
String reminderFrequencyLabel(
  BuildContext context,
  ReminderFrequency frequency,
) {
  return frequency.map(
    daily: (_) => context.l.reminderFrequencyDaily,
    weekly: (_) => context.l.reminderFrequencyWeekly,
    monthly: (f) => context.l.reminderFrequencyMonthly(f.dayOfMonth),
    customInterval: (f) => context.l.reminderFrequencyEveryNDays(f.days),
  );
}

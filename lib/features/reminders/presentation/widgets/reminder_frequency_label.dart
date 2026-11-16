import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
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
    // B33: a single occurrence is named by its day, not by a rhythm — and the
    // day is rendered by the app's existing date formatter rather than a pattern
    // invented here, so a one-shot reads the same way as every other date in the
    // app. The dateless branch is D-R8's tolerant read of a hand-edited backup:
    // there is no day to name, and saying so beats showing nothing.
    oneTime: (f) => f.date == null
        ? context.l.reminderFrequencyOneTimeNow
        : context.l.reminderFrequencyOneTime(
            formatDateShort(context, f.date!),
          ),
  );
}

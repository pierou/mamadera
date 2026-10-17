import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/theme.dart';
import '../../../../data/local/db_constants.dart' as db_const;
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminders_state.dart';
import '../providers/reminder_providers.dart';
import 'reminder_frequency_label.dart';

/// A line from the welcome message recall list (D1): icon type, label.
/// rhythm, last completion, and then the two actual actions: "Done" and "Undone."
/// Ignorer.
///
/// The line is specifically designed for active babies, encompassing both actions.
/// They go through [reminderNotifierProvider], which writes using the ID of the active baby.
/// A reminder that was ignored for one baby remains visible for the other.
class ReminderRow extends ConsumerWidget {
  const ReminderRow({required this.status, super.key});

  /// The amount due is displayed on the line.
  final ReminderStatus status;

  /// Underlying item, for stocks and tests.
  ReminderItem get item => status.item;

  /// Icon type: If a related care item exists, display that; otherwise, display the generic alarm icon.
  /// detached recall items (D2).
  IconData get _icon {
    final subtypeValue = item.subtypeValue;
    if (subtypeValue != null) return HealthIcons.fromValue(subtypeValue);
    return Icons.alarm;
  }

  /// Displayed label: The name entered by the parent for a reminder.
  /// personalized, the full name of the treatment for a related preset, and the...
  /// Short label, translated as a last resort.
  String _label(BuildContext context) {
    // A personalized item bears the parent's name in the [ReminderItem.labelKey] field:
    // It's never truly resolved as a localization key (l10n), otherwise it's just a "thermometer" [meaning a simple indicator].
    // It would appear as a key.
    if (item.id.startsWith(CustomReminderPresets.customIdPrefix)) {
      return item.labelKey;
    }
    final subtypeValue = item.subtypeValue;
    if (subtypeValue != null) {
      final subtype = HealthSubtype.byValue(subtypeValue);
      if (subtype != null) return resolveHealthLabel(context, subtype);
    }
    final l = context.l;
    return switch (item.labelKey) {
      'reminderVitaminD' => l.reminderVitaminD,
      'reminderVitaminK' => l.reminderVitaminK,
      'reminderEyeCleaning' => l.reminderEyeCleaning,
      'reminderFaceCleaning' => l.reminderFaceCleaning,
      _ => item.labelKey,
    };
  }

  /// "Last time:..." — the event that triggers the recall, or the log.
  /// manual for a detached component – or "Never done" if nothing has been logged yet.
  String _lastDoneLabel(BuildContext context) {
    final at = status.lastEventAt;
    if (at == null) return context.l.reminderNeverDone;
    return context.l.reminderLastDone(formatDate(context, at));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppTheme.spacingLg,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              _icon,
              size: AppTheme.spacingMd,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(context), style: theme.textTheme.bodyLarge),
                Text(
                  '${reminderFrequencyLabel(context, item.frequency)} · '
                  '${_lastDoneLabel(context)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // "Done" only appears where it conveys a specific meaning (D2):
          // A reminder related to a treatment is scheduled **following the treatment**, not before.
          // by checking a box. Manually writing a completion message for him will not.
          // would not resolve (the `tracking_events` service) and would display a...
          // "Placebo button" - the parent would believe they are administering the vitamin labeled.
          // while nothing is.
          if (item.completionSource == db_const.completionManual)
            IconButton(
              tooltip: context.l.reminderMarkDone,
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () =>
                  ref.read(reminderNotifierProvider.notifier).markDone(item),
            ),
          IconButton(
            tooltip: context.l.reminderDismiss,
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(reminderNotifierProvider.notifier).snooze(item),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../domain/entities/reminder_frequency.dart';
import 'reminder_frequency_label.dart';

/// The line under a reminder's name: its rhythm, and the hour it actually fires
/// at (BACKLOG B30).
///
/// Both states show a clock time on purpose. A reminder with no hour of its own
/// is not "hour-less" — it fires at the installation-wide hour — and hiding that
/// is how a parent ends up believing the global row is being ignored. So the
/// inherited hour is shown, and marked as inherited.
///
/// Tapping the hour opens the OS time picker. The reset button appears only when
/// the reminder *has* its own hour, because "inherit" is not a choice still open
/// to somebody who is already inheriting.
///
/// Shared by the preset rows and the custom tiles: one surface, so the two kinds
/// of reminder cannot offer two different ways to say the same thing.
class ReminderHourControl extends StatelessWidget {
  const ReminderHourControl({
    required this.frequency,
    required this.hourLabel,
    required this.inherited,
    required this.onPick,
    required this.onUseGlobal,
    this.showHour = true,
    super.key,
  });

  /// The rhythm text, through the shared label helper (the home pills use it too).
  final ReminderFrequency frequency;

  /// `HH:mm` — the reminder's own when it has one, the global hour otherwise.
  final String hourLabel;

  /// `true` ⇒ [hourLabel] is the installation-wide hour, not this row's own.
  final bool inherited;

  /// Opens the time picker for this row.
  final VoidCallback onPick;

  /// Writes NULL, i.e. inherits the global hour again.
  final VoidCallback onUseGlobal;

  /// `false` while the global hour has not been read yet: the rhythm is known,
  /// the effective hour is not, and a wrong clock time is worse than none.
  final bool showHour;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    // One wrapped line, not two stacked ones: a reminder row that grows to three
    // lines pushes the bottom of this screen out of a small phone's viewport,
    // and on a list that is the whole content. `Wrap` breaks the line only when
    // the width demands it.
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(reminderFrequencyLabel(context, frequency), style: style),
        if (showHour) ...[
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingXs,
                horizontal: AppTheme.spacingSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_outlined, size: 16),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    inherited
                        ? context.l.reminderHourInherited(hourLabel)
                        : context.l.reminderHourOwn(hourLabel),
                    style: style,
                  ),
                ],
              ),
            ),
          ),
          if (!inherited)
            IconButton(
              icon: const Icon(Icons.settings_backup_restore, size: 18),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: context.l.reminderHourUseDefault,
              onPressed: onUseGlobal,
            ),
        ],
      ],
    );
  }
}

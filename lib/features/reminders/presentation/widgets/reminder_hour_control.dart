import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../domain/entities/reminder_frequency.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/services/notification_time.dart';
import '../providers/reminder_providers.dart';
import '../providers/reminder_sync_notifier.dart';
import 'reminder_frequency_label.dart';

/// The hour state of one reminder: what to show, and whether it is inherited.
typedef ReminderHourState = ({
  String hourLabel,
  bool inherited,
  bool showHour,
  NotificationPreferences? prefs,
});

/// Resolve the effective hour of one reminder from its own stored column and the
/// installation-wide preference (B30).
///
/// One function because two surfaces answer this question — the settings row and
/// the preset edit sheet — and they must not disagree about what "this reminder's
/// hour" means. The reminder's own hour wins when the row carries a usable one;
/// otherwise it is the global hour, shown and marked as inherited: "no hour of my
/// own" is not "no hour". While the global preference is still being read and the
/// reminder has nothing of its own, the hour line stays away rather than guessing
/// 09:00.
ReminderHourState resolveReminderHour({
  required String? storedTimeOfDay,
  required NotificationPreferences? prefs,
}) {
  // Promoted once, here: "has an hour of its own" is then one question with one
  // answer, for the label, the marker and the picker's initial time.
  final own =
      (storedTimeOfDay != null && isValidNotificationTime(storedTimeOfDay))
          ? storedTimeOfDay
          : null;
  return (
    hourLabel: own ?? prefs?.timeLabel ?? defaultNotificationTime,
    inherited: own == null,
    showHour: own != null || prefs != null,
    prefs: prefs,
  );
}

/// The OS time picker for one reminder, starting from the hour it actually uses
/// — its own, or the global one it inherits.
///
/// Writes through `setTime`, the single column-scoped writer of
/// `reminder_settings.time`, so the settings row and the edit sheet setting the
/// same hour cannot overwrite each other's neighbour columns (the discipline M2
/// established when `setEnabled` used to erase a stored hour on its way past).
Future<void> pickReminderHour({
  required BuildContext context,
  required WidgetRef ref,
  required ReminderItem item,
  required String? storedTimeOfDay,
}) async {
  final hour = resolveReminderHour(
    storedTimeOfDay: storedTimeOfDay,
    prefs: ref.read(notificationSettingsProvider).value,
  );
  final fallback = notificationTimeDefaults();
  final prefs = hour.prefs;
  final initial = hour.inherited
      ? (
          hour: prefs?.hour ?? fallback.hour,
          minute: prefs?.minute ?? fallback.minute,
        )
      : parseNotificationTime(hour.hourLabel);

  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    helpText: context.l.reminderHourPickerTitle,
  );
  if (picked == null) return;

  await ref
      .read(reminderSettingsProvider.notifier)
      .setTime(item, hour: picked.hour, minute: picked.minute);
}

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
/// Shared by the preset rows, the custom tiles and the preset edit sheet: one
/// surface, so the kinds of reminder and the two places that edit them cannot
/// offer two different ways to say the same thing.
class ReminderHourControl extends StatelessWidget {
  const ReminderHourControl({
    required this.frequency,
    required this.hourLabel,
    required this.inherited,
    required this.onPick,
    required this.onUseGlobal,
    this.showHour = true,
    this.showRhythm = true,
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

  /// `false` where the rhythm is already on screen above this line — the preset
  /// edit sheet picks it with chips, so repeating it here is noise.
  final bool showRhythm;

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
        if (showRhythm)
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

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';
import 'reminder_frequency_label.dart';

/// What the parent requests on a personalized reminder tile.
enum CustomReminderAction { edit, delete }

/// A personalized reminder option can be found in Settings → Reminders.
///
/// The switch and the menu are intentionally separated; tapping on a line will open the menu.
/// modification, touching the switch turns off the reminder. Both are in the same area.
/// They would force the parent to choose between "I'm not thinking about it anymore" and "I want to change it."
/// "day," without asking him which one he wants.
class CustomReminderTile extends StatelessWidget {
  const CustomReminderTile({
    required this.reminder,
    required this.display,
    required this.enabled,
    required this.onToggle,
    required this.onAction,
    super.key,
  });

  /// The recall, as recorded, includes its label, its key, and its ID.
  final CustomReminder reminder;

  /// The same reminder appears in the welcome section – its frequency is based on the user's date of birth.
  /// of the active baby, which is something that a simple reminder cannot convey.
  final ReminderItem display;

  /// `item_id → enabled` is an opt-out mechanism: a missing key is equivalent to `true`.
  /// The caller resolves the value.
  final bool enabled;

  /// Deactivation/reactivation of the reminder.
  final ValueChanged<bool> onToggle;

  /// Demande de modification ou de suppression.
  final ValueChanged<CustomReminderAction> onAction;

  /// Key for the `reminder_settings` of this reminder.
  ///
  /// The format exists in three places: here, the screen displaying the shutdown message, and the storage location.
  /// which organizes the reminder – and these three must be written on the same line, otherwise...
  /// The switch and the menu contradict each other. Therefore, it is unique in this case.
  static String keyOf(CustomReminder reminder) =>
      '${CustomReminderPresets.customIdPrefix}${reminder.id}';

  String get settingsKey => keyOf(reminder);

  @override
  Widget build(BuildContext context) {
    // A standalone reminder doesn't need to mention anything specific; it's more about stating something rather than elaborating on it.
    // to give the impression that there is some kind of oversight or monitoring in place.
    final isDetached = reminder.subtypeValue == null;

    return ListTile(
      contentPadding: const EdgeInsets.only(right: AppTheme.spacingSm),
      title: Text(reminder.label),
      subtitle: isDetached
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminderFrequencyLabel(context, display.frequency)),
                Text(
                  context.l.reminderCustomCareNoneHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : Text(reminderFrequencyLabel(context, display.frequency)),

      onTap: () => onAction(CustomReminderAction.edit),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: enabled, onChanged: onToggle),
          PopupMenuButton<CustomReminderAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: context.l.reminderCustomSheetEdit,
            initialValue: CustomReminderAction.edit,
            onSelected: onAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CustomReminderAction.edit,
                child: Text(context.l.edit),
              ),
              PopupMenuItem(
                value: CustomReminderAction.delete,
                child: Text(
                  context.l.delete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

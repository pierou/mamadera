import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';
import 'reminder_frequency_label.dart';

/// Ce que le parent demande sur une tuile de rappel personnalisé.
enum CustomReminderAction { edit, delete }

/// Une ligne de rappel personnalisé dans Réglages → Rappels.
///
/// Le switch et le menu sont séparés volontairement : toucher la ligne ouvre la
/// modification, toucher le switch éteint le rappel. Les deux sur la même zone
/// feraient choisir au parent entre « je n'y pense plus » et « je veux changer le
/// jour », sans lui demander lequel il veut.
class CustomReminderTile extends StatelessWidget {
  const CustomReminderTile({
    required this.reminder,
    required this.display,
    required this.enabled,
    required this.onToggle,
    required this.onAction,
    super.key,
  });

  /// Le rappel tel qu'enregistré : c'est son libellé, sa clé et son id.
  final CustomReminder reminder;

  /// Le même rappel en item d'accueil — sa fréquence porte le jour de naissance
  /// du bébé actif, que le rappel seul ne connaît pas.
  final ReminderItem display;

  /// `item_id → activé` est un opt-out : une clé absente vaut `true`, c'est
  /// l'appelant qui résout la valeur.
  final bool enabled;

  /// Extinction / rallumage du rappel.
  final ValueChanged<bool> onToggle;

  /// Demande de modification ou de suppression.
  final ValueChanged<CustomReminderAction> onAction;

  /// Clé de `reminder_settings` de ce rappel.
  ///
  /// Le format vit à trois endroits — ici, l'écran qui lit l'extinction, le dépôt
  /// qui range le rappel — et ces trois-là doivent écrire sur la même ligne, sinon
  /// le switch et le menu se contredisent. Il est donc unique, ici.
  static String keyOf(CustomReminder reminder) =>
      '${CustomReminderPresets.customIdPrefix}${reminder.id}';

  String get settingsKey => keyOf(reminder);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(right: AppTheme.spacingSm),
      title: Text(reminder.label),
      subtitle: Text(reminderFrequencyLabel(context, display.frequency)),
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

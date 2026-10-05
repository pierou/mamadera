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

/// Une ligne de la liste des rappels d'accueil (D1) : icône du type, libellé,
/// rythme, dernière complétion, puis les deux actions réelles — Fait et
/// Ignorer.
///
/// La ligne est scopée au bébé actif par construction : les deux actions
/// passent par [reminderNotifierProvider], qui écrit avec l'id du bébé actif.
/// Un rappel ignoré pour un bébé reste affiché pour l'autre.
class ReminderRow extends ConsumerWidget {
  const ReminderRow({required this.status, super.key});

  /// Le rappel dû affiché par la ligne.
  final ReminderStatus status;

  /// Item sous-jacent, pour les actions et les tests.
  ReminderItem get item => status.item;

  /// Icône du type : le soin lié quand il y en a un, sinon l'alarme générique
  /// des rappels détachés (D2).
  IconData get _icon {
    final subtypeValue = item.subtypeValue;
    if (subtypeValue != null) return HealthIcons.fromValue(subtypeValue);
    return Icons.alarm;
  }

  /// Libellé affiché : le nom saisi par le parent pour un rappel
  /// personnalisé, le nom complet du soin pour un préréglage lié, et la
  /// courte étiquette traduite en dernier recours.
  String _label(BuildContext context) {
    // Un personnalisé porte le nom du parent dans [ReminderItem.labelKey] :
    // on ne le résout jamais comme clé l10n, sinon un « Thermomètre »
    // s'afficherait comme une clé.
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

  /// « Dernière fois: … » — l'événement qui règle le rappel, ou le journal
  /// manuel pour un détaché — ou « Jamais fait » si rien n'est encore loggé.
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
          // « Fait » ne s'affiche que là où il veut dire quelque chose (D2) :
          // un rappel lié à un soin se règle en **suivant le soin**, pas en
          // cochant une case. Écrire un achèvement manuel pour lui ne le
          // réglerait pas (le service lit `tracking_events`) et afficherait un
          // bouton qui fait semblant — le parent croirait la vitamine notée
          // alors que rien ne l'est.
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

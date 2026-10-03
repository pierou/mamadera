import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/entities/reminders_state.dart';
import '../providers/reminder_providers.dart';
import 'reminder_row.dart';

/// La liste des rappels d'accueil (D1) : les rappels dus du bébé actif, sous
/// les boutons de soin, en remplacement du compteur « +N » que la pastille ne
/// permettait pas de lire.
///
/// Préréglages d'abord, puis personnalisés dans l'ordre de création — l'ordre
/// du notifieur, jamais réordonné ici. Sans rappel dû, la section se réduit à
/// une ligne discrète : pas de carte, pas d'erreur.
class HomeRemindersSection extends ConsumerWidget {
  const HomeRemindersSection({super.key});

  /// Aplati la carte du notifieur en liste ordonnée ; vide en attente ou en
  /// erreur — la pastille des boutons porte déjà l'état, et un spinner au
  /// milieu de l'accueil vaudrait moins que le silence.
  List<ReminderStatus> _due(
    AsyncValue<Map<TrackingType, List<ReminderStatus>>> reminders,
  ) {
    final byType = reminders.maybeWhen(
      data: (m) => m,
      orElse: () => const <TrackingType, List<ReminderStatus>>{},
    );
    return byType.values.expand((statuses) => statuses).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _due(ref.watch(reminderNotifierProvider));
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppTheme.spacingXl),
        child: Text(
          context.l.reminderListEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingXl),
          child: Text(
            context.l.reminderListTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        for (final status in items) ReminderRow(status: status),
      ],
    );
  }
}

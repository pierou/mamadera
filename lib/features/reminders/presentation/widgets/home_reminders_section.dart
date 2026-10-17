import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/entities/reminders_state.dart';
import '../providers/reminder_providers.dart';
import 'reminder_row.dart';

/// The list of welcome reminders (D1): these are reminders for active babies, specifically those that are due.
/// The care buttons replace the "+N" counter that the patch does not.
/// permettait pas de lire.
///
/// First, the presets, then the custom settings, in the order they were created – that's the order.
/// from the notifier, never reordered here. Without any outstanding reminders, the section is reduced to...
/// a discreet row: no card, no error.
class HomeRemindersSection extends ConsumerWidget {
  const HomeRemindersSection({super.key});

  /// Flatten the notification map into an ordered list; display pending or processed items.
  /// error — the button's status is already indicated, and a spinner is used to...
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

    // The baby's name, which is dynamically inserted, goes through the l10n message placeholder, but never directly.
    // by concatenation: the order of words is not universal.
    // `watch`: The title refers to a change in the baby's condition. Without an active baby, the...
    // Neutral title: "Things to remember" — no "null" values, no false information.
    // identity.
    final babyName = ref.watch(activeBabyProvider).value?.name;
    final title = (babyName != null && babyName.trim().isNotEmpty)
        ? context.l.reminderListTitleFor(babyName)
        : context.l.reminderListTitle;

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
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

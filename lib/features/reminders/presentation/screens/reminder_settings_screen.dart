import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../domain/entities/reminder_frequency.dart';
import '../../domain/entities/reminder_item.dart';
import '../providers/reminder_providers.dart';

/// Écran Réglages → Rappels : le parent éteint les rappels qui ne le
/// concernent pas (Vit. K après la naissance, soins arrêtés sur avis médical…).
///
/// Un rappel éteint n'est pas supprimé : il ne sonne plus, reste listé ici pour
/// pouvoir être rallumé, et son historique de complétion est conservé. Rien
/// d'automatique n'est envoyé à l'extérieur de l'app — les rappels sont des
/// bandeaux sur l'accueil, jamais des notifications système.
class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(dynamicRemindersProvider);
    final settingsAsync = ref.watch(reminderSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.reminderSettingsTitle),
        centerTitle: true,
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Jamais l'exception brute à l'écran (charte confidentialité).
        error: (_, __) => Center(child: Text(context.l.reminderSettingsError)),
        data: (items) => settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(context.l.reminderSettingsError)),
          data: (settings) => _ReminderList(items: items, settings: settings),
        ),
      ),
    );
  }
}

class _ReminderList extends ConsumerWidget {
  const _ReminderList({required this.items, required this.settings});

  final List<ReminderItem> items;

  /// `item_id → activé` ; une clé absente vaut activé (opt-out, pas opt-in).
  final Map<String, bool> settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      children: [
        Text(
          context.l.reminderSettingsDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        for (final item in items)
          SwitchListTile(
            // Contenu accessible : le libellé et la fréquence sont lus ensemble.
            title: Text(_labelFor(context, item)),
            subtitle: Text(_frequencyLabel(context, item.frequency)),
            value: settings[item.id] ?? true,
            onChanged: (enabled) =>
                ref.read(reminderSettingsProvider.notifier).setEnabled(item.id, enabled: enabled),
          ),
      ],
    );
  }

  /// Nom complet du soin plutôt que l'abréviation de la pastille (« Vitamine D »
  /// et non « Vit. D ») : ici on règle un rappel, on ne le lit pas en un coup
  /// d'œil au-dessus d'un bouton.
  String _labelFor(BuildContext context, ReminderItem item) {
    final subtypeValue = item.subtypeValue;
    if (subtypeValue != null) {
      final subtype = HealthSubtype.byValue(subtypeValue);
      if (subtype != null) return resolveHealthLabel(context, subtype);
    }
    // Invitation pour un rappel sans sous-type (les préréglages actuels en ont
    // tous un) : on retombe sur la clé plutôt que de planter.
    return item.labelKey;
  }

  String _frequencyLabel(BuildContext context, ReminderFrequency frequency) {
    return frequency.map(
      daily: (_) => context.l.reminderFrequencyDaily,
      weekly: (_) => context.l.reminderFrequencyWeekly,
      monthly: (f) => context.l.reminderFrequencyMonthly(f.dayOfMonth),
      customInterval: (f) => context.l.reminderFrequencyEveryNDays(f.days),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';
import '../providers/reminder_providers.dart';
import '../widgets/custom_reminder_form_sheet.dart';
import '../widgets/custom_reminder_tile.dart';
import '../widgets/reminder_frequency_label.dart';

/// Écran Réglages → Rappels : le parent éteint les rappels qui ne le concernent
/// pas (Vit. K après la naissance, soins arrêtés sur avis médical…) et ajoute les
/// siens.
///
/// Un rappel éteint n'est pas supprimé : il ne sonne plus, reste listé ici pour
/// pouvoir être rallumé, et son historique de complétion est conservé. Rien
/// d'automatique n'est envoyé à l'extérieur de l'app — les rappels sont des
/// bandeaux sur l'accueil, jamais des notifications système.
class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(dynamicRemindersProvider);
    final settingsAsync = ref.watch(reminderSettingsProvider);
    final customAsync = ref.watch(customRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.reminderSettingsTitle),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          // Trois sources, un seul écran : afficher une section pendant que les
          // autres tournent encore laisserait le parent deviner si « rien ici »
          // veut dire « rien à régler » ou « pas encore chargé ».
          if (presetsAsync.isLoading ||
              settingsAsync.isLoading ||
              customAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // Jamais l'exception brute à l'écran (charte confidentialité).
          if (presetsAsync.hasError ||
              settingsAsync.hasError ||
              customAsync.hasError) {
            return Center(child: Text(context.l.reminderSettingsError));
          }
          return _ReminderList(
            presets: presetsAsync.requireValue,
            custom: customAsync.requireValue,
            settings: settingsAsync.requireValue,
            // Jour de naissance du bébé actif : seul un rythme mensuel s'en
            // sert, et c'est ce qui affiche « Le 14 de chaque mois » plutôt que
            // le jour fictif stocké en base.
            monthlyDay: ref.watch(activeBabyProvider).value?.birthDate.day,
          );
        },
      ),
    );
  }
}

class _ReminderList extends ConsumerWidget {
  const _ReminderList({
    required this.presets,
    required this.custom,
    required this.settings,
    required this.monthlyDay,
  });

  final List<ReminderItem> presets;

  /// Rappels personnalisés enregistrés, dans l'ordre de création.
  final List<CustomReminder> custom;

  /// `item_id → activé` ; une clé absente vaut activé (opt-out, pas opt-in).
  final Map<String, bool> settings;

  /// Jour de naissance du bébé actif, `null` sans profil.
  final int? monthlyDay;

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
        for (final item in presets)
          SwitchListTile(
            // Contenu accessible : le libellé et la fréquence sont lus ensemble.
            title: Text(_presetLabel(context, item)),
            subtitle: Text(reminderFrequencyLabel(context, item.frequency)),
            value: settings[item.id] ?? true,
            onChanged: (enabled) => ref
                .read(reminderSettingsProvider.notifier)
                .setEnabled(item.id, enabled: enabled),
          ),

        const SizedBox(height: AppTheme.spacingXxl),
        Text(
          context.l.reminderCustomSectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          context.l.reminderCustomSectionDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (custom.isEmpty)
          Text(
            context.l.reminderCustomEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          for (final reminder in custom)
            CustomReminderTile(
              reminder: reminder,
              display: CustomReminderPresets.forCustom(
                reminder,
                monthlyDay: monthlyDay,
              ),
              enabled: settings[_settingsKey(reminder)] ?? true,
              onToggle: (enabled) => ref
                  .read(reminderSettingsProvider.notifier)
                  .setEnabled(_settingsKey(reminder), enabled: enabled),
              onAction: (action) =>
                  _onAction(context, ref, reminder, action),
            ),
        ListTile(
          leading: const Icon(Icons.add_alarm_outlined),
          title: Text(context.l.reminderCustomAdd),
          onTap: () => _openForm(context, ref),
        ),
      ],
    );
  }

  /// Clé de `reminder_settings` d'un rappel personnalisé.
  ///
  /// Rendue par [CustomReminderTile.keyOf] : l'extinction écrite par le switch de
  /// la tuile et lue par cette liste tombent sur la même ligne par construction,
  /// pas par coïncidence de deux chaînes recopiées.
  String _settingsKey(CustomReminder reminder) =>
      CustomReminderTile.keyOf(reminder);

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    CustomReminder reminder,
    CustomReminderAction action,
  ) async {
    switch (action) {
      case CustomReminderAction.edit:
        await _openForm(context, ref, existing: reminder);
      case CustomReminderAction.delete:
        await _confirmDelete(context, ref, reminder);
    }
  }

  /// Ouvre le formulaire et écrit ce qu'il rend.
  ///
  /// La feuille ne touche jamais la base : créer ici plutôt que dans la feuille
  /// garde une seule sortie possible, celle qui prévient l'accueil.
  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    CustomReminder? existing,
  }) async {
    final draft = await showModalBottomSheet<CustomReminder>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => CustomReminderFormSheet(existing: existing),
    );
    if (draft == null) return;

    final notifier = ref.read(customRemindersProvider.notifier);
    // Le try/catch n'est pas décoratif : sans lui, une écriture refusée (stockage
    // plein, ligne trop longue) part dans un futur que personne n'attend — plante
    // en debug, silencieuse en release — et le parent voit le panneau se fermer
    // sans que rien n'apparaisse sur la liste.
    try {
      if (existing == null) {
        await notifier.create(draft);
      } else {
        await notifier.edit(draft);
      }
    } on Object {
      if (!context.mounted) return;
      showError(context, context.l.reminderCustomSaveError);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CustomReminder reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l.reminderCustomDeleteConfirm),
        // Le parent peut craindre de perdre son historique : c'est le moment de
        // dire que non, les événements suivis ne bougent pas.
        content: Text(dialogContext.l.reminderCustomDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(dialogContext.l.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = reminder.id;
    if (id == null) return;
    try {
      await ref.read(customRemindersProvider.notifier).remove(id);
    } on Object {
      if (!context.mounted) return;
      // Sans ce garde-fou, l'écran afficherait un rang vidé alors que la ligne
      // est toujours en base — et le ressersirait au prochain ouverture.
      showError(context, context.l.reminderCustomDeleteError);
    }
  }

  /// Nom complet du soin plutôt que l'abréviation de la pastille (« Vitamine D »
  /// et non « Vit. D ») : ici on règle un rappel, on ne le lit pas en un coup
  /// d'œil au-dessus d'un bouton.
  String _presetLabel(BuildContext context, ReminderItem item) {
    final subtypeValue = item.subtypeValue;
    if (subtypeValue != null) {
      final subtype = HealthSubtype.byValue(subtypeValue);
      if (subtype != null) return resolveHealthLabel(context, subtype);
    }
    // Invitation pour un rappel sans sous-type (les préréglages actuels en ont
    // tous un) : on retombe sur la clé plutôt que de planter.
    return item.labelKey;
  }
}

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

/// Settings screen → Reminders: The parent disables the reminders that are not relevant to them.
/// (Vitamin K after birth, discontinuation of treatment based on medical advice, etc.) and add the following:
/// siens.
///
/// A muted reminder is not deleted; it simply stops sounding, but remains listed here.
/// It can be restarted, and its completion history is preserved. Nothing else.
/// automatic notifications are not sent outside of the app—reminders are.
/// Banners displayed on the homepage, never system notifications.
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
          // Three sources, one screen: display one section while the...
          // Some still turn, allowing the parent to guess if "nothing is here."
          // It means "nothing to adjust" or "not yet charged."
          if (presetsAsync.isLoading ||
              settingsAsync.isLoading ||
              customAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // Never display the raw exception on the screen (confidentiality policy).
          if (presetsAsync.hasError ||
              settingsAsync.hasError ||
              customAsync.hasError) {
            return Center(child: Text(context.l.reminderSettingsError));
          }
          return _ReminderList(
            presets: presetsAsync.requireValue,
            custom: customAsync.requireValue,
            settings: settingsAsync.requireValue,
            // Date of birth of the active baby: only a monthly cycle applies.
            // serves, and that's why it displays "The 14th of each month" instead of...
            // The fictional date is stored in the database.
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

  /// Personalized reminders, listed in the order they were created.
  final List<CustomReminder> custom;

  /// `item_id → enabled`; if the key is missing, it defaults to enabled (opt-out, not opt-in).
  final Map<String, bool> settings;

  /// Date of birth of the active baby, `null` if no profile exists.
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
            // Accessible content: The label and frequency are read together.
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
              onAction: (action) => _onAction(context, ref, reminder, action),
            ),
        ListTile(
          leading: const Icon(Icons.add_alarm_outlined),
          title: Text(context.l.reminderCustomAdd),
          onTap: () => _openForm(context, ref),
        ),
      ],
    );
  }

  /// Key for the `reminder_settings` of a custom reminder.
  ///
  /// Set by [CustomReminderTile.keyOf]: the written message from the switch.
  /// By default, the "tile" and "lue" elements in this list will appear on the same line.
  /// Not due to a coincidental match between two copied sequences.
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

  /// Open the form and write down whatever it says.
  ///
  /// The leaf never touches the base: create here instead of on the leaf.
  /// It only allows for one possible exit, the one that alerts reception.
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
    // The try/catch block is not merely decorative; without it, a failed write operation (e.g., to storage) will...
    // (full, excessively long queue) goes into a future that no one expects – plant.
    // In debug mode, it's silent; in release mode, it's quiet, and the parent sees the panel close.
    // without anything appearing on the list.
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
        // The parent may be afraid of losing their data: this is the time to...
        // To say no, the subsequent events remain unchanged.
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
      // Without this safeguard, the screen would display an empty row, while the line...
      // It's still in the base, and I would tighten it again at the next opening.
      showError(context, context.l.reminderCustomDeleteError);
    }
  }

  /// Use the full name of the treatment rather than the abbreviation on the pill ("Vitamin D").
  /// and not "Vit. D") : here, we're setting a reminder, not reading something quickly.
  /// slightly above a button.
  String _presetLabel(BuildContext context, ReminderItem item) {
    final subtypeValue = item.subtypeValue;
    if (subtypeValue != null) {
      final subtype = HealthSubtype.byValue(subtypeValue);
      if (subtype != null) return resolveHealthLabel(context, subtype);
    }
    // Invitation for a reminder without a specific subtype (the current presets include...).
    // all as one): it falls back to the key instead of crashing.
    return item.labelKey;
  }
}

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
import '../providers/reminder_sync_notifier.dart';
import '../widgets/custom_reminder_form_sheet.dart';
import '../widgets/custom_reminder_tile.dart';
import '../widgets/reminder_frequency_label.dart';

/// Settings screen → Reminders: the parent turns off the reminders that do not
/// apply to them (vitamin K after the neonatal period, a care stopped on
/// medical advice…) and adds their own.
///
/// A turned-off reminder is not deleted: it stops being due, stays listed
/// here, and keeps its completion history.
///
/// Two delivery surfaces, both on-device: the Home banners (always) and —
/// only if the parent turns them on in the “System notifications” section —
/// OS notifications scheduled by `ReminderScheduler` (item 12, D8). The
/// permission is asked for at that switch, never at launch, and turning the
/// switch off cancels every pending notification. Nothing leaves the device
/// either way.
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
          // Three sources, one screen: keep showing the spinner until all
          // three have answered, so the parent never has to guess whether an
          // empty list means "nothing configured" or "still loading".
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
        const _SystemNotificationsSection(),
      ],
    );
  }

  /// Key for the `reminder_settings` row of a custom reminder — the same key
  /// the tile writes, so the switch in the list and the switch on the tile can
  /// never disagree (`CustomReminderTile.keyOf`).
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

  /// Opens the form and writes what it returns.
  ///
  /// The sheet never touches the database: creation and edit happen here, so
  /// there is exactly one write path for a custom reminder.
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
    // The try/catch is not decorative: without it a failed write (a full
    // disk, a constraint violation) lands in a future nobody awaits — silent
    // in release, and the parent would see the sheet close with nothing in
    // the list.
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
        // Say plainly that only the reminder goes: the events already
        // logged stay untouched.
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
      // Without this the screen would show a row that is gone from the list
      // but still in the database, reappearing at the next opening.
      showError(context, context.l.reminderCustomDeleteError);
    }
  }

  /// The care's full name rather than the Home abbreviation ("Vitamin D", not
  /// "Vit. D"): this is a setting being chosen, not a label scanned above a
  /// button. Items with no health subtype fall back to their `labelKey`.
  String _presetLabel(BuildContext context, ReminderItem item) {
    final subtypeValue = item.subtypeValue;
    if (subtypeValue != null) {
      final subtype = HealthSubtype.byValue(subtypeValue);
      if (subtype != null) return resolveHealthLabel(context, subtype);
    }
    return item.labelKey;
  }
}

/// The “System notifications” section (item 12, D8), trailing the reminder
/// lists — the app-level channel that delivers whatever is switched on above.
///
/// The switch is the consent moment: flipping it on is what asks the OS for
/// the permission, and the switch stays off if the answer is no — with the hint
/// that says where to turn it on. The time row is live only when the switch is
/// on, because a time for notifications that will never arrive is noise.
class _SystemNotificationsSection extends ConsumerWidget {
  const _SystemNotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationSettingsProvider);

    return prefsAsync.when(
      // Nothing on screen until the settings row is read: a half-rendered
      // consent switch is worse than none.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (prefs) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXxl),
            child: Text(
              context.l.reminderNotificationsSectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SwitchListTile(
            // Accessible content: the switch is read with its label.
            title: Text(context.l.reminderNotificationsOptIn),
            value: prefs.optIn,
            onChanged: (wanted) => ref
                .read(notificationSettingsProvider.notifier)
                .setOptIn(wanted: wanted),
          ),
          if (prefs.permissionDenied)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                0,
                AppTheme.spacingMd,
                AppTheme.spacingSm,
              ),
              child: Text(
                context.l.reminderNotificationsPermissionDenied,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(context.l.reminderNotificationsTimeLabel),
            subtitle: Text(prefs.timeLabel),
            enabled: prefs.optIn,
            onTap: () => _pickTime(context, ref, prefs),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
    );
    if (picked == null) return;
    await ref
        .read(notificationSettingsProvider.notifier)
        .setTime(hour: picked.hour, minute: picked.minute);
  }
}

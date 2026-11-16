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
import '../../domain/entities/reminder_item_setting.dart';
import '../../domain/services/notification_time.dart';
import '../providers/reminder_providers.dart';
import '../providers/reminder_sync_notifier.dart';
import '../widgets/custom_reminder_form_sheet.dart';
import '../widgets/custom_reminder_tile.dart';
import '../widgets/reminder_hour_control.dart';

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

  /// The stored row of each reminder of this scope, for the rows that **exist**:
  /// the switch and the reminder's own hour (B30). A missing key means "never
  /// touched", which resolves per item to `ReminderItem.enabledByDefault` (B6:
  /// vitamin D starts off, everything else on) and to the global hour.
  final Map<String, ReminderItemSetting> settings;

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
            subtitle: _hourControl(context, ref, item),
            value: settings[item.id]?.enabled ?? item.enabledByDefault,
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
          for (final reminder in custom) _customTile(context, ref, reminder),
        ListTile(
          leading: const Icon(Icons.add_alarm_outlined),
          title: Text(context.l.reminderCustomAdd),
          onTap: () => _openForm(context, ref),
        ),
        const _SystemNotificationsSection(),
      ],
    );
  }

  /// The hour state of one row: what to show, and whether it is inherited.
  ///
  /// The reminder's own hour wins when the row carries a usable one; otherwise
  /// it is the installation-wide hour, shown and marked as inherited — "no hour
  /// of my own" is not "no hour" (B30). While the global preference is still
  /// being read and the row has nothing of its own, the hour line stays away
  /// rather than guessing 09:00.
  ({
    String hourLabel,
    bool inherited,
    bool showHour,
    NotificationPreferences? prefs
  }) _hourFor(WidgetRef ref, ReminderItem item) {
    final stored = settings[item.id]?.timeOfDay;
    // Promoted once, here: "has an hour of its own" is then one question with
    // one answer, for the label, the marker and the picker's initial time.
    final own =
        (stored != null && isValidNotificationTime(stored)) ? stored : null;
    final prefs = ref.watch(notificationSettingsProvider).value;
    return (
      hourLabel: own ?? prefs?.timeLabel ?? defaultNotificationTime,
      inherited: own == null,
      showHour: own != null || prefs != null,
      prefs: prefs,
    );
  }

  /// The rhythm + effective hour line of one preset row, with its two actions.
  Widget _hourControl(BuildContext context, WidgetRef ref, ReminderItem item) {
    final hour = _hourFor(ref, item);
    return ReminderHourControl(
      frequency: item.frequency,
      hourLabel: hour.hourLabel,
      inherited: hour.inherited,
      showHour: hour.showHour,
      onPick: () => _pickHour(context, ref, item, hour.prefs),
      onUseGlobal: () =>
          ref.read(reminderSettingsProvider.notifier).useGlobalTime(item),
    );
  }

  /// The OS time picker for one reminder, starting from the hour the reminder
  /// actually uses — its own, or the global one it inherits.
  Future<void> _pickHour(
    BuildContext context,
    WidgetRef ref,
    ReminderItem item,
    NotificationPreferences? prefs,
  ) async {
    final stored = settings[item.id]?.timeOfDay;
    final own =
        (stored != null && isValidNotificationTime(stored)) ? stored : null;
    final fallback = notificationTimeDefaults();
    final initial = own != null
        ? parseNotificationTime(own)
        : (
            hour: prefs?.hour ?? fallback.hour,
            minute: prefs?.minute ?? fallback.minute,
          );

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

  /// Key for the `reminder_settings` row of a custom reminder — the same key
  /// the tile writes, so the switch in the list and the switch on the tile can
  /// never disagree (`CustomReminderTile.keyOf`).
  String _settingsKey(CustomReminder reminder) =>
      CustomReminderTile.keyOf(reminder);

  /// One custom reminder row.
  ///
  /// The display item is built once and serves both the tile and the default
  /// state of its switch, so a row and its default can never come from two
  /// different item objects (one of B6's four read sites, D-R2).
  Widget _customTile(
    BuildContext context,
    WidgetRef ref,
    CustomReminder reminder,
  ) {
    final display = CustomReminderPresets.forCustom(
      reminder,
      monthlyDay: monthlyDay,
    );
    final key = _settingsKey(reminder);
    final hour = _hourFor(ref, display);
    return CustomReminderTile(
      reminder: reminder,
      display: display,
      enabled: settings[key]?.enabled ?? display.enabledByDefault,
      onToggle: (enabled) => ref
          .read(reminderSettingsProvider.notifier)
          .setEnabled(key, enabled: enabled),
      onAction: (action) => _onAction(context, ref, reminder, action),
      hourLabel: hour.hourLabel,
      hourInherited: hour.inherited,
      showHour: hour.showHour,
      onPickHour: () => _pickHour(context, ref, display, hour.prefs),
      onUseGlobalHour: () =>
          ref.read(reminderSettingsProvider.notifier).useGlobalTime(display),
    );
  }

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
      // Named, like the per-reminder picker: two time pickers in one screen that
      // answer two different questions must not wear the same heading.
      helpText: context.l.reminderNotificationsTimeLabel,
    );
    if (picked == null) return;
    await ref
        .read(notificationSettingsProvider.notifier)
        .setTime(hour: picked.hour, minute: picked.minute);
  }
}

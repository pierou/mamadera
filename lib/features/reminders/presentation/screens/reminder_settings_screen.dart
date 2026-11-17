import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../../../shared/domain/entities/baby_profile.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminder_item_setting.dart';
import '../../domain/services/effective_reminders.dart';
import '../../domain/services/notification_time.dart';
import '../providers/reminder_providers.dart';
import '../providers/reminder_sync_notifier.dart';
import '../widgets/custom_reminder_form_sheet.dart';
import '../widgets/custom_reminder_tile.dart';
import '../widgets/preset_reminder_edit_sheet.dart';
import '../widgets/reminder_display_name.dart';
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
          final profile = ref.watch(activeBabyProvider).value;
          // B33 (D-R2): the same domain function Home and the notification
          // scheduler call, so a renamed, re-paced, ended or removed preset cannot
          // look different here than it does on Home or in the OS schedule. The
          // removed ones are partitioned out of the *declared* list — the function
          // drops them, and D-R4's section needs to show them.
          final declared = presetsAsync.requireValue;
          final stored = settingsAsync.requireValue;
          return _ReminderList(
            presets: effectiveItemsForScope(
              items: declared,
              settings: stored,
              profile: profile,
            ),
            removedPresets: [
              for (final item in declared)
                if (isRemoved(stored[item.id])) item,
            ],
            custom: customAsync.requireValue,
            settings: stored,
            profile: profile,
            // Date of birth of the active baby: only a monthly cycle applies.
            // serves, and that's why it displays "The 14th of each month" instead of...
            // The fictional date is stored in the database.
            monthlyDay: profile?.birthDate.day,
          );
        },
      ),
    );
  }
}

class _ReminderList extends ConsumerWidget {
  const _ReminderList({
    required this.presets,
    required this.removedPresets,
    required this.custom,
    required this.settings,
    required this.profile,
    required this.monthlyDay,
  });

  /// The presets as they are for this parent: overrides applied, removed ones
  /// absent (they are in [removedPresets]).
  final List<ReminderItem> presets;

  /// The presets this parent removed, in declaration order (D-R4's section).
  /// They are *not* deleted: one tap restores each with its hour, name, rhythm and
  /// end intact.
  final List<ReminderItem> removedPresets;

  /// The active baby, for the age form of "program an end" and the monthly rhythm.
  /// `null` on the legacy profileless scope, where the age option is disabled
  /// with a hint (D-R10).
  final BabyProfile? profile;

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
            // B33/D-R6: a preset is editable and removable like a custom one. The
            // menu sits in `secondary` because the switch already owns `trailing`,
            // and both must stay reachable with one thumb.
            secondary: _PresetMenu(
              item: item,
              setting: settings[item.id],
              profile: profile,
            ),
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
        // D-R4: the bottom of the screen, because it is a place things go to be
        // left alone, and one tap away from being not.
        _RemovedSection(items: removedPresets, settings: settings),
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
    final profile = ref.read(activeBabyProvider).value;
    // The end stored for this reminder so far, so editing shows what is set
    // instead of offering "no end" while one exists.
    final stored = existing == null
        ? null
        : ref.read(reminderSettingsProvider).value?['custom_${existing.id}'];
    final draft = await showModalBottomSheet<CustomReminderDraft>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => CustomReminderFormSheet(
        existing: existing,
        birthDate: profile?.birthDate,
        existingEndDate: parseCalendarDate(stored?.endDate),
        existingEndAgeMonths: stored?.endAgeMonths,
      ),
    );
    if (draft == null) return;
    final reminder = draft.reminder;

    final notifier = ref.read(customRemindersProvider.notifier);
    // The try/catch is not decorative: without it a failed write (a full
    // disk, a constraint violation) lands in a future nobody awaits — silent
    // in release, and the parent would see the sheet close with nothing in
    // the list.
    try {
      if (existing == null) {
        await notifier.create(reminder);
      } else {
        await notifier.edit(reminder);
      }
      // D-R5: the end lives on the settings row, not on the reminder, so it is a
      // second write after the reminder itself. `enabledIfNew: true` because
      // creating a custom reminder is itself the consent to run it (B6).
      await ref.read(reminderSettingsProvider.notifier).setEndById(
            'custom_${reminder.id}',
            endDate: draft.endDate,
            endAgeMonths: draft.endAgeMonths,
            enabledIfNew: true,
          );
      if (!context.mounted) return;
      // B17: this path used to complete silently to the finger — the record landed
      // with nothing but a row appearing. `showFeedback` is the app's single haptic
      // contract for a committed insert, and a reminder is an insert like any other.
      showFeedback(
        context,
        existing == null
            ? context.l.reminderCustomAdded
            : context.l.reminderCustomUpdated,
      );
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
    // Through the shared override helper (B33/D-R6): a preset the parent renamed
    // must not answer here with the app's original wording.
    return reminderDisplayName(context, item,
        localised: () => presetCareLabel(context, item));
  }
}

/// The `edit` / `remove` menu of a preset row (B33/D-R6, the custom tile's
/// pattern). Removal is not deletion: the row keeps every column it had and the
/// Removed section offers it back, so no confirmation dialog pretends otherwise —
/// the undo is one tap away and says so.
class _PresetMenu extends ConsumerWidget {
  const _PresetMenu({
    required this.item,
    required this.setting,
    required this.profile,
  });

  final ReminderItem item;
  final ReminderItemSetting? setting;
  final BabyProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: l.reminderCustomSheetEdit,
      initialValue: null,
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await showPresetReminderEditSheet(
              context,
              ref,
              item: item,
              setting: setting,
              birthDate: profile?.birthDate,
            );
          case 'remove':
            await ref.read(reminderSettingsProvider.notifier).remove(item);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(l.edit)),
        PopupMenuItem(value: 'remove', child: Text(l.reminderActionRemove)),
      ],
    );
  }
}

/// D-R4: the removed presets, collapsed, with one-tap restore.
///
/// Removal is a state flag, so the preset has to be reachable again — otherwise a
/// misclick would be permanent for a parent who never meant to stop a clinical
/// reminder. Absent when nothing is removed, so the screen does not grow an empty
/// section nobody asked for.
class _RemovedSection extends ConsumerWidget {
  const _RemovedSection({required this.items, required this.settings});

  final List<ReminderItem> items;
  final Map<String, ReminderItemSetting> settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingXxl),
        ExpansionTile(
          title: Text(l.reminderSettingsRemovedSectionTitle),
          subtitle: Text(
            l.reminderSettingsRemovedDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          tilePadding: EdgeInsets.zero,
          children: [
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reminderDisplayName(context, item,
                    localised: () => presetCareLabel(context, item))),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(reminderSettingsProvider.notifier).restore(item),
                  child: Text(l.reminderActionRestore),
                ),
              ),
          ],
        ),
      ],
    );
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

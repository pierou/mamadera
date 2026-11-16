import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_frequency.dart';
import 'reminder_end_picker.dart';

/// Suggested rhythms for creating a reminder.
///
/// Four, and no more: these are the four that `isDue` is able to evaluate. A rhythm...
/// "Every Tuesday at 8 PM" would require a clock and a system notification.
/// Here are two things that this app doesn't have.
enum CustomReminderFrequencyChoice {
  daily,
  weekly,
  monthlyBirth,
  everyNDays,

  /// B33 Part 1/D-R5 form 1: **one occurrence on a day**. The 365-day ceiling of
  /// "every n days" was always a sign that the parent wanted a date rather than a
  /// rhythm — this is that door, and the day is required, not optional.
  oneTime,
}

/// What the sheet returns: the reminder itself, plus the **end** the parent chose
/// in the same sheet (D-R5).
///
/// The end is not a field of [CustomReminder] because it is not part of the
/// reminder — it is this scope's decision about it, and it lives on the
/// `reminder_settings` row beside the switch and the hour (`custom_<id>`). The
/// sheet keeps its "writes nothing" contract by handing both halves to the screen,
/// which performs the two writes.
class CustomReminderDraft {
  const CustomReminderDraft(
    this.reminder, {
    this.endDate,
    this.endAgeMonths,
  });

  final CustomReminder reminder;
  final DateTime? endDate;
  final int? endAgeMonths;
}

/// Personalized reminder form, on a template sheet.
///
/// It doesn't involve any writing; it simply creates a [CustomReminder] object and returns it.
/// Navigator: The screen that opens this application allows the user to create or modify something, and then proceeds to...
/// The notifier – it's the only way to invalidate the reception prompts.
class CustomReminderFormSheet extends StatefulWidget {
  const CustomReminderFormSheet({
    required this.birthDate,
    this.existing,
    this.existingEndDate,
    this.existingEndAgeMonths,
    super.key,
  });

  /// Pre-filled value; `null` for a new creation.
  final CustomReminder? existing;

  /// The active baby's birthdate: needed to offer "until an age" (D-R10 disables
  /// it with a hint on the legacy profileless scope).
  final DateTime? birthDate;

  /// The end currently stored for this reminder (`reminder_settings`), so the
  /// sheet shows what is really set rather than "no end".
  final DateTime? existingEndDate;
  final int? existingEndAgeMonths;

  @override
  State<CustomReminderFormSheet> createState() =>
      _CustomReminderFormSheetState();
}

class _CustomReminderFormSheetState extends State<CustomReminderFormSheet> {
  /// Upper limit of the range: after one year, the parent wants a specific date.
  /// Not a reminder.
  static const int _maxIntervalDays = 365;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _daysController;

  /// `null` = detached reminder: "No care needed" is the first entry in the...
  /// The menu and its value, never a forced default.
  late String? _subtypeValue;
  late CustomReminderFrequencyChoice _choice;
  DateTime? _oneTimeDate;
  late DateTime? _endDate;
  late int? _endAgeMonths;

  /// The default interval suggested when creating a new one: three days, the frequency.
  /// applying a cream on medical advice, the most commonly requested.
  static const int _defaultIntervalDays = 3;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    // Regarding the modification, the existing options will be retained, including the option to disconnect: him.
    // Applying a default treatment would essentially trigger a reminder without any actual treatment being provided.
    // Health event coming up. Only a new reminder will be sent for the most requested item.
    _subtypeValue = existing == null
        ? HealthSubtype.nettoyageNez.value
        : existing.subtypeValue;
    _choice = _choiceOf(existing?.frequency);
    _endDate = widget.existingEndDate;
    _endAgeMonths = widget.existingEndAgeMonths;
    if (existing?.frequency case OneTime(:final date)) _oneTimeDate = date;
    // Only one field requires you to enter a number of days; the others do not.
    // The rhythms start with the default setting, which is invisible until a selection is made.
    // est ailleurs.
    final storedDays = existing?.frequency.map(
      daily: (_) => null,
      weekly: (_) => null,
      monthly: (_) => null,
      customInterval: (f) => f.days,
      // A one-shot has no "number of days" field to fill. Unreachable while the
      // form offers no one-shot entry point — M4 gives this sheet that entry
      // point (plan §M4: the 365-day cap becomes the one-shot's door), and the
      // day picker replaces this field there.
      oneTime: (_) => null,
    );
    _daysController = TextEditingController(
      text: '${storedDays ?? _defaultIntervalDays}',
    );
  }

  /// Requested interval, limited to [1, _maxIntervalDays].
  ///
  /// An unreadable input defaults to the default range instead of...
  /// block: the field validator has already had its chance, and a reminder has been created.
  /// reste modifiable.
  int get _intervalDays =>
      (int.tryParse(_daysController.text) ?? _defaultIntervalDays)
          .clamp(1, _maxIntervalDays);

  /// The rhythm the form pre-selects for an existing reminder.
  ///
  /// **Known gap until M4** (`PLAN-v1.4.0.md` §9/M3): this sheet has no one-shot
  /// option yet, so a custom reminder restored as `one_time` (only reachable from a
  /// hand-built backup today — nothing in the app writes one) reads back as *daily*
  /// if it is edited and saved. M4 gives the sheet its one-shot entry point — the
  /// plan's "the 365-day cap becomes the one-shot's door" — and the
  /// `custom_reminders.frequency_date` column already exists for it. Listed here
  /// rather than left to the changelog because the fallback is silent by shape.
  CustomReminderFrequencyChoice _choiceOf(ReminderFrequency? frequency) {
    return switch (frequency) {
      CustomInterval() => CustomReminderFrequencyChoice.everyNDays,
      Weekly() => CustomReminderFrequencyChoice.weekly,
      Monthly() => CustomReminderFrequencyChoice.monthlyBirth,
      OneTime() => CustomReminderFrequencyChoice.oneTime,
      _ => CustomReminderFrequencyChoice.daily,
    };
  }

  @override
  void dispose() {
    _labelController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final frequency = switch (_choice) {
      CustomReminderFrequencyChoice.daily => const ReminderFrequency.daily(),
      // Weekdays are not considered: `isDue` ignores them (it only checks if a task is due on a specific day).
      // The weekly reminder simply postpones the matter to the following week, regardless of the circumstances.
      // "...), and suggest "Tuesday" for a reminder that also appears on Friday."
      // serait un mensonge.
      CustomReminderFrequencyChoice.weekly => const ReminderFrequency.weekly(
          dayOfWeek: 1,
        ),
      // No specific date is chosen here; the date is simply the baby's birthday.
      // active, and displayed as such, similar to vitamin K.
      CustomReminderFrequencyChoice.monthlyBirth =>
        const ReminderFrequency.monthly(
          dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
        ),
      CustomReminderFrequencyChoice.everyNDays =>
        ReminderFrequency.customInterval(
          days: _intervalDays,
        ),
      CustomReminderFrequencyChoice.oneTime =>
        ReminderFrequency.oneTime(date: _oneTimeDate),
    };

    Navigator.of(context).pop(
      CustomReminderDraft(
        CustomReminder(
          label: _labelController.text.trim(),
          subtypeValue: _subtypeValue,
          // D2: The choice of treatment determines the source – a reminder without treatment is...
          // It was determined by the "Done" button, never by a health-related event.
          completionSource:
              _subtypeValue == null ? completionManual : completionFromEvents,
          frequency: frequency,
          id: widget.existing?.id,
        ),
        endDate: _endDate,
        endAgeMonths: _endAgeMonths,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingXxl,
        right: AppTheme.spacingXxl,
        top: AppTheme.spacingXl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingXl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null
                  ? context.l.reminderCustomSheetAdd
                  : context.l.reminderCustomSheetEdit,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabelField(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildCareField(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildFrequencyField(),
                  if (_choice == CustomReminderFrequencyChoice.everyNDays) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildIntervalField(),
                  ],
                  if (_choice == CustomReminderFrequencyChoice.oneTime) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildOneTimeDateField(),
                  ],
                  const SizedBox(height: AppTheme.spacingXl),
                  // D-R5: the same end section as a preset's, so "until a date"
                  // and "until an age" mean one thing wherever they are set.
                  ReminderEndPicker(
                    birthDate: widget.birthDate,
                    endDate: _endDate,
                    endAgeMonths: _endAgeMonths,
                    onChanged: ({DateTime? endDate, int? endAgeMonths}) =>
                        setState(() {
                      _endDate = endDate;
                      _endAgeMonths = endAgeMonths;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            DialogActionButtons(
              cancelLabel: context.l.cancelButton,
              confirmLabel: context.l.confirmButton,
              onCancelPressed: () => Navigator.of(context).pop(),
              // D-R5 write-strict: a one-shot without a day is not a rhythm, and
              // the repository refuses the call anyway — the button is the honest
              // place to say so.
              onConfirmPressed:
                  _choice == CustomReminderFrequencyChoice.oneTime &&
                          _oneTimeDate == null
                      ? null
                      : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelField() {
    return TextFormField(
      controller: _labelController,
      maxLength: 60,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: context.l.reminderCustomLabelField,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: (value) => (value ?? '').trim().isEmpty
          ? context.l.reminderCustomLabelRequired
          : null,
    );
  }

  Widget _buildCareField() {
    return DropdownButtonFormField<String>(
      initialValue: _subtypeValue,
      // "No care" is an entry like any other, but its value is...
      // `null`: The dropdown displays the selected option as an index.
      hint: Text(context.l.reminderCustomCareNone),
      decoration: InputDecoration(
        labelText: context.l.reminderCustomCareField,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(context.l.reminderCustomCareNone),
        ),
        for (final subtype in HealthSubtype.values)
          DropdownMenuItem(
            value: subtype.value,
            child: Text(resolveHealthLabel(context, subtype)),
          ),
      ],
      onChanged: (value) {
        _subtypeValue = value;
      },
    );
  }

  Widget _buildFrequencyField() {
    return DropdownButtonFormField<CustomReminderFrequencyChoice>(
      initialValue: _choice,
      decoration: InputDecoration(
        labelText: context.l.reminderCustomFrequencyField,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final choice in CustomReminderFrequencyChoice.values)
          DropdownMenuItem(
            value: choice,
            child: Text(_frequencyChoiceLabel(choice)),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        // The "number of days" field is only available for shift schedules.
        setState(() => _choice = value);
      },
    );
  }

  /// The day the single occurrence happens on, plus the reason the confirm button
  /// is greyed out while it is empty.
  Widget _buildOneTimeDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l.reminderOneTimeNeedsDate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _oneTimeDate == null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextButton.icon(
          onPressed: _pickOneTimeDate,
          icon: const Icon(Icons.event),
          label: Text(_oneTimeDate == null
              ? context.l.reminderEndOnDate
              : formatDateShort(context, _oneTimeDate!)),
        ),
      ],
    );
  }

  Future<void> _pickOneTimeDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _oneTimeDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(
        () => _oneTimeDate = DateTime(picked.year, picked.month, picked.day));
  }

  Widget _buildIntervalField() {
    return TextFormField(
      controller: _daysController,
      keyboardType: TextInputType.number,
      maxLength: 3,
      decoration: InputDecoration(
        labelText: context.l.reminderCustomIntervalField,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final days = int.tryParse((value ?? '').trim());
        if (days == null || days < 1 || days > _maxIntervalDays) {
          return context.l.reminderCustomIntervalRequired;
        }
        return null;
      },
    );
  }

  /// Wording for selecting a rhythm from the drop-down list.
  ///
  /// The scheduling system uses the label "Interval in days" for that field, rather than...
  /// "Every n days": The value of 'n' has not yet been entered in this field, and neither has [the value associated with 'him/her/it']."
  /// Displaying one would create a discrepancy between the list and the field.
  String _frequencyChoiceLabel(CustomReminderFrequencyChoice choice) {
    return switch (choice) {
      CustomReminderFrequencyChoice.daily => context.l.reminderFrequencyDaily,
      CustomReminderFrequencyChoice.weekly => context.l.reminderFrequencyWeekly,
      CustomReminderFrequencyChoice.monthlyBirth =>
        context.l.reminderFrequencyMonthlyBirth,
      CustomReminderFrequencyChoice.everyNDays =>
        context.l.reminderCustomIntervalField,
      CustomReminderFrequencyChoice.oneTime =>
        context.l.reminderFrequencyOnceChoice,
    };
  }
}

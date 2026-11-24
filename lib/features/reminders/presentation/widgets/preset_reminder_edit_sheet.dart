import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../domain/entities/reminder_frequency.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminder_item_setting.dart';
import '../../domain/services/reminder_frequency_codec.dart';
import '../providers/reminder_providers.dart';
import '../providers/reminder_sync_notifier.dart';
import 'reminder_display_name.dart';
import 'reminder_end_picker.dart';
import 'reminder_frequency_label.dart';
import 'reminder_hour_control.dart';

/// Edit one preset reminder (B33/D-R6): its **name**, its **rhythm** (including a
/// single occurrence), the **hour** it fires at (B30) and its **end** — the same
/// decisions a custom reminder form offers, so a preset is not a second-class row
/// a parent can only switch off.
///
/// What is deliberately *not* here: the **care** the reminder is settled by. D-R6
/// rules it out — re-pointing `vitamine_k` at some other event would decouple the
/// reminder from the dose that settles it, and the app would then mark a care done
/// that was never recorded (invariant D2's whole reason for existing).
///
/// Every field is optional in the strongest sense: leaving one alone writes
/// nothing for it, and choosing "back to the default" writes NULL, which is how the
/// row says "no override" (D-R2). A preset whose rhythm was reset that way follows
/// the preset again, including future changes to it.
Future<void> showPresetReminderEditSheet(
  BuildContext context,
  WidgetRef ref, {
  required ReminderItem item,
  required ReminderItemSetting? setting,
  required DateTime? birthDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _PresetReminderEditSheet(
      item: item,
      setting: setting,
      birthDate: birthDate,
      ref: ref,
    ),
  );
}

/// The rhythms the sheet offers: the four `isDue` can evaluate, the one-shot from
/// B33, and "no override".
enum _Choice { preset, daily, weekly, monthly, everyNDays, oneTime }

class _PresetReminderEditSheet extends StatefulWidget {
  const _PresetReminderEditSheet({
    required this.item,
    required this.setting,
    required this.birthDate,
    required this.ref,
  });

  final ReminderItem item;
  final ReminderItemSetting? setting;
  final DateTime? birthDate;
  final WidgetRef ref;

  @override
  State<_PresetReminderEditSheet> createState() =>
      _PresetReminderEditSheetState();
}

class _PresetReminderEditSheetState extends State<_PresetReminderEditSheet> {
  static const int _maxIntervalDays = 365;

  late final TextEditingController _labelController;
  late final TextEditingController _daysController;
  late _Choice _choice;
  late DateTime? _oneTimeDate;
  late DateTime? _endDate;
  late int? _endAgeMonths;

  /// The hour column as this sheet last left it (B30).
  ///
  /// The sheet is handed a snapshot of the row, and an hour is written the moment
  /// it is picked (the settings row behaves the same way), so the copy has to be
  /// kept here: without it, pressing the reset button inside the sheet would look
  /// like nothing happened until the sheet was reopened.
  late String? _storedTime;

  @override
  void initState() {
    super.initState();
    _storedTime = widget.setting?.timeOfDay;
    _labelController = TextEditingController(
      text: widget.setting?.label ?? '',
    );
    _daysController = TextEditingController(text: '3');
    _endDate = widget.setting?.endDate == null
        ? null
        : _parseDate(widget.setting!.endDate!);
    _endAgeMonths = widget.setting?.endAgeMonths;
    switch (widget.item.frequency) {
      case Daily():
        _choice = _Choice.daily;
      case Weekly():
        _choice = _Choice.weekly;
      case Monthly():
        _choice = _Choice.monthly;
      case CustomInterval():
        _choice = _Choice.everyNDays;
      case OneTime():
        _choice = _Choice.oneTime;
    }
    // An override in the row wins over the preset's own rhythm, and the sheet has
    // to start from what the parent actually sees.
    if (widget.setting?.frequency == null) {
      _choice = _Choice.preset;
    } else if (widget.setting!.frequency == 'every_n_days') {
      _daysController.text = '${widget.setting!.intervalDays ?? 3}';
    }
    _oneTimeDate = _parseDate(widget.setting?.frequencyDate);
    if (_oneTimeDate == null) {
      final frequency = widget.item.frequency;
      if (frequency is OneTime) _oneTimeDate = frequency.date;
    }
  }

  static DateTime? _parseDate(String? stored) {
    if (stored == null || stored.length != 10) return null;
    final y = int.tryParse(stored.substring(0, 4));
    final m = int.tryParse(stored.substring(5, 7));
    final d = int.tryParse(stored.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  bool get _oneTimeMissing =>
      _choice == _Choice.oneTime && _oneTimeDate == null;

  /// One reminder's hour state, resolved by the same function the settings row
  /// uses, so the two surfaces cannot disagree about what "its hour" is.
  ReminderHourState get _hour => resolveReminderHour(
        storedTimeOfDay: _storedTime,
        prefs: widget.ref.read(notificationSettingsProvider).value,
      );

  /// Write the hour, then show what was actually stored.
  ///
  /// Re-read rather than formatted from the picked `TimeOfDay`: the codec that
  /// owns `HH:mm` stays the only place that spelling is produced.
  Future<void> _writeHour(Future<void> Function() write) async {
    await write();
    if (!mounted) return;
    setState(() {
      _storedTime = widget.ref
          .read(reminderSettingsProvider)
          .value?[widget.item.id]
          ?.timeOfDay;
    });
  }

  Future<void> _save() async {
    if (_oneTimeMissing) return;
    final notifier = widget.ref.read(reminderSettingsProvider.notifier);
    final item = widget.item;

    final typed = _labelController.text.trim();
    if (typed != (widget.setting?.label ?? '')) {
      await notifier.setLabel(item, label: typed.isEmpty ? null : typed);
    }

    final frequency = _frequencyOrNull();
    if (frequency != widget.setting?.asFrequency()) {
      await notifier.setFrequency(item, frequency: frequency);
    }

    if (_endDate != _endDateOf(widget.setting) ||
        _endAgeMonths != widget.setting?.endAgeMonths) {
      await notifier.setEnd(
        item,
        endDate: _endDate,
        endAgeMonths: _endAgeMonths,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// The rhythm the sheet now expresses, or `null` for "follow the preset again".
  ReminderFrequency? _frequencyOrNull() => switch (_choice) {
        _Choice.preset => null,
        _Choice.daily => const ReminderFrequency.daily(),
        _Choice.weekly => const ReminderFrequency.weekly(dayOfWeek: 1),
        _Choice.monthly => ReminderFrequency.monthly(
            dayOfMonth: widget.birthDate?.day ?? 1,
          ),
        _Choice.everyNDays => ReminderFrequency.customInterval(
            days: (int.tryParse(_daysController.text) ?? 3)
                .clamp(1, _maxIntervalDays),
          ),
        _Choice.oneTime => ReminderFrequency.oneTime(date: _oneTimeDate),
      };

  static DateTime? _endDateOf(ReminderItemSetting? setting) {
    final stored = setting?.endDate;
    return stored == null ? null : _parseDate(stored);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingLg,
          right: AppTheme.spacingLg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: GlobalKey<FormState>(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Named with the reminder's current wording, override included.
                  '${l.reminderPresetEditTitle} — '
                  '${reminderDisplayName(context, widget.item, localised: () => presetCareLabel(context, widget.item))}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                TextField(
                  controller: _labelController,
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: l.reminderCustomLabelField,
                    counterText: '',
                    suffixIcon: TextButton(
                      onPressed: () {
                        setState(_labelController.clear);
                      },
                      child: Text(l.reminderLabelReset),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(l.reminderCustomFrequencyField,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: [
                    _chip(_Choice.preset, l.reminderFrequencyReset),
                    _chip(_Choice.daily, l.reminderFrequencyDaily),
                    _chip(_Choice.weekly, l.reminderFrequencyWeekly),
                    _chip(
                      _Choice.monthly,
                      l.reminderFrequencyMonthly(widget.birthDate?.day ?? 1),
                    ),
                    _chip(
                      _Choice.everyNDays,
                      l.reminderFrequencyEveryNDays(3),
                    ),
                    _chip(_Choice.oneTime, l.reminderFrequencyOnceChoice),
                  ],
                ),
                if (_choice == _Choice.everyNDays)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                    child: TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.reminderCustomIntervalField,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                if (_choice == _Choice.oneTime)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: _pickOneTimeDate,
                          icon: const Icon(Icons.event),
                          label: Text(_oneTimeDate == null
                              ? l.reminderOneTimeNeedsDate
                              : formatDateShort(context, _oneTimeDate!)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingLg),
                // B30: the hour belongs with the rhythm it fires on. It used to be
                // reachable only from the settings row, so "edit this reminder"
                // offered a name, a frequency and an end — and not the one number
                // a parent most often wants to move.
                Text(l.reminderHourSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall),
                ReminderHourControl(
                  frequency: _frequencyOrNull() ?? widget.item.frequency,
                  // The chips above already are the rhythm; this line is about the
                  // hour alone.
                  showRhythm: false,
                  hourLabel: _hour.hourLabel,
                  inherited: _hour.inherited,
                  showHour: _hour.showHour,
                  onPick: () => _writeHour(
                    () => pickReminderHour(
                      context: context,
                      ref: widget.ref,
                      item: widget.item,
                      storedTimeOfDay: _storedTime,
                    ),
                  ),
                  onUseGlobal: () => _writeHour(
                    () => widget.ref
                        .read(reminderSettingsProvider.notifier)
                        .useGlobalTime(widget.item),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
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
                const SizedBox(height: AppTheme.spacingLg),
                DialogActionButtons(
                  cancelLabel: l.cancelButton,
                  confirmLabel: l.confirmButton,
                  onCancelPressed: () => Navigator.of(context).pop(),
                  // D-R5 write-strict: a one-shot without a day is not a rhythm,
                  // so the sheet cannot be saved in that state.
                  onConfirmPressed: _oneTimeMissing ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(_Choice value, String label) => ChoiceChip(
        label: Text(label),
        selected: _choice == value,
        onSelected: (_) => setState(() => _choice = value),
      );

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
}

extension on ReminderItemSetting {
  /// The row's stored rhythm, as the domain type — so "did the parent change the
  /// rhythm?" compares two rhythms instead of two spellings of one.
  ReminderFrequency? asFrequency() => frequency == null
      ? null
      : decodeFrequency(
          frequency!,
          intervalDays,
          occurrenceDate: frequencyDate,
        );
}

/// The rhythm line a preset row shows, override included.
String presetFrequencyLine(
  BuildContext context,
  ReminderItem item,
) =>
    reminderFrequencyLabel(context, item.frequency);

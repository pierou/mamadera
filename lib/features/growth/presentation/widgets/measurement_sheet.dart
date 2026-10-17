import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../home/presentation/widgets/quantity_picker_inline.dart';
import '../../domain/entities/measure_kind.dart';
import '../providers/measurement_providers.dart';
import 'measure_kind_accent.dart';

/// Sheet for entering a growth measurement (weight, height, temperature).
class MeasurementSheet extends ConsumerStatefulWidget {
  const MeasurementSheet({
    required this.kind,
    super.key,
  });

  final MeasureKind kind;

  /// Opens the sheet and returns the entered value (null if cancelled).
  static Future<double?> show(
    BuildContext context, {
    required MeasureKind kind,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MeasurementSheet(kind: kind),
    );
  }

  @override
  ConsumerState<MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<MeasurementSheet> {
  late double _value;
  bool _inRange = true;
  DateTime _selectedDate = DateTime.now();
  late TextEditingController _noteController;

  /// Supplemental label: "last: 36.8 °C", resolved asynchronously — `null`
  /// As long as the data hasn't been loaded, in which case the result will be...
  /// The type reference. Resolved **outside of `initState`**: `context.l` is not available there.
  /// It is not yet certain, and asynchronous operations never provide a result.
  /// Automatically fill in the field.
  String? _lastHint;

  /// Did the parent enter a number? The save button is not working.
  /// Previously: display the initial value as a measurement taken, which...
  /// serait l'inventer.
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _value = widget.kind.defaultValue;
    _noteController = TextEditingController();
    _loadLastValue();
  }

  /// Supplemental description: the most recent measure of the same type, if one exists.
  /// Otherwise, the reference value for the type (e.g., "37°C").
  String get _hintLabel =>
      _lastHint ??
      widget.kind
          .format(widget.kind.defaultValue, localeName: context.l.localeName);

  /// Last measurement of the same type, if available: "last: 36.8 °C".
  /// If a digit is illegible or has no value, the reference number is retained.
  /// type — the auxiliary heating is a comfort feature, never a blocking mechanism.
  ///
  /// It also serves as the **starting point for the cursor and the +/- buttons** (default).
  /// v1.2.1 (displayed on the device): The header shows "Last reading: 36.8 °C".
  /// From the moment it opens, and upon the initial contact with the cursor or a plus/minus sign, it redirects.
  /// 37.0 – This is the reference value for the type, meaning a number that no one has actually measured.
  /// The target should be located at the intended point. The text field remains empty, and...
  /// Autosave is disabled: a cursor position is not considered an input.
  Future<void> _loadLastValue() async {
    try {
      final repository = await ref.read(measurementRepositoryProvider.future);
      final babyId = ref.read(activeBabyProvider).value?.id;
      final last = await repository.latestOfKind(babyId, widget.kind);
      final lastValue = last?.value;
      if (!mounted || lastValue == null) return;
      setState(() {
        _lastHint = context.l.growthSheetLastValueHint(
          widget.kind.format(lastValue, localeName: context.l.localeName),
        );
        // Never after a parent's seizure: the reading happens asynchronously and...
        // It would overwrite the number he was currently typing.
        if (!_hasInput && widget.kind.contains(lastValue)) {
          _value = lastValue;
        }
      });
    } catch (_) {
      // The sheet remains usable even without the additional component.
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_inRange) return;
    final repository = await ref.read(measurementRepositoryProvider.future);
    final babyId = ref.read(activeBabyProvider).value?.id;
    await repository.add(
      babyId: babyId,
      kind: widget.kind,
      value: _value,
      recordedAt: _selectedDate,
      notes: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    // Please review here before closing: the welcome section and the Growth screen.
    // watchent `measurementNotifierProvider`, qui ne se relit ni tout seul ni au
    // Return from another page (bug in version 1.2.1: the parent recorded 4.2 kg).
    // It remained displayed at 3.9 kg until the baby was changed.)
    await ref.read(measurementNotifierProvider.notifier).refresh();
    if (!mounted) return;
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    // The header columns display units, not raw numbers.
    // "200–20000 g" is read as "between two hundred grams and twenty kilograms."
    final rangeLabel =
        '${widget.kind.min.round()}–${widget.kind.max.round()} ${widget.kind.displayUnit}';
    final title = switch (widget.kind) {
      MeasureKind.poids => l.growthSheetTitleWeight,
      MeasureKind.taille => l.growthSheetTitleHeight,
      MeasureKind.temperature => l.growthSheetTitleTemperature,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingMd,
      ),
      child: SingleChildScrollView(
        // If the sheet extends beyond the screen (e.g., on a small phone or with the keyboard open),...
        // It's set to record instead of being muted: the record button needs to be...
        // It remains accessible at any size.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              rangeLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            QuantityPickerInline(
              unit: widget.kind.displayUnit,
              min: widget.kind.min,
              max: widget.kind.max,
              divisions: widget.kind.divisions,
              step: widget.kind.step,
              decimals: widget.kind.decimals,
              value: _value,
              accentColor: widget.kind.accent,
              hintLabel: _hintLabel,
              onValueChanged: (double value) {
                setState(() {
                  _value = value;
                  _inRange = true;
                  _hasInput = true;
                });
              },
              onValueOutOfRange: (double value) {
                setState(() {
                  _value = value;
                  _inRange = false;
                  _hasInput = true;
                });
              },
            ),
            if (!_inRange) ...[
              const SizedBox(height: 8),
              Text(
                l.growthValueOutOfRange(
                  widget.kind.formatBound(widget.kind.min),
                  widget.kind.formatBound(widget.kind.max),
                  widget.kind.displayUnit,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppTheme.spacingMd),
            EventDateTimeField(
              value: _selectedDate,
              onChanged: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l.growthSheetNoteField,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            DialogCancelButton(
              label: l.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            DialogConfirmButton(
              label: l.growthSheetSave,
              onPressed: (_inRange && _hasInput) ? _save : null,
              showIcon: true,
            ),
          ],
        ),
      ),
    );
  }
}

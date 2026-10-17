import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../home/presentation/widgets/quantity_picker_inline.dart';
import '../../domain/entities/growth_measurement.dart';
import '../../domain/entities/measure_kind.dart';
import 'measure_kind_accent.dart';

/// Result displayed from the editing sheet of a measurement, as viewed in the history.
sealed class MeasurementEditResult {
  const MeasurementEditResult();
}

/// The measurement has been corrected (value, date, and/or note).
final class MeasurementUpdated extends MeasurementEditResult {
  const MeasurementUpdated(this.measurement);

  /// The corrected measurement, including its original ID.
  final GrowthMeasurement measurement;
}

/// The measure has been removed.
final class MeasurementDeleted extends MeasurementEditResult {
  const MeasurementDeleted(this.id);

  final int id;
}

/// Growth measure editing sheet: here, you can correct the value and...
/// either the date or the note of an existing line (we don't create a new one), or...
/// on la supprime.
///
/// The "kind," "unit," and "baby" never move; they always stay on the same line.
/// is corrected. An out-of-range input follows rule B5 – the number remains.
/// Displayed, the error appears, "Save" is disabled, and there is no clamping.
class EditMeasurementSheet extends StatefulWidget {
  const EditMeasurementSheet({required this.measurement, super.key});

  final GrowthMeasurement measurement;

  /// Opens the sheet and returns the result (`null` if canceled).
  static Future<MeasurementEditResult?> show(
    BuildContext context, {
    required GrowthMeasurement measurement,
  }) {
    return showModalBottomSheet<MeasurementEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditMeasurementSheet(measurement: measurement),
    );
  }

  @override
  State<EditMeasurementSheet> createState() => _EditMeasurementSheetState();
}

class _EditMeasurementSheetState extends State<EditMeasurementSheet> {
  late double _value;
  bool _inRange = true;
  late DateTime _selectedDate;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    // The displayed value: either the value of the item, or the reference number of the type, if applicable.
    // The number is illegible (header editing is required in this case). The field is...
    // pre-filled – this refers to the **version** of a measure that has been taken, not the process of entering data.
    // News: The data entry form, on the other hand, starts empty.
    _value = widget.measurement.value ?? widget.measurement.kind.defaultValue;
    _inRange = widget.measurement.kind.contains(_value);
    _selectedDate = widget.measurement.recordedAt;
    _noteController =
        TextEditingController(text: widget.measurement.notes ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_inRange) return;
    Navigator.of(context).pop(MeasurementUpdated(
      widget.measurement.copyWith(
        value: _value,
        recordedAt: _selectedDate,
        notes: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    ));
  }

  void _delete() {
    Navigator.of(context).pop(MeasurementDeleted(widget.measurement.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final kind = widget.measurement.kind;
    final title = switch (kind) {
      MeasureKind.poids => l.growthSheetEditTitleWeight,
      MeasureKind.taille => l.growthSheetEditTitleHeight,
      MeasureKind.temperature => l.growthSheetEditTitleTemperature,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingMd,
      ),
      child: SingleChildScrollView(
        // Like the input form: if the form extends beyond the screen (small).
        // (phone, keyboard open), instead of cutting off, it keeps scrolling — the button.
        // The recording and deletion processes must remain accessible.
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
            const SizedBox(height: AppTheme.spacingMd),
            QuantityPickerInline(
              unit: kind.displayUnit,
              min: kind.min,
              max: kind.max,
              divisions: kind.divisions,
              step: kind.step,
              decimals: kind.decimals,
              value: _value,
              accentColor: kind.accent,
              onValueChanged: (double value) {
                setState(() {
                  _value = value;
                  _inRange = true;
                });
              },
              onValueOutOfRange: (double value) {
                setState(() {
                  _value = value;
                  _inRange = false;
                });
              },
            ),
            if (!_inRange) ...[
              const SizedBox(height: 8),
              // `formatBound`: The boundaries are integers by default, and...
              // The seizure warrant already states "between 200 and 20,000 grams." Let's proceed.
              // The "raw" values for `double` ranged from "200.0 to 20000.0 g" – two sentences.
              // For the same error, but with the numbers formatted differently.
              Text(
                l.growthValueOutOfRange(
                  kind.formatBound(kind.min),
                  kind.formatBound(kind.max),
                  kind.displayUnit,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.deleteButton,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                // `Expanded` + ellipse: on a 412 dp screen, the two...
                // The labels, at their natural size, extended 6 pixels beyond the edge – a...
                // A button that is only partially visible on the screen is not a button. The action...
                // The main text takes up the majority of the space, while the label fades into the background.
                // avant qu'elle disparaisse.
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _inRange ? _save : null,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l.growthSheetSave,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

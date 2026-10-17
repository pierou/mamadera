import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/unit_localization.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../../shared/domain/entities/quantity_unit.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import 'quantity_picker_inline.dart';

/// A dialog for tracking feeding events with subtype selection and quantity.
///
/// Contains:
/// - Feeding subtype chip selector (natural/artificial/solid) at the top
/// - Unit toggle, **only** for `natural`: a feed at the breast is timed
///   (minutes), expressed milk is measured (millilitres), and the same parent
///   does both the same day
/// - Quantity picker whose unit and range follow the selected unit
/// - Date and time of the feed (defaults to now)
/// - Confirm button that returns (feedingSubtype, unit, quantity, timestamp)
class FeedingTrackingDialog extends ConsumerStatefulWidget {
  const FeedingTrackingDialog({super.key});

  @override
  ConsumerState<FeedingTrackingDialog> createState() =>
      _FeedingTrackingDialogState();
}

class _FeedingTrackingDialogState extends ConsumerState<FeedingTrackingDialog> {
  late FeedingSubtype _selectedSubtype;

  /// Unit of the quantity being entered. `min` at the open: a breastfeed is
  /// timed, a bottle is measured.
  late QuantityUnit _unit;
  double _selectedQuantity = 0;

  /// The quantity is reset to zero when the unit changes, and the dialog indicates this.
  bool _unitResetNotice = false;

  /// Number entered is outside the valid range; `null` indicates that the value is within the range (or that nothing has been entered).
  double? _outOfRange;

  /// Date and time of the feed. Defaulted once at open time: the dialog is
  /// rebuilt on every slider tick, so a plain field initialiser keeps the
  /// displayed "now" stable while the parent is choosing.
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedSubtype = FeedingSubtype.natural; // Default to breast milk
    _unit = QuantityUnit.min;
  }

  void _onQuantityChanged(double quantity) {
    setState(() {
      _selectedQuantity = quantity;
      _outOfRange = null;
    });
  }

  /// Unit carried by a subtype: grams for solids, minutes at the breast,
  /// millilitres for a bottle. Fixed for every subtype except `natural`,
  /// where the parent chooses.
  static QuantityUnit _unitFor(FeedingSubtype subtype) => switch (subtype) {
        FeedingSubtype.natural => QuantityUnit.min,
        FeedingSubtype.artificial => QuantityUnit.ml,
        FeedingSubtype.solid => QuantityUnit.g,
      };

  bool get _inRange => _outOfRange == null;

  /// Selection of a subtype: the unit remains, but **the number does not survive.**
  /// a change of unit.
  ///
  /// 20 ml is not 20 minutes, and 20 minutes is not 20 grams. Please keep this in mind.
  /// The number changes by simply altering the label, which is precisely the flaw that this [thing/system/process] exhibits.
  /// deleted version: the field resets to 0, and the dialog box indicates this directly within the field.
  void _selectSubtype(FeedingSubtype subtype) {
    setState(() {
      _selectedSubtype = subtype;
      final nextUnit = _unitFor(subtype);
      if (nextUnit != _unit) {
        _unit = nextUnit;
        _selectedQuantity = 0;
        _unitResetNotice = true;
      }
      _outOfRange = null;
    });
  }

  /// Parent selection within a range (ml ↔ min): The same rule applies, and no number changes.
  /// with gentle unity.
  void _selectUnit(QuantityUnit unit) {
    if (unit == _unit) return;
    setState(() {
      _unit = unit;
      _selectedQuantity = 0;
      _unitResetNotice = true;
      _outOfRange = null;
    });
  }

  /// Picker bounds and step, **depending on the chosen unit** (plan
  /// v1.2.1) : `ml` 0–300 par 10, `min` 0–120 par 1, `g` 0–1000 par 5.
  /// A 40-minute feeding session doesn't necessarily translate to a 40-minute bottle feeding, and...
  /// A volume of 5 ml is off by one increment of 10.
  ///
  /// The pair of sliders (B2) was included with each unit: removed - one.
  /// The slider brings it closer, the stepper adjusts it precisely, and the input field sets the value.
  /// dernier cran (docs/BACKLOG.md B2).
  ({double min, double max, int divisions, double step}) get _pickerSpec =>
          switch (_unit) {
            QuantityUnit.ml => (min: 0, max: 300, divisions: 30, step: 10),
            QuantityUnit.min => (min: 0, max: 120, divisions: 120, step: 1),
            QuantityUnit.g => (min: 0, max: 1000, divisions: 200, step: 5),
          };

  /// The displayed unit: the unit of the line currently being entered, resolved since...
  /// the locale — an `'ml'` character will never be written in the widget.
  String _feedingUnit(BuildContext context) =>
      quantityUnitLabel(context, _unit);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              context.l.feedingDialogTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Feeding subtype selector
            Text(
              context.l.feedingSubtypeLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeedingSubtype.natural.icon, size: 18),
                        Flexible(
                          child: Text(
                            context.l.feedingSubtypeNatural,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selected: _selectedSubtype == FeedingSubtype.natural,
                    onSelected: (_) => _selectSubtype(FeedingSubtype.natural),
                    selectedColor: AppTheme.miam.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeedingSubtype.artificial.icon, size: 18),
                        Flexible(
                          child: Text(
                            context.l.feedingSubtypeArtificial,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selected: _selectedSubtype == FeedingSubtype.artificial,
                    onSelected: (_) =>
                        _selectSubtype(FeedingSubtype.artificial),
                    selectedColor: AppTheme.miam.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeedingSubtype.solid.icon, size: 18),
                        Flexible(
                          child: Text(
                            context.l.feedingSolid,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selected: _selectedSubtype == FeedingSubtype.solid,
                    onSelected: (_) => _selectSubtype(FeedingSubtype.solid),
                    selectedColor: AppTheme.miam.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Unit — the breast has only two legitimate units: breastfeeding is counted.
            // In minutes, the amount of milk expressed is measured in milliliters, and the same mother can...
            // Both occurred on the same day. The other subtypes remain unchanged.
            if (_selectedSubtype == FeedingSubtype.natural) ...[
              Text(
                context.l.feedingUnitLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<QuantityUnit>(
                segments: [
                  ButtonSegment(
                    value: QuantityUnit.ml,
                    label: Text(context.l.feedingUnitMl),
                  ),
                  ButtonSegment(
                    value: QuantityUnit.min,
                    label: Text(context.l.feedingUnitMin),
                  ),
                ],
                selected: {_unit},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => _selectUnit(selection.first),
              ),
              const SizedBox(height: 24),
            ],

            // The reset message originates from the `natural` block: transitioning from...
            // "From 'Liquid' (min) to 'Solid' (g), this also adjusts the quantity."
            // at 0, and a silent reset to 0 is the bug that v1.2.1 fixes.
            // There are items to be deleted.
            if (_unitResetNotice) ...[
              const SizedBox(height: 8),
              Text(
                context.l.feedingUnitReset,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity section
            Text(
              context.l.feedingQuantityLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            QuantityPickerInline(
              unit: _feedingUnit(context),
              min: _pickerSpec.min,
              max: _pickerSpec.max,
              divisions: _pickerSpec.divisions,
              // The stepper motor is aligned with the slider's step for the current unit.
              step: _pickerSpec.step,
              value: _selectedQuantity,
              onValueChanged: _onQuantityChanged,
              // An out-of-range input was no longer being suppressed (BACKLOG B5): the number.
              // The parent element remains on the screen, the error message is displayed, and then "Save" is clicked.
              // remains disabled. Never use `clamp`: correct a number of...
              // This app refuses to allow users to track a child's location without their knowledge.
              onValueOutOfRange: (value) => setState(() {
                _selectedQuantity = value;
                _outOfRange = value;
              }),
            ),

            if (!_inRange) ...[
              const SizedBox(height: 8),
              Text(
                context.l.feedingValueOutOfRange(
                  _pickerSpec.min.toInt().toString(),
                  _pickerSpec.max.toInt().toString(),
                  _feedingUnit(context),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],

            const SizedBox(height: 24),

            EventDateTimeField(
              value: _selectedDate,
              onChanged: (date) => setState(() => _selectedDate = date),
            ),

            const SizedBox(height: 24),

            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: _inRange
                  ? () {
                      if (context.mounted) {
                        Navigator.pop(context, {
                          'subtype': _selectedSubtype,
                          // The unit travels with the number: it is what states what
                          // what the number represents.
                          'unit': _unit,
                          'quantity': _selectedQuantity,
                          'timestamp': _selectedDate,
                        });
                      }
                    }
                  : null,
              cancelLabel: context.l.cancelButton,
              confirmLabel: context.l.confirmButton,
            ),
          ],
        ),
      ),
    );
  }
}

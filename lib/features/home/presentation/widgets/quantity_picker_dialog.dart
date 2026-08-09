import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';

// ignore_for_file: public_member_api_docs

/// A dialog with a bidirectional slider + text input for quantity values.
///
/// Used for feeding quantity (ml) and sleep duration (min).
class QuantityPickerDialog extends StatefulWidget {
  const QuantityPickerDialog({
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onQuantitySelected,
    this.initialValue = 0,
    super.key,
  });

  /// Unit suffix displayed in the UI ('ml' or 'min').
  final String unit;

  /// Minimum value for the slider.
  final double min;

  /// Maximum value for the slider.
  final double max;

  /// Number of divisions on the slider.
  final int divisions;

  /// Initial value for the slider/text field.
  final double initialValue;

  /// Callback fired when the user confirms a value.
  final void Function(double quantity) onQuantitySelected;

  @override
  State<QuantityPickerDialog> createState() => _QuantityPickerDialogState();
}

class _QuantityPickerDialogState extends State<QuantityPickerDialog> {
  late double _selectedValue;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _textController = TextEditingController(text: widget.initialValue.toInt().toString());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _selectedValue = value;
      _textController.text = value.round().toString();
    });
  }

  void _onTextChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null && parsed >= widget.min && parsed <= widget.max) {
      setState(() {
        _selectedValue = parsed;
      });
    }
  }

  String _formatValue(double value) {
    return '${value.round()} ${widget.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.l.quantityPickerTitle} (${widget.unit})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                _formatValue(_selectedValue),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 56,
                      color: AppTheme.miam,
                    ),
              ),
            ),
            const SizedBox(height: 32),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.miam,
                inactiveTrackColor: Theme.of(context).colorScheme.outline,
                thumbColor: AppTheme.miam,
                overlayColor: AppTheme.miam.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _selectedValue.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                label: _formatValue(_selectedValue),
                onChanged: _onSliderChanged,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: widget.unit,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: widget.unit,
              ),
              onChanged: _onTextChanged,
            ),
            const SizedBox(height: 24),
            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: () {
                widget.onQuantitySelected(_selectedValue);
              },
              cancelLabel: context.l.cancelButton,
              confirmLabel: context.l.confirmButton,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

/// Inline quantity picker widget for use inside other dialogs/forms.
///
/// Unlike the modal `QuantityPickerDialog`, this does NOT wrap itself in a
/// modal - it's designed to be embedded directly in a Column or similar layout.
class QuantityPickerInline extends StatefulWidget {
  const QuantityPickerInline({
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onValueChanged,
    super.key,
  });

  final String unit;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final void Function(double) onValueChanged;

  @override
  State<QuantityPickerInline> createState() => _QuantityPickerInlineState();
}

class _QuantityPickerInlineState extends State<QuantityPickerInline> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value.toInt().toString());
  }

  @override
  void didUpdateWidget(covariant QuantityPickerInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _textController.text = widget.value.toInt().toString();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    widget.onValueChanged(value);
  }

  void _onTextChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null && parsed >= widget.min && parsed <= widget.max) {
      widget.onValueChanged(parsed);
    }
  }

  String _formatValue(double value) {
    return '${value.round()} ${widget.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            _formatValue(widget.value),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.miam,
                ),
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.miam,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            thumbColor: AppTheme.miam,
            overlayColor: AppTheme.miam.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: _formatValue(widget.value),
            onChanged: _onSliderChanged,
          ),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }
}

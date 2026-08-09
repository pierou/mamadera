import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';

class DurationPickerDialog extends StatefulWidget {
  const DurationPickerDialog({
    required this.onDurationSelected,
    this.initialMinutes = 30.0,
    super.key,
  });

  final void Function(double minutes) onDurationSelected;
  final double initialMinutes;

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late double _selectedMinutes;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
  }

  String _formatDuration(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    if (hours > 0) {
      return '${hours}h${mins.toString().padLeft(2, '0')}';
    }
    return '$mins min';
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
              context.l.durationPickerTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                _formatDuration(_selectedMinutes),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 56,
                      color: AppTheme.dodo,
                    ),
              ),
            ),
            const SizedBox(height: 32),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.dodo,
                inactiveTrackColor: Theme.of(context).colorScheme.outline,
                thumbColor: AppTheme.dodo,
                overlayColor: AppTheme.dodo.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _selectedMinutes.clamp(0.0, 480.0),
                min: 0,
                max: 480, // 8 heures max
                divisions: 96, // pas de 5 minutes
                label: _formatDuration(_selectedMinutes),
                onChanged: (value) {
                  setState(() => _selectedMinutes = value);
                },
              ),
            ),
            const SizedBox(height: 24),
            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: () {
                widget.onDurationSelected(_selectedMinutes);
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

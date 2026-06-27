import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';

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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                _formatDuration(_selectedMinutes),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dodo,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.dodo,
                inactiveTrackColor: Colors.grey.shade700,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l.cancelButton, style: const TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDurationSelected(_selectedMinutes);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dodo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(context.l.confirmButton),
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

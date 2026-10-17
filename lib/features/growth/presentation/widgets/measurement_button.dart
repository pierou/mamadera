import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/show_feedback.dart';
import '../../domain/entities/growth_measurement.dart';
import '../../domain/entities/measure_kind.dart';
import '../providers/measurement_providers.dart';
import 'measure_kind_accent.dart';
import 'measurement_sheet.dart';

/// Home button for a high-growth company (item 1 of v1.2.0).
///
/// More compact than a `TrackButton`: icon, label displayed within a `FittedBox` (never...).
/// a trimmed version), and a `bodySmall` sub-line with the last value – the hyphen.
/// half-width dash `—` when there is none, never an error state.
class MeasurementButton extends StatelessWidget {
  const MeasurementButton({
    required this.label,
    required this.kind,
    required this.onTap,
    this.latestValue,
    super.key,
  });

  /// Resolved label (retrieving the label using the [MeasureKind.labelKey] key).
  final String label;

  final MeasureKind kind;

  final VoidCallback onTap;

  /// Last value, already formatted (`3,4 kg`); `null` → the dash `—`.
  final String? latestValue;

  /// Representation of a lack of value – never an invented number.
  static const String _noValue = '—';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = kind.accent;
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.shapeCardRadius),
          child: Container(
            height: 132,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.shapeCardRadius),
              border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(kind.icon, size: 32, color: color),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  latestValue ?? _noValue,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Located below the main 2x2 grid are three measurement buttons.
///
/// Standalone widget: the existing grid only changes with a single container, and the...
/// The current targets for tapping are not shrinking.
class MeasurementButtonRow extends ConsumerWidget {
  const MeasurementButtonRow({super.key});

  /// Translated [MeasureKind.labelKey] – same structure as the switch for...
  /// `_pillLabelFor`: The key is simply a key name and is never interpolated.
  String _labelFor(BuildContext context, MeasureKind kind) {
    return switch (kind.labelKey) {
      'homeButtonPoids' => context.l.homeButtonPoids,
      'homeButtonTaille' => context.l.homeButtonTaille,
      'homeButtonTemperature' => context.l.homeButtonTemperature,
      _ => kind.labelKey,
    };
  }

  /// First occurrence of the "kind": the list is sorted from most recent to oldest.
  /// It's an old value, so it's the last one.
  String? _latestFor(
    BuildContext context,
    List<GrowthMeasurement> measurements,
    MeasureKind kind,
  ) {
    for (final measurement in measurements) {
      if (measurement.kind != kind) continue;
      final value = measurement.value;
      return value == null
          ? context.l.growthValueUndecryptable
          : kind.format(value, localeName: context.l.localeName);
    }
    return null;
  }

  Future<void> _openSheet(BuildContext context, MeasureKind kind) async {
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.shapeBottomSheetRadius),
        ),
      ),
      builder: (_) => MeasurementSheet(kind: kind),
    );
    if (value != null && context.mounted) {
      showFeedback(
        context,
        context.l.growthFeedbackSaved(
          kind.format(value, localeName: context.l.localeName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements =
        ref.watch(measurementNotifierProvider).value ?? const <GrowthMeasurement>[];
    return Row(
      children: [
        for (final kind in MeasureKind.values) ...[
          Expanded(
            child: MeasurementButton(
              key: ValueKey('measure-${kind.dbValue}'),
              label: _labelFor(context, kind),
              kind: kind,
              latestValue: _latestFor(context, measurements, kind),
              onTap: () => _openSheet(context, kind),
            ),
          ),
          if (kind != MeasureKind.values.last)
            const SizedBox(width: AppTheme.spacingMd),
        ],
      ],
    );
  }
}

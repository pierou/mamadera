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

/// Bouton d'accueil d'une grande de croissance (item 1 de v1.2.0).
///
/// Plus compact qu'un `TrackButton` : icône, libellé en `FittedBox` (jamais
/// rogné), et une sous-ligne `bodySmall` avec la dernière valeur — le tiret
/// demi-cadrat `—` quand il n'y en a pas, jamais un état d'erreur.
class MeasurementButton extends StatelessWidget {
  const MeasurementButton({
    required this.label,
    required this.kind,
    required this.onTap,
    this.latestValue,
    super.key,
  });

  /// Libellé résolu (l'appelant traduit [MeasureKind.labelKey]).
  final String label;

  final MeasureKind kind;

  final VoidCallback onTap;

  /// Dernière valeur, déjà formatée (`3,4 kg`) ; `null` → tiret demi-cadrat.
  final String? latestValue;

  /// Représentation d'une absence de valeur — jamais un nombre inventé.
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

/// Rangée des trois boutons de mesure sous la grille 2×2 d'accueil.
///
/// Widget autonome : la grille existante ne change que d'un conteneur, et les
/// cibles de tap actuelles ne rétrécissent pas.
class MeasurementButtonRow extends ConsumerWidget {
  const MeasurementButtonRow({super.key});

  /// Traduit [MeasureKind.labelKey] — même schéma que le switch de
  /// `_pillLabelFor` : la clé n'est qu'un nom de clé, jamais interpolée.
  String _labelFor(BuildContext context, MeasureKind kind) {
    return switch (kind.labelKey) {
      'homeButtonPoids' => context.l.homeButtonPoids,
      'homeButtonTaille' => context.l.homeButtonTaille,
      'homeButtonTemperature' => context.l.homeButtonTemperature,
      _ => kind.labelKey,
    };
  }

  /// Première occurrence du kind : la liste est triée du plus récent au plus
  /// ancien, donc c'est la dernière valeur.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/theme.dart';
import '../../domain/entities/growth_measurement.dart';
import '../../domain/entities/measure_kind.dart';
import '../providers/measurement_providers.dart';
import '../widgets/measure_kind_accent.dart';

/// Écran « Croissance » (item 1 de v1.2.0) — lecture seule.
///
/// Dernières valeurs par grande en tête, puis historique le plus récent en
/// premier. Pas d'édition ni de suppression en v1.2.0 : une valeur erronée
/// se corrige en ajoutant la bonne — l'historique complet reste lisible.
class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  /// Traduit [MeasureKind.labelKey] en libellé de dernière valeur
  /// (poids → « Dernier poids », etc.).
  String _latestLabelFor(BuildContext context, MeasureKind kind) {
    return switch (kind) {
      MeasureKind.poids => context.l.growthLatestWeight,
      MeasureKind.taille => context.l.growthLatestHeight,
      MeasureKind.temperature => context.l.growthLatestTemperature,
    };
  }

  /// Valeur affichée d'une mesure : formatée, ou « valeur illisible » quand
  /// le déchiffrement a échoué — jamais un nombre inventé.
  String _displayValue(BuildContext context, GrowthMeasurement measurement) {
    final value = measurement.value;
    if (value == null) return context.l.growthValueUndecryptable;
    return measurement.kind.format(value, localeName: context.l.localeName);
  }

  Widget _latestCard(BuildContext context, GrowthMeasurement? latest, MeasureKind kind) {
    final theme = Theme.of(context);
    final color = kind.accent;
    final value =
        latest == null ? '—' : _displayValue(context, latest);
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.shapeCardRadius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _latestLabelFor(context, kind),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTile(BuildContext context, GrowthMeasurement measurement) {
    final theme = Theme.of(context);
    final color = measurement.kind.accent;
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(measurement.kind.icon, size: 22, color: color),
      ),
      title: Text(
        _displayValue(context, measurement),
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        formatDate(context, measurement.recordedAt) +
            (measurement.notes == null ? '' : ' — ${measurement.notes}'),
      ),
      trailing: Text(
        measurement.kind.displayUnit,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final measurementsAsync = ref.watch(measurementNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.growthScreenTitle),
        centerTitle: true,
      ),
      body: measurementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l.errorMessage(error.toString()))),
        data: (measurements) {
          if (measurements.isEmpty) {
            return Center(child: Text(l.growthEmptyState));
          }
          final latestByKind = <MeasureKind, GrowthMeasurement>{};
          for (final measurement in measurements) {
            latestByKind.putIfAbsent(measurement.kind, () => measurement);
          }
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            children: [
              Row(
                children: [
                  for (final kind in MeasureKind.values) ...[
                    Expanded(child: _latestCard(context, latestByKind[kind], kind)),
                    if (kind != MeasureKind.values.last)
                      const SizedBox(width: AppTheme.spacingMd),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),
              Text(
                l.growthSectionTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              for (final measurement in measurements)
                _historyTile(context, measurement),
            ],
          );
        },
      ),
    );
  }
}

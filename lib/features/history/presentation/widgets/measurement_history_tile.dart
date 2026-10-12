import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../growth/domain/entities/growth_measurement.dart';
import '../../../growth/domain/entities/measure_kind.dart';
import '../../../growth/presentation/widgets/measure_kind_accent.dart';

/// Tuile d'une mesure de croissance dans la frise unifiée de l'historique.
///
/// Même habillage que `HistoryTile`, une source différente : la valeur vient
/// de la table `measurements` (toujours chiffrée), jamais d'une copie dans
/// `tracking_events`. Une valeur illisible s'affiche comme telle — jamais
/// zéro, jamais masquée.
class MeasurementHistoryTile extends StatelessWidget {
  const MeasurementHistoryTile({
    required this.measurement,
    required this.time,
    super.key,
    this.onTap,
  });

  final GrowthMeasurement measurement;
  final String time; // formaté en dd/MM/yyyy HH:mm
  final VoidCallback? onTap;

  String _kindLabel(BuildContext context) {
    return switch (measurement.kind) {
      MeasureKind.poids => context.l.homeButtonPoids,
      MeasureKind.taille => context.l.homeButtonTaille,
      MeasureKind.temperature => context.l.homeButtonTemperature,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: measurement.kind.accent.withValues(alpha: 0.2),
          child: Icon(measurement.kind.icon, color: measurement.kind.accent),
        ),
        title: Text(_kindLabel(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              measurement.value != null
                  ? measurement.kind.format(
                      measurement.value!,
                      localeName: context.l.localeName,
                    )
                  : context.l.growthValueUndecryptable,
              style: theme.textTheme.bodyMedium,
            ),
            if (measurement.notes != null && measurement.notes!.isNotEmpty)
              Text(measurement.notes!),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined,
                  size: 16, color: Theme.of(context).colorScheme.secondary),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
      ),
    );
  }
}

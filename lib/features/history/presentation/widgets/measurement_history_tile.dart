import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../growth/domain/entities/growth_measurement.dart';
import '../../../growth/domain/entities/measure_kind.dart';
import '../../../growth/presentation/widgets/measure_kind_accent.dart';

/// Tile representing a growth measurement within the unified historical timeline.
///
/// Same appearance as `HistoryTile`, but with a different data source: the value comes from...
/// from the `measurements` table (which always contains numerical data), and never from a copy.
/// `tracking_events`. An unreadable value will be displayed as such – never anything else.
/// zero, never masked.
class MeasurementHistoryTile extends StatelessWidget {
  const MeasurementHistoryTile({
    required this.measurement,
    required this.time,
    super.key,
    this.onTap,
  });

  final GrowthMeasurement measurement;
  final String time;   // formatted as dd/MM/yyyy HH:mm.
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

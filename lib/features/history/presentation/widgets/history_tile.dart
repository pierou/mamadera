import 'package:flutter/material.dart';

import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';

/// Tile affichant un événement dans l'historique.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    required this.event,
    required this.time,
    super.key,
    this.onTap,
  });

  final TrackingEvent event;
  final String time; // formaté en dd/MM/yyyy HH:mm
  final VoidCallback? onTap;

  IconData get _icon {
    switch (event) {
      case FeedingEvent():
        return Icons.lunch_dining;
      case SleepEvent():
        return Icons.nightlight;
      case final DiaperEvent diaper:
        if (diaper.wasteType == WasteType.pipi) return Icons.water_drop_outlined;
        if (diaper.wasteType == WasteType.lesDeux) return Icons.wb_sunny;
        return Icons.water_drop;
      case HealthEvent():
        return Icons.favorite;
    }
  }

  String get _typeLabel {
    switch (event) {
      case FeedingEvent():
        return 'Miam';
      case SleepEvent():
        return 'Sommeil';
      case final DiaperEvent diaper:
        switch (diaper.wasteType) {
          case WasteType.pipi:
            return 'Pipi';
          case WasteType.lesDeux:
            return 'Pipi & Caca';
          default:
            return 'Caca';
        }
      case final HealthEvent health:
        return health.subtype.label;
    }
  }

  String? get _notes {
    switch (event) {
      case final FeedingEvent feeding:
        return feeding.notes;
      case final SleepEvent sleep:
        return sleep.notes;
      case final DiaperEvent diaper:
        return diaper.notes;
      case final HealthEvent health:
        return health.notes;
    }
  }

  double? get _duration {
    switch (event) {
      case final FeedingEvent feeding:
        return feeding.duration;
      case final SleepEvent sleep:
        return sleep.duration;
      default:
        return null;
    }
  }


  /// Parse les couleurs depuis un DiaperEvent et retourne une liste de paires (label, color).
  List<MapEntry<String, Color>> _parseColors() {
    if (event is! DiaperEvent) return [];
    final diaper = event as DiaperEvent;

    final colors = <MapEntry<String, Color>>[];
    if (diaper.pipiColor != null) {
      colors.add(MapEntry(diaper.pipiColor!.label, Color(diaper.pipiColor!.colorHex)));
    }
    if (diaper.cacaColor != null) {
      colors.add(MapEntry(diaper.cacaColor!.label, Color(diaper.cacaColor!.colorHex)));
    }
    return colors;
  }

  bool get _hasWasteDetails => event is DiaperEvent && (event as DiaperEvent).wasteType != null;

  Widget _buildColorIndicator() {
    final parsedColors = _parseColors();
    if (parsedColors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: parsedColors.map((entry) {
          return Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 1),
            ),
            child: Tooltip(
                message: entry.key,
                child: const SizedBox.shrink()),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(_typeLabel),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_duration != null) Text('Durée: ${_duration!.toInt()} min'),
            if (_hasWasteDetails) ...[
              _buildColorIndicator(),
            ],
            if (event is! HealthEvent && _notes != null && _notes!.isNotEmpty)
              Text(_notes!),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time),
            // Indicateur visuel que la tile est éditable
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

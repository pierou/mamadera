import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
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

  String _typeLabel(BuildContext context) {
    switch (event) {
      case FeedingEvent():
        return context.l.typeLabelMiam;
      case SleepEvent():
        return context.l.typeLabelSommeil;
      case final DiaperEvent diaper:
        switch (diaper.wasteType) {
          case WasteType.pipi:
            return context.l.typeLabelPipi;
          case WasteType.lesDeux:
            return context.l.typeLabelPipiEtCaca;
          default:
            return context.l.typeLabelCaca;
        }
      case final HealthEvent health:
        return _resolveLabelKey(context, health.subtype.labelKey);
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

  /// Parse les couleurs depuis un DiaperEvent et retourne une liste de paires (localized label, color).
  List<MapEntry<String, Color>> _parseColors(BuildContext context) {
    if (event is! DiaperEvent) return [];
    final diaper = event as DiaperEvent;

    final colors = <MapEntry<String, Color>>[];
    if (diaper.pipiColor != null) {
      colors.add(MapEntry(
        _resolveLabelKey(context, diaper.pipiColor!.labelKey),
        Color(diaper.pipiColor!.colorHex),
      ));
    }
    if (diaper.cacaColor != null) {
      colors.add(MapEntry(
        _resolveLabelKey(context, diaper.cacaColor!.labelKey),
        Color(diaper.cacaColor!.colorHex),
      ));
    }
    return colors;
  }

  bool get _hasWasteDetails => event is DiaperEvent && (event as DiaperEvent).wasteType != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(_typeLabel(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_duration != null)
              Text(context.l.durationPrefix(_duration!.toInt())),
            if (_hasWasteDetails) ...[
              _ColorIndicator(colors: _parseColors(context)),
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

/// Map de labels localisés pour chaque HealthSubtype.
final Map<String, String Function(BuildContext)> _kHealthLabels = {
  'healthNettoyageYeux': (c) => c.l.healthNettoyageYeux,
  'healthNettoyageNombril': (c) => c.l.healthNettoyageNombril,
  'healthNettoyageVisage': (c) => c.l.healthNettoyageVisage,
  'healthNettoyageNez': (c) => c.l.healthNettoyageNez,
  'healthVitamineD': (c) => c.l.healthVitamineD,
  'healthVitamineK': (c) => c.l.healthVitamineK,
};

final Map<String, String Function(BuildContext)> _kTypeLabels = {
  'Miam': (c) => c.l.typeLabelMiam,
  'Sommeil': (c) => c.l.typeLabelSommeil,
  'Pipi': (c) => c.l.typeLabelPipi,
  'Caca': (c) => c.l.typeLabelCaca,
};

String _resolveTypeLabel(BuildContext context, String type) {
  return _kTypeLabels[type]?.call(context) ?? '';
}

String _resolveLabelKey(BuildContext context, String labelKey) {
  // Try health labels first.
  final healthLabel = _kHealthLabels[labelKey]?.call(context);
  if (healthLabel != null && healthLabel.isNotEmpty) return healthLabel;

  // Fallback for typeLabel prefixed keys.
  if (labelKey.startsWith('typeLabel')) {
    final type = labelKey.replaceAll('typeLabel', '');
    return _resolveTypeLabel(context, type);
  }

  return labelKey;
}

/// Widget affichant les indicateurs de couleur pour un DiaperEvent.
class _ColorIndicator extends StatelessWidget {
  const _ColorIndicator({required this.colors});

  final List<MapEntry<String, Color>> colors;

  Widget _buildDot(MapEntry<String, Color> entry) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: entry.value,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Tooltip(message: entry.key, child: const SizedBox.shrink()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: colors.map(_buildDot).toList(),
      ),
    );
  }
}

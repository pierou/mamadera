import 'package:flutter/material.dart';

import '../../../../shared/domain/entities/tracking_enums.dart';

/// Tile affichant un événement dans l'historique.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    required this.type,
    required this.time,
    super.key,
    this.notes,
    this.duration,
    this.wasteType, // backward compat : valeur DB snake_case ('pipi', 'caca', 'les_deux')
    this.color, // backward compat : valeur DB (pipe-délimitée pour les_deux)
    this.onTap,
  });

  final String type; // label affiché (ex: 'Caca', 'Miam')
  final String time; // formaté en dd/MM/yyyy HH:mm
  final String? notes; // health subtypes stockés ici ('nettoyage_yeux'...)
  final double? duration; // durée en minutes
  final String? wasteType; // backward compat : valeur DB snake_case
  final String? color; // backward compat : couleur ou pipe-délimitée
  final VoidCallback? onTap;

  /// Version normalisée en minuscule pour les comparaisons de type.
  String get _normalizedType => type.toLowerCase();

  IconData _getIcon() {
    switch (_normalizedType) {
      case 'miam':
        return Icons.lunch_dining;
      case 'dodo':
        return Icons.nightlight;
      case 'caca':
        if (wasteType == WasteType.pipi.dbValue) {
          return Icons.water_drop_outlined; // pipi seul → goutte transparente
        } else if (_isBoth()) {
          return Icons.wb_sunny; // les_deux → soleil
        }
        return Icons.water_drop; // caca seul → goutte pleine
      case 'sante':
        return Icons.favorite;
      default:
        return Icons.circle;
    }
  }

  bool _isPipiOnly() => wasteType == WasteType.pipi.dbValue;
  bool _isBoth() => wasteType == WasteType.lesDeux.dbValue;

  String _getTypeLabel() {
    // Santé : lookup via HealthSubtype enum au lieu de switch sur string
    if (_normalizedType == 'sante' && notes != null && notes!.isNotEmpty) {
      final subtype = HealthSubtype.byValue(notes!);
      return subtype?.label ?? notes!;
    }

    // Caca : affichage contextuel selon wasteType
    switch (_normalizedType) {
      case 'miam':
        return 'Miam';
      case 'dodo':
        return 'Sommeil';
      case 'caca':
        if (wasteType == WasteType.pipi.dbValue) {
          return 'Pipi';
        } else if (_isBoth()) {
          return 'Pipi & Caca';
        }
        return 'Caca';
      case 'sante':
        return 'Santé';
      default:
        return type;
    }
  }

  /// Parse la couleur stockée et retourne une liste de paires (label, color).
  List<MapEntry<String, Color>> _parseColors() {
    if (color == null || color!.isEmpty) {
      return [];
    }

    final colors = <MapEntry<String, Color>>[];

    // Cas "les_deux" : pipe-délimité pipi_color|caca_color
    if (_isBoth()) {
      final parts = color!.split('|');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          // Lookup via les enums du domain au lieu de switch sur string
          final pipiMatch = _pipiColors.firstWhere(
            (c) => c.key == trimmed,
            orElse: () => const MapEntry('', Colors.transparent),
          );
          if (pipiMatch.key.isNotEmpty &&
              pipiMatch.value != Colors.transparent) {
            colors.add(pipiMatch);
            continue;
          }

          final cacaMatch = _cacaColors.firstWhere(
            (c) => c.key == trimmed,
            orElse: () => const MapEntry('', Colors.transparent),
          );
          if (cacaMatch.key.isNotEmpty &&
              cacaMatch.value != Colors.transparent) {
            colors.add(cacaMatch);
          }
        }
      }
    } else if (_isPipiOnly()) {
      final match = _pipiColors.firstWhere(
        (c) => c.key == color,
        orElse: () => const MapEntry('', Colors.transparent),
      );
      if (match.key.isNotEmpty && match.value != Colors.transparent) {
        colors.add(match);
      }
    } else {
      // Caca seul : essaie PipiColor puis CacaColor via les enums du domain
      final pipiMatch = _pipiColors.firstWhere(
        (c) => c.key == color,
        orElse: () => const MapEntry('', Colors.transparent),
      );
      if (pipiMatch.key.isNotEmpty && pipiMatch.value != Colors.transparent) {
        colors.add(pipiMatch);
      } else {
        final cacaMatch = _cacaColors.firstWhere(
          (c) => c.key == color,
          orElse: () => const MapEntry('', Colors.transparent),
        );
        if (cacaMatch.key.isNotEmpty && cacaMatch.value != Colors.transparent) {
          colors.add(cacaMatch);
        }
      }
    }

    return colors;
  }

  // Tables de couleurs centralisées via les enums du domain — plus de magic strings !
  static final List<MapEntry<String, Color>> _pipiColors = [
    MapEntry(PipiColor.incolore.value, Color(PipiColor.incolore.colorHex)),
    MapEntry(PipiColor.jauneClair.value, Color(PipiColor.jauneClair.colorHex)),
    MapEntry(PipiColor.jauneFonce.value, Color(PipiColor.jauneFonce.colorHex)),
    MapEntry(PipiColor.roseUrates.value, Color(PipiColor.roseUrates.colorHex)),
  ];

  static final List<MapEntry<String, Color>> _cacaColors = [
    MapEntry(CacaColor.meconium.value, Color(CacaColor.meconium.colorHex)),
    MapEntry(CacaColor.vertOlive.value, Color(CacaColor.vertOlive.colorHex)),
    MapEntry(
        CacaColor.jauneMoutarde.value, Color(CacaColor.jauneMoutarde.colorHex)),
  ];

  bool get hasWasteDetails => wasteType != null;

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
                message: _getColorLabel(entry.key),
                child: const SizedBox.shrink()),
          );
        }).toList(),
      ),
    );
  }

  /// Retourne le label d'une couleur via les enums du domain au lieu de switch sur string.
  String _getColorLabel(String value) {
    final pipi = PipiColor.byValue(value);
    if (pipi != null) {
      return pipi.label;
    }
    final caca = CacaColor.byValue(value);
    if (caca != null) {
      return caca.label;
    }
    return value; // fallback : valeur brute si inconnue
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_getIcon(), color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(_getTypeLabel()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (duration != null) Text('Durée: ${duration!.toInt()} min'),
            // Pour les événements caca/pipi, on affiche la couleur si disponible
            if (hasWasteDetails && _normalizedType == 'caca') ...[
              _buildColorIndicator(),
            ],
            if (_normalizedType != 'sante' &&
                notes != null &&
                notes!.isNotEmpty)
              Text(notes!),
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

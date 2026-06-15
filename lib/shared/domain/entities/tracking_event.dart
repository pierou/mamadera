import 'package:equatable/equatable.dart';
import 'tracking_enums.dart';
import 'tracking_type.dart';

/// Entity pure pour un événement de suivi.
class TrackingEvent extends Equatable {
  const TrackingEvent({
    required this.type,
    required this.timestamp,
    this.id,
    this.duration,
    this.notes,
    this.wasteType,
    this.pipiColor,
    this.cacaColor,
  });

  final int? id;
  final TrackingType type;
  final DateTime timestamp;
  final double? duration;
  final String? notes; // health subtypes stockés ici (ex: 'nettoyage_yeux')
  final WasteType? wasteType;    // typed : pipi, caca, les_deux
  final PipiColor? pipiColor;    // typed : couleur urine
  final CacaColor? cacaColor;    // typed : couleur selle

  /// Retourne la valeur DB formatée pour la colonne `color`.
  /// Pour `lesDeux`, retourne le format pipe-délimité (`pipi_color|caca_color`).
  String? get colorDbValue {
    if (wasteType == null) return null;

    switch (wasteType!) {
      case WasteType.pipi:
        return pipiColor?.value;
      case WasteType.caca:
        return cacaColor?.value;
      case WasteType.lesDeux:
        final p = pipiColor?.value ?? '';
        final c = cacaColor?.value ?? '';
        if (p.isNotEmpty && c.isNotEmpty) {
          return '$p|$c';
        }
        return p.isEmpty ? c : p;
    }
  }
  @override
  List<Object?> get props => [id, type, timestamp, duration, notes, wasteType, pipiColor, cacaColor];

  @override
  String toString() =>
      'TrackingEvent(id: $id, type: $type, timestamp: $timestamp, duration: $duration, notes: $notes, wasteType: $wasteType, pipiColor: $pipiColor, cacaColor: $cacaColor)';
}



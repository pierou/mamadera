import 'package:equatable/equatable.dart';
import 'tracking_enums.dart';
import 'tracking_type.dart';


/// Sealed base class for all tracking events.
///
/// Subtypes carry only their relevant fields — no nullable garbage from
/// unrelated event types. The [trackingType] tag on the base class allows
/// filtering/aggregation without requiring pattern matching.
sealed class TrackingEvent extends Equatable {
  const TrackingEvent({required this.timestamp, this.id});

  final int? id;
  final DateTime timestamp;

  /// Discriminator tag returned by each subtype for its [TrackingType].
  TrackingType get trackingType;
}

/// Alimentation (miam) — tétée ou biberon.
class FeedingEvent extends TrackingEvent {
  const FeedingEvent({
    required super.timestamp, required this.subtype, required this.duration, super.id,
    this.notes,
  });

  final FeedingSubtype subtype;
  final double duration;
  final String? notes;

  @override
  TrackingType get trackingType => TrackingType.miam;

  @override
  List<Object?> get props => [id, timestamp, subtype, duration, notes];

  @override
  String toString() =>
      'FeedingEvent(id: $id, timestamp: $timestamp, subtype: $subtype, duration: $duration, notes: $notes)';
}

/// Sommeil (dodo).
class SleepEvent extends TrackingEvent {
  const SleepEvent({
    required super.timestamp, required this.duration, super.id,
    this.notes,
  });

  final double duration;
  final String? notes;

  @override
  TrackingType get trackingType => TrackingType.dodo;

  @override
  List<Object?> get props => [id, timestamp, duration, notes];

  @override
  String toString() =>
      'SleepEvent(id: $id, timestamp: $timestamp, duration: $duration, notes: $notes)';
}

/// Caca / Pipi — type de selle + couleurs optionnelles.
class DiaperEvent extends TrackingEvent {
  const DiaperEvent({
    required super.timestamp, super.id,
    this.wasteType,
    this.pipiColor,
    this.cacaColor,
    this.notes,
  });

  final WasteType? wasteType;
  final PipiColor? pipiColor;
  final CacaColor? cacaColor;
  final String? notes;

  /// Retourne la valeur DB formatée pour la colonne `color`.
  /// Pour [WasteType.lesDeux], retourne le format pipe-délimité (`pipi_color|caca_color`).
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
  TrackingType get trackingType => TrackingType.caca;

  @override
  List<Object?> get props => [id, timestamp, wasteType, pipiColor, cacaColor, notes];

  @override
  String toString() =>
      'DiaperEvent(id: $id, timestamp: $timestamp, wasteType: $wasteType, pipiColor: $pipiColor, cacaColor: $cacaColor, notes: $notes)';
}

/// Santé (sante) — soin avec sous-type typé.
class HealthEvent extends TrackingEvent {
  const HealthEvent({
    required super.timestamp, required this.subtype, super.id,
    this.notes,
  });

  final HealthSubtype subtype;
  final String? notes;

  @override
  TrackingType get trackingType => TrackingType.sante;

  @override
  List<Object?> get props => [id, timestamp, subtype, notes];

  @override
  String toString() =>
      'HealthEvent(id: $id, timestamp: $timestamp, subtype: ${subtype.value}, notes: $notes)';
}



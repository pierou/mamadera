import 'package:freezed_annotation/freezed_annotation.dart';

import 'quantity_unit.dart';
import 'tracking_enums.dart';
import 'tracking_type.dart';

part 'tracking_event.freezed.dart';

/// Sealed base class for all tracking events.
///
/// Subtypes carry only their relevant fields — no nullable garbage from
/// unrelated event types. The [trackingType] tag on the base class allows
/// filtering/aggregation without requiring pattern matching.
@freezed
sealed class TrackingEvent with _$TrackingEvent {
  const factory TrackingEvent(
      {required DateTime timestamp, int? id, String? babyId}) = _TrackingEvent;

  const factory TrackingEvent.feeding({
    required FeedingSubtype subtype,
    required DateTime timestamp,

    /// Unit of the quantity being carried; chosen by the parent for `natural` (ml or min),
    /// fixed for the other subtypes. Required so no insert path can write a
    /// quantity whose unit is nobody's decision.
    required QuantityUnit unit,
    double? quantity,
    int? id,
    String? babyId,
    String? notes,
  }) = FeedingEvent;

  const factory TrackingEvent.sleep({
    required double duration,
    required DateTime timestamp,

    /// Always [QuantityUnit.min]; carried on the row rather than inferred at
    /// read time, so the history tile renders from data like every other row.
    required QuantityUnit unit,
    double? quantity,
    int? id,
    String? babyId,
    String? notes,
  }) = SleepEvent;

  const factory TrackingEvent.diaper({
    required DateTime timestamp,
    int? id,
    String? babyId,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
    StoolTexture? stoolTexture,
    String? notes,
  }) = DiaperEvent;

  const factory TrackingEvent.health({
    required HealthSubtype subtype,
    required DateTime timestamp,
    int? id,
    String? babyId,
    String? notes,
  }) = HealthEvent;
}

/// Returns the [TrackingType] discriminator for a given event.
extension TrackingEventTrackingType on TrackingEvent {
  /// Discriminator tag returned by each subtype for filtering/aggregation.
  TrackingType get trackingType {
    return when(
      (timestamp, id, babyId) =>
          throw StateError('Cannot get trackingType from base TrackingEvent'),
      feeding: (subtype, timestamp, unit, quantity, id, babyId, notes) =>
          TrackingType.miam,
      sleep: (duration, timestamp, unit, quantity, id, babyId, notes) =>
          TrackingType.dodo,
      diaper: (timestamp, id, babyId, wasteType, pipiColor, cacaColor,
              stoolTexture, notes) =>
          TrackingType.caca,
      health: (subtype, timestamp, id, babyId, notes) => TrackingType.sante,
    );
  }
}

/// Extension providing [colorDbValue] on [DiaperEvent].
extension DiaperEventColorDbValue on DiaperEvent {
  /// Retourne la valeur DB formatée pour la colonne `color`.
  /// Pour [WasteType.lesDeux], retourne le format pipe-délimité (`pipi_color|caca_color`).
  String? get colorDbValue {
    final wasteType = this.wasteType;
    if (wasteType == null) return null;

    switch (wasteType) {
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
}

/// Extension providing [textureDbValue] on [DiaperEvent].
extension DiaperEventStoolTextureDbValue on DiaperEvent {
  /// Retourne la valeur DB de la colonne `texture`.
  ///
  /// La consistance ne décrit qu'une selle : un change enregistré comme pipi
  /// (ou sans type, ligne héritée) écrit NULL même si [stoolTexture] était
  /// encore remplie dans le formulaire. Sans ce garde, tourner un « caca
  /// pâteux » en « pipi » laissait une texture orpheline dans l'historique.
  String? get textureDbValue {
    final wasteType = this.wasteType;
    if (wasteType == null || wasteType == WasteType.pipi) return null;
    return stoolTexture?.value;
  }
}

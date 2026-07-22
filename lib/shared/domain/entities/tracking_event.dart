import 'package:freezed_annotation/freezed_annotation.dart';

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
  const factory TrackingEvent({int? id, DateTime? timestamp, String? babyId}) = _TrackingEvent;

  const factory TrackingEvent.feeding({
    required FeedingSubtype subtype, required double duration, int? id,
    DateTime? timestamp,
    String? babyId,
    String? notes,
  }) = FeedingEvent;

  const factory TrackingEvent.sleep({
    required double duration, int? id,
    DateTime? timestamp,
    String? babyId,
    String? notes,
  }) = SleepEvent;

  const factory TrackingEvent.diaper({
    int? id,
    DateTime? timestamp,
    String? babyId,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
    String? notes,
  }) = DiaperEvent;

  const factory TrackingEvent.health({
    required HealthSubtype subtype, int? id,
    DateTime? timestamp,
    String? babyId,
    String? notes,
  }) = HealthEvent;
}

/// Returns the [TrackingType] discriminator for a given event.
extension TrackingEventTrackingType on TrackingEvent {
  /// Discriminator tag returned by each subtype for filtering/aggregation.
  TrackingType get trackingType {
    return when(
      (id0, ts0, baby0) => throw StateError('Cannot get trackingType from base TrackingEvent'),
      feeding: (id1, ts1, baby1, sub1, dur1, notes1) => TrackingType.miam,
      sleep: (id2, ts2, baby2, dur2, notes2) => TrackingType.dodo,
      diaper: (id3, ts3, baby3, wt3, pc3, cc3, notes3) => TrackingType.caca,
      health: (id4, ts4, baby4, sub4, notes4) => TrackingType.sante,
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



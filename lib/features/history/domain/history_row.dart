import '../../../shared/domain/entities/tracking_event.dart';
import '../../growth/domain/entities/growth_measurement.dart';

/// Une ligne de la frise unifiée de l'historique : soit un événement de
/// suivi, soit une mesure de croissance.
///
/// Les mesures de croissance **n'ont jamais leur ligne dupliquée** : la
/// table `measurements` reste la source de vérité (chiffrée), la frise ne
/// fait qu'une lecture unifiée des deux tables (décision 2026-10-04).
sealed class HistoryRow {
  const HistoryRow({required this.timestamp});

  factory HistoryRow.event(TrackingEvent event) => EventHistoryRow(event);

  factory HistoryRow.measurement(GrowthMeasurement measurement) =>
      MeasurementHistoryRow(measurement);

  /// Instant de la ligne — clé de tri de la frise, desc.
  final DateTime timestamp;
}

/// Ligne portée par un événement de suivi (`tracking_events`).
final class EventHistoryRow extends HistoryRow {
  EventHistoryRow(this.event) : super(timestamp: event.timestamp);

  final TrackingEvent event;
}

/// Ligne portée par une mesure de croissance (`measurements`).
final class MeasurementHistoryRow extends HistoryRow {
  MeasurementHistoryRow(this.measurement)
      : super(timestamp: measurement.recordedAt);

  final GrowthMeasurement measurement;
}

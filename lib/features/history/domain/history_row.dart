import '../../../shared/domain/entities/tracking_event.dart';
import '../../growth/domain/entities/growth_measurement.dart';

/// A line from the unified historical timeline: either an event or...
/// monitoring, or a measure of growth.
///
/// Growth metrics **have never had their lines duplicated**: the...
/// The `measurements` table remains the source of truth (in terms of numerical data), and the chart does not.
/// namely, a unified interpretation of the two tables (decision dated October 4, 2026).
sealed class HistoryRow {
  const HistoryRow({required this.timestamp});

  factory HistoryRow.event(TrackingEvent event) => EventHistoryRow(event);

  factory HistoryRow.measurement(GrowthMeasurement measurement) =>
      MeasurementHistoryRow(measurement);

  /// Instant on the timeline – sorting key for the timeline, description.
  final DateTime timestamp;
}

/// Row backed by a tracking event (`tracking_events`).
final class EventHistoryRow extends HistoryRow {
  EventHistoryRow(this.event) : super(timestamp: event.timestamp);

  final TrackingEvent event;
}

/// Row backed by a growth measurement (`measurements`).
final class MeasurementHistoryRow extends HistoryRow {
  MeasurementHistoryRow(this.measurement)
      : super(timestamp: measurement.recordedAt);

  final GrowthMeasurement measurement;
}

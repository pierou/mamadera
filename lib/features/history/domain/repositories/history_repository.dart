import '../../../../core/entities/tracking_event.dart';

/// Repository interface pour le module history (lecture seule)
abstract class HistoryRepository {
  Future<List<TrackingEvent>> getAllEventsOrdered();
  Future<List<TrackingEvent>> getEventsByType(String type);
}

import '../entities/tracking_event.dart';

abstract class TrackingRepository {
  Future<List<TrackingEvent>> getAllEventsOrdered();
  Future<List<TrackingEvent>> getEventsByType(String type);
  Future<int> insertEvent({
    required String type,
    DateTime? timestamp,
    double? duration,
    String? notes,
  });
}
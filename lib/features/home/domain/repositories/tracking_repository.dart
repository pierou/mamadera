import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

abstract class TrackingRepository {
  Future<List<TrackingEvent>> getAllEventsOrdered();
  Future<List<TrackingEvent>> getEventsByType(TrackingType type);
  /// Insert a tracking event (any subtype). The repository handles extracting
  /// subtype-specific fields to build the correct DB companion.
  Future<int> insertEvent(TrackingEvent event);
}



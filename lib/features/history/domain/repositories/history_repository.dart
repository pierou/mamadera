import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

/// Repository interface for the history module (read and update).
abstract class HistoryRepository {
  Future<List<TrackingEvent>> getAllEventsOrdered({String? babyId});
  Future<List<TrackingEvent>> getEventsByType(TrackingType type, {String? babyId});

  /// Updates an existing event.
  Future<bool> updateEvent({required int id, required TrackingEvent event});

  /// Deletes an event by its ID. Returns true if a row was deleted.
  Future<bool> deleteEvent(int id);
}


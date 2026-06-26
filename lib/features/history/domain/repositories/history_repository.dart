import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

/// Repository interface pour le module history (lecture + mise à jour)
abstract class HistoryRepository {
  Future<List<TrackingEvent>> getAllEventsOrdered();
  Future<List<TrackingEvent>> getEventsByType(TrackingType type);

  /// Met à jour un événement existant.
  Future<bool> updateEvent({required int id, required TrackingEvent event});

  /// Supprime un événement par son ID. Retourne true si une ligne a été supprimée.
  Future<bool> deleteEvent(int id);
}


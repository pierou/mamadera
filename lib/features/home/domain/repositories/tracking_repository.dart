import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

abstract class TrackingRepository {
  Future<List<TrackingEvent>> getAllEventsOrdered();
  Future<List<TrackingEvent>> getEventsByType(TrackingType type);
  Future<int> insertEvent({
    required TrackingType type,
    DateTime? timestamp,
    double? duration,
    String? notes,
    WasteType? wasteType,     // typed au lieu de String?
    PipiColor? pipiColor,     // nouveau champ typed
    CacaColor? cacaColor,     // nouveau champ typed
  });
}



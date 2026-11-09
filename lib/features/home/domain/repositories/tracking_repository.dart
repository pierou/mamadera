import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

abstract class TrackingRepository {
  Future<List<TrackingEvent>> getAllEventsOrdered();
  Future<List<TrackingEvent>> getEventsByType(TrackingType type);

  /// Insert a tracking event (any subtype). The repository handles extracting
  /// subtype-specific fields to build the correct DB companion.
  Future<int> insertEvent(TrackingEvent event);

  /// Return the most recent event matching [type] and optional [subtypeValue].
  /// For health events, [subtypeValue] matches against HealthSubtype.value (e.g., 'vitamine_d').
  /// Returns null if no matching event exists.
  Future<DateTime?> getLastEventByTypeAndSubtype(TrackingType type,
      {String? subtypeValue});

  /// When [type] was last recorded **for one baby** — `null` when it never was.
  ///
  /// Unlike [getLastEventByTypeAndSubtype], which is not scoped and so answers
  /// across the whole family, this takes the baby explicitly: the home grid
  /// shows one baby at a time and must not borrow the other's history
  /// (`null` means the profile-less state, see the implementation).
  Future<DateTime?> getLastEventAt(TrackingType type, {String? babyId});
}

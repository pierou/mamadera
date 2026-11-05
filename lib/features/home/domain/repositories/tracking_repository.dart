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

  /// Timestamp of the most recent [type] event recorded for [babyId]
  /// (any profile when `babyId` is null), or null when no such event exists.
  ///
  /// Feeds the home buttons' « last tracked » line: the line is activity-based
  /// — the last event of the type — and must not depend on whether the type
  /// has reminders configured. A scalar MAX query: no row hydration, no
  /// notes decryption.
  Future<DateTime?> getLatestEventTimestamp(TrackingType type,
      {String? babyId});
}

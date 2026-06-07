import 'package:drift/drift.dart' hide Column;
import '../../../../data/local/app_db.dart' hide TrackingEvent;
import '../../../../data/local/database.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final DatabaseService _dbService = DatabaseService();

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async {
    try {
      print('🔍 [Repo] getAllEventsOrdered - Starting...');
    final db = await _dbService.database;
      print('🔍 [Repo] getAllEventsOrdered - DB acquired');
    final events = await db.getAllEventsOrdered();
      print('🔍 [Repo] getAllEventsOrdered - Query completed, ${events.length} events');

    return events
        .map((e) => TrackingEvent(
              id: e.id,
              type: e.type,
              timestamp: e.timestamp,
              duration: e.duration,
              notes: e.notes,
            ))
        .toList();
    } catch (e, stack) {
      print('❌ [Repo] getAllEventsOrdered - Error: $e');
      print('❌ [Repo] Stack: $stack');
      rethrow;
  }
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(String type) async {
    try {
      print('🔍 [Repo] getEventsByType($type) - Starting...');
    final db = await _dbService.database;
      print('🔍 [Repo] getEventsByType($type) - DB acquired');
    final events = await db.getEventsByType(type);
      print('🔍 [Repo] getEventsByType($type) - Query completed, ${events.length} events');

    return events
        .map((e) => TrackingEvent(
              type: e.type,
              timestamp: e.timestamp,
              duration: e.duration,
              notes: e.notes,
            ))
        .toList();
    } catch (e, stack) {
      print('❌ [Repo] getEventsByType($type) - Error: $e');
      print('❌ [Repo] Stack: $stack');
      rethrow;
  }
  }

  @override
  Future<int> insertEvent({
    required String type,
    DateTime? timestamp,
    double? duration,
    String? notes,
  }) async {
    try {
      print('🔍 [Repo] insertEvent($type) - Starting...');
    final db = await _dbService.database;
    final companion = TrackingEventsCompanion(
      type: Value(type),
      timestamp: Value(timestamp ?? DateTime.now()),
      duration: Value(duration),
      notes: Value(notes),
    );
      final result = await db.insertEvent(companion);
      print('🔍 [Repo] insertEvent($type) - Success, id: $result');
      return result;
    } catch (e, stack) {
      print('❌ [Repo] insertEvent($type) - Error: $e');
      print('❌ [Repo] Stack: $stack');
      rethrow;
  }
}
}


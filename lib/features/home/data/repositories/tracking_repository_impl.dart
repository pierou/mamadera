import 'package:drift/drift.dart' hide Column;
import 'package:logger/logger.dart';

import '../../../../data/local/app_db.dart' hide TrackingEvent;
import '../../../../data/local/database.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final DatabaseService _dbService = DatabaseService();
  final Logger _logger = Logger();

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async {
    try {
      _logger.d('getAllEventsOrdered - Starting...');
      final db = await _dbService.database;
      _logger.d('getAllEventsOrdered - DB acquired');
      final events = await db.getAllEventsOrdered();
      _logger
          .d('getAllEventsOrdered - Query completed, ${events.length} events');

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
      _logger.e('getAllEventsOrdered - Error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(String type) async {
    try {
      _logger.d('getEventsByType($type) - Starting...');
      final db = await _dbService.database;
      _logger.d('getEventsByType($type) - DB acquired');
      final events = await db.getEventsByType(type);
      _logger.d(
          'getEventsByType($type) - Query completed, ${events.length} events');

      return events
          .map((e) => TrackingEvent(
                type: e.type,
                timestamp: e.timestamp,
                duration: e.duration,
                notes: e.notes,
              ))
          .toList();
    } catch (e, stack) {
      _logger.e('getEventsByType($type) - Error: $e',
          error: e, stackTrace: stack);
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
      _logger.d('insertEvent($type) - Starting...');
      final db = await _dbService.database;
      final companion = TrackingEventsCompanion(
        type: Value(type),
        timestamp: Value(timestamp ?? DateTime.now()),
        duration: Value(duration),
        notes: Value(notes),
      );
      final result = await db.insertEvent(companion);
      _logger.d('insertEvent($type) - Success, id: $result');
      return result;
    } catch (e, stack) {
      _logger.e('insertEvent($type) - Error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

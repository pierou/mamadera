import '../../../../core/entities/tracking_event.dart';
import '../../../../data/local/database.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final DatabaseService _dbService = DatabaseService();

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async {
    final db = await _dbService.database;
    final events = await db.getAllEventsOrdered();
    return events
        .map((e) => TrackingEvent(
              id: e.id,
              type: e.type,
              timestamp: e.timestamp,
              duration: e.duration,
              notes: e.notes,
            ))
        .toList();
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(String type) async {
    final db = await _dbService.database;
    final events = await db.getEventsByType(type);
    return events
        .map((e) => TrackingEvent(
              id: e.id,
              type: e.type,
              timestamp: e.timestamp,
              duration: e.duration,
              notes: e.notes,
            ))
        .toList();
  }
}

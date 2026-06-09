import '../../../../core/entities/tracking_event.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../data/local/database.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  // Injection de dépendance pour la testabilité et le chiffrement
  HistoryRepositoryImpl({required this.encryption, DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  final EncryptionService encryption;
  late final DatabaseService _dbService;

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
              notes: encryption.decrypt(e.notes),
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
              notes: encryption.decrypt(e.notes),
            ))
        .toList();
  }
}

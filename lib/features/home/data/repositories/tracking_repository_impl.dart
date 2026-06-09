import 'package:drift/drift.dart' hide Column;
import 'package:logger/logger.dart';

import '../../../../core/services/encryption_service.dart';
import '../../../../data/local/app_db.dart' hide TrackingEvent;
import '../../../../data/local/database.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  // Injection de dépendance pour la testabilité et le chiffrement
  TrackingRepositoryImpl({
    required this.encryption,
    DatabaseService? dbService,
  }) : _dbService = dbService ?? DatabaseService();

  final EncryptionService encryption;
  late final DatabaseService _dbService;
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
                notes: encryption.decrypt(e.notes),
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
                id: e.id,
                type: e.type,
                timestamp: e.timestamp,
                duration: e.duration,
                notes: encryption.decrypt(e.notes),
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

      // Chiffre les notes sensibles avant insertion en DB
      final encryptedNotes = notes != null ? encryption.encrypt(notes) : null;

      final companion = TrackingEventsCompanion(
        type: Value(type),
        timestamp: Value(timestamp ?? DateTime.now()),
        duration: Value(duration),
        notes: Value(encryptedNotes),
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

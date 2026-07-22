import 'package:drift/drift.dart' hide Column;
import 'package:logger/logger.dart';

import '../../../../core/services/encryption_service.dart';
// Alias pour le row généré par drift (différent de l'entity domain)
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/db_constants.dart' as db_const;
import '../../../../data/local/tracking_event_mapper.dart' as mapper;
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';

import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  /// Injection explicite : pas de fallback singleton.
  TrackingRepositoryImpl({
    required this.encryption,
    required db_app.AppDatabase database,
  }) : _database = database;

  final EncryptionService encryption;
  final db_app.AppDatabase _database;
  final Logger _logger = Logger();

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async {
    try {
      _logger.d('getAllEventsOrdered - Starting...');
      final events = await _database.getAllEventsOrdered();
      _logger.d(
          'getAllEventsOrdered - Query completed, ${events.length} events');

      return events.map((row) => mapper.mapToEntity(row, encryption)).toList();
    } catch (e, stack) {
      _logger.e('getAllEventsOrdered - Error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type) async {
    try {
      _logger.d('getEventsByType(${type.name}) - Starting...');
      final events = await _database.getEventsByType(type.name);
      _logger.d(
          'getEventsByType(${type.name}) - Query completed, ${events.length} events');

      return events.map((row) => mapper.mapToEntity(row, encryption)).toList();
    } catch (e, stack) {
      _logger.e('getEventsByType(${type.name}) - Error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<int> insertEvent(TrackingEvent event) async {
    try {
      db_app.TrackingEventsCompanion companion;
      companion = event.map(
        (e) => throw StateError('Cannot insert base TrackingEvent'),
        feeding: (e) {
          final encryptedNotes = e.notes != null ? encryption.encrypt(e.notes!) : null;
          return db_app.TrackingEventsCompanion(
            type: const Value(db_const.typeMiam),
            timestamp: Value(e.timestamp!),
            duration: Value(e.duration),
            subtype: Value(e.subtype.name),
            notes: Value(encryptedNotes),
            babyId: Value(e.babyId),
            wasteType: const Value.absent(),
            color: const Value.absent(),
          );
        },
        sleep: (e) {
          final encryptedNotes = e.notes != null ? encryption.encrypt(e.notes!) : null;
          return db_app.TrackingEventsCompanion(
            type: const Value(db_const.typeDodo),
            timestamp: Value(e.timestamp!),
            duration: Value(e.duration),
            notes: Value(encryptedNotes),
            babyId: Value(e.babyId),
            wasteType: const Value.absent(),
            color: const Value.absent(),
          );
        },
        diaper: (e) {
          final encryptedNotes = e.notes != null ? encryption.encrypt(e.notes!) : null;
          return db_app.TrackingEventsCompanion(
            type: const Value(db_const.typeCaca),
            timestamp: Value(e.timestamp!),
            duration: const Value.absent(),
            notes: Value(encryptedNotes),
            babyId: Value(e.babyId),
            wasteType: Value(e.wasteType?.dbValue),
            color: Value(e.colorDbValue),
          );
        },
        health: (e) {
          final encryptedNotes = e.notes != null ? encryption.encrypt(e.notes!) : null;
          return db_app.TrackingEventsCompanion(
            type: const Value(db_const.typeSante),
            timestamp: Value(e.timestamp!),
            duration: const Value.absent(),
            subtype: Value(e.subtype.value),
            notes: Value(encryptedNotes),
            babyId: Value(e.babyId),
            wasteType: const Value.absent(),
            color: const Value.absent(),
          );
        },
      );

      final result = await _database.insertEvent(companion);
      _logger.d('insertEvent(${event.trackingType.name}) - Success, id: $result');
      return result;
    } catch (e, stack) {
      _logger.e('insertError: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastEventByTypeAndSubtype(TrackingType type, {String? subtypeValue}) async {
    try {
      final events = await getEventsByType(type);
      if (events.isEmpty) return null;

      // When a subtype is specified, filter to matching events only.
      // For health events, the subtype value matches against HealthSubtype.value.
      final filtered = subtypeValue != null && subtypeValue.isNotEmpty
          ? events.where((e) {
              if (e is! HealthEvent) return false;
              return e.subtype.value == subtypeValue;
            }).toList()
          : events;

      if (filtered.isEmpty) return null;
      // Events are already ordered by timestamp DESC from the DB query.
      return filtered.first.timestamp;
    } catch (e, stack) {
      _logger.e('getLastEventByTypeAndSubtype(${type.name}) - Error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}



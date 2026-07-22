import 'package:drift/drift.dart' hide Column;

import '../../../../core/services/encryption_service.dart';
// Alias pour le row généré par drift (différent de l'entity domain)
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/db_constants.dart' as db_const;
import '../../../../data/local/tracking_event_mapper.dart' as mapper;
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  /// Injection explicite : pas de fallback singleton.
  HistoryRepositoryImpl({
    required this.encryption,
    required db_app.AppDatabase database,
  }) : _database = database;
  final EncryptionService encryption;
  final db_app.AppDatabase _database;

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered({String? babyId}) async {
    final rows = babyId != null
        ? await _database.getEventsByBabyId(babyId)
        : await _database.getAllEventsOrdered();
    return rows.map((row) => mapper.mapToEntity(row, encryption)).toList();
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type, {String? babyId}) async {
    final rows = babyId != null
        ? await _database.getEventsByBabyId(babyId)
            .then((events) => events.where((row) => row.type == type.name).toList())
        : await _database.getEventsByType(type.name);
    return rows.map((row) => mapper.mapToEntity(row, encryption)).toList();
  }

  /// Met à jour un événement existant avec les champs du nouveau subtype.
  @override
  Future<bool> updateEvent({required int id, required TrackingEvent event}) async {
    db_app.TrackingEventsCompanion companion;
    companion = event.map(
      (e) => throw StateError('Cannot update base TrackingEvent'),
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

    // Retourne true si au moins une ligne a été modifiée
    return await _database.updateEvent(id, companion) > 0;
  }

  /// Supprime un événement par son ID.
  @override
  Future<bool> deleteEvent(int id) async {
    return _database.deleteEvent(id);
  }
}


import 'package:drift/drift.dart' hide Column;
import 'package:logger/logger.dart';

import '../../../../core/services/encryption_service.dart';
// Alias pour le row généré par drift (différent de l'entity domain)
import '../../../../data/local/app_db.dart' as db_app;

import '../../../../shared/domain/entities/tracking_enums.dart';
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

  /// Mappe un row DB (drift) vers l'entity TrackingEvent avec déchiffrement des notes.
  TrackingEvent _mapToEntity(db_app.TrackingEvent row) {
    final wasteType = WasteType.fromDbValue(row.wasteType);

    // Parse la couleur stockée en format pipe-délimité si nécessaire (les_deux).
    PipiColor? pipiColor;
    CacaColor? cacaColor;
    if (row.color != null && row.color!.isNotEmpty) {
      final parts = row.color!.split('|');

      switch (wasteType) {
        case WasteType.pipi:
          pipiColor = PipiColor.byValue(parts.first.trim());
        case WasteType.caca:
          cacaColor = CacaColor.byValue(parts.first.trim());
        case WasteType.lesDeux:
          if (parts.length >= 2) {
            pipiColor = PipiColor.byValue(parts[0].trim());
            cacaColor = CacaColor.byValue(parts[1].trim());
          } else if (parts.isNotEmpty) {
            // Fallback : essaie d'abord comme couleur pipi, puis caca
            pipiColor = PipiColor.byValue(parts.first.trim()) ??
                CacaColor.byValue(parts.first.trim()) as PipiColor?;
          }
        case null:
          break;
      }
    }

    return TrackingEvent(
      id: row.id,
      type: TrackingType.fromString(row.type),
      timestamp: row.timestamp,
      duration: row.duration,
      notes: row.notes != null ? encryption.decrypt(row.notes!) : null,
      wasteType: wasteType,
      pipiColor: pipiColor,
      cacaColor: cacaColor,
    );
  }

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async {
    try {
      _logger.d('getAllEventsOrdered - Starting...');
      final events = await _database.getAllEventsOrdered();
      _logger
          .d('getAllEventsOrdered - Query completed, ${events.length} events');

      return events.map(_mapToEntity).toList();
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

      return events.map(_mapToEntity).toList();
    } catch (e, stack) {
      _logger.e('getEventsByType(${type.name}) - Error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<int> insertEvent({
    required TrackingType type,
    DateTime? timestamp,
    double? duration,
    String? notes,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
  }) async {
    try {
      _logger.d('insertEvent(${type.name}) - Starting...');
      // Chiffre les notes sensibles avant insertion en DB
      final encryptedNotes = notes != null ? encryption.encrypt(notes) : null;

      // Convertit les enums typed vers leurs valeurs DB (String)
      final wasteTypeValue = wasteType?.dbValue;
      final cacaColorValue = cacaColor?.value;

      final companion = db_app.TrackingEventsCompanion(
        type: Value(type.name),
        timestamp: Value(timestamp ?? DateTime.now()),
        duration: Value(duration),
        notes: Value(encryptedNotes),
        wasteType: Value(wasteTypeValue),
        color: Value(cacaColorValue), // backward compat : stocké dans 'color' column
      );

      final result = await _database.insertEvent(companion);
      _logger.d('insertEvent(${type.name}) - Success, id: $result');
      return result;
    } catch (e, stack) {
      _logger.e('insertEvent(${type.name}) - Error: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}



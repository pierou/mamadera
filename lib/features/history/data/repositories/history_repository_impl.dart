import 'package:drift/drift.dart' hide Column;

import '../../../../core/services/encryption_service.dart';
// Alias pour le row généré par drift (différent de l'entity domain)
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../shared/domain/entities/tracking_enums.dart';
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
        type: TrackingType.fromString(row.type), // Convertit String → enum
        timestamp: row.timestamp,
        duration: row.duration,
      notes: row.notes != null ? encryption.decrypt(row.notes) : null,
      wasteType: wasteType,
      pipiColor: pipiColor,
      cacaColor: cacaColor,
      );
  }

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async {
    final rows = await _database.getAllEventsOrdered();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type) async {
    // La DB attend un String (nom de l'enum), on convertit
    final rows = await _database.getEventsByType(type.name);
    return rows.map(_mapToEntity).toList();
  }

  /// Met à jour les champs éditables d'un événement.
  /// Les notes sont chiffrées avant insertion en DB.
  @override
  Future<bool> updateEvent({
    required int id,
    DateTime? timestamp,
    double? duration,
    String? notes,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
  }) async {
    // Chiffre les notes sensibles avant écriture DB
    final encryptedNotes = notes != null ? encryption.encrypt(notes) : null;

    // Convertit les enums typed vers leurs valeurs DB (String)
    final wasteTypeValue = wasteType?.dbValue;
    final colorDbValue = cacaColor?.value ?? pipiColor?.value;

    final companion = db_app.TrackingEventsCompanion(
      // Utilise Value.absent() pour les champs non fournis → Drift ne les met pas à jour
      timestamp: timestamp != null ? Value(timestamp) : const Value.absent(),
      duration: duration != null ? Value(duration) : const Value.absent(),
      notes: encryptedNotes != null ? Value(encryptedNotes) : const Value.absent(),
      wasteType: wasteTypeValue != null ? Value(wasteTypeValue) : const Value.absent(),
      color: colorDbValue != null ? Value(colorDbValue) : const Value.absent(),
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


/// Shared DB → domain entity mapping logic for tracking events.
///
/// Both home and history repository implementations use this single function
/// to convert Drift rows into the appropriate sealed subtype, eliminating
/// duplicated parsing code across modules.
library;

import '../../../../core/services/encryption_service.dart';
import '../../shared/domain/entities/tracking_enums.dart';
import '../../shared/domain/entities/tracking_event.dart';
import 'app_db.dart' as db_app;
import 'db_constants.dart' as db_const;

/// Mappe un row Drift vers le sous-type [TrackingEvent] approprié.
TrackingEvent mapToEntity(db_app.TrackingEvent row, EncryptionService encryption) {
  switch (row.type) {
    case db_const.typeMiam:
      return _createFeedingEvent(row, encryption);
    case db_const.typeDodo:
      return _createSleepEvent(row, encryption);
    case db_const.typeCaca:
      return _createDiaperEvent(row, encryption, isFallback: false);
    case db_const.typeSante:
      return _createHealthEvent(row, encryption);
    default:
      return _createDiaperEvent(row, encryption, isFallback: true);
  }
}

TrackingEvent _createFeedingEvent(db_app.TrackingEvent row, EncryptionService encryption) {
  return FeedingEvent(
    id: row.id,
    timestamp: row.timestamp,
    subtype: _feedingSubtypeFromRow(row),
    duration: row.duration ?? 0.0,
    notes: encryption.decrypt(row.notes),
  );
}

TrackingEvent _createSleepEvent(db_app.TrackingEvent row, EncryptionService encryption) {
  return SleepEvent(
    id: row.id,
    timestamp: row.timestamp,
    duration: row.duration ?? 0.0,
    notes: encryption.decrypt(row.notes),
  );
}

TrackingEvent _createDiaperEvent(db_app.TrackingEvent row, EncryptionService encryption, {required bool isFallback}) {
  final colors = _parseColors(row);
  final wasteType = isFallback ? null : WasteType.fromDbValue(row.wasteType);

  final base = DiaperEvent(
    id: row.id,
    timestamp: row.timestamp,
    pipiColor: colors.$1,
    cacaColor: colors.$2,
    notes: encryption.decrypt(row.notes),
  );

  return isFallback ? base : DiaperEvent(
    id: row.id,
    timestamp: row.timestamp,
    wasteType: wasteType,
    pipiColor: colors.$1,
    cacaColor: colors.$2,
    notes: encryption.decrypt(row.notes),
  );
}

TrackingEvent _createHealthEvent(db_app.TrackingEvent row, EncryptionService encryption) {
  final subtype = HealthSubtype.byValue(row.wasteType ?? '') ?? HealthSubtype.nettoyageYeux;
  return HealthEvent(
    id: row.id,
    timestamp: row.timestamp,
    subtype: subtype,
    notes: encryption.decrypt(row.notes),
  );
}

/// Détermine le FeedingSubtype depuis la colonne `notes` ou fallback à `sein`.
FeedingSubtype _feedingSubtypeFromRow(db_app.TrackingEvent row) {
  if (row.notes != null && row.notes!.isNotEmpty) {
    switch (row.notes!) {
      case 'bib':
        return FeedingSubtype.bib;
      default:
        // Par défaut, on considère que c'est un sein maternel
        return FeedingSubtype.sein;
    }
  }
  return FeedingSubtype.sein;
}

/// Parse la colonne `color` (format pipe-délimité pour les_deux).
(PipiColor?, CacaColor?) _parseColors(db_app.TrackingEvent row) {
  PipiColor? pipiColor;
  CacaColor? cacaColor;

  if (row.color != null && row.color!.isNotEmpty) {
    final parts = row.color!.split('|');
    final wasteType = WasteType.fromDbValue(row.wasteType);

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

  return (pipiColor, cacaColor);
}

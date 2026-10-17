/// Shared DB → domain entity mapping logic for tracking events.
///
/// Both home and history repository implementations use this single function
/// to convert Drift rows into the appropriate sealed subtype, eliminating
/// duplicated parsing code across modules.
library;

import '../../../../core/services/encryption_service.dart';
import '../../shared/domain/entities/quantity_unit.dart';
import '../../shared/domain/entities/tracking_enums.dart';
import '../../shared/domain/entities/tracking_event.dart';
import 'app_db.dart' as db_app;
import 'db_constants.dart' as db_const;

/// Map the "row drift" event to the appropriate "[TrackingEvent]" subtype.
TrackingEvent mapToEntity(
    db_app.TrackingEvent row, EncryptionService encryption) {
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

TrackingEvent _createFeedingEvent(
    db_app.TrackingEvent row, EncryptionService encryption) {
  return TrackingEvent.feeding(
    id: row.id,
    timestamp: row.timestamp,
    babyId: row.babyId,
    subtype: _feedingSubtypeFromRow(row),
    unit: _unitFromRow(row),
    quantity: row.quantity,
    notes: encryption.decrypt(row.notes),
  );
}

TrackingEvent _createSleepEvent(
    db_app.TrackingEvent row, EncryptionService encryption) {
  return TrackingEvent.sleep(
    id: row.id,
    timestamp: row.timestamp,
    babyId: row.babyId,
    duration: row.duration ?? 0.0,
    unit: _unitFromRow(row),
    quantity: row.quantity,
    notes: encryption.decrypt(row.notes),
  );
}

/// Line unit, as it is **stored** (v12).
///
/// The column is NOT NULL starting from version 12: a new row will always have a value in this column.
/// The fallback mechanism only addresses one abnormal case: a column that predates the...
/// migration, or a value that this version does not recognize, and in that case, it will display the name.
/// the unit that the parent saw on the screen ([defaultUnitFor]) instead of using a different one.
/// invent a new one. The goal is to eliminate all hard-coded `'ml'` values.
/// un widget.
QuantityUnit _unitFromRow(db_app.TrackingEvent row) =>
    QuantityUnit.fromDbValue(row.unit) ??
    defaultUnitFor(typeValue: row.type, subtypeValue: row.subtype);

TrackingEvent _createDiaperEvent(
    db_app.TrackingEvent row, EncryptionService encryption,
    {required bool isFallback}) {
  final colors = _parseColors(row);
  final wasteType = isFallback ? null : WasteType.fromDbValue(row.wasteType);

  return TrackingEvent.diaper(
    id: row.id,
    timestamp: row.timestamp,
    babyId: row.babyId,
    wasteType: wasteType,
    pipiColor: colors.$1,
    cacaColor: colors.$2,
    stoolTexture: findStoolTextureByValue(row.texture),
    notes: encryption.decrypt(row.notes),
  );
}

/// Maps a health-related row to [TrackingEvent.health].
///
/// Known limitation: a row where the `subtype` column is NULL (very old data).
/// The "old" status is associated with the default subtype.
/// [HealthSubtype.nettoyageYeux] — This domain entity does not represent anything.
/// explicitly, a previously unknown subtype.
TrackingEvent _createHealthEvent(
    db_app.TrackingEvent row, EncryptionService encryption) {
  // Read the subtype from the designated column (or use a fallback for older data).
  final subtypeValue = row.subtype ?? '';
  final subtype =
      HealthSubtype.byValue(subtypeValue) ?? HealthSubtype.nettoyageYeux;
  return TrackingEvent.health(
    id: row.id,
    timestamp: row.timestamp,
    babyId: row.babyId,
    subtype: subtype,
    notes: encryption.decrypt(row.notes),
  );
}

/// Determine the `FeedingSubtype` from the `subtype` column, or default to `natural` if the `subtype` column is empty or contains an invalid value.
FeedingSubtype _feedingSubtypeFromRow(db_app.TrackingEvent row) {
  if (row.subtype != null && row.subtype!.isNotEmpty) {
    return FeedingSubtype.fromDbValue(row.subtype!) ?? FeedingSubtype.natural;
  }
  // Fallback mechanism for older data without a subtype column.
  return FeedingSubtype.natural;
}

/// Parse the `color` column (pipe-delimited format for both).
(PipiColor?, CacaColor?) _parseColors(db_app.TrackingEvent row) {
  PipiColor? pipiColor;
  CacaColor? cacaColor;

  if (row.color != null && row.color!.isNotEmpty) {
    final parts = row.color!.split('|');
    final wasteType = WasteType.fromDbValue(row.wasteType);

    switch (wasteType) {
      case WasteType.pipi:
        pipiColor = findPipiColorByValue(parts.first.trim());
      case WasteType.caca:
        cacaColor = findCacaColorByValue(parts.first.trim());
      case WasteType.lesDeux:
        if (parts.length >= 2) {
          pipiColor = findPipiColorByValue(parts[0].trim());
          cacaColor = findCacaColorByValue(parts[1].trim());
        } else if (parts.isNotEmpty) {
          // Row legacy: a single colored section. Be careful of the trap.
          // Precedence: `as` binds more strongly than `??`, therefore...
          // `findPipiColorByValue(x) ?? findCacaColorByValue(x) as PipiColor?`
          // It is evaluated as `findPipi ?? (findCaca as PipiColor?)` and raises an.
          // TypeError occurs as soon as the value is a "poop" color. Therefore, we need to find a solution.
          // explicitly assigns the value to its correct color type.
          final part = parts.first.trim();
          final pipi = findPipiColorByValue(part);
          pipiColor = pipi;
          cacaColor = pipi == null ? findCacaColorByValue(part) : null;
        }
      case null:
        break;
    }
  }

  return (pipiColor, cacaColor);
}

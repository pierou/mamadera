import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../data/local/app_db.dart' as db_app;
import '../../domain/entities/growth_measurement.dart';
import '../../domain/entities/measure_kind.dart';
import '../../domain/repositories/measurement_repository.dart';

/// Implementation based on growth metrics.
///
/// `measurements.value` is an AES-GCM encrypted value stored in a `TEXT` column:
/// The plaintext only exists during the decryption process and never enters [the system/process].
/// in a log (health data).
class MeasurementRepositoryImpl implements MeasurementRepository {
  /// Injection explicite : pas de fallback singleton.
  MeasurementRepositoryImpl({
    required db_app.AppDatabase database,
    required EncryptionService encryption,
  })  : _database = database,
        _encryption = encryption;

  final db_app.AppDatabase _database;
  final EncryptionService _encryption;

  static final Logger _logger = appLogger();

  @override
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  }) async {
    // Safety barrier: the sheet already rejects it, but a line is out of bounds.
    // The word "beach" should never appear in the table.
    if (!kind.contains(value)) {
      throw ArgumentError.value(
          value, 'value', 'Valeur hors bornes pour ${kind.dbValue}');
    }
    // Encryption before insertion: the column never contains the unencrypted data.
    await _database.into(_database.measurements).insert(
          db_app.MeasurementsCompanion.insert(
            babyId: Value(babyId),
            kind: kind.dbValue,
            value: _encryption.encrypt(value.toString()),
            unit: kind.unit,
            recordedAt: recordedAt,
            notes: Value(notes == null ? null : _encryption.encrypt(notes)),
          ),
        );
    // Kind and meter readings only – never the value (health data).
    _logger.d('mesure ajoutée kind=${kind.dbValue}');
  }

  /// Baby lines (and potentially just one [kind]), sorted from the longest to the shortest.
  /// Most recent to oldest (equal: then decreasing).
  ///
  /// Unfiltered reading, followed by processing in Dart: `app_db.dart` is the source.
  /// The validity of the schema is not affected by version 1.2.
  Future<List<db_app.Measurement>> _rows(
      String? babyId, MeasureKind? kind) async {
    final rows = await _database.getAllMeasurements();
    // `babyId == null` = "all babies" - same meaning as the...
    // Event repository: a strict filter will show you nothing.
    final scoped = [
      for (final row in rows)
        if ((babyId == null || row.babyId == babyId) &&
            (kind == null || row.kind == kind.dbValue))
          row,
    ]..sort((a, b) {
        final byDate = b.recordedAt.compareTo(a.recordedAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return scoped;
  }

  /// Translates a row into an entity; returns `null` if the type is unknown (row).
  /// orphan record, kept in the database but never displayed).
  GrowthMeasurement? _toEntity(db_app.Measurement row) {
    final kind = MeasureKind.byValue(row.kind);
    if (kind == null) {
      _logger.w('mesure ignorée : kind inconnu id=${row.id}');
      return null;
    }
    final decrypted = _encryption.decrypt(row.value);
    return GrowthMeasurement(
      id: row.id,
      babyId: row.babyId,
      kind: kind,
      // An unreadable value becomes `null` – the user interface displays it as "not available."
      // decipherable, never like zero.
      value: decrypted == null ? null : double.tryParse(decrypted),
      unit: row.unit,
      recordedAt: row.recordedAt,
      notes: _encryption.decrypt(row.notes),
    );
  }

  @override
  Future<GrowthMeasurement?> latestOfKind(
      String? babyId, MeasureKind kind) async {
    final rows = await _rows(babyId, kind);
    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  @override
  Future<List<GrowthMeasurement>> allForBaby(String? babyId,
      {MeasureKind? kind}) async {
    final rows = await _rows(babyId, kind);
    final entities = <GrowthMeasurement>[];
    for (final row in rows) {
      final entity = _toEntity(row);
      if (entity != null) entities.add(entity);
    }
    return entities;
  }

  @override
  Future<void> update(GrowthMeasurement measurement) async {
    final id = measurement.id;
    final value = measurement.value;
    if (value == null) {
      throw ArgumentError.value(
          value, 'value', 'Impossible de mettre à jour une mesure sans valeur');
    }
    // The same type of boundary protection is used at the input: any value outside the valid range will not be accepted.
    // It should never exist in the table.
    if (!measurement.kind.contains(value)) {
      throw ArgumentError.value(value, 'value',
          'Valeur hors bornes pour ${measurement.kind.dbValue}');
    }
    await (_database.update(_database.measurements)
          ..where((t) => t.id.equals(id)))
        .write(db_app.MeasurementsCompanion(
      value: Value(_encryption.encrypt(value.toString())),
      recordedAt: Value(measurement.recordedAt),
      notes: Value(measurement.notes == null
          ? null
          : _encryption.encrypt(measurement.notes!)),
    ));
    // Kind and ID only – never the value (health data).
    _logger.d('mesure mise à jour id=$id kind=${measurement.kind.dbValue}');
  }

  @override
  Future<bool> deleteById(int id) async {
    final deleted = await (_database.delete(_database.measurements)
          ..where((t) => t.id.equals(id)))
        .go();
    if (deleted > 0) _logger.d('mesure supprimée id=$id');
    return deleted > 0;
  }
}

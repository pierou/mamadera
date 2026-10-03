import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../data/local/app_db.dart' as db_app;
import '../../domain/entities/growth_measurement.dart';
import '../../domain/entities/measure_kind.dart';
import '../../domain/repositories/measurement_repository.dart';

/// Implémentation base des mesures de croissance.
///
/// `measurements.value` est du chiffré AES-GCM dans une colonne `TEXT` :
/// l'en-clair n'existe que pendant la dé-chiffrement ici, et n'entre jamais
/// dans un log (donnée de santé).
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
    // Garde-fous de borne : la feuille refuse déjà, mais une ligne hors
    // plage ne doit jamais exister dans la table.
    if (!kind.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Valeur hors bornes pour ${kind.dbValue}');
    }
    // Chiffrement avant insertion : la colonne ne contient jamais l'en-clair.
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
    // Kind et compteur uniquement — jamais la valeur (donnée de santé).
    _logger.d('mesure ajoutée kind=${kind.dbValue}');
  }

  /// Lignes du bébé (et éventuellement d'un seul [kind]), triées du plus
  /// récent au plus ancien (ex æquo : id décroissant).
  ///
  /// Lecture non filtrée puis borne en Dart : `app_db.dart` est la source de
  /// vérité du schéma et n'est pas touchée par v1.2.
  Future<List<db_app.Measurement>> _rows(String? babyId, MeasureKind? kind) async {
    final rows = await _database.getAllMeasurements();
    final scoped = [
      for (final row in rows)
        if (row.babyId == babyId && (kind == null || row.kind == kind.dbValue)) row,
    ]..sort((a, b) {
        final byDate = b.recordedAt.compareTo(a.recordedAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return scoped;
  }

  /// Traduit un row en entité ; `null` si le kind est inconnu (ligne
  /// orpheline conservée en base, jamais affichée).
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
      // Une valeur illisible devient `null` — l'UI l'affiche comme non
      // déchiffrable, jamais comme zéro.
      value: decrypted == null ? null : double.tryParse(decrypted),
      unit: row.unit,
      recordedAt: row.recordedAt,
      notes: _encryption.decrypt(row.notes),
    );
  }

  @override
  Future<GrowthMeasurement?> latestOfKind(String? babyId, MeasureKind kind) async {
    final rows = await _rows(babyId, kind);
    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  @override
  Future<List<GrowthMeasurement>> allForBaby(String? babyId, {MeasureKind? kind}) async {
    final rows = await _rows(babyId, kind);
    final entities = <GrowthMeasurement>[];
    for (final row in rows) {
      final entity = _toEntity(row);
      if (entity != null) entities.add(entity);
    }
    return entities;
  }
}

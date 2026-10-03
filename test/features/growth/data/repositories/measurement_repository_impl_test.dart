import 'package:drift/drift.dart' show LazyDatabase, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/growth/data/repositories/measurement_repository_impl.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';

/// Fake de chiffrement déterministe : `enc:<texte>` → `<texte>`.
/// Tout texte sans préfixe `enc:` déchiffre en null — cas clé perdue/rotée.
class _FakeEncryption extends EncryptionService {
  @override
  String encrypt(String plainText) => 'enc:$plainText';

  @override
  String? decrypt(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return null;
    if (!cipherText.startsWith('enc:')) return null;
    return cipherText.substring('enc:'.length);
  }
}

void main() {
  group('MeasurementRepositoryImpl', () {
    late AppDatabase database;
    late _FakeEncryption encryption;
    late MeasurementRepositoryImpl repository;

    setUp(() async {
      final connection = LazyDatabase(NativeDatabase.memory);
      database = AppDatabase(connection);
      // Déclenche la migration pour créer les tables avant toute lecture.
      await database.select(database.reminderDismissals).get();
      encryption = _FakeEncryption();
      repository = MeasurementRepositoryImpl(database: database, encryption: encryption);
    });

    tearDown(() async {
      await database.close();
    });

    Future<int> seedRow({
      String? babyId = 'baby_1',
      String kind = 'poids',
      required String value,
      String unit = 'g',
      DateTime? recordedAt,
      String? notes,
    }) =>
        database.into(database.measurements).insert(
              MeasurementsCompanion.insert(
                babyId: Value(babyId),
                kind: kind,
                value: value,
                unit: unit,
                recordedAt: recordedAt ?? DateTime.utc(2025, 6, 1),
                notes: Value(notes),
              ),
            );

    group('add', () {
      test('stores ciphertext in the value column, never plaintext', () async {
        await repository.add(
          babyId: 'baby_1',
          kind: MeasureKind.poids,
          value: 3500,
          recordedAt: DateTime.utc(2025, 6, 1),
        );

        final rows = await database.getAllMeasurements();
        expect(rows, hasLength(1));
        expect(rows.single.value, isNot('3500.0'));
        expect(rows.single.value, startsWith('enc:'));
        expect(rows.single.unit, 'g');
        expect(rows.single.kind, 'poids');
      });

      test('stores notes encrypted and reads them back decrypted', () async {
        await repository.add(
          babyId: 'baby_1',
          kind: MeasureKind.temperature,
          value: 36.5,
          recordedAt: DateTime.utc(2025, 6, 1),
          notes: 'sous le bras',
        );

        final rows = await database.getAllMeasurements();
        expect(rows.single.notes, isNot('sous le bras'));

        final entity = await repository.latestOfKind('baby_1', MeasureKind.temperature);
        expect(entity, isNotNull);
        expect(entity!.notes, 'sous le bras');
        expect(entity.value, 36.5);
        expect(entity.unit, 'degC');
      });

      test('empty notes are stored as null', () async {
        await repository.add(
          babyId: 'baby_1',
          kind: MeasureKind.poids,
          value: 3000,
          recordedAt: DateTime.utc(2025, 6, 1),
          notes: null,
        );

        final rows = await database.getAllMeasurements();
        expect(rows.single.notes, isNull);
      });

      test('round-trips a saved value through allForBaby', () async {
        await repository.add(
          babyId: null,
          kind: MeasureKind.taille,
          value: 50.3,
          recordedAt: DateTime.utc(2025, 6, 1),
        );

        final rows = await repository.allForBaby(null);
        expect(rows, hasLength(1));
        expect(rows.single.value, 50.3);
        expect(rows.single.kind, MeasureKind.taille);
        expect(rows.single.babyId, isNull);
      });

      test('rejects a value one step below the minimum', () async {
        await expectLater(
          repository.add(
            babyId: 'baby_1',
            kind: MeasureKind.poids,
            value: 199,
            recordedAt: DateTime.utc(2025, 6, 1),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(await database.getAllMeasurements(), isEmpty);
      });

      test('rejects a value one step above the maximum', () async {
        await expectLater(
          repository.add(
            babyId: 'baby_1',
            kind: MeasureKind.temperature,
            value: 42.1,
            recordedAt: DateTime.utc(2025, 6, 1),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(await database.getAllMeasurements(), isEmpty);
      });
    });

    group('baby scoping', () {
      test('allForBaby returns only the given baby rows', () async {
        await seedRow(babyId: 'baby_1', value: 'enc:3500.0');
        await seedRow(babyId: 'baby_2', value: 'enc:4000.0');
        await seedRow(babyId: null, value: 'enc:4200.0');

        final rows = await repository.allForBaby('baby_1');
        expect(rows, hasLength(1));
        expect(rows.single.babyId, 'baby_1');
        expect(rows.single.value, 3500);
      });

      test('allForBaby(null) returns orphan rows only', () async {
        await seedRow(babyId: 'baby_1', value: 'enc:3500.0');
        await seedRow(babyId: null, value: 'enc:4200.0');

        final rows = await repository.allForBaby(null);
        expect(rows, hasLength(1));
        expect(rows.single.babyId, isNull);
      });

      test('kind filter narrows within the baby', () async {
        await seedRow(babyId: 'baby_1', kind: 'poids', value: 'enc:3500.0', unit: 'g');
        await seedRow(babyId: 'baby_1', kind: 'taille', value: 'enc:50.3', unit: 'cm');

        final rows = await repository.allForBaby('baby_1', kind: MeasureKind.taille);
        expect(rows, hasLength(1));
        expect(rows.single.kind, MeasureKind.taille);
      });
    });

    group('ordering and robustness', () {
      test('allForBaby is newest first, ties broken by id', () async {
        final late_ = DateTime.utc(2025, 6, 3);
        final early = DateTime.utc(2025, 6, 1);
        await seedRow(value: 'enc:3000.0', recordedAt: late_);
        await seedRow(value: 'enc:3200.0', recordedAt: early);
        await seedRow(value: 'enc:3100.0', recordedAt: late_);

        final rows = await repository.allForBaby('baby_1');
        expect(rows.map((m) => m.value).toList(), [3100, 3000, 3200]);
      });

      test('latestOfKind is the most recent row of that kind', () async {
        await seedRow(value: 'enc:3000.0', recordedAt: DateTime.utc(2025, 6, 3));
        await seedRow(value: 'enc:3200.0', recordedAt: DateTime.utc(2025, 6, 1));
        await seedRow(kind: 'taille', value: 'enc:50.3', unit: 'cm', recordedAt: DateTime.utc(2025, 6, 4));

        final latest = await repository.latestOfKind('baby_1', MeasureKind.poids);
        expect(latest, isNotNull);
        expect(latest!.value, 3000);
      });

      test('latestOfKind is null when the baby has none', () async {
        expect(await repository.latestOfKind('baby_1', MeasureKind.poids), isNull);
      });

      test('an undecryptable value surfaces as null, never as zero', () async {
        await seedRow(value: 'BAD:rotated-key-ciphertext');

        final rows = await repository.allForBaby('baby_1');
        expect(rows, hasLength(1));
        expect(rows.single.value, isNull);
      });

      test('a row with an unknown kind is dropped from reads', () async {
        await seedRow(kind: 'inconnu', value: 'enc:1');
        await seedRow(kind: 'poids', value: 'enc:3500.0');

        final rows = await repository.allForBaby('baby_1');
        expect(rows, hasLength(1));
        expect(rows.single.kind, MeasureKind.poids);
      });
    });
  });
}

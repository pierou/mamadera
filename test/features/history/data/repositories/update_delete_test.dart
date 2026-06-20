// ignore_for_file: missing_whitespace_between_adjacent_strings, prefer_int_literals, public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' as db_app;
import 'package:mamadera/features/history/data/repositories/history_repository_impl.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_delete_test.mocks.dart';

@GenerateMocks([db_app.AppDatabase, EncryptionService])
void main() {
  late HistoryRepositoryImpl repository;
  late MockAppDatabase mockDb;
  late MockEncryptionService mockEncryption;

  setUp(() {
    mockDb = MockAppDatabase();
    mockEncryption = MockEncryptionService();
    when(mockEncryption.encrypt(any)).thenReturn('encrypted_data');

    repository = HistoryRepositoryImpl(database: mockDb, encryption: mockEncryption);
  });

  tearDown(() {
    reset(mockDb);
    reset(mockEncryption);
  });

  group('updateEvent()', () {
    test('tous les champs fournis → true + encrypt appelé', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final result = await repository.updateEvent(
        id: 42,
        timestamp: DateTime(2025, 1, 1),
        duration: 30.0,
        notes: 'une note',
        wasteType: WasteType.pipi,
        pipiColor: PipiColor.jauneClair,
      );

      expect(result, isTrue);
      verify(mockEncryption.encrypt('une note')).called(1);
    });

    test("partiel : seul timestamp fourni → pas d'encryptage", () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final result = await repository.updateEvent(
        id: 10,
        timestamp: DateTime(2025, 6, 15),
      );

      expect(result, isTrue);
      // Pas de notes → encrypt ne doit jamais être appelé (privacy-first)
      verifyNever(mockEncryption.encrypt(any));
    });

    test('partiel : seule notes fournie → encrypt + absent sur autres', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final result = await repository.updateEvent(id: 5, notes: 'seule note');

      expect(result, isTrue);
      verify(mockEncryption.encrypt('seule note')).called(1);
    });

    test('wasteType.lesDeux + pipiColor + cacaColor → true', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final result = await repository.updateEvent(
        id: 7,
        wasteType: WasteType.lesDeux,
        pipiColor: PipiColor.jauneFonce,
        cacaColor: CacaColor.vertOlive,
      );

      expect(result, isTrue);
    });

    test('événement inexistant (DB retourne 0) → false', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 0);

      final result = await repository.updateEvent(id: -1, duration: 15.0);

      expect(result, isFalse);
    });

    test('notes explicite null → pas d\'encryptage (privacy-first)', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final result = await repository.updateEvent(
        id: 99,
        notes: null, // explicitement null — ne doit rien encrypter
        duration: 5.0,
      );

      expect(result, isTrue);
      verifyNever(mockEncryption.encrypt(any));
    });
  });

  group('deleteEvent()', () {
    test('succès → true', () async {
      when(mockDb.deleteEvent(any)).thenAnswer((_) async => true);

      final result = await repository.deleteEvent(42);

      expect(result, isTrue);
      verify(mockDb.deleteEvent(42)).called(1);
    });

    test('inexistant → false', () async {
      when(mockDb.deleteEvent(any)).thenAnswer((_) async => false);

      final result = await repository.deleteEvent(-999);

      expect(result, isFalse);
      verify(mockDb.deleteEvent(-999)).called(1);
    });
  });
}


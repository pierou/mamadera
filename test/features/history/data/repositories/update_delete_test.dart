// ignore_for_file: missing_whitespace_between_adjacent_strings, prefer_int_literals, public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' as db_app;
import 'package:mamadera/features/history/data/repositories/history_repository_impl.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
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
    test('tous les champs fournis (FeedingEvent) → true + encrypt appelé', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final event = FeedingEvent(
        id: 42,
        timestamp: DateTime(2025, 1, 1),
        subtype: FeedingSubtype.sein,
        duration: 30.0,
        notes: 'une note',
      );
      final result = await repository.updateEvent(id: 42, event: event);

      expect(result, isTrue);
      verify(mockEncryption.encrypt('une note')).called(1);
    });

    test("partiel : SleepEvent avec timestamp seulement → pas d'encryptage", () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final event = SleepEvent(
        id: 10,
        timestamp: DateTime(2025, 6, 15),
        duration: 45.0,
      );
      final result = await repository.updateEvent(id: 10, event: event);

      expect(result, isTrue);
      // Pas de notes → encrypt ne doit jamais être appelé (privacy-first)
      verifyNever(mockEncryption.encrypt(any));
    });

    test('FeedingEvent avec seule note fournie → encrypt + absent sur autres', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final event = FeedingEvent(
        id: 5,
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.sein,
        duration: 0.0,
        notes: 'seule note',
      );
      final result = await repository.updateEvent(id: 5, event: event);

      expect(result, isTrue);
      verify(mockEncryption.encrypt('seule note')).called(1);
    });

    test('DiaperEvent.lesDeux + pipiColor + cacaColor → true', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final event = DiaperEvent(
        id: 7,
        timestamp: DateTime.now(),
        wasteType: WasteType.lesDeux,
        pipiColor:
        pipiColorJauneFonce,
        cacaColor:
        cacaColorVertOlive,
      );
      final result = await repository.updateEvent(id: 7, event: event);

      expect(result, isTrue);
    });

    test('événement inexistant (DB retourne 0) → false', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 0);

      final event = FeedingEvent(
        id: -1,
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.sein,
        duration: 15.0,
      );
      final result = await repository.updateEvent(id: -1, event: event);

      expect(result, isFalse);
    });

    test('HealthEvent sans notes explicite → pas d\'encryptage (privacy-first)', () async {
      when(mockDb.updateEvent(any, any)).thenAnswer((_) async => 1);

      final event = HealthEvent(
        id: 99,
        timestamp: DateTime.now(),
        subtype: HealthSubtype.nettoyageYeux,
      );
      final result = await repository.updateEvent(id: 99, event: event);

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


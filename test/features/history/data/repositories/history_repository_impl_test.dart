import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' as drift;
import 'package:mamadera/features/history/data/repositories/history_repository_impl.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart' as entity;
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'history_repository_impl_test.mocks.dart';

@GenerateMocks([drift.AppDatabase, EncryptionService])
void main() {
  late HistoryRepositoryImpl repository;
  late MockAppDatabase mockAppDatabase;
  late MockEncryptionService mockEncryption;

  setUp(() async {
    mockAppDatabase = MockAppDatabase();
    mockEncryption = MockEncryptionService();
    // Le mock de déchiffrement retourne la valeur brute pour les tests
    when(mockEncryption.decrypt(any)).thenReturn('decrypted_notes');

    repository = HistoryRepositoryImpl(
      database: mockAppDatabase,
      encryption: mockEncryption,
    );
  });

  tearDown(() {
    reset(mockAppDatabase);
    reset(mockEncryption);
  });

  group('HistoryRepositoryImpl', () {
    group('getAllEventsOrdered()', () {
      test('retourne une liste d\'événements triés en succès', () async {
        final dbEvent1 = drift.TrackingEvent(
          id: 2,
          type: 'dodo',
          timestamp: DateTime(2023, 10, 1),
          duration: 30,
          notes: null,
        );
        final dbEvent2 = drift.TrackingEvent(
          id: 1,
          type: 'miam',
          timestamp: DateTime(2023, 10, 2),
          duration: 15,
          notes: 'encrypted_notes_data',
        );

        when(mockAppDatabase.getAllEventsOrdered())
            .thenAnswer((_) async => [dbEvent1, dbEvent2]);

        // Configure le mock pour retourner null sur decrypt(null) et la valeur brute sinon
        when(mockEncryption.decrypt(null)).thenReturn(null);
        when(mockEncryption.decrypt('encrypted_notes_data'))
            .thenReturn('notes test');

        final result = await repository.getAllEventsOrdered();

        expect(result, isA<List<entity.TrackingEvent>>());
        expect(result.length, 2);
        // Les événements sont retournés tels quels par le mock
        expect(result[0].id, 2);
        expect(result[0].type, TrackingType.dodo);
        expect(result[0].duration, 30.0);
        expect(result[1].id, 1);
        expect(result[1].type, TrackingType.miam);
        expect(result[1].notes, 'notes test');

        verify(mockAppDatabase.getAllEventsOrdered()).called(1);
      });

      test('rethrow en cas d\'erreur de base de données', () async {
        when(mockAppDatabase.getAllEventsOrdered())
            .thenThrow(Exception('DB Connection Lost'));

        expect(
          () => repository.getAllEventsOrdered(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getEventsByType()', () {
      test('filtre correctement par type en succès', () async {
        final dbEvent = drift.TrackingEvent(
          id: 1,
          type: 'miam',
          timestamp: DateTime.now(),
          duration: 12,
          notes: null,
        );

        when(mockAppDatabase.getEventsByType('miam'))
            .thenAnswer((_) async => [dbEvent]);

        when(mockEncryption.decrypt(null)).thenReturn(null);

        final result = await repository.getEventsByType(TrackingType.miam);

        expect(result.length, 1);
        expect(result[0].type.name, 'miam');
        expect(result[0].duration, 12.0);

        verify(mockAppDatabase.getEventsByType('miam')).called(1);
      });

      test('retourne une liste vide pour un type inexistant', () async {
        when(mockAppDatabase.getEventsByType('dodo'))
            .thenAnswer((_) async => []);
        final result = await repository.getEventsByType(TrackingType.dodo);

        expect(result, isEmpty);
        verify(mockAppDatabase.getEventsByType('dodo')).called(1);
      });

      test('rethrow en cas d\'erreur de requête', () async {
        when(mockAppDatabase.getEventsByType('caca'))
            .thenThrow(Exception('Invalid Query'));

        expect(
          () => repository.getEventsByType(TrackingType.caca),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateEvent()', () {
      test('met à jour timestamp uniquement', () async {
        final newTimestamp = DateTime(2024, 1, 15);
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        final result = await repository.updateEvent(
          id: 1,
          timestamp: newTimestamp,
        );

        expect(result, true);
        verify(mockAppDatabase.updateEvent(1, any)).called(1);
      });

      test('met à jour duration uniquement', () async {
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        final result = await repository.updateEvent(
          id: 2,
          duration: 45,
        );

        expect(result, true);
      });

      test('met à jour notes avec chiffrement', () async {
        when(mockEncryption.encrypt(any)).thenReturn('encrypted_new_notes');
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        final result = await repository.updateEvent(
          id: 3,
          notes: 'new sensitive notes',
        );

        expect(result, true);
        verify(mockEncryption.encrypt('new sensitive notes')).called(1);
      });

      test('met à jour wasteType pipi avec couleur', () async {
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        final result = await repository.updateEvent(
          id: 4,
          wasteType: WasteType.pipi,
          pipiColor: PipiColor.roseUrates,
        );

        expect(result, true);
      });

      test('met à jour wasteType caca avec couleur', () async {
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        final result = await repository.updateEvent(
          id: 5,
          wasteType: WasteType.caca,
          cacaColor: CacaColor.vertOlive,
        );

        expect(result, true);
      });

      test('met à jour wasteType lesDeux avec deux couleurs', () async {
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        final result = await repository.updateEvent(
          id: 6,
          wasteType: WasteType.lesDeux,
          pipiColor: PipiColor.incolore,
          cacaColor: CacaColor.meconium,
        );

        expect(result, true);
      });

      test('met à jour plusieurs champs en même temps', () async {
        when(mockEncryption.encrypt(any)).thenReturn('encrypted_multi');
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        final result = await repository.updateEvent(
          id: 7,
          timestamp: DateTime(2024, 6, 1),
          duration: 25.5,
          notes: 'multi update',
        );

        expect(result, true);
      });

      test('retourne false quand aucun événement n\'est trouvé', () async {
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 0);

        final result = await repository.updateEvent(
          id: 999,
          timestamp: DateTime.now(),
        );

        expect(result, false);
      });

      test('ne chiffre pas les notes si elles sont null', () async {
        when(mockAppDatabase.updateEvent(any, any)).thenAnswer((_) async => 1);

        await repository.updateEvent(
          id: 8,
          timestamp: DateTime.now(),
          // notes is intentionally omitted (null)
        );

        verifyNever(mockEncryption.encrypt(any));
      });
    });

    group('deleteEvent()', () {
      test('supprime un événement existant', () async {
        when(mockAppDatabase.deleteEvent(1)).thenAnswer((_) async => true);

        final result = await repository.deleteEvent(1);

        expect(result, true);
        verify(mockAppDatabase.deleteEvent(1)).called(1);
      });

      test('retourne false pour un événement inexistant', () async {
        when(mockAppDatabase.deleteEvent(999))
            .thenAnswer((_) async => false);

        final result = await repository.deleteEvent(999);

        expect(result, false);
        verify(mockAppDatabase.deleteEvent(999)).called(1);
      });

      test('rethrow en cas d\'erreur de base de données', () async {
        when(mockAppDatabase.deleteEvent(any))
            .thenThrow(Exception('Delete failed'));

        expect(() => repository.deleteEvent(42), throwsA(isA<Exception>()));
      });
    });
  });
}


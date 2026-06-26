import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
// Alias pour le drift database (différent de l'entity domain)
import 'package:mamadera/data/local/app_db.dart' as db_app;
import 'package:mamadera/features/home/data/repositories/tracking_repository_impl.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'tracking_repository_impl_test.mocks.dart';

@GenerateMocks([db_app.AppDatabase, EncryptionService])
void main() {
  late TrackingRepositoryImpl repository;
  late MockAppDatabase mockDb;
  late MockEncryptionService mockEncryption;

  setUp(() async {
    mockDb = MockAppDatabase();
    mockEncryption = MockEncryptionService();
    repository = TrackingRepositoryImpl(
      encryption: mockEncryption,
      database: mockDb,
    );
  });

  group('insertEvent', () {
    test('insère un événement simple (FeedingEvent)', () async {
      when(mockDb.insertEvent(any)).thenAnswer((_) async => 1);

      final event = FeedingEvent(
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.sein,
        duration: 30,
      );
      final id = await repository.insertEvent(event);

      expect(id, equals(1));
      verify(mockDb.insertEvent(any)).called(1);
    });

    test('chiffre les notes avant insertion', () async {
      when(mockEncryption.encrypt(any)).thenReturn('encrypted_notes');
      when(mockDb.insertEvent(any)).thenAnswer((_) async => 2);

      final event = FeedingEvent(
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.sein,
        duration: 15,
        notes: 'sensitive note',
      );
      await repository.insertEvent(event);

      verify(mockEncryption.encrypt('sensitive note')).called(1);
    });

    test('insère avec duration (SleepEvent)', () async {
      when(mockDb.insertEvent(any)).thenAnswer((_) async => 3);

      final event = SleepEvent(
        timestamp: DateTime.now(),
        duration: 60,
      );
      final id = await repository.insertEvent(event);

      expect(id, equals(3));
    });

    test('insère avec wasteType et couleurs (DiaperEvent)', () async {
      when(mockDb.insertEvent(any)).thenAnswer((_) async => 4);

      final event = DiaperEvent(
        timestamp: DateTime.now(),
        wasteType: WasteType.pipi,
        pipiColor: PipiColor.jauneClair,
        cacaColor: CacaColor.meconium,
      );
      final id = await repository.insertEvent(event);

      expect(id, equals(4));
    });

    test('propage l\'exception du database', () async {
      when(mockDb.insertEvent(any)).thenThrow(Exception('DB error'));

      final event = FeedingEvent(
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.sein,
        duration: 10,
      );
      expect(
        () => repository.insertEvent(event),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getAllEventsOrdered', () {
    test('retourne la liste des événements ordonnée par timestamp desc', () async {
      when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => []);

      final events = await repository.getAllEventsOrdered();

      expect(events, isEmpty);
      verify(mockDb.getAllEventsOrdered()).called(1);
    });

    test('déchiffre les notes des événements', () async {
      when(mockEncryption.decrypt(any)).thenReturn('decrypted note');
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'miam',
            timestamp: DateTime.utc(2024),
            duration: null,
            notes: 'encrypted_note_value',
            wasteType: null,
            color: null,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        expect((events.first as FeedingEvent).notes, equals('decrypted note'));
      });

      test('mappe WasteType.pipi avec pipiColor', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            notes: null,
            wasteType: WasteType.pipi.dbValue,
            color: PipiColor.jauneClair.value,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.wasteType, equals(WasteType.pipi));
        expect(diaper.pipiColor, isNotNull);
        expect(diaper.pipiColor?.value, equals(PipiColor.jauneClair.value));
      });

      test('mappe WasteType.caca avec cacaColor', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            notes: null,
            wasteType: WasteType.caca.dbValue,
            color: CacaColor.meconium.value,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.wasteType, equals(WasteType.caca));
        expect(diaper.cacaColor, isNotNull);
        expect(diaper.cacaColor?.value, equals(CacaColor.meconium.value));
      });

      test('mappe WasteType.lesDeux avec couleurs pipe-délimitées', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        final colorPipe = '${PipiColor.jauneFonce.value}|${CacaColor.vertOlive.value}';
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            notes: null,
            wasteType: WasteType.lesDeux.dbValue,
            color: colorPipe,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.wasteType, equals(WasteType.lesDeux));
        expect(diaper.pipiColor?.value, equals(PipiColor.jauneFonce.value));
        expect(diaper.cacaColor?.value, equals(CacaColor.vertOlive.value));
      });

      test('mappe WasteType.lesDeux avec fallback couleur unique', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            notes: null,
            wasteType: WasteType.lesDeux.dbValue,
            color: PipiColor.jauneClair.value,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.wasteType, equals(WasteType.lesDeux));
        expect(diaper.pipiColor, isNotNull);
      });

      test('ignore couleur nulle', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            notes: null,
            wasteType: WasteType.pipi.dbValue,
            color: null,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.pipiColor, isNull);
        expect(diaper.cacaColor, isNull);
      });

      test('ignore couleur vide', () async {
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            notes: null,
            wasteType: WasteType.caca.dbValue,
            color: '', // empty string — should be ignored
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.pipiColor, isNull);
        expect(diaper.cacaColor, isNull);
      });

      test('propage l\'exception du database', () async {
        when(mockDb.getAllEventsOrdered()).thenThrow(Exception('DB error'));

        expect(
          () => repository.getAllEventsOrdered(),
          throwsA(isA<Exception>()),
        );
      });
  });

  group('getEventsByType', () {
    test('filtre les événements par type', () async {
      when(mockDb.getEventsByType(any)).thenAnswer((_) async => []);

      final events = await repository.getEventsByType(TrackingType.miam);

      expect(events, isEmpty);
      verify(mockDb.getEventsByType('miam')).called(1);
    });

    test('mappe événements avec wasteType via getEventsByType', () async {
      when(mockEncryption.decrypt(any)).thenReturn(null);
      when(mockDb.getEventsByType(any)).thenAnswer((_) async => [
        db_app.TrackingEvent(
          id: 1,
          type: 'caca',
          timestamp: DateTime.utc(2024),
          duration: null,
          notes: null,
          wasteType: WasteType.pipi.dbValue,
          color: PipiColor.roseUrates.value,
        ),
      ]);

      final events = await repository.getEventsByType(TrackingType.caca);

      expect(events.length, equals(1));
      final diaper = events.first as DiaperEvent;
      expect(diaper.wasteType, equals(WasteType.pipi));
      expect(diaper.pipiColor?.value, equals(PipiColor.roseUrates.value));
    });

    test('propage l\'exception du database', () async {
      when(mockDb.getEventsByType(any)).thenThrow(Exception('DB error'));

      expect(
        () => repository.getEventsByType(TrackingType.miam),
        throwsA(isA<Exception>()),
      );
    });
  });
}

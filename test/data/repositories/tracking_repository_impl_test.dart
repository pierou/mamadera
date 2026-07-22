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
        pipiColor: pipiColorJauneClair,
        cacaColor: cacaColorMeconium,
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

    test('ecrit le subtype pour FeedingEvent.bib dans la colonne subtype', () async {
      when(mockDb.insertEvent(any)).thenAnswer((invocation) async {
        final companion = invocation.positionalArguments.first as db_app.TrackingEventsCompanion;
        // Vérifier que subtype est écrit avec 'bib'
        expect(companion.subtype.value, equals('bib'));
        return 1;
      });

      final event = FeedingEvent(
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.bib,
        duration: 20,
      );
      final id = await repository.insertEvent(event);

      expect(id, equals(1));
    });

    test('ecrit le subtype pour HealthEvent.vitamine_d dans la colonne subtype', () async {
      when(mockDb.insertEvent(any)).thenAnswer((invocation) async {
        final companion = invocation.positionalArguments.first as db_app.TrackingEventsCompanion;
        // Vérifier que health subtype est écrit dans 'subtype' et NON dans wasteType
        expect(companion.subtype.value, equals('vitamine_d'));
        expect(companion.wasteType.value, isNull);
        return 1;
      });

      final event = HealthEvent(
        timestamp: DateTime.now(),
        subtype: HealthSubtype.vitamineD,
      );
      final id = await repository.insertEvent(event);

      expect(id, equals(1));
    });

    test('round-trip: FeedingEvent.bib → DB row avec subtype="bib" → mapper retourne bib', () async {
      when(mockDb.insertEvent(any)).thenAnswer((_) async => 100);
      when(mockEncryption.decrypt(any)).thenReturn(null);

      final event = FeedingEvent(
        timestamp: DateTime.utc(2024, 5, 1),
        subtype: FeedingSubtype.bib,
        duration: 25,
      );
      final insertedId = await repository.insertEvent(event);
      expect(insertedId, equals(100));

      // Simuler la lecture depuis DB avec subtype="bib" dans la colonne dédiée
      when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
        db_app.TrackingEvent(
          id: 100,
          type: 'miam',
          timestamp: DateTime.utc(2024, 5, 1),
          duration: 25,
          subtype: 'bib', // La colonne subtype contient bien 'bib'
          notes: null,
          wasteType: null,
          color: null,
        ),
      ]);

      final events = await repository.getAllEventsOrdered();
      expect(events.length, equals(1));
      final readBack = events.first as FeedingEvent;
      expect(readBack.subtype, equals(FeedingSubtype.bib));
    });

    test('round-trip: HealthEvent.nettoyage_yeux → DB row avec subtype="nettoyage_yeux" → mapper retourne nettoyageYeux', () async {
      when(mockDb.insertEvent(any)).thenAnswer((_) async => 200);
      when(mockEncryption.decrypt(any)).thenReturn(null);

      final event = HealthEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        subtype: HealthSubtype.nettoyageYeux,
      );
      await repository.insertEvent(event);

      // Simuler la lecture depuis DB avec subtype="nettoyage_yeux" dans la colonne dédiée
      when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
        db_app.TrackingEvent(
          id: 200,
          type: 'sante',
          timestamp: DateTime.utc(2024, 6, 15),
          duration: null,
          subtype: 'nettoyage_yeux', // La colonne subtype contient la valeur health
          notes: null,
          wasteType: null,
          color: null,
        ),
      ]);

      final events = await repository.getAllEventsOrdered();
      expect(events.length, equals(1));
      final readBack = events.first as HealthEvent;
      expect(readBack.subtype.value, equals('nettoyage_yeux'));
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
            subtype: 'sein',
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
            subtype: null, // diaper events have no subtype
            notes: null,
            wasteType: WasteType.pipi.dbValue,
            color:
        pipiColorJauneClair.value,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.wasteType, equals(WasteType.pipi));
        expect(diaper.pipiColor, isNotNull);
        expect(diaper.pipiColor?.value, equals(pipiColorJauneClair.value));
      });

      test('mappe WasteType.caca avec cacaColor', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,            subtype: null, // diaper events have no subtype            notes: null,
            wasteType: WasteType.caca.dbValue,
            color: cacaColorMeconium.value,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.wasteType, equals(WasteType.caca));
        expect(diaper.cacaColor, isNotNull);
        expect(diaper.cacaColor?.value, equals(cacaColorMeconium.value));
      });

      test('mappe WasteType.lesDeux avec couleurs pipe-délimitées', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        final colorPipe = '${pipiColorJauneFonce.value}|${cacaColorVertOlive.value}';
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,            subtype: null, // diaper events have no subtype            notes: null,
            wasteType: WasteType.lesDeux.dbValue,
            color: colorPipe,
          ),
        ]);

        final events = await repository.getAllEventsOrdered();

        expect(events.length, equals(1));
        final diaper = events.first as DiaperEvent;
        expect(diaper.wasteType, equals(WasteType.lesDeux));
        expect(diaper.pipiColor?.value, equals(pipiColorJauneFonce.value));
        expect(diaper.cacaColor?.value, equals(cacaColorVertOlive.value));
      });

      test('mappe WasteType.lesDeux avec fallback couleur unique', () async {
        when(mockEncryption.decrypt(any)).thenReturn(null);
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            subtype: null, // diaper events have no subtype
            notes: null,
            wasteType: WasteType.lesDeux.dbValue,
            color:
        pipiColorJauneClair.value,
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
            subtype: null, // diaper events have no subtype
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
        when(mockEncryption.decrypt(any)).thenReturn(null);
        when(mockDb.getAllEventsOrdered()).thenAnswer((_) async => [
          db_app.TrackingEvent(
            id: 1,
            type: 'caca',
            timestamp: DateTime.utc(2024),
            duration: null,
            subtype: null, // diaper events have no subtype
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
          subtype: null, // diaper events have no subtype
          notes: null,
          wasteType: WasteType.pipi.dbValue,
          color: pipiColorRoseUrates.value,
        ),
      ]);

      final events = await repository.getEventsByType(TrackingType.caca);

      expect(events.length, equals(1));
      final diaper = events.first as DiaperEvent;
      expect(diaper.wasteType, equals(WasteType.pipi));
      expect(diaper.pipiColor?.value, equals(pipiColorRoseUrates.value));
    });

    test('propage l\'exception du database', () async {
      when(mockDb.getEventsByType(any)).thenThrow(Exception('DB error'));

      expect(
        () => repository.getEventsByType(TrackingType.miam),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getLastEventByTypeAndSubtype', () {
    test('retourne null quand aucun événement du type', () async {
      when(mockDb.getEventsByType(any)).thenAnswer((_) async => []);

      final result = await repository.getLastEventByTypeAndSubtype(
        TrackingType.sante,
        subtypeValue: 'vitamine_d',
      );

      expect(result, isNull);
      verify(mockDb.getEventsByType('sante')).called(1);
    });

    test('retourne le timestamp de l\'événement le plus récent sans filtre sous-type', () async {
      when(mockEncryption.decrypt(any)).thenReturn(null);
      when(mockDb.getEventsByType(any)).thenAnswer((_) async => [
        db_app.TrackingEvent(
          id: 2,
          type: 'miam',
          timestamp: DateTime.utc(2024, 6, 1),
          duration: null,
          subtype: 'sein', // feeding events have subtype
          notes: null,
          wasteType: null,
          color: null,
        ),
      ]);

      final result = await repository.getLastEventByTypeAndSubtype(TrackingType.miam);

      expect(result, equals(DateTime.utc(2024, 6, 1)));
    });

    test('retourne le timestamp de l\'événement le plus récent sans filtre sous-type (multiple events)', () async {
      when(mockEncryption.decrypt(any)).thenReturn(null);
      final older = DateTime.utc(2024, 1, 1);
      final newer = DateTime.utc(2024, 6, 1);
      // Drift returns DESC by timestamp — newest first
      when(mockDb.getEventsByType(any)).thenAnswer((_) async => [
        db_app.TrackingEvent(
          id: 2,
          type: 'miam',
          timestamp: newer,
          duration: null,
          subtype: 'sein', // feeding events have subtype
          notes: null,
          wasteType: null,
          color: null,
        ),
        db_app.TrackingEvent(
          id: 1,
          type: 'miam',
          timestamp: older,
          duration: null,
          subtype: 'sein', // feeding events have subtype
          notes: null,
          wasteType: null,
          color: null,
        ),
      ]);

      final result = await repository.getLastEventByTypeAndSubtype(TrackingType.miam);

      expect(result, equals(newer));
    });

    test('filtre HealthEvents par sous-type et retourne le plus récent', () async {
      // Subtypes are now in the dedicated subtype column, not in encrypted notes
      when(mockEncryption.decrypt(any)).thenReturn(null);
      final olderVitD = DateTime.utc(2024, 1, 15);
      final newerVitK = DateTime.utc(2024, 3, 20);
      when(mockDb.getEventsByType(any)).thenAnswer((_) async => [
        db_app.TrackingEvent(
          id: 1,
          type: 'sante',
          timestamp: olderVitD,
          duration: null,
          subtype: 'vitamine_d', // health subtype in dedicated column
          notes: null,
          wasteType: null,
          color: null,
        ),
        db_app.TrackingEvent(
          id: 2,
          type: 'sante',
          timestamp: newerVitK,
          duration: null,
          subtype: 'vitamine_k', // health subtype in dedicated column
          notes: null,
          wasteType: null,
          color: null,
        ),
      ]);

      final result = await repository.getLastEventByTypeAndSubtype(
        TrackingType.sante,
        subtypeValue: 'vitamine_d',
      );

      expect(result, equals(olderVitD));
    });

    test('retourne null quand le filtre sous-type ne correspond à rien', () async {
      // Subtypes are in dedicated column, no match for 'nettoyage_yeux'
      when(mockEncryption.decrypt(any)).thenReturn(null);
      when(mockDb.getEventsByType(any)).thenAnswer((_) async => [
        db_app.TrackingEvent(
          id: 1,
          type: 'sante',
          timestamp: DateTime.utc(2024),
          duration: null,
          subtype: 'vitamine_d', // health subtype in dedicated column
          notes: null,
          wasteType: null,
          color: null,
        ),
      ]);

      final result = await repository.getLastEventByTypeAndSubtype(
        TrackingType.sante,
        subtypeValue: 'nettoyage_yeux',
      );

      expect(result, isNull);
    });

    test('propage l\'exception du database avec logging', () async {
      when(mockDb.getEventsByType(any)).thenThrow(Exception('DB error'));

      await expectLater(
        repository.getLastEventByTypeAndSubtype(TrackingType.sante),
        throwsA(isA<Exception>()),
      );
    });
  });
}

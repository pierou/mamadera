// ignore_for_file: lines_longer_than_80_chars // Tests de TrackingRepositoryImpl — encrypting notes before DB insert, decrypting on read

import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' as db_app;
import 'package:mamadera/features/home/data/repositories/tracking_repository_impl.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('TrackingRepositoryImpl (integration)', () {
    late TrackingRepositoryImpl repository;
    late db_app.AppDatabase database;
    late EncryptionService encryption;

    setUp(() async {
      encryption = EncryptionService();
      await encryption.initialize();
      final connection = LazyDatabase(NativeDatabase.memory);
      database = db_app.AppDatabase(connection);
      // Trigger migration to create tables.
      await database.select(database.babyProfiles).get();
      repository = TrackingRepositoryImpl(
        encryption: encryption,
        database: database,
      );
    });

    tearDown(() async {
      await database.close();
    });

    group('insertEvent', () {
      test('encrypts notes before DB insert for FeedingEvent', () async {
        final event = FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10, 0),
          subtype: FeedingSubtype.natural,
          duration: 30,
          notes: 'sensitive feeding note',
        );
        await repository.insertEvent(event);

        // Verify the DB row has encrypted notes (not plaintext).
        final rows = await database.select(database.trackingEvents).get();
        expect(rows.length, 1);
        expect(rows.first.notes, isNotNull);
        expect(rows.first.notes, isNot(contains('sensitive feeding note')));
      });

      test('does not encrypt when notes are null', () async {
        final event = FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10, 0),
          subtype: FeedingSubtype.artificial,
          duration: 20,
        );
        await repository.insertEvent(event);

        final rows = await database.select(database.trackingEvents).get();
        expect(rows.first.notes, isNull);
      });

      test('encrypts notes for SleepEvent', () async {
        final event = SleepEvent(
          timestamp: DateTime.utc(2024, 1, 1, 14, 0),
          duration: 90,
          notes: 'sleeping in crib',
        );
        await repository.insertEvent(event);

        final rows = await database.select(database.trackingEvents).get();
        expect(rows.first.notes, isNotNull);
        expect(rows.first.notes, isNot(contains('sleeping in crib')));
      });

      test('encrypts notes for DiaperEvent', () async {
        final event = DiaperEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8, 0),
          wasteType: WasteType.pipi,
          pipiColor: pipiColorJauneClair,
          notes: 'yellow urine',
        );
        await repository.insertEvent(event);

        final rows = await database.select(database.trackingEvents).get();
        expect(rows.first.notes, isNotNull);
        expect(rows.first.notes, isNot(contains('yellow urine')));
      });

      test('encrypts notes for HealthEvent', () async {
        final event = HealthEvent(
          timestamp: DateTime.utc(2024, 1, 1, 9, 0),
          subtype: HealthSubtype.vitamineD,
          notes: 'vitamin D administered',
        );
        await repository.insertEvent(event);

        final rows = await database.select(database.trackingEvents).get();
        expect(rows.first.notes, isNotNull);
        expect(rows.first.notes, isNot(contains('vitamin D administered')));
      });

      test('stores correct type for each event subtype', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          duration: 30,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10),
          duration: 60,
        ));
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime.utc(2024, 1, 1, 12),
          wasteType: WasteType.caca,
        ));
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime.utc(2024, 1, 1, 14),
          subtype: HealthSubtype.vitamineK,
        ));

        final rows = await database.select(database.trackingEvents).get();
        expect(rows.length, 4);
        expect(rows[0].type, 'miam');
        expect(rows[1].type, 'dodo');
        expect(rows[2].type, 'caca');
        expect(rows[3].type, 'sante');
      });
    });

    group('getAllEventsOrdered', () {
      test('returns empty list when no events exist', () async {
        final result = await repository.getAllEventsOrdered();
        expect(result, isEmpty);
      });

      test('returns events sorted by timestamp descending', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          duration: 20,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          duration: 60,
        ));
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          subtype: FeedingSubtype.artificial,
          duration: 25,
        ));

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(3));
        // Most recent first
        expect(result.first.timestamp, DateTime(2024, 1, 1, 14));
        expect(result[1].timestamp, DateTime(2024, 1, 1, 10));
        expect(result.last.timestamp, DateTime(2024, 1, 1, 8));
      });

      test('decrypts notes on read', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10),
          subtype: FeedingSubtype.natural,
          duration: 30,
          notes: 'encrypted note content',
        ));

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(1));
        final event = result.first as FeedingEvent;
        expect(event.notes, 'encrypted note content');
      });

      test('handles null notes correctly after read', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10),
          subtype: FeedingSubtype.artificial,
          duration: 20,
          notes: null,
        ));

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(1));
        final event = result.first as FeedingEvent;
        expect(event.notes, isNull);
      });

      test('returns correct domain types for each event', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          duration: 30,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10),
          duration: 60,
        ));
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime.utc(2024, 1, 1, 12),
          wasteType: WasteType.pipi,
          pipiColor: pipiColorJauneClair,
        ));
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime.utc(2024, 1, 1, 14),
          subtype: HealthSubtype.vitamineD,
        ));

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(4));
        expect(result.first, isA<HealthEvent>());
        expect(result[1], isA<DiaperEvent>());
        expect(result[2], isA<SleepEvent>());
        expect(result.last, isA<FeedingEvent>());
      });

      test('preserves DiaperEvent wasteType and colors through round-trip', () async {
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8),
          wasteType: WasteType.lesDeux,
          pipiColor: pipiColorRoseUrates,
          cacaColor: cacaColorMeconium,
          notes: 'les deux',
        ));

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(1));
        final event = result.first as DiaperEvent;
        expect(event.wasteType, WasteType.lesDeux);
        expect(event.pipiColor, pipiColorRoseUrates);
        expect(event.cacaColor, cacaColorMeconium);
        expect(event.notes, 'les deux');
      });
    });

    group('getEventsByType', () {
      test('filters events by TrackingType.miam', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          duration: 30,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10),
          duration: 60,
        ));
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 14),
          subtype: FeedingSubtype.artificial,
          duration: 20,
        ));

        final result = await repository.getEventsByType(TrackingType.miam);
        expect(result, hasLength(2));
        expect(result.every((e) => e is FeedingEvent), isTrue);
      });

      test('filters events by TrackingType.dodo', () async {
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime.utc(2024, 1, 1, 10),
          duration: 90,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime.utc(2024, 1, 1, 20),
          duration: 120,
        ));

        final result = await repository.getEventsByType(TrackingType.dodo);
        expect(result, hasLength(2));
        expect(result.every((e) => e is SleepEvent), isTrue);
      });

      test('filters events by TrackingType.caca', () async {
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8),
          wasteType: WasteType.pipi,
        ));
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime.utc(2024, 1, 1, 12),
          wasteType: WasteType.caca,
          cacaColor: cacaColorVertOlive,
        ));

        final result = await repository.getEventsByType(TrackingType.caca);
        expect(result, hasLength(2));
        expect(result.every((e) => e is DiaperEvent), isTrue);
      });

      test('filters events by TrackingType.sante', () async {
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime.utc(2024, 1, 1, 9),
          subtype: HealthSubtype.vitamineD,
        ));
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime.utc(2024, 1, 1, 15),
          subtype: HealthSubtype.nettoyageYeux,
        ));

        final result = await repository.getEventsByType(TrackingType.sante);
        expect(result, hasLength(2));
        expect(result.every((e) => e is HealthEvent), isTrue);
      });

      test('returns empty list for type with no events', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          duration: 30,
        ));

        final result = await repository.getEventsByType(TrackingType.sante);
        expect(result, isEmpty);
      });
    });

    group('getLastEventByTypeAndSubtype', () {
      test('returns null when no events exist', () async {
        final result = await repository.getLastEventByTypeAndSubtype(TrackingType.miam);
        expect(result, isNull);
      });

      test('returns last feeding event by type', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          duration: 20,
        ));
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          subtype: FeedingSubtype.natural,
          duration: 25,
        ));

        final result = await repository.getLastEventByTypeAndSubtype(TrackingType.miam);
        expect(result, DateTime(2024, 1, 1, 14));
      });

      test('returns last health event by type and subtype', () async {
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: HealthSubtype.vitamineD,
        ));
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          subtype: HealthSubtype.vitamineD,
        ));

        final result = await repository.getLastEventByTypeAndSubtype(
          TrackingType.sante,
          subtypeValue: 'vitamine_d',
        );
        expect(result, DateTime(2024, 1, 1, 14));
      });

      test('returns null for non-existent subtype', () async {
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime.utc(2024, 1, 1, 8),
          subtype: HealthSubtype.vitamineD,
        ));

        final result = await repository.getLastEventByTypeAndSubtype(
          TrackingType.sante,
          subtypeValue: 'non_existent',
        );
        expect(result, isNull);
      });
    });

    group('integration: mixed events round-trip', () {
      test('inserts and reads back all event types with data integrity', () async {
        // Insert a mix of events
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime.utc(2024, 3, 15, 7, 30),
          subtype: FeedingSubtype.natural,
          duration: 25,
          notes: 'morning feeding',
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime.utc(2024, 3, 15, 9, 0),
          duration: 120,
          notes: 'nap time',
        ));
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime.utc(2024, 3, 15, 11, 0),
          wasteType: WasteType.pipi,
          pipiColor: pipiColorJauneFonce,
          notes: 'dark yellow',
        ));
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime.utc(2024, 3, 15, 12, 0),
          subtype: HealthSubtype.vitamineD,
          notes: 'daily vitamin D',
        ));

        // Read all
        final all = await repository.getAllEventsOrdered();
        expect(all, hasLength(4));

        // Verify order (descending by timestamp)
        expect(all.first, isA<HealthEvent>());
        expect(all[1], isA<DiaperEvent>());
        expect(all[2], isA<SleepEvent>());
        expect(all.last, isA<FeedingEvent>());

        // Verify notes are decrypted
        final health = all.first as HealthEvent;
        expect(health.notes, 'daily vitamin D');

        final diaper = all[1] as DiaperEvent;
        expect(diaper.notes, 'dark yellow');
        expect(diaper.pipiColor, pipiColorJauneFonce);

        final sleep = all[2] as SleepEvent;
        expect(sleep.notes, 'nap time');

        final feeding = all.last as FeedingEvent;
        expect(feeding.notes, 'morning feeding');
        expect(feeding.subtype, FeedingSubtype.natural);
      });
    });
  });
}

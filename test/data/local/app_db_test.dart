import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    // Use in-memory SQLite for testing
    final connection = LazyDatabase(NativeDatabase.memory);
    db = AppDatabase(connection);
  });

  tearDown(() async {
    await db.close();
  });

  group('schema migrations', () {
    test('schemaVersion is 13 (v13 adds app-level settings)', () {
      expect(db.schemaVersion, equals(13));
    });
  });

  group('insertEvent and getEvents', () {
    test('can insert an event and retrieve it', () async {
      final now = DateTime.now();
      final id = await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('ml'),
          type: const Value('miam'),
          timestamp: Value(now),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      expect(id, greaterThanOrEqualTo(1));

      final events = await db.getEvents();
      expect(events.length, equals(1));
      expect(events.first.type, equals('miam'));
    });

    test('getEvents returns all inserted events', () async {
      // Insert 3 events
      for (var i = 0; i < 3; i++) {
        await db.insertEvent(
          TrackingEventsCompanion(
            unit: const Value('ml'),
            type: Value(['miam', 'dodo', 'caca'][i]),
            timestamp: Value(DateTime.now().add(Duration(minutes: i))),
            duration: const Value(null),
            notes: const Value(null),
            wasteType: const Value(null),
            color: const Value(null),
          ),
        );
      }

      final events = await db.getEvents();
      expect(events.length, equals(3));
    });
  });

  group('getAllTrackingEvents', () {
    test('returns all events without ordering guarantees', () async {
      for (var i = 0; i < 5; i++) {
        await db.insertEvent(
          TrackingEventsCompanion(
            unit: const Value('ml'),
            type: const Value('miam'),
            timestamp: Value(DateTime.now().add(Duration(minutes: i))),
            duration: const Value(null),
            notes: const Value(null),
            wasteType: const Value(null),
            color: const Value(null),
          ),
        );
      }

      final events = await db.getAllTrackingEvents();
      expect(events.length, equals(5));
    });
  });

  group('getAllEventsOrdered', () {
    test('returns events ordered by timestamp DESC', () async {
      // Insert oldest first
      await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('ml'),
          type: const Value('miam'),
          timestamp: Value(DateTime.now().subtract(const Duration(hours: 2))),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('min'),
          type: const Value('dodo'),
          timestamp: Value(DateTime.now().subtract(const Duration(hours: 1))),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('ml'),
          type: const Value('caca'),
          timestamp: Value(DateTime.now()),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      final events = await db.getAllEventsOrdered();
      expect(events.length, equals(3));
      // Most recent first
      expect(events.first.type, equals('caca'));
    });
  });

  group('getFeedingEvents', () {
    test('returns only feeding type events (type = miam)', () async {
      // Insert feeding events with subtype natural/artificial
      for (final subtype in FeedingSubtype.values) {
        await db.insertEvent(
          TrackingEventsCompanion(
            unit: const Value('ml'),
            type: const Value('miam'),
            subtype: Value(subtype.dbValue),
            timestamp: Value(DateTime.now()),
            duration: const Value(null),
            notes: const Value(null),
            wasteType: const Value(null),
            color: const Value(null),
          ),
        );
      }

      // Insert non-feeding event
      await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('min'),
          type: const Value('dodo'),
          timestamp: Value(DateTime.now()),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      final feedingEvents = await db.getFeedingEvents();
      // Should only return feeding events (type = 'miam'), not 'dodo'
      expect(feedingEvents.length, equals(FeedingSubtype.values.length));
    });
  });

  group('getEventsByType', () {
    test('returns events filtered by type string', () async {
      await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('ml'),
          type: const Value('miam'),
          timestamp: Value(DateTime.now()),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('min'),
          type: const Value('dodo'),
          timestamp: Value(DateTime.now()),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      final miamEvents = await db.getEventsByType('miam');
      expect(miamEvents.length, equals(1));
      expect(miamEvents.first.type, equals('miam'));
    });
  });

  group('updateEvent', () {
    test('updates an existing event by id', () async {
      final now = DateTime.now();
      final id = await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('ml'),
          type: const Value('miam'),
          timestamp: Value(now),
          duration: const Value(null),
          notes: const Value('initial note'),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      final updated = await db.updateEvent(
        id,
        const TrackingEventsCompanion(
            unit: const Value('ml'), notes: Value('updated note')),
      );
      expect(updated, equals(1)); // 1 row affected

      final events = await db.getEvents();
      expect(events.first.notes, equals('updated note'));
    });
  });

  group('updateNotesForEvent', () {
    test('updates only notes field for an event by id', () async {
      final now = DateTime.now();
      final id = await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('min'),
          type: const Value('dodo'),
          timestamp: Value(now),
          duration: const Value(30),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      final updated = await db.updateNotesForEvent(id, 'new note');
      expect(updated, equals(1));

      final events = await db.getEvents();
      expect(events.first.notes, equals('new note'));
      // Other fields unchanged
      expect(events.first.duration, 30.0);
    });
  });

  group('deleteEvent', () {
    test('deletes an event by id and returns true', () async {
      final now = DateTime.now();
      final id = await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('ml'),
          type: const Value('caca'),
          timestamp: Value(now),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      final deleted = await db.deleteEvent(id);
      expect(deleted, isTrue);

      final events = await db.getEvents();
      expect(events.length, equals(0));
    });

    test('returns false when deleting non-existent id', () async {
      final deleted = await db.deleteEvent(99999);
      expect(deleted, isFalse);
    });
  });

  group('babyProfiles', () {
    test('can insert and retrieve baby profiles', () async {
      final profileId = await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('test-baby-1'),
          name: Value('Test Baby'),
          birthDate: Value(DateTime.now().millisecondsSinceEpoch),
          isActive: Value(true),
        ),
      );

      expect(profileId, greaterThanOrEqualTo(1));

      final profiles = await db.getAllBabyProfiles();
      expect(profiles.length, equals(1));
      expect(profiles.first.name, equals('Test Baby'));
    });

    test('can update baby profile', () async {
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('test-baby-2'),
          name: Value('Old Name'),
          birthDate: Value(DateTime.now().millisecondsSinceEpoch),
          isActive: Value(false),
        ),
      );

      await db.updateBabyProfile(
        'test-baby-2',
        BabyProfilesCompanion(name: Value('New Name')),
      );

      final profiles = await db.getAllBabyProfiles();
      expect(profiles.first.name, equals('New Name'));
    });

    test('can delete baby profile', () async {
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('test-baby-3'),
          name: Value('ToDelete'),
          birthDate: Value(DateTime.now().millisecondsSinceEpoch),
          isActive: Value(false),
        ),
      );

      final deleted = await db.deleteBabyProfile('test-baby-3');
      expect(deleted, isTrue);

      final profiles = await db.getAllBabyProfiles();
      expect(profiles.length, equals(0));
    });

    test('getActiveBabyProfile returns active profile', () async {
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('active-baby'),
          name: Value('Active Baby'),
          birthDate: Value(DateTime.now().millisecondsSinceEpoch),
          isActive: Value(true),
        ),
      );

      final active = await db.getActiveBabyProfile();
      expect(active, isA<BabyProfile>());
      expect(active!.name, equals('Active Baby'));
    });

    test('getActiveBabyProfile is deterministic with multiple active rows',
        () async {
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('later-baby'),
          name: Value('Later'),
          birthDate: Value(DateTime(2026, 8, 1).millisecondsSinceEpoch),
          isActive: Value(true),
        ),
      );
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('earlier-baby'),
          name: Value('Earlier'),
          birthDate: Value(DateTime(2026, 1, 1).millisecondsSinceEpoch),
          isActive: Value(true),
        ),
      );

      final active = await db.getActiveBabyProfile();
      expect(active, isA<BabyProfile>());
      expect(active!.id, equals('earlier-baby'));
    });

    test('getActiveBabyProfile breaks birth date ties by id', () async {
      final sameBirthDate = DateTime(2026, 5, 10).millisecondsSinceEpoch;
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('id-b'),
          name: Value('B'),
          birthDate: Value(sameBirthDate),
          isActive: Value(true),
        ),
      );
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('id-a'),
          name: Value('A'),
          birthDate: Value(sameBirthDate),
          isActive: Value(true),
        ),
      );

      final active = await db.getActiveBabyProfile();
      expect(active, isA<BabyProfile>());
      expect(active!.id, equals('id-a'));
    });

    test('getEventsByBabyId filters events correctly', () async {
      await db.insertBabyProfile(
        BabyProfilesCompanion(
          id: Value('baby-1'),
          name: Value('Baby 1'),
          birthDate: Value(DateTime.now().millisecondsSinceEpoch),
          isActive: Value(true),
        ),
      );

      await db.insertEvent(
        TrackingEventsCompanion(
          unit: const Value('ml'),
          type: Value('miam'),
          timestamp: Value(DateTime.now()),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
          babyId: Value('baby-1'),
        ),
      );

      final events = await db.getEventsByBabyId('baby-1');
      expect(events.length, equals(1));
      expect(events.first.type, equals('miam'));
    });
  });

  group('getLastEventTimestamp', () {
    Future<void> insert(
      String type,
      DateTime at, {
      String? babyId,
    }) async {
      await db.insertEvent(TrackingEventsCompanion(
        unit: const Value('ml'),
        type: Value(type),
        timestamp: Value(at),
        babyId: Value(babyId),
      ));
    }

    test('returns null when the type has no event at all', () async {
      await insert('miam', DateTime(2026, 11, 1, 9));

      expect(await db.getLastEventTimestamp('dodo', babyId: 'a'), isNull);
    });

    test('returns the newest event of the type, not the oldest', () async {
      await insert('miam', DateTime(2026, 11, 1, 9), babyId: 'a');
      await insert('miam', DateTime(2026, 11, 3, 22), babyId: 'a');
      await insert('miam', DateTime(2026, 11, 2, 14), babyId: 'a');

      expect(await db.getLastEventTimestamp('miam', babyId: 'a'),
          DateTime(2026, 11, 3, 22));
    });

    test('a baby never reads the other baby\u0027s history', () async {
      // The defect B28 would have installed if the line had been wired to the
      // unscoped getLastEventByTypeAndSubtype: log nothing for the second baby
      // and still be told when it was last fed.
      await insert('miam', DateTime(2026, 11, 8, 8), babyId: 'a');
      await insert('dodo', DateTime(2026, 11, 9, 3), babyId: 'b');

      expect(await db.getLastEventTimestamp('miam', babyId: 'b'), isNull,
          reason: 'baby b has no feeding of its own');
      expect(await db.getLastEventTimestamp('dodo', babyId: 'b'),
          DateTime(2026, 11, 9, 3));
    });

    test('the profile-less state reads only the unowned rows', () async {
      // Same scoping as RemindersRepositoryImpl.getLastCompleted: a null baby
      // means `baby_id IS NULL`, never somebody else\u0027s row.
      await insert('caca', DateTime(2026, 11, 5), babyId: null);
      await insert('caca', DateTime(2026, 11, 7), babyId: 'a');

      expect(await db.getLastEventTimestamp('caca'), DateTime(2026, 11, 5));
      expect(await db.getLastEventTimestamp('caca', babyId: 'a'),
          DateTime(2026, 11, 7));
    });

    test('a sleep event does not answer for the feeding type', () async {
      await insert('dodo', DateTime(2026, 11, 9), babyId: 'a');

      expect(await db.getLastEventTimestamp('miam', babyId: 'a'), isNull);
      expect(await db.getLastEventTimestamp('dodo', babyId: 'a'),
          DateTime(2026, 11, 9));
    });
  });
}

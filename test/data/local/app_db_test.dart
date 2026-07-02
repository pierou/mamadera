import 'package:drift/drift.dart';
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
    test('schemaVersion is 4 (baby_profiles + tracking_events.baby_id)', () {
      expect(db.schemaVersion, equals(4));
    });
  });

  group('insertEvent and getEvents', () {
    test('can insert an event and retrieve it', () async {
      final now = DateTime.now();
      final id = await db.insertEvent(
        TrackingEventsCompanion(
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
    test('returns only feeding type events (FeedingSubtype values)', () async {
      for (final subtype in FeedingSubtype.values) {
        await db.insertEvent(
          TrackingEventsCompanion(
            type: Value(subtype.name),
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
          type: const Value('dodo'),
          timestamp: Value(DateTime.now()),
          duration: const Value(null),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      final feedingEvents = await db.getFeedingEvents();
      // Should only return FeedingSubtype events, not 'dodo'
      expect(feedingEvents.length, equals(FeedingSubtype.values.length));
    });
  });

  group('getEventsByType', () {
    test('returns events filtered by type string', () async {
      await db.insertEvent(
        TrackingEventsCompanion(
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
        const TrackingEventsCompanion(notes: Value('updated note')),
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
}

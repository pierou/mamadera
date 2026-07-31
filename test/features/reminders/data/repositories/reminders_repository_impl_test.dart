import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';

void main() {
  group('RemindersRepositoryImpl', () {
    late AppDatabase database;
    late RemindersRepositoryImpl repository;

    setUp(() async {
      final connection = LazyDatabase(NativeDatabase.memory);
      database = AppDatabase(connection);
      // Trigger migration to create tables before any test runs.
      await database.select(database.reminderDismissals).get();
      repository = RemindersRepositoryImpl(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    final vitaminDItem = ReminderItemPresets.vitaminD;

    group('getLastCompleted', () {
      test('returns null when no tracking events exist', () async {
        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNull);
      });

      test('returns event from yesterday (not just today)', () async {
        // Regression: previously filtered to TODAY only, causing Vitamin K reminder
        // to show as due even when tracked 1 day ago. Now returns last completed ever.
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: yesterday,
          ),
        );

        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNotNull);
        expect(result!.day, equals(yesterday.day));
      });

      test('returns event timestamp from today', () async {
        final now = DateTime.now();
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: now,
          ),
        );

        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNotNull);
        expect(result!.year, equals(now.year));
        expect(result.month, equals(now.month));
        expect(result.day, equals(now.day));
      });

      test('returns most recent of multiple events across dates', () async {
        // Ensures query returns the latest event, not an older one.
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: weekAgo,
          ),
        );
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: yesterday,
          ),
        );

        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNotNull);
        // Should return yesterday's event (most recent), not week ago.
        expect(result!.day, equals(yesterday.day));
      });

      test('returns null for different tracking type', () async {
        final vitaminK = ReminderItemPresets.vitaminK;
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            wasteType: Value(vitaminDItem.subtypeValue),
            timestamp: DateTime.now(),
          ),
        );

        final result = await repository.getLastCompleted(vitaminK);
        expect(result, isNull);
      });
    });

    group('saveDismissalTime', () {
      test('saves dismissal and retrieves it', () async {
        final now = DateTime.now();
        await repository.saveDismissalTime(vitaminDItem.id, now);

        final result = await repository.getDismissalTime(vitaminDItem.id);
        expect(result, isNotNull);
        expect(result!.year, equals(now.year));
      });

      test('updates existing dismissal on second save', () async {
        final first = DateTime.now().subtract(const Duration(hours: 5));
        await repository.saveDismissalTime(vitaminDItem.id, first);

        final second = DateTime.now();
        await repository.saveDismissalTime(vitaminDItem.id, second);

        final result = await repository.getDismissalTime(vitaminDItem.id);
        expect(result!.hour, equals(second.hour));
      });

      test('stores different items independently', () async {
        final vitaminK = ReminderItemPresets.vitaminK;
        final nowD = DateTime.now();
        final nowK = DateTime.now().add(const Duration(hours: 1));

        await repository.saveDismissalTime(vitaminDItem.id, nowD);
        await repository.saveDismissalTime(vitaminK.id, nowK);

        final resultD = await repository.getDismissalTime(vitaminDItem.id);
        final resultK = await repository.getDismissalTime(vitaminK.id);

        expect(resultD!.hour, equals(nowD.hour));
        expect(resultK!.hour, equals(nowK.hour));
      });
    });

    group('getDismissalTime', () {
      test('returns null for non-existent item', () async {
        final result = await repository.getDismissalTime(vitaminDItem.id);
        expect(result, isNull);
      });

      test('returns saved dismissal time', () async {
        final now = DateTime.now();
        await repository.saveDismissalTime(vitaminDItem.id, now);

        final result = await repository.getDismissalTime(vitaminDItem.id);
        expect(result, isNotNull);
      });
    });
  });
}

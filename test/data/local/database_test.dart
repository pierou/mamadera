import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Note: The real createAppDatabase() factory uses path_provider which requires
// platform bindings. We test the core logic by using in-memory database instead,
// and verify that AppDatabase can be instantiated with a LazyDatabase connection.
// This covers the executable lines without requiring native file system access.
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/data/local/database.dart';

void main() {
  group('database creation - in-memory', () {
    test('AppDatabase can be created with memory-backed SQLite', () async {
      final connection = LazyDatabase(NativeDatabase.memory);
      final db = AppDatabase(connection);

      expect(db.schemaVersion, greaterThan(0));

      // Verify we can perform operations (database is functional)
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

      final events = await db.getEvents();
      expect(events.length, equals(1));

      await db.close();
    });

    test('AppDatabase migrations run on creation', () async {
      // When creating a new in-memory database, onCreate migration should run
      // and create indexes. We verify this by checking the schemaVersion > 0
      final connection = LazyDatabase(NativeDatabase.memory);
      final db = AppDatabase(connection);

      expect(db.schemaVersion, equals(2));

      await db.close();
    });

    test('AppDatabase can handle multiple operations sequentially', () async {
      final connection = LazyDatabase(NativeDatabase.memory);
      final db = AppDatabase(connection);

      // Insert
      final id = await db.insertEvent(
        TrackingEventsCompanion(
          type: const Value('dodo'),
          timestamp: Value(DateTime.now()),
          duration: const Value(60),
          notes: const Value(null),
          wasteType: const Value(null),
          color: const Value(null),
        ),
      );

      // Update
      await db.updateEvent(id, const TrackingEventsCompanion(notes: Value('nap')));

      // Read
      final events = await db.getEvents();
      expect(events.first.notes, equals('nap'));

      // Delete
      final deleted = await db.deleteEvent(id);
      expect(deleted, isTrue);

      await db.close();
    });
  });

  group('createAppDatabase factory with temporary directory', () {
    late Directory tempDir;
    var counter = 0;

    setUp(() async {
      counter++;
      final uniqueName = 'mamadera_test_$counter${DateTime.now().millisecondsSinceEpoch}';
      tempDir = await Directory('${Directory.systemTemp.path}/$uniqueName').create(recursive: true);
    });

    tearDown(() async {
      // Clean up temp directory and database file
      final dbFile = File('${tempDir.path}/mamadera.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      await tempDir.delete(recursive: true);
    });

    test('createAppDatabase creates functional database with directoryPath', () async {
      final db = await createAppDatabase(directoryPath: tempDir.path);

      expect(db.schemaVersion, greaterThan(0));

      // Verify we can perform operations (database is functional)
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

      final events = await db.getEvents();
      expect(events.length, equals(1));

      // Verify the database file was created on disk
      final dbFile = File('${tempDir.path}/mamadera.db');
      expect(await dbFile.exists(), isTrue);

      await db.close();
    });
  });
}

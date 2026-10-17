import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';

/// Empty [GeneratedDatabase] shell used solely for executing raw SQL queries.
/// on a file, without any tables defined by Drift.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 7;
}

/// Regression of migration v8: a database created before the existence of...
/// `reminder_settings` (versions 3 through 7) was upgraded to version 8, but the table was never... (The sentence is incomplete).
/// created by onUpgrade, and all read/write operations related to reminder settings.
/// It failed with the error "no such table: reminder_settings".
///
/// This test physically recreates a v7 base (v7 schema of...).
/// lib/data/local/schema.sql (without the reminder_settings section), opens the AppDatabase.
/// It uses the same file and then proves that the table exists and is writable.
void main() {
  test('opening a v7 database (no reminder_settings) upgrades it to a writable v8', () async {
    final tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v7');
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });
    final dbFile = File('${tempDir.path}/mamadera_v7.db');

    // 1. Physical v7 database: Existing tables from v7, user version 7.
    // SANS reminder_settings (the bug: it didn't exist at that time).
    final raw = _RawSqlDatabase(NativeDatabase(dbFile));
    await raw.customStatement('''
      CREATE TABLE baby_profiles (
        id          TEXT PRIMARY KEY NOT NULL,
        name        TEXT               NOT NULL,
        birth_date  INTEGER            NOT NULL,
        is_active   BOOLEAN DEFAULT 1 NOT NULL
      )''');
    await raw.customStatement('''
      CREATE TABLE tracking_events (
        id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        type        TEXT                              NOT NULL,
        timestamp   TIMESTAMP                         NOT NULL,
        duration    REAL,
        subtype     TEXT,
        notes       TEXT,
        waste_type  TEXT,
        color       TEXT,
        baby_id     TEXT,
        quantity    REAL
      )''');
    await raw.customStatement('CREATE INDEX idx_tracking_events_type ON tracking_events(type)');
    await raw.customStatement(
        'CREATE INDEX idx_tracking_events_timestamp_type ON tracking_events(timestamp DESC, type)');
    await raw.customStatement('''
      CREATE TABLE reminder_dismissals (
        item_id      TEXT PRIMARY KEY NOT NULL,
        dismissed_at TIMESTAMP        NOT NULL
      )''');
    await raw.close();

    // Premise: At this stage, the table does not actually exist.
    final premise = _RawSqlDatabase(NativeDatabase(dbFile));
    await expectLater(
      premise.customStatement('SELECT * FROM reminder_settings'),
      throwsA(anything),       // "Table 'reminder_settings' does not exist."
    );
    await premise.close();

    // 2. For the `AppDatabase` on the same file: the `onUpgrade` function (from version 7 to version 8) must be executed.
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    await db.select(db.babyProfiles).get(); // force ouverture + migrations.

    // The table now exists and can be modified.
    await db.into(db.reminderSettings).insert(
      const ReminderSettingsCompanion(
        babyId: Value(''),
        itemId: Value('test-reminder'),
        enabled: Value(true),
      ),
    );
    final rows = await db.select(db.reminderSettings).get();
    expect(rows, hasLength(1));
    expect(rows.first.itemId, equals('test-reminder'));
    expect(rows.first.enabled, isTrue);

    await db.close();
  });
}

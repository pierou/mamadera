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
  int get schemaVersion => 8;
}

/// Migration regression v9: Added the `texture` column.
/// (stool consistency) in the `tracking_events` table.
///
/// Two things are verified because these are the two ways in which a...
/// Column migration can silently corrupt data.
/// 1. The column exists after the data is loaded, so this is the first backup since then.
/// The device does not fail with the error message "no such column: texture";
/// 2. Any changes that have already been recorded will remain as NULL – we don't fabricate data.
/// consistency with a previously recorded exchange rate before this option was applied.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v9');
    dbFile = File('${tempDir.path}/mamadera_v8.db');

    // A physical V8 database, as described by the `lib/data/local/schema.sql` file (V8 version).
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
    await raw.customStatement('''
      CREATE TABLE reminder_settings (
        item_id TEXT PRIMARY KEY NOT NULL,
        enabled BOOLEAN NOT NULL
      )''');
    // Created from version 3 onwards, it was absent from this minimalist seed but is present on...
    // Any real V8 database: the V11 reconstruction reads it; it must exist.
    await raw.customStatement('''
      CREATE TABLE reminder_dismissals (
        item_id     TEXT PRIMARY KEY NOT NULL,
        dismissed_at TIMESTAMP            NOT NULL
      )''');
    // A layer that was saved before the option was applied, with a specific color.
    await raw.customStatement(
      "INSERT INTO tracking_events (type, timestamp, waste_type, color) "
      "VALUES ('caca', 1756684800, 'caca', 'jaune_moutarde')",
    );
    await raw.close();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('a v8 database gains the texture column and keeps its rows', () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    final events = await db.select(db.trackingEvents).get();
    expect(events, hasLength(1));
    // Checked using Drift: the column exists, and the old row is intact.
    expect(events.first.color, equals('jaune_moutarde'));
    expect(events.first.texture, equals(null));
    // The file has been updated to the current version, not just to version 9.
    expect(db.schemaVersion, equals(12));
  });

  test('a diaper saved after the upgrade can store a texture', () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    await db.into(db.trackingEvents).insert(TrackingEventsCompanion.insert(
          unit: 'ml',
          type: 'caca',
          timestamp: DateTime.utc(2026, 9, 1),
          wasteType: const Value('caca'),
          color: const Value('vert_olive'),
          texture: const Value('pateuse'),
        ));

    final rows = await db.select(db.trackingEvents).get();
    final fresh = rows.firstWhere((r) => r.texture != null);
    expect(fresh.texture, equals('pateuse'));
    // And the previous line was not affected by the writing.
    expect(rows.firstWhere((r) => r.color == 'jaune_moutarde').texture,
        equals(null));
  });
}

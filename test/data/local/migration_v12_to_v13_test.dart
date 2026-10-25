import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';

/// Empty [GeneratedDatabase] shell used solely for executing raw SQL on a
/// file, without any tables defined by Drift.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 12;
}

/// Migration v12 → v13 (roadmap item 12): the `app_settings` table.
///
/// The v13 step is the simplest kind of migration — one additive
/// `CREATE TABLE`, no rekey, no data movement — so the risk it must not
/// regress is the one every "additive" migration carries: touching or
/// losing existing data. The test seeds a genuine v12 database (all seven
/// tables, real rows, both the `''` sentinel scope and profileless
/// `baby_id NULL` rows), opens it with the v13 code, and checks that the
/// new table exists, is empty, and usable — and that every v12 row is
/// intact.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v13');
    dbFile = File('${tempDir.path}/mamadera_v12.db');

    // A physical v12 database, as described by lib/data/local/schema.sql
    // (v12: all seven tables, tracking_events with the unit column).
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
        texture     TEXT,
        baby_id     TEXT,
        quantity    REAL,
        unit        TEXT                              NOT NULL
      )''');
    await raw.customStatement('''
      CREATE TABLE reminder_dismissals (
        baby_id     TEXT    NOT NULL DEFAULT '',
        item_id     TEXT    NOT NULL,
        dismissed_at TIMESTAMP NOT NULL,
        PRIMARY KEY (baby_id, item_id)
      )''');
    await raw.customStatement('''
      CREATE TABLE reminder_settings (
        baby_id     TEXT    NOT NULL DEFAULT '',
        item_id     TEXT    NOT NULL,
        enabled     BOOLEAN NOT NULL,
        PRIMARY KEY (baby_id, item_id)
      )''');
    await raw.customStatement('''
      CREATE TABLE custom_reminders (
        id               INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        baby_id          TEXT    NOT NULL DEFAULT '',
        label            TEXT                              NOT NULL,
        subtype_value    TEXT,
        frequency        TEXT    NOT NULL,
        interval_days    INTEGER,
        completion_source TEXT    NOT NULL DEFAULT 'from_events'
      )''');
    await raw.customStatement('''
      CREATE TABLE measurements (
        id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        baby_id     TEXT,
        kind        TEXT                              NOT NULL,
        value       TEXT                              NOT NULL,
        unit        TEXT                              NOT NULL,
        recorded_at TIMESTAMP                         NOT NULL,
        notes       TEXT
      )''');
    await raw.customStatement('''
      CREATE TABLE reminder_completions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        baby_id     TEXT                              NOT NULL,
        item_id     TEXT                              NOT NULL,
        completed_at TIMESTAMP                        NOT NULL
      )''');

    // Real rows in all seven v12 tables: one baby, both sentinel scope and
    // profileless (NULL) rows, and every reminder state table populated.
    await raw.customStatement(
      "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
      "VALUES ('baby-AAA', 'Léa', 1700000000000, 1)",
    );
    // Drift stores dateTime columns as epoch milliseconds (INTEGER).
    await raw.customStatement(
      "INSERT INTO tracking_events "
      "(type, timestamp, subtype, baby_id, quantity, unit) VALUES "
      "('miam', 1761456000000, 'natural', 'baby-AAA', 120, 'ml')",
    );
    await raw.customStatement(
      "INSERT INTO tracking_events "
      "(type, timestamp, baby_id, duration, quantity, unit) VALUES "
      "('dodo', 1761452400000, NULL, 60.0, 60, 'min')",
    );
    await raw.customStatement(
      "INSERT INTO tracking_events "
      "(type, timestamp, subtype, baby_id, unit) VALUES "
      "('sante', 1761459600000, 'vitamine_d', 'baby-AAA', 'ml')",
    );
    await raw.customStatement(
      "INSERT INTO reminder_dismissals (baby_id, item_id, dismissed_at) "
      "VALUES ('baby-AAA', 'vitamine_d', 1761463200000)",
    );
    await raw.customStatement(
      "INSERT INTO reminder_settings (baby_id, item_id, enabled) VALUES "
      "('', 'face_cleaning', 0), ('baby-AAA', 'vitamine_k', 1)",
    );
    await raw.customStatement(
      "INSERT INTO custom_reminders "
      "(baby_id, label, subtype_value, frequency, interval_days, completion_source) "
      "VALUES ('baby-AAA', 'Crème du change', 'nettoyage_nez', 'every_n_days', 3, 'from_events')",
    );
    await raw.customStatement(
      "INSERT INTO measurements (baby_id, kind, value, unit, recorded_at) "
      "VALUES ('baby-AAA', 'poids', 'iv:ciphertext-base64', 'g', 1761454800000)",
    );
    await raw.customStatement(
      "INSERT INTO reminder_completions (baby_id, item_id, completed_at) "
      "VALUES ('baby-AAA', 'vitamine_d', 1761459900000)",
    );
    await raw.close();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('a v12 database gains app_settings and keeps every v12 row intact',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    expect(db.schemaVersion, 13);

    // The new table exists, is empty, and has the expected shape.
    final info = await db
        .customSelect("PRAGMA table_info('app_settings')")
        .get();
    expect(info, hasLength(2));
    expect(info.map((r) => r.read<String>('name')),
        containsAll(['key', 'value']));
    expect((await db.select(db.appSettings).get()), isEmpty);

    // All seven v12 tables keep exactly the rows that were seeded.
    expect(await db.select(db.babyProfiles).get(), hasLength(1));
    expect(await db.select(db.trackingEvents).get(), hasLength(3));
    expect(await db.select(db.reminderDismissals).get(), hasLength(1));
    expect(await db.select(db.reminderSettings).get(), hasLength(2));
    expect(await db.select(db.customReminders).get(), hasLength(1));
    expect(await db.select(db.measurements).get(), hasLength(1));
    expect(await db.select(db.reminderCompletions).get(), hasLength(1));

    // Spot-check the rows the migration most often breaks: the unit column
    // (v12), the '' sentinel scope, and the profileless NULL row.
    final events = await db.select(db.trackingEvents).get();
    expect(events.map((e) => e.unit), containsAll(['ml', 'min', 'ml']));
    final settings = await db.select(db.reminderSettings).get();
    expect(
        settings.map((s) => s.babyId),
        containsAll(['', 'baby-AAA']),
        reason: 'the sentinel row must survive the migration');
    final profileless = await db
        .customSelect(
            "SELECT COUNT(*) AS n FROM tracking_events WHERE baby_id IS NULL")
        .getSingle();
    expect(profileless.read<int>('n'), 1);

    // The table is usable right after the migration.
    await db
        .into(db.appSettings)
        .insert(AppSettingsCompanion.insert(key: 'notifications_opt_in', value: '1'));
    final row = await db
        .customSelect(
            "SELECT value FROM app_settings WHERE key = 'notifications_opt_in'")
        .getSingle();
    expect(row.read<String>('value'), '1');
  });

  test('a fresh install (onCreate) also has app_settings', () async {
    final freshFile = File('${tempDir.path}/fresh.db');
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(freshFile)));
    addTearDown(db.close);

    expect(db.schemaVersion, 13);
    expect((await db.select(db.appSettings).get()), isEmpty);
  });
}

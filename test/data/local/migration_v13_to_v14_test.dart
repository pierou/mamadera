import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
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
  int get schemaVersion => 13;
}

/// The vitamin D seed of the v14 migration, verbatim from `app_db.dart`.
///
/// Duplicated on purpose: the idempotency test must re-run *the same
/// statement* the migration ran, and reaching into the migration for it would
/// mean running the whole v13 → v14 step again (which `from < 14` makes
/// impossible on an already-migrated file).
const String _seedVitaminD = '''
  INSERT INTO reminder_settings (baby_id, item_id, enabled)
  SELECT s.baby_id, 'vitamine_d', 1
  FROM (SELECT '' AS baby_id UNION ALL SELECT id FROM baby_profiles) s
  WHERE NOT EXISTS (
    SELECT 1 FROM reminder_settings r
    WHERE r.baby_id = s.baby_id AND r.item_id = 'vitamine_d'
  )
''';

/// The eight columns v14 adds to `reminder_settings`, in declaration order.
const List<String> _v14Columns = [
  'time',
  'label',
  'frequency',
  'interval_days',
  'frequency_date',
  'end_date',
  'end_age_months',
  'removed',
];

/// Migration v13 → v14 (PLAN-v1.4.0 D-R2/D-R3 + B6's seed, D-R1).
///
/// Two things can go wrong here and both are silent on a phone:
///
/// 1. the seed touching a row it should not — a parent who **turned vitamin D
///    off** must not get it back, and one who never touched it must not lose
///    it (owner decision A: existing installs keep the reminder "until manual
///    turning off");
/// 2. the columns arriving in an order that differs from a fresh install, which
///    is what `schema_parity_test.dart` compares.
///
/// So each test seeds a genuine v13 file (all eight tables, real rows, both the
/// `''` sentinel scope and a profile scope), opens it with the v14 code, and
/// reads the settings rows back.
void main() {
  late Directory tempDir;
  late File dbFile;

  /// A physical v13 database: all eight tables, one baby, both scopes, rows in
  /// every table the migration must not disturb. No vitamin D row — each test
  /// adds what it needs with [withRawSql].
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v14');
    dbFile = File('${tempDir.path}/mamadera_v13.db');

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
    await raw.customStatement('''
      CREATE TABLE app_settings (
        key         TEXT    PRIMARY KEY NOT NULL,
        value       TEXT                              NOT NULL
      )''');

    await raw.customStatement(
      "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
      "VALUES ('baby-AAA', 'Léa', 1700000000000, 1)",
    );
    await raw.customStatement(
      "INSERT INTO tracking_events "
      "(type, timestamp, subtype, baby_id, quantity, unit) VALUES "
      "('miam', 1761456000000, 'natural', 'baby-AAA', 120, 'ml')",
    );
    await raw.customStatement(
      "INSERT INTO tracking_events "
      "(type, timestamp, subtype, baby_id, unit) VALUES "
      "('sante', 1761459600000, 'vitamine_d', 'baby-AAA', 'ml')",
    );
    await raw.customStatement(
      "INSERT INTO reminder_dismissals (baby_id, item_id, dismissed_at) "
      "VALUES ('baby-AAA', 'eye_cleaning', 1761463200000)",
    );
    // Two rows that are **not** vitamin D: the seed must leave both alone.
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
    await raw.customStatement(
      "INSERT INTO app_settings (key, value) VALUES "
      "('notifications_opt_in', '1'), ('notification_time_of_day', '20:30')",
    );
    await raw.close();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// Runs raw statements against the seeded v13 file, before the migration.
  Future<void> withRawSql(
      Future<void> Function(_RawSqlDatabase db) body) async {
    final raw = _RawSqlDatabase(NativeDatabase(dbFile));
    await body(raw);
    await raw.close();
  }

  Future<AppDatabase> openMigrated() async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get(); // triggers onUpgrade
    return db;
  }

  Future<List<_SettingRow>> vitaminDRows(AppDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT baby_id, item_id, enabled FROM reminder_settings "
          "WHERE item_id = 'vitamine_d' ORDER BY baby_id",
        )
        .get();
    return [
      for (final row in rows)
        (
          babyId: row.read<String>('baby_id'),
          enabled: row.read<int>('enabled'),
        ),
    ];
  }

  test('a parent who turned vitamin D off stays off — the seed only inserts',
      () async {
    await withRawSql((raw) => raw.customStatement(
          "INSERT INTO reminder_settings (baby_id, item_id, enabled) "
          "VALUES ('baby-AAA', 'vitamine_d', 0)",
        ));

    final db = await openMigrated();
    expect(db.schemaVersion, 14);

    // The explicit off survives byte-for-byte: the migration has no UPDATE.
    final rows = await vitaminDRows(db);
    expect(rows, hasLength(2));
    final mine = rows.firstWhere((r) => r.babyId == 'baby-AAA');
    expect(mine.enabled, 0,
        reason: 'D-R1: the seed never turns a reminder back on');

    // The profileless scope had no vitamin D row at all, so it is seeded —
    // that is the documented behaviour of §3, and it inserts, it never updates.
    expect(rows.firstWhere((r) => r.babyId == '').enabled, 1);
    final untouched = await db
        .customSelect(
          "SELECT baby_id, enabled FROM reminder_settings "
          "WHERE item_id = 'face_cleaning'",
        )
        .get();
    expect(untouched, hasLength(1));
    expect(untouched.single.read<String>('baby_id'), '');
    expect(untouched.single.read<int>('enabled'), 0);
  });

  test('a v13 scope with no vitamin D row gains an explicit enabled = 1 row',
      () async {
    final db = await openMigrated();

    final rows = await vitaminDRows(db);
    expect(rows.map((r) => r.babyId), ['', 'baby-AAA'],
        reason: 'the sentinel scope and every existing profile are both '
            'pre-existing scopes (§3): both keep the reminder');
    expect(rows.every((r) => r.enabled == 1), isTrue,
        reason: 'the seed writes enabled = 1, never 0');

    // Nothing else moved.
    expect(await db.select(db.babyProfiles).get(), hasLength(1));
    expect(await db.select(db.trackingEvents).get(), hasLength(2));
    expect(await db.select(db.reminderDismissals).get(), hasLength(1));
    expect(await db.select(db.customReminders).get(), hasLength(1));
    expect(await db.select(db.measurements).get(), hasLength(1));
    expect(await db.select(db.reminderCompletions).get(), hasLength(1));
    expect(await db.select(db.appSettings).get(), hasLength(2));
    expect(await db.select(db.reminderSettings).get(), hasLength(4),
        reason: 'the two v13 rows plus two seeded vitamin D rows');
  });

  test('the seed is idempotent and never overwrites an existing row', () async {
    // A second baby whose vitamin D is already off, so a re-run has one scope
    // to leave alone and one to (attempt to) re-insert.
    await withRawSql((raw) async {
      await raw.customStatement(
        "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
        "VALUES ('baby-BBB', 'Noé', 1700000000000, 0)",
      );
      await raw.customStatement(
        "INSERT INTO reminder_settings (baby_id, item_id, enabled) "
        "VALUES ('baby-BBB', 'vitamine_d', 0)",
      );
    });

    final db = await openMigrated();
    final afterMigration = await vitaminDRows(db);
    expect(afterMigration, hasLength(3)); // '', baby-AAA, baby-BBB

    // Re-run the statement twice: the NOT EXISTS guard inserts nothing, and the
    // parent's off stays off.
    await db.customStatement(_seedVitaminD);
    await db.customStatement(_seedVitaminD);

    final after = await vitaminDRows(db);
    expect(after.map((r) => r.babyId), ['', 'baby-AAA', 'baby-BBB']);
    expect(after.firstWhere((r) => r.babyId == 'baby-BBB').enabled, 0,
        reason: 'a re-run must not resurrect a reminder the parent turned off');
    expect(after.firstWhere((r) => r.babyId == '').enabled, 1);
  });

  test('every v14 column exists after the migration, NULL except removed',
      () async {
    final db = await openMigrated();

    final info =
        await db.customSelect("PRAGMA table_info('reminder_settings')").get();
    expect(
        info.map((r) => r.read<String>('name')),
        [
          'baby_id',
          'item_id',
          'enabled',
          ..._v14Columns,
        ],
        reason: 'the ALTER order is the drift declaration order — parity with '
            'a fresh install depends on it');

    final row = await db
        .customSelect(
          "SELECT * FROM reminder_settings WHERE baby_id = 'baby-AAA' "
          "AND item_id = 'vitamine_k'",
        )
        .getSingle();
    for (final column in _v14Columns.where((c) => c != 'removed')) {
      expect(row.data[column], isNull, reason: '$column must default to NULL');
    }
    expect(row.read<int>('removed'), 0);

    // The NOT NULL column really is NOT NULL (SQLite would have refused the
    // ALTER on a populated table without its DEFAULT).
    final notNull = {
      for (final r in info) r.read<String>('name'): r.read<int>('notnull') == 1,
    };
    expect(notNull['removed'], isTrue);
    expect(notNull['time'], isFalse);
  });

  test('a fresh install lands on v14 with the columns and no seeded rows',
      () async {
    final freshFile = File('${tempDir.path}/fresh.db');
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(freshFile)));
    addTearDown(db.close);

    expect(db.schemaVersion, 14);
    await db.customSelect('SELECT 1').get(); // triggers onCreate

    final info =
        await db.customSelect("PRAGMA table_info('reminder_settings')").get();
    expect(info.map((r) => r.read<String>('name')),
        containsAll(<String>[..._v14Columns, 'enabled']));

    // The seed lives in the migration, not in an insert path: a fresh database
    // is created at v14 and must therefore be empty of phantom rows.
    expect(await db.select(db.reminderSettings).get(), isEmpty,
        reason: 'a fresh install created at v14 has no settings rows at all');
  });
}

typedef _SettingRow = ({String babyId, int enabled});

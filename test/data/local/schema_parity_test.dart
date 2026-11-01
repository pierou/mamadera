import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';

/// Empty [GeneratedDatabase] shell: raw SQL code written to a file, without any...
/// Table defined by the drift framework. It has the same structure as `migration_v10_to_v11_test.dart`.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 10;
}

/// Structure of a table, reduced to the elements that must be consistent between two databases:
/// columns (name, type, NOT NULL, primary key) and indexes.
typedef _TableStructure = ({
  List<String> columns,
  List<String> indexes,
});

/// Whether fresh or frozen, the base must have **the same structure**.
///
/// Why this file exists: This repository has already delivered two versions that are identical.
/// type — `reminder_settings` declared but never created by `onUpgrade`.
/// (corrected in version 8), and the v11 indexes that were created during the migration but are missing from...
/// `onCreate`, which are therefore unavailable on a fresh installation. No tests were performed.
/// The migration process can only view the second [database]; it only compares a migrated database to itself.
/// the same. The only test that detects this is one that compares a new base to a...
/// The base is built upon this file.
///
/// The comparison focuses on the actual structure, not the SQL text itself.
/// `BOOLEAN DEFAULT 1 NOT NULL` and `BOOLEAN NOT NULL DEFAULT 1` are the same.
/// table, and pasting it in a "drift" format would make the test unreliable without it.
/// rendre plus vrai.
/// Tables that v11 creates or rebuilds – the scope within which `onCreate` and...
/// The `onUpgrade` function should produce the same result.
///
/// `baby_profiles` et `tracking_events` en sont volontairement absentes : v11
/// Do not modify them, and comparing them would reveal discrepancies in their formatting.
/// `drift` (`INTEGER`) and `seed` (`TIMESTAMP`) values that existed before this release, which...
/// noieraient le signal.
const List<String> _v11Tables = [
  'custom_reminders',
  'measurements',
  'reminder_completions',
  'reminder_dismissals',
  'reminder_settings',
];

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_schema_parity');
    // Two datasets within the same test, but located in **two separate files**:
    // The drift warning applies to two bases running on the same executor, which...
    // This is not the case. Without this flag, each test buries its result under...
    // a ten-line stack trace.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// Index of a table: name + columns, sorted (the order of creation is not relevant).
  /// meaning, and the content itself has one).
  Future<List<String>> indexesOf(GeneratedDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA index_list("$table")').get();
    final indexes = <String>[];
    for (final row in rows) {
      final indexName = row.read<String>('name');
      final columns =
          await db.customSelect('PRAGMA index_info("$indexName")').get();
      indexes.add(
        '$indexName('
        '${columns.map((c) => c.data['name'] ?? '?').join(',')}'
        ')',
      );
    }
    return indexes..sort();
  }

  /// Effective structure for all tables within an open database.
  Future<Map<String, _TableStructure>> structureOf(GeneratedDatabase db) async {
    final names = (await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              'AND name NOT LIKE \'sqlite_%\' ORDER BY name',
            )
            .get())
        .map((row) => row.read<String>('name'))
        .toList();

    final result = <String, _TableStructure>{};
    for (final table in names) {
      final columns =
          await db.customSelect('PRAGMA table_info("$table")').get();
      result[table] = (
        columns: columns
            .map((c) => [
                  c.read<String>('name'),
                  _affinityOf(c.read<String>('type')),
                  c.read<int>('notnull') == 1 ? 'NOT NULL' : 'NULL',
                  c.read<int>('pk') > 0 ? 'PK${c.read<int>('pk')}' : '',
                  _normaliseDefault(c.data['dflt_value']),
                ].join('|'))
            .toList(),
        indexes: await indexesOf(db, table),
      );
    }
    return result;
  }

  /// Index of a table: name + columns, sorted (the order of creation is not relevant).
  /// meaning, and the content itself has one).

  Future<AppDatabase> freshDatabase() async {
    final file = File('${tempDir.path}/fresh.db');
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(file)));
    await db.customSelect('SELECT 1').get(); // triggers onCreate.
    return db;
  }

  /// Physical base v10 (the schema as described by `schema.sql` in version 10),
  /// Available through real-time migration up to version 11.
  Future<AppDatabase> migratedDatabase() async {
    final file = File('${tempDir.path}/migrated.db');
    final raw = _RawSqlDatabase(NativeDatabase(file));
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
        quantity    REAL
      )''');
    await raw.customStatement('''
      CREATE TABLE reminder_dismissals (
        item_id     TEXT PRIMARY KEY NOT NULL,
        dismissed_at TIMESTAMP            NOT NULL
      )''');
    await raw.customStatement('''
      CREATE TABLE reminder_settings (
        item_id TEXT PRIMARY KEY NOT NULL,
        enabled BOOLEAN NOT NULL
      )''');
    await raw.customStatement('''
      CREATE TABLE custom_reminders (
        id            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        label         TEXT                              NOT NULL,
        subtype_value TEXT                              NOT NULL,
        frequency     TEXT                              NOT NULL,
        interval_days INTEGER
      )''');
    await raw.close();

    final db = AppDatabase(LazyDatabase(() => NativeDatabase(file)));
    await db.customSelect('SELECT 1').get(); // triggers the onUpgrade event.
    return db;
  }

  test('a fresh install and a v10-upgraded database have the same tables',
      () async {
    final fresh = await freshDatabase();
    final migrated = await migratedDatabase();
    addTearDown(fresh.close);
    addTearDown(migrated.close);

    final freshSchema = await structureOf(fresh);
    final migratedSchema = await structureOf(migrated);

    expect(freshSchema.keys.toList()..sort(),
        equals(migratedSchema.keys.toList()..sort()));
  });

  test(
      'every table has the same columns, nullability, keys and defaults '
      'whether fresh or migrated', () async {
    final fresh = await freshDatabase();
    final migrated = await migratedDatabase();
    addTearDown(fresh.close);
    addTearDown(migrated.close);

    final freshSchema = await structureOf(fresh);
    final migratedSchema = await structureOf(migrated);

    for (final table in _v11Tables) {
      expect(
        freshSchema[table]!.columns,
        equals(migratedSchema[table]!.columns),
        reason: 'colonnes différentes pour `$table` entre neuf et migré',
      );
    }
  });

  test(
      'every index exists on a fresh install too — the v11 gap that only '
      'showed on new phones', () async {
    final fresh = await freshDatabase();
    final migrated = await migratedDatabase();
    addTearDown(fresh.close);
    addTearDown(migrated.close);

    final freshSchema = await structureOf(fresh);
    final migratedSchema = await structureOf(migrated);

    for (final table in _v11Tables) {
      expect(
        freshSchema[table]!.indexes,
        equals(migratedSchema[table]!.indexes),
        reason: 'index différents pour `$table` entre neuf et migré',
      );
    }

    // Explicit check for the corrected defect: both v11 indexes must be...
    // On both sides, not just documented in the schema.sql file.
    for (final indexes in [
      freshSchema['measurements']!.indexes,
      migratedSchema['measurements']!.indexes,
    ]) {
      expect(
        indexes,
        contains(startsWith('idx_measurements_baby_kind_recorded')),
        reason: 'index des mesures manquant',
      );
    }
    for (final indexes in [
      freshSchema['reminder_completions']!.indexes,
      migratedSchema['reminder_completions']!.indexes,
    ]) {
      expect(
        indexes,
        contains(startsWith('idx_reminder_completions_baby_item')),
        reason: 'index des achèvements manuels manquant',
      );
    }
  });
}

/// SQLite storage affinity, not the declared name: `TIMESTAMP` (the name).
/// that these columns in the seed v10) and `INTEGER` (which is what drift.
/// declares) **are the same column** — SQLite stores an exact integer of the same...
/// The approach is the same in both cases, and that's the behavior we want to be consistent.
/// Comparing the names would cause the test to fail on a minor grammatical detail, which...
/// It's exactly the kind of alarm that makes people stop paying attention to alarms.
String _affinityOf(String declaredType) {
  final t = declaredType.toUpperCase();
  // In this context, "INT" and "NUMERIC" are treated as equivalent: the "drift" function writes an integer value.
  // `recorded_at`/`dismissed_at`, and a declared `TIMESTAMP` column inherited from another table.
  // It has a NUMERIC affinity and stores the same integer value. Only a TEXT string can be placed between them.
  // Having both would be a real flaw.
  if (t.contains('INT') || t == 'NUMERIC') return 'NUMBER';
  if (t.contains('CHAR') || t.contains('CLOB') || t.contains('TEXT')) {
    return 'TEXT';
  }
  if (t.contains('BLOB')) return 'BLOB';
  if (t.contains('REAL') || t.contains('FLOA') || t.contains('DOUB')) {
    return 'REAL';
  }
  return 'NUMBER';
}

/// Default normalization: `''` and `<absent>` are treated as the same thing – not.
/// By default, the default value for SQL is NULL, and it is the `NOT NULL` constraint that enforces this.
/// The constraint here is that quotation marks and syntax spaces are meaningless.
String _normaliseDefault(Object? raw) {
  if (raw == null) return '';
  return raw.toString().replaceAll(RegExp(r"[\s']"), '').toUpperCase();
}

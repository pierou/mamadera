import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';

/// Coquille [GeneratedDatabase] vide : du SQL brut sur un fichier, sans aucune
/// table définie par drift. Même forme que `migration_v10_to_v11_test.dart`.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 10;
}

/// Structure d'une table, réduite à ce qui doit coïncider entre deux bases :
/// colonnes (nom, type, NOT NULL, clé primaire) et index.
typedef _TableStructure = ({
  List<String> columns,
  List<String> indexes,
});

/// Fraîche ou migrée, la base doit avoir **la même structure**.
///
/// Pourquoi ce fichier existe : ce dépôt a déjà livré deux écarts du même
/// genre — `reminder_settings` déclarée puis jamais créée par `onUpgrade`
/// (corrigée en v8), et les index v11 créés dans la migration mais absents de
/// `onCreate`, donc introuvables sur une installation neuve. Aucun test de
/// migration ne peut voir le second : il ne compare qu'une base migrée à elle-
/// même. Le seul test qui le voit est celui qui compare une base neuve à une
/// base montée — c'est ce fichier.
///
/// La comparaison porte sur la structure effective, pas sur le texte SQL :
/// `BOOLEAN DEFAULT 1 NOT NULL` et `BOOLEAN NOT NULL DEFAULT 1` sont la même
/// table, et coller au format de drift rendrait le test fragile sans le
/// rendre plus vrai.
/// Tables que v11 crée ou reconstruit — le périmètre où `onCreate` et
/// `onUpgrade` doivent produire la même chose.
///
/// `baby_profiles` et `tracking_events` en sont volontairement absentes : v11
/// ne les touche pas, et les comparer ferait remonter des écarts de typage
/// drift (`INTEGER`) / seed (`TIMESTAMP`) antérieurs à cette release, qui
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
    // Deux bases dans un même test, mais sur **deux fichiers distincts** :
    // l'avertissement de drift vise deux bases sur le même executor, ce qui
    // n'est pas ce cas. Sans ce drapeau, chaque test noie son résultat sous
    // une stack trace de dix lignes.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// Index d'une table : nom + colonnes, trié (l'ordre de création n'a pas de
  /// sens, le contenu en a un).
  Future<List<String>> indexesOf(GeneratedDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA index_list("$table")').get();
    final indexes = <String>[];
    for (final row in rows) {
      final indexName = row.read<String>('name');
      final columns = await db
          .customSelect('PRAGMA index_info("$indexName")')
          .get();
      indexes.add(
        '$indexName('
        '${columns.map((c) => c.data['name'] ?? '?').join(',')}'
        ')',
      );
    }
    return indexes..sort();
  }

  /// Structure effective de toutes les tables d'une base ouverte.
  Future<Map<String, _TableStructure>> structureOf(GeneratedDatabase db) async {
    final names = (await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      'AND name NOT LIKE \'sqlite_%\' ORDER BY name',
    ).get())
        .map((row) => row.read<String>('name'))
        .toList();


    final result = <String, _TableStructure>{};
    for (final table in names) {
      final columns = await db
          .customSelect('PRAGMA table_info("$table")')
          .get();
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

  /// Index d'une table : nom + colonnes, trié (l'ordre de création n'a pas de
  /// sens, le contenu en a un).

  Future<AppDatabase> freshDatabase() async {
    final file = File('${tempDir.path}/fresh.db');
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(file)));
    await db.customSelect('SELECT 1').get(); // déclenche onCreate
    return db;
  }

  /// Base v10 physique (le schéma tel que `schema.sql` le décrivait à v10),
  /// ouverte par la migration réelle jusqu'à v11.
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
    await db.customSelect('SELECT 1').get(); // déclenche onUpgrade
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

    // Verrou explicite du défaut corrigé : les deux index v11 doivent être
    // là des deux côtés, pas seulement documentés dans schema.sql.
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

/// Affinité de stockage SQLite, et non le nom déclaré : `TIMESTAMP` (le nom
/// que portaient ces colonnes dans le seed v10) et `INTEGER` (ce que drift
/// déclare) **sont la même colonne** — SQLite range un entier exact de la même
/// façon dans les deux, et c'est le comportement qu'on veut identique.
/// Comparer les noms ferait échouer le test sur un détail de grammaire, ce qui
/// est exactement le genre d'alarme qui fait cesser de lire les alarmes.
String _affinityOf(String declaredType) {
  final t = declaredType.toUpperCase();
  // INT et NUMERIC comptent comme la même chose : drift écrit un entier dans
  // `recorded_at`/`dismissed_at`, et une colonne héritée déclarée `TIMESTAMP`
  // a l'affinité NUMERIC et range ce même entier. Seul un TEXT coincé entre
  // les deux serait un vrai défaut.
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

/// Default normalisé : `''` et `<absent>` comptent comme la même chose — pas
/// de default est le default SQL, qui est NULL, et c'est `NOT NULL` qui porte
/// la contrainte ici. Les guillemets et espaces de syntaxe n'ont pas de sens.
String _normaliseDefault(Object? raw) {
  if (raw == null) return '';
  return raw.toString().replaceAll(RegExp(r"[\s']"), '').toUpperCase();
}

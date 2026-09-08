import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';

/// Coquille [GeneratedDatabase] vide servant uniquement à exécuter du SQL brut
/// sur un fichier, sans aucune table définie par drift.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 8;
}

/// Régression de la migration v9 : ajout de la colonne `texture`
/// (consistance des selles) sur `tracking_events`.
///
/// Deux choses sont vérifiées, parce que ce sont les deux façons dont une
/// migration de colonne peut silencieusement abîmer des données :
/// 1. la colonne existe après montée, donc la première sauvegarde depuis
///    l'appareil n'échoue pas sur « no such column: texture » ;
/// 2. les changes déjà enregistrées restent à NULL — on n'invente pas la
///    consistance d'un change noté avant cette option.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v9');
    dbFile = File('${tempDir.path}/mamadera_v8.db');

    // Base v8 physique, telle que lib/data/local/schema.sql (v8) la décrit.
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
    // Une couche enregistrée avant l'option, avec une couleur.
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
    // Lue via Drift : la colonne existe, et l'ancienne ligne est intacte.
    expect(events.first.color, equals('jaune_moutarde'));
    expect(events.first.texture, equals(null));
    expect(db.schemaVersion, equals(9));
  });

  test('a diaper saved after the upgrade can store a texture', () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    await db.into(db.trackingEvents).insert(TrackingEventsCompanion.insert(
          type: 'caca',
          timestamp: DateTime.utc(2026, 9, 1),
          wasteType: const Value('caca'),
          color: const Value('vert_olive'),
          texture: const Value('pateuse'),
        ));

    final rows = await db.select(db.trackingEvents).get();
    final fresh = rows.firstWhere((r) => r.texture != null);
    expect(fresh.texture, equals('pateuse'));
    // Et l'ancienne ligne n'a pas été touchée par l'écriture.
    expect(rows.firstWhere((r) => r.color == 'jaune_moutarde').texture,
      equals(null));
  });
}

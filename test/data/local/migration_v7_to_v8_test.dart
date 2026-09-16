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
  int get schemaVersion => 7;
}

/// Régression de la migration v8 : une base créée avant l'existence de
/// `reminder_settings` (v3..v7) montait en v8 sans que la table soit jamais
/// créée par onUpgrade, et toute lecture/écriture de réglage de rappel
/// échouait avec « no such table: reminder_settings ».
///
/// Ce test reconstruit physiquement une base v7 (schéma v7 de
/// lib/data/local/schema.sql, sans reminder_settings), ouvre AppDatabase sur
/// le même fichier et prouve que la table existe ensuite et est writable.
void main() {
  test('opening a v7 database (no reminder_settings) upgrades it to a writable v8', () async {
    final tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v7');
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });
    final dbFile = File('${tempDir.path}/mamadera_v7.db');

    // 1. Base v7 physique : tables existantes à la v7, user_version 7,
    //    SANS reminder_settings (le bug : elle n'existait pas alors).
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

    // Prémisse : la table n'existe vraiment pas à ce stade.
    final premise = _RawSqlDatabase(NativeDatabase(dbFile));
    await expectLater(
      premise.customStatement('SELECT * FROM reminder_settings'),
      throwsA(anything), // « no such table: reminder_settings »
    );
    await premise.close();

    // 2. AppDatabase sur le même fichier : onUpgrade v7 → v8 doit s'exécuter.
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    await db.select(db.babyProfiles).get(); // force ouverture + migrations.

    // La table existe maintenant et est writable.
    await db.into(db.reminderSettings).insert(
      const ReminderSettingsCompanion(
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

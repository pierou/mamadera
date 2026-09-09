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
  int get schemaVersion => 9;
}

/// Régression de la migration v10 : création de `custom_reminders`, la table des
/// rappels inventés par le parent.
///
/// Le risque n°1 d'une migration « créer une table » n'est pas la table neuve —
/// c'est ce qui entoure : ici `reminder_settings` porte l'extinction de chaque
/// rappel, y compris celle des rappels personnalisés (`custom_<id>`). Une
/// migration qui la recréerait éteindrait d'un coup tous les rappels que le
/// parent a pris la peine de couper. Les tests vérifient donc d'abord que les
/// lignes anciennes survivent, puis que la nouvelle table est utilisable et
/// revisitée après fermeture.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v10');
    dbFile = File('${tempDir.path}/mamadera_v9.db');

    // Base v9 physique, telle que lib/data/local/schema.sql (v9) la décrit.
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
    // Un préréglé éteint avant la mise à jour : il doit rester éteint après.
    await raw.customStatement(
      "INSERT INTO reminder_settings (item_id, enabled) VALUES ('vitamine_k', 0)",
    );
    await raw.customStatement(
      "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
      "VALUES ('baby_1', 'Bébé Test', 1756600000000, 1)",
    );
    await raw.close();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('a v9 database gains custom_reminders and keeps its reminder settings',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    expect(db.schemaVersion, equals(10));
    expect(await db.getAllCustomReminders(), isEmpty);

    // Le rappel éteint avant la mise à jour l'est toujours : la migration n'a
    // pas touché à reminder_settings.
    final enabled = await db.getAllReminderSettings();
    expect(enabled, hasLength(1));
    expect(enabled.single.itemId, equals('vitamine_k'));
    expect(enabled.single.enabled, isFalse);

    final profiles = await db.getAllBabyProfiles();
    expect(profiles.single.name, equals('Bébé Test'));
  });

  test('a custom reminder written after the upgrade is readable and linked',
      () async {
    var db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    final id = await db.into(db.customReminders).insert(
          CustomRemindersCompanion.insert(
            label: 'Crème du change',
            subtypeValue: 'nettoyage_nez',
            frequency: 'every_n_days',
            intervalDays: const Value(3),
          ),
        );
    // L'extinction du rappel personnalisé vit dans l'autre table, sous sa clé.
    await db.customStatement(
      'INSERT INTO reminder_settings (item_id, enabled) VALUES (?, ?)',
      ['custom_$id', 0],
    );
    await db.close();

    // Rouverture sur le même fichier : ce qui a été écrit est réellement en
    // base, et pas seulement en cache de connexion.
    db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    final reminders = await db.getAllCustomReminders();
    expect(reminders, hasLength(1));
    expect(reminders.single.id, equals(id));
    expect(reminders.single.label, equals('Crème du change'));
    expect(reminders.single.frequency, equals('every_n_days'));
    expect(reminders.single.intervalDays, equals(3));

    final enabled = await db.getAllReminderSettings();
    expect(enabled.map((s) => s.itemId), containsAll(['vitamine_k', 'custom_$id']));
  });

  test('several custom reminders come back in creation order', () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    // L'ordre de la liste est celui de l'écran Réglages : insérer dans le
    // désordre (id auto-incrémenté) ne doit pas réordonner les rappels.
    for (final label in ['Deuxième', 'Premier', 'Troisième']) {
      await db.into(db.customReminders).insert(
            CustomRemindersCompanion.insert(
              label: label,
              subtypeValue: 'nettoyage_nez',
              frequency: 'daily',
            ),
          );
    }

    final reminders = await db.getAllCustomReminders();
    expect(reminders.map((r) => r.id), orderedEquals([1, 2, 3]));
  });
}

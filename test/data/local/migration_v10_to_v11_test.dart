import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/data/local/db_constants.dart' as db_const;

/// Coquille [GeneratedDatabase] vide servant uniquement à exécuter du SQL brut
/// sur un fichier, sans aucune table définie par drift.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 10;
}

/// Régression de la migration v11 : re-clés des tables de rappels par bébé,
/// reconstruction de `custom_reminders` (`subtype_value` nullable, `baby_id`,
/// `completion_source`) et création de `measurements` + `reminder_completions`.
///
/// Le risque n°1 n'est pas les tables neuves — ce sont les deux tables
/// reconstruites : `reminder_settings` porte l'extinction de chaque rappel, et
/// les ids de `custom_reminders` sont l'ancre de ces extinctions
/// (`custom_<id>`). Les tests vérifient donc d'abord que les lignes anciennes
/// survivent au copier-renommer, puis que la table reconstruite accepte des
/// écritures sans collision d'ids, et enfin que la clé composite change
/// bien le comportement — le point entier de l'item M.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v11');
    dbFile = File('${tempDir.path}/mamadera_v10.db');

    // Base v10 physique, telle que lib/data/local/schema.sql (v10) la décrit.
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
    await raw.customStatement('''
      CREATE TABLE custom_reminders (
        id            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        label         TEXT                              NOT NULL,
        subtype_value TEXT                              NOT NULL,
        frequency     TEXT                              NOT NULL,
        interval_days INTEGER
      )''');
    // Un préréglé éteint avant la mise à jour : il doit rester éteint après.
    await raw.customStatement(
      "INSERT INTO reminder_settings (item_id, enabled) VALUES ('vitamine_k', 0)",
    );
    await raw.customStatement(
      "INSERT INTO reminder_settings (item_id, enabled) VALUES ('vitamine_d', 1)",
    );
    await raw.customStatement(
      "INSERT INTO reminder_settings (item_id, enabled) VALUES ('custom_7', 1)",
    );
    // Rappel personnalisé à id explicite : cet id est l'ancre de la ligne
    // 'custom_7' ci-dessus, il doit survivre à la reconstruction.
    await raw.customStatement(
      "INSERT INTO custom_reminders (id, label, subtype_value, frequency, interval_days) "
      "VALUES (7, 'Crème du nombril', 'nettoyage_nombril', 'every_n_days', 3)",
    );
    await raw.customStatement(
      "INSERT INTO reminder_dismissals (item_id, dismissed_at) "
      "VALUES ('eye_cleaning', 1768477800)",
    );
    await raw.customStatement(
      "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
      "VALUES ('baby_1', 'Bébé Un', 1756600000000, 1)",
    );
    await raw.customStatement(
      "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
      "VALUES ('baby_2', 'Bébé Deux', 1756700000000, 0)",
    );
    await raw.close();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('a v10 database is upgraded to v11 and the new tables are writable',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    expect(db.schemaVersion, equals(11));

    await db.into(db.measurements).insert(
      MeasurementsCompanion.insert(
        kind: db_const.kindPoids,
        value: 'iv:ciphertext',
        unit: db_const.unitG,
        recordedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.into(db.reminderCompletions).insert(
      ReminderCompletionsCompanion.insert(
        babyId: const Value(db_const.sharedBabyId),
        itemId: 'vitamine_k',
        completedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    expect(await db.select(db.measurements).get(), hasLength(1));
    expect(await db.select(db.reminderCompletions).get(), hasLength(1));
  });

  test('a preset switched off before the upgrade is still off after it',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    // L'extinction écrite avant la montée est conservée par la migration
    // copier-renommer : une migration qui aurait recréé reminder_settings
    // aurait rallumé tous les rappels coupés par le parent.
    final settings = await db.getAllReminderSettings();
    final vitamineK = settings.firstWhere((s) => s.itemId == 'vitamine_k');
    expect(vitamineK.babyId, equals(db_const.sharedBabyId));
    expect(vitamineK.enabled, isFalse);
  });

  test(
      'custom reminder ids survive the rebuild and new inserts do not collide',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    // Les ids sont recopiés explicitement : la clé d'extinction
    // `custom_<id>` de reminder_settings s'y rapporte.
    final migrated = await db.getAllCustomReminders();
    expect(migrated, hasLength(1));
    expect(migrated.single.id, equals(7));
    expect(migrated.single.label, equals('Crème du nombril'));
    expect(migrated.single.babyId, equals(db_const.sharedBabyId));
    expect(migrated.single.subtypeValue, equals('nettoyage_nombril'));
    expect(migrated.single.frequency, equals(db_const.freqEveryNDays));
    expect(migrated.single.intervalDays, equals(3));
    expect(migrated.single.completionSource,
        equals(db_const.completionFromEvents));

    // Le piège AUTOINCREMENT : si la table reconstruite était repartie de 1,
    // cette insertion collerait avec l'id 7 recopié.
    final newId = await db.into(db.customReminders).insert(
      CustomRemindersCompanion.insert(
        babyId: const Value(db_const.sharedBabyId),
        label: 'Gouttes pour le nez',
        frequency: db_const.freqDaily,
        completionSource: const Value(db_const.completionManual),
      ),
    );
    expect(newId, greaterThan(7));
  });

  test(
      'legacy settings rows carry the shared sentinel and the composite key '
      'rejects duplicates', () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    final settings = await db.getAllReminderSettings();
    expect(settings, hasLength(3));
    for (final setting in settings) {
      expect(setting.babyId, equals(db_const.sharedBabyId));
    }

    // La clé composite rejette une seconde ligne « partagée » du même
    // rappel…
    await expectLater(
      db.into(db.reminderSettings).insert(
        ReminderSettingsCompanion.insert(
          babyId: const Value(db_const.sharedBabyId),
          itemId: 'vitamine_k',
          enabled: true,
        ),
      ),
      throwsA(anything),
    );

    // …et accepte une ligne par bébé pour le même item : le point entier
    // de l'item M.
    await db.into(db.reminderSettings).insert(
      ReminderSettingsCompanion.insert(
        babyId: const Value('baby_2'),
        itemId: 'vitamine_k',
        enabled: true,
      ),
    );
    expect(await db.getAllReminderSettings(), hasLength(4));
  });

  test('two babies get independent settings rows for the same reminder',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    await db.into(db.reminderSettings).insert(
      ReminderSettingsCompanion.insert(
        babyId: const Value('baby_1'),
        itemId: 'vitamine_k',
        enabled: true,
      ),
    );
    await db.into(db.reminderSettings).insert(
      ReminderSettingsCompanion.insert(
        babyId: const Value('baby_2'),
        itemId: 'vitamine_k',
        enabled: true,
      ),
    );

    final updated = await (db.update(db.reminderSettings)
          ..where((t) => t.babyId.equals('baby_1') & t.itemId.equals('vitamine_k')))
        .write(const ReminderSettingsCompanion(enabled: Value(false)));
    expect(updated, equals(1));

    final byBaby = {
      for (final s in await db.getAllReminderSettings())
        '${s.babyId}|${s.itemId}': s.enabled,
    };
    expect(byBaby['baby_1|vitamine_k'], isFalse);
    expect(byBaby['baby_2|vitamine_k'], isTrue);
    // La ligne « partagée » écrite avant la montée n'est pas touchée.
    expect(byBaby['|vitamine_k'], isFalse);
  });

  test('dismissals survive the re-key with the shared sentinel', () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    final dismissals = await db.getAllReminderDismissals();
    expect(dismissals, hasLength(1));
    expect(dismissals.single.babyId, equals(db_const.sharedBabyId));
    expect(dismissals.single.itemId, equals('eye_cleaning'));
    // drift relit les dates en zone locale : on compare l'instant, pas la
    // représentation.
    expect(
      dismissals.single.dismissedAt.millisecondsSinceEpoch,
      equals(1768477800 * 1000),
    );
  });

  test('a format-1 backup restore shape lands on the shared sentinel in v11',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    // Document de sauvegarde format 1, tel que l'exporteur v1.1.x l'écrit :
    // cinq sections, pas de measurements ni de reminderCompletions.
    const document = r'''
{
  "exportFormatVersion": 1,
  "generator": "mamadera",
  "appVersion": "1.1.0",
  "databaseSchemaVersion": 10,
  "exportedAt": "2026-01-15T11:50:00.000Z",
  "counts": {
    "babyProfiles": 2,
    "trackingEvents": 0,
    "customReminders": 1,
    "reminderSettings": 3,
    "reminderDismissals": 1
  },
  "babyProfiles": [
    {"id": "baby_1", "name": "Bébé Un", "birthDateEpochMs": 1756600000000, "birthDateUtc": "2025-08-31T00:26:40.000Z", "isActive": true},
    {"id": "baby_2", "name": "Bébé Deux", "birthDateEpochMs": 1756700000000, "birthDateUtc": "2025-09-01T04:13:20.000Z", "isActive": false}
  ],
  "trackingEvents": [],
  "customReminders": [
    {"id": 7, "label": "Crème du nombril", "subtypeValue": "nettoyage_nombril", "frequency": "every_n_days", "intervalDays": 3}
  ],
  "reminderSettings": [
    {"itemId": "vitamine_k", "enabled": false},
    {"itemId": "vitamine_d", "enabled": true},
    {"itemId": "custom_7", "enabled": true}
  ],
  "reminderDismissals": [
    {"itemId": "eye_cleaning", "dismissedAtEpochSeconds": 1768477800, "dismissedAtUtc": "2026-01-15T11:50:00.000Z"}
  ]
}
''';
    final decoded = jsonDecode(document) as Map<String, dynamic>;

    // La restauration v11 de ce document suit la même forme que
    // ImportRepositoryImpl au M4 : effacement complet, lignes de rappels
    // insérées sur la sentinelle partagée, source d'achèvement par défaut
    // 'from_events'. Les nouvelles tables restent vides : le document format
    // 1 ne porte pas de sections pour elles.
    await db.transaction(() async {
      await db.delete(db.customReminders).go();
      await db.delete(db.reminderSettings).go();
      await db.delete(db.reminderDismissals).go();

      for (final rawRow in decoded['customReminders'] as List) {
        final row = rawRow as Map<String, dynamic>;
        await db.into(db.customReminders).insert(
          CustomRemindersCompanion.insert(
            id: Value(row['id'] as int),
            babyId: const Value(db_const.sharedBabyId),
            label: row['label'] as String,
            subtypeValue: Value(row['subtypeValue'] as String),
            frequency: row['frequency'] as String,
            intervalDays: Value(row['intervalDays'] as int?),
            completionSource: const Value(db_const.completionFromEvents),
          ),
        );
      }

      for (final rawRow in decoded['reminderSettings'] as List) {
        final row = rawRow as Map<String, dynamic>;
        await db.into(db.reminderSettings).insert(
          ReminderSettingsCompanion.insert(
            babyId: const Value(db_const.sharedBabyId),
            itemId: row['itemId'] as String,
            enabled: row['enabled'] as bool,
          ),
        );
      }

      for (final rawRow in decoded['reminderDismissals'] as List) {
        final row = rawRow as Map<String, dynamic>;
        await db.into(db.reminderDismissals).insert(
          ReminderDismissalsCompanion.insert(
            babyId: const Value(db_const.sharedBabyId),
            itemId: row['itemId'] as String,
            dismissedAt: DateTime.fromMillisecondsSinceEpoch(
              (row['dismissedAtEpochSeconds'] as int) * 1000,
              isUtc: true,
            ),
          ),
        );
      }
    });

    // Les sections neuves de l'export format 2 restent vides après
    // restauration d'un fichier format 1.
    expect(await db.select(db.measurements).get(), isEmpty);
    expect(await db.select(db.reminderCompletions).get(), isEmpty);

    final reminder = (await db.getAllCustomReminders()).single;
    expect(reminder.id, equals(7));
    expect(reminder.babyId, equals(db_const.sharedBabyId));
    expect(reminder.completionSource, equals(db_const.completionFromEvents));

    final settings = await db.getAllReminderSettings();
    expect(settings, hasLength(3));
    for (final setting in settings) {
      expect(setting.babyId, equals(db_const.sharedBabyId));
    }

    expect(
      (await db.getAllReminderDismissals()).single.babyId,
      equals(db_const.sharedBabyId),
    );
  });
}

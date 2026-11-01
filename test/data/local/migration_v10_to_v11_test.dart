import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/data/local/db_constants.dart' as db_const;

/// Empty [GeneratedDatabase] shell used solely for executing raw SQL queries.
/// on a file, without any tables defined by Drift.
class _RawSqlDatabase extends GeneratedDatabase {
  _RawSqlDatabase(super.e);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 10;
}

/// Migration regression v11: Re-keying of recall tables by baby.
/// reconstruction de `custom_reminders` (`subtype_value` nullable, `baby_id`,
/// `completion_source`) and creation of `measurements` and `reminder_completions`.
///
/// The number one risk isn't new tables; it's the two tables.
/// rebuilt: `reminder_settings` now includes the expiration time for each reminder, and
/// The IDs of `custom_reminders` serve as the key to triggering these shutdowns.
/// (`custom_<id>`). The tests first verify that the older lines...
/// they survive the copy-rename operation, and then the rebuilt table can accept new...
/// collision-free ID assignments, and finally, that the composite key changes.
/// bien le comportement — le point entier de l'item M.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v11');
    dbFile = File('${tempDir.path}/mamadera_v10.db');

    // Physical database structure, as described by the `lib/data/local/schema.sql` file (version 10).
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
    // A preset setting was turned off before the update: it should remain turned off after the update.
    await raw.customStatement(
      "INSERT INTO reminder_settings (item_id, enabled) VALUES ('vitamine_k', 0)",
    );
    await raw.customStatement(
      "INSERT INTO reminder_settings (item_id, enabled) VALUES ('vitamine_d', 1)",
    );
    await raw.customStatement(
      "INSERT INTO reminder_settings (item_id, enabled) VALUES ('custom_7', 1)",
    );
    // Personalized reminder with explicit ID: this ID serves as the anchor for the line.
    // "custom_7," as mentioned above, must survive the reconstruction process.
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

    // The file has been updated to the latest version.
    expect(db.schemaVersion, equals(13));

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

    // The extinction rule, defined before the climb, is preserved through migration.
    // copy-rename: a migration that would have recreated the `reminder_settings`.
    // It would have reactivated all the reminders that the parent had previously disabled.
    final settings = await db.getAllReminderSettings();
    final vitamineK = settings.firstWhere((s) => s.itemId == 'vitamine_k');
    expect(vitamineK.babyId, equals(db_const.sharedBabyId));
    expect(vitamineK.enabled, isFalse);
  });

  test('custom reminder ids survive the rebuild and new inserts do not collide',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    // The IDs are explicitly copied: the kill switch key.
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

    // The AUTOINCREMENT trap: if the rebuilt table started counting from 1 again.
    // This insertion should be linked to the ID number 7 that was copied.
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

    // The composite key rejects a second "shared" row from the same table.
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

    // ...and please use one line per baby for each item: this will be considered the total quantity.
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
          ..where(
              (t) => t.babyId.equals('baby_1') & t.itemId.equals('vitamine_k')))
        .write(const ReminderSettingsCompanion(enabled: Value(false)));
    expect(updated, equals(1));

    final byBaby = {
      for (final s in await db.getAllReminderSettings())
        '${s.babyId}|${s.itemId}': s.enabled,
    };
    expect(byBaby['baby_1|vitamine_k'], isFalse);
    expect(byBaby['baby_2|vitamine_k'], isTrue);
    // The "shared" line written before the climb is not affected.
    expect(byBaby['|vitamine_k'], isFalse);
  });

  test('dismissals survive the re-key with the shared sentinel', () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    final dismissals = await db.getAllReminderDismissals();
    expect(dismissals, hasLength(1));
    expect(dismissals.single.babyId, equals(db_const.sharedBabyId));
    expect(dismissals.single.itemId, equals('eye_cleaning'));
    // Drift recalculates the dates based on the local time zone: it compares the current time, not the date itself.
    // representation.
    expect(
      dismissals.single.dismissedAt.millisecondsSinceEpoch,
      equals(1768477800 * 1000),
    );
  });

  test('a format-1 backup restore shape lands on the shared sentinel in v11',
      () async {
    final db = AppDatabase(LazyDatabase(() => NativeDatabase(dbFile)));
    addTearDown(db.close);

    // Backup file in format 1, as written by the exporter version 1.1.x:
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

    // The v11 revision of this document follows the same format as...
    // ImportRepositoryImpl at M4: complete deletion, including reminder lines.
    // inserted on the shared sentinel, serving as the default completion source.
    // 'from_events'. The new tables remain empty: document format.
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

    // The new sections in the format 2 export remain empty after...
    // Restoring a file in format 1.
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

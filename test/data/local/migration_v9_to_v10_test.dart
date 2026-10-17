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
  int get schemaVersion => 9;
}

/// Migration regression v10: creation of `custom_reminders`, the table for...
/// Reminders created by the parent.
///
/// The number one risk associated with a "create table" migration is not the new table itself.
/// This is what it looks like: here, `reminder_settings` controls the disabling of each [feature/setting].
/// reminder, including personalized reminders (`custom_<id>`). A
/// migration that would recreate it would instantly erase all the memories that the...
/// The parent took the trouble to cut [something]. Therefore, the tests first verify that [something] is properly cut.
/// "Older lines still exist, and the new table is functional."
/// Revised after closure.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_migration_v10');
    dbFile = File('${tempDir.path}/mamadera_v9.db');

    // Physical database v9, as described by the `lib/data/local/schema.sql` file (v9).
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
    // A preset setting was turned off before the update: it should remain turned off after the update.
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

    expect(db.schemaVersion, equals(12));
    expect(await db.getAllCustomReminders(), isEmpty);

    // The reminder that was active before the update remains so: the migration has...
    // No changes made to reminder settings.
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
            babyId: const Value(''),
            label: 'Crème du change',
            subtypeValue: const Value('nettoyage_nez'),
            frequency: 'every_n_days',
            intervalDays: const Value(3),
            completionSource: const Value('from_events'),
          ),
        );
    // The deletion of the personalized reminder is stored in another table, under its corresponding key.
    await db.customStatement(
      'INSERT INTO reminder_settings (item_id, enabled) VALUES (?, ?)',
      ['custom_$id', 0],
    );
    await db.close();

    // Reopening the same file: what has been written is actually saved.
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

    // The order of the list corresponds to the order in the Settings screen: insert into the...
    // The "disorder" field (with an automatically incrementing ID) should not reorder the reminders.
    for (final label in ['Deuxième', 'Premier', 'Troisième']) {
      await db.into(db.customReminders).insert(
            CustomRemindersCompanion.insert(
              babyId: const Value(''),
              label: label,
              subtypeValue: const Value('nettoyage_nez'),
              frequency: 'daily',
              completionSource: const Value('from_events'),
            ),
          );
    }

    final reminders = await db.getAllCustomReminders();
    expect(reminders.map((r) => r.id), orderedEquals([1, 2, 3]));
  });
}

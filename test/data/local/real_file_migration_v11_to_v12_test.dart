import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/data/local/database.dart';

/// Perform a migration from version 11 to version 12 on a **real version 11 file**.
///
/// The v11 file is produced honestly: the v10 → v12 process is running.
/// First, we create the fixture, and then we remove the only thing that v12 adds (the column).
/// We are lowering the `user_version` to 11 and reseeding the sentinel value to an empty string (`''`).
/// that the V12 reassigned – the result is a bit-for-bit copy of what it was.
/// Install version 1.2.0 before updating.
///
/// Why not stop at 11 in the migration process? The guard for the v12 block is...
/// `from < 12`, not `to == 12` – a version 11 schema would open the fixture.
/// v10 and would also execute the v12 block. To create v11, remove...
/// v12 is the only path that doesn't require duplicating the migration code.
void main() {
  group('Migration v11 → v12 sur fichier réel', () {
    late Directory tmp;
    const dbFile = 'mamadera.db';

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mamadera_migr_v11');
      final fixture =
          File('test/data/local/fixtures/mamadera_v10.db').readAsBytesSync();
      await File('${tmp.path}/$dbFile').writeAsBytes(fixture);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    /// Upgrade the fixture from version 10 to the current schema, then revert it
    /// to a genuine version 11: the `unit` column and the eight v14 columns are
    /// dropped, the vitamin D seed rows are deleted, and the `''` sentinel is
    /// re-injected. A file that only pretends to be v11 makes the next upgrade
    /// fail on a duplicate column instead of doing the migration's work.
    Future<void> rollBackToV11({bool addSecondBaby = false}) async {
      final db = await createAppDatabase(directoryPath: tmp.path);
      // The second profile is inserted **before** the backward movement: the base.
      // It's currently running in v12 mode, so there's no risk of it being re-assigned during the upgrade process.
      if (addSecondBaby) {
        await db.customStatement(
            "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
            "VALUES ('baby-BBB', 'Lucas', 1700000000000, 0)");
      }
      await db.customStatement('ALTER TABLE tracking_events DROP COLUMN unit');
      // The same reason this helper already drops `unit`: a migration is not
      // re-runnable (`ALTER TABLE … ADD COLUMN` has no IF NOT EXISTS), so a
      // file that claims to be v11 must not still carry the columns v14 adds —
      // otherwise the next open fails on "duplicate column name: time".
      for (final column in const [
        'time',
        'label',
        'frequency',
        'interval_days',
        'frequency_date',
        'end_date',
        'end_age_months',
        'removed',
      ]) {
        await db.customStatement(
            'ALTER TABLE reminder_settings DROP COLUMN "$column"');
      }
      // Same obligation on the other table v14 touches (M3 added
      // `custom_reminders.frequency_date` to the same migration batch): drop it,
      // or the v14 step dies on "duplicate column name: frequency_date" the
      // moment this helper opens a database written by the current schema.
      await db.customStatement(
          'ALTER TABLE custom_reminders DROP COLUMN frequency_date');
      // And no vitamin D seed row: it comes from a migration this file now
      // pretends never ran, so the v14 step must find its real job here too.
      await db.customStatement(
          "DELETE FROM reminder_settings WHERE item_id = 'vitamine_d'");
      await db.customStatement('PRAGMA user_version = 11');
      // Version 12 has already reassigned the "sentinel" role to the single child: we...
      // It's being adjusted to ensure that the V12 engine has enough work to do.
      await db.customStatement(
          "UPDATE custom_reminders SET baby_id = '' WHERE baby_id != ''");
      await db.customStatement(
          "UPDATE reminder_settings SET baby_id = '' WHERE baby_id != ''");
      await db.customStatement(
          "UPDATE reminder_dismissals SET baby_id = '' WHERE baby_id != ''");
      final version = await db.customSelect('PRAGMA user_version').get();
      expect(version.first.read<int>('user_version'), 11);
      final unitGone = await db
          .customSelect(
              "SELECT COUNT(*) AS n FROM pragma_table_info('tracking_events') "
              "WHERE name = 'unit'")
          .getSingle();
      expect(unitGone.read<int>('n'), 0,
          reason: 'le fichier testé doit être un v11, pas un v12 travesti');
      final settingsColumns = await db
          .customSelect("SELECT COUNT(*) AS n FROM pragma_table_info("
              "'reminder_settings')")
          .getSingle();
      expect(settingsColumns.read<int>('n'), 3,
          reason: 'same class of lie: a v11 file has no v14 column in it');
      final customColumns = await db
          .customSelect("SELECT COUNT(*) AS n FROM pragma_table_info("
              "'custom_reminders')")
          .getSingle();
      expect(customColumns.read<int>('n'), 7,
          reason: 'and the same for custom_reminders: v11 had seven columns');
      await db.close();
    }

    test('montée v11 → v12 : unit backfillé, une seule passe', () async {
      await rollBackToV11();

      final db = await createAppDatabase(directoryPath: tmp.path);

      final events = await db
          .customSelect(
              'SELECT type, subtype, unit FROM tracking_events ORDER BY id')
          .get();
      expect(events.length, 4);
      for (final row in events) {
        final type = row.read<String>('type');
        final subtype = row.read<String?>('subtype');
        // The "backfill" refers to the unit displayed on the screen, and never to a conversion.
        // dodo = min, puree = g, everything else = ml (due to a missing column).
        final expected = type == 'dodo'
            ? 'min'
            : (type == 'miam' && subtype == 'solid')
                ? 'g'
                : 'ml';
        expect(row.read<String>('unit'), expected,
            reason: 'type=$type subtype=$subtype');
      }

      final version = await db.customSelect('PRAGMA user_version').get();
      expect(version.first.read<int>('user_version'), 14);

      final babies = await db.select(db.babyProfiles).get();
      expect(babies.length, 1);
      expect(babies.first.name, 'Léa');

      await db.close();
    });

    test("un seul bébé : les lignes '' sont ré-attribuées", () async {
      await rollBackToV11();

      final db = await createAppDatabase(directoryPath: tmp.path);
      final babyId = (await db.select(db.babyProfiles).get()).single.id;

      for (final table in [
        'custom_reminders',
        'reminder_settings',
        'reminder_dismissals',
        'reminder_completions',
      ]) {
        // v14 (D-R1) deliberately leaves ONE sentinel row behind: the vitamin D
        // seed of the profileless scope, which is a pre-existing scope in its
        // own right and keeps the reminder. This test is about the rows the
        // parent already had, so the seed row is excluded by name rather than
        // pretended away.
        final seed = table == 'reminder_settings'
            ? " AND NOT (item_id = 'vitamine_d' AND baby_id = '')"
            : '';
        final orphans = await db
            .customSelect(
                "SELECT COUNT(*) AS n FROM $table WHERE baby_id = ''$seed")
            .getSingle();
        expect(orphans.read<int>('n'), 0,
            reason:
                '$table : l\'installation à un bébé ne garde pas de ligne orpheline');
        final unassigned = await db
            .customSelect(
                "SELECT COUNT(*) AS n FROM $table WHERE baby_id IS NOT NULL")
            .getSingle();
        final all = await db
            .customSelect("SELECT COUNT(*) AS n FROM $table")
            .getSingle();
        expect(unassigned.read<int>('n'), all.read<int>('n'),
            reason: '$table : toutes les lignes portent le bébé unique');
        if (table == 'custom_reminders') {
          final ids = await db
              .customSelect(
                  'SELECT id, baby_id FROM custom_reminders ORDER BY id')
              .get();
          expect(ids.map((r) => r.read<int>('id')).toList(), [3, 7]);
          for (final row in ids) {
            expect(row.read<String>('baby_id'), babyId);
          }
        }
      }

      await db.close();
    });

    test("plusieurs bébés : on ne devine pas, les lignes restent sans profil",
        () async {
      // Two babies at the beginning of the climb: the written state without a profile.
      // It refers to neither of the two options — decision made on October 4, 2026; never guess.
      await rollBackToV11(addSecondBaby: true);

      final db = await createAppDatabase(directoryPath: tmp.path);
      expect((await db.select(db.babyProfiles).get()).length, 2);

      final customs = await db
          .customSelect("SELECT baby_id FROM custom_reminders ORDER BY id")
          .get();
      expect(customs.map((r) => r.read<String>('baby_id')).toList(), ['', ''],
          reason:
              'deux bébés : la ré-attribution est interdite, la sentinelle reste');
      final settings = await db
          .customSelect('SELECT baby_id, item_id FROM reminder_settings')
          .get();
      // The rows the parent had stay sentinel — nothing may be guessed. v14
      // adds vitamin D rows that are *not* inherited: the seed writes one per
      // pre-existing scope, profiles included (D-R1), which is a new choice,
      // not a re-attribution.
      expect(
        settings
            .where((r) => r.read<String>('item_id') != 'vitamine_d')
            .map((r) => r.read<String>('baby_id'))
            .toSet(),
        {''},
        reason:
            'deux bébés : les lignes héritées ne sont ré-attribuées à personne',
      );
      expect(
        settings
            .where((r) => r.read<String>('item_id') == 'vitamine_d')
            .map((r) => r.read<String>('baby_id'))
            .toSet(),
        {'', 'baby-AAA', 'baby-BBB'},
        reason: 'v14 seeds every pre-existing scope, including both profiles',
      );
      final dismissals = await db
          .customSelect("SELECT baby_id FROM reminder_dismissals")
          .get();
      expect(dismissals.map((r) => r.read<String>('baby_id')).toSet(), {''});

      // The backfill for `unit` is independent of the number of babies.
      final units = await db
          .customSelect('SELECT COUNT(*) AS n FROM tracking_events')
          .getSingle();
      expect(units.read<int>('n'), 4);

      await db.close();
    });
  });
}

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

    /// Upgrade the fixture from version 10 to version 12, then revert it to a genuine version 11.
    /// The `unit` column has been removed, version 11. The `''` sentinel has been re-injected.
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
      expect(version.first.read<int>('user_version'), 13);

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
        final orphans = await db
            .customSelect("SELECT COUNT(*) AS n FROM $table WHERE baby_id = ''")
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
      final settings =
          await db.customSelect("SELECT baby_id FROM reminder_settings").get();
      expect(settings.map((r) => r.read<String>('baby_id')).toSet(), {''});
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

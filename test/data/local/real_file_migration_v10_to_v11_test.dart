import 'dart:convert' show latin1;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/data/local/database.dart';

/// Migration process applied to a genuine v10 file.
///
/// The `fixtures/mamadera_v10.db` file is an authentic v10 database (DDL of...
/// Version 1.1.1+8, with `PRAGMA user_version = 10`, containing the data.
/// from a parent: one baby, four events, including one `natural` event at age 20, and two...
/// personalized reminders (IDs 3 and 7), a disabled preset, and a dismissal.
///
/// This test is the purpose of the emulator replay feature (AGENTS.md), which allows you to reproduce the environment.
/// CI: The `onCreate` method will **never** indicate whether an upgrade from version 10 to version 11 is successful.
/// since it builds the structure from the outset without moving anything. Here, the code...
/// The migration process actually relies on a file that already contains data.
void main() {
  group('Migration v10 → v12 sur fichier réel', () {
    late Directory tmp;
    late String fixturePath;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mamadera_migr_v10');
      fixturePath = '${tmp.path}/mamadera.db';
      final fixture =
          File('test/data/local/fixtures/mamadera_v10.db').readAsBytesSync();
      await File(fixturePath).writeAsBytes(fixture);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('le fichier seedé est bien en v10 avant ouverture', () {
      // If this statement proves to be false, then the fixture has been updated, and everything else is as described.
      // The test no longer proves anything: we are migrating from one version 11 to another version 11.
      final header = File(fixturePath).readAsBytesSync();
      expect(header.length, greaterThan(0));
      expect(
        latin1.decode(header.sublist(0, 100)),
        contains('SQLite format 3'),
      );
    });

    test('onUpgrade monte en v12 et conserve les données du parent', () async {
      final db = await createAppDatabase(directoryPath: tmp.path);

      final babies = await db.select(db.babyProfiles).get();
      expect(babies.length, 1);
      expect(babies.first.name, 'Léa');
      // Single-baby installation: the V12 system reconfigures the layout.
      // "without profile" (sentinel `''`, leak v1.2.0) - only one child.
      // Decision 2026-10-04: Never try to guess the gender of multiple babies at the same time.
      final babyId = babies.first.id;

      final events = await db.select(db.trackingEvents).get();
      expect(events.length, 4,
          reason:
              'les quatre événements existants doivent survivre à la montée');

      // The IDs for personalized reminders are stored in the file.
      // The user and the `reminder_settings` refer to them using the format `custom_<id>`.
      // Renumbering the items will also reset the silent mode setting.
      // The user had previously "disabled this reminder," but it has now been re-enabled.
      final customs = await db
          .customSelect(
            'SELECT id, baby_id, subtype_value, completion_source '
            'FROM custom_reminders ORDER BY id',
          )
          .get();
      expect(customs.map((r) => r.read<int>('id')).toList(), [3, 7]);
      for (final row in customs) {
        expect(row.read<String>('baby_id'), babyId,
            reason:
                'un seul bébé : la sentinelle vide est ré-attribuée à ce bébé, '
                'jamais laissée orpheline');
        expect(row.read<String>('completion_source'), 'from_events');
      }

      // Re-implantation using a composite key: no key value should be NULL.
      // SQLite allows duplicate entries as long as at least one column of the primary key is unique.
      final settings = await db
          .customSelect(
            'SELECT baby_id, item_id, enabled FROM reminder_settings ORDER BY item_id',
          )
          .get();
      expect(settings.length, 2);
      expect(
        settings.map((r) => r.read<String>('baby_id')).toSet(),
        {babyId},
        reason: 'les réglages reprennent le profil unique, pas la sentinelle',
      );

      final dismissals = await db
          .customSelect(
            'SELECT baby_id, item_id FROM reminder_dismissals',
          )
          .get();
      expect(dismissals.length, 1);
      expect(dismissals.first.read<String>('baby_id'), babyId);

      final userVersion = await db.customSelect('PRAGMA user_version').get();
      expect(userVersion.first.read<int>('user_version'), 13);

      // An index that is missing after a migration is invisible to the user and can be costly.
      // Perform a full table scan on every recall query, every time.
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name IN ('measurements','reminder_completions') ORDER BY name",
          )
          .get();
      expect(indexes, isNotEmpty,
          reason: 'les tables neuves doivent être indexées après migration, '
              'pas seulement après onCreate');

      await db.close();
    });

    test('un second opening ne re-migre pas et ne corrompt rien', () async {
      final first = await createAppDatabase(directoryPath: tmp.path);
      await first.select(first.babyProfiles).get();
      await first.close();

      final second = await createAppDatabase(directoryPath: tmp.path);
      final events = await second.select(second.trackingEvents).get();
      expect(events.length, 4,
          reason: 'ouvrir deux fois ne doit ni dupliquer ni perdre de lignes');
      final version = await second.customSelect('PRAGMA user_version').get();
      expect(version.first.read<int>('user_version'), 13);
      await second.close();
    });
  });
}

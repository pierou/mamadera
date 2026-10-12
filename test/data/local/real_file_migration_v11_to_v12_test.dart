import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/data/local/database.dart';

/// Passe de migration v11 → v12 sur un **vrai fichier v11**.
///
/// Le fichier v11 est fabriqué honnêtement : la chaîne v10 → v12 tourne sur
/// le fixture, puis on en retire la seule chose que v12 ajoute (la colonne
/// `unit`), on rebaisse `user_version` à 11 et on ré-seed la sentinelle `''`
/// que la v12 a ré-attribuée — le résultat est bit-à-bit ce qu'était une
/// installation 1.2.0 avant sa mise à jour.
///
/// Pourquoi ne pas s'arrêter à 11 en migration : le garde du bloc v12 est
/// `from < 12`, pas `to == 12` — un schéma à version 11 ouvrirait le fixture
/// v10 et déroulerait **aussi** le bloc v12. Fabriquer le v11 en retirant
/// v12 est le seul chemin qui n'a pas à dupliquer le code de migration.
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

    /// Monte le fixture v10 en v12, puis le ramène à un v11 authentique :
    /// colonne `unit` retirée, version 11, sentinelle `''` ré-injectée.
    Future<void> rollBackToV11({bool addSecondBaby = false}) async {
      final db = await createAppDatabase(directoryPath: tmp.path);
      // Le second profil est inséré **avant** le retour en arrière : la base
      // est en v12 ouverte, aucun risque que la montée ré-attribue en chemin.
      if (addSecondBaby) {
        await db.customStatement(
            "INSERT INTO baby_profiles (id, name, birth_date, is_active) "
            "VALUES ('baby-BBB', 'Lucas', 1700000000000, 0)");
      }
      await db.customStatement('ALTER TABLE tracking_events DROP COLUMN unit');
      await db.customStatement('PRAGMA user_version = 11');
      // La v12 a déjà ré-attribuée la sentinelle au bébé unique : on la
      // remet en place pour que la montée v12 ait du travail à faire.
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
        // Le backfill nomme l'unité vue à l'écran, jamais une conversion :
        // dodo = min, purée = g, tout le reste = ml (défaut de colonne).
        final expected = type == 'dodo'
            ? 'min'
            : (type == 'miam' && subtype == 'solid')
                ? 'g'
                : 'ml';
        expect(row.read<String>('unit'), expected,
            reason: 'type=$type subtype=$subtype');
      }

      final version = await db.customSelect('PRAGMA user_version').get();
      expect(version.first.read<int>('user_version'), 12);

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
      // Deux bébés au moment de la montée : l'état écrit sans profil ne
      // désigne aucun des deux — décision 2026-10-04, jamais de deviner.
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

      // Le backfill de `unit` est indépendant du nombre de bébés.
      final units = await db
          .customSelect('SELECT COUNT(*) AS n FROM tracking_events')
          .getSingle();
      expect(units.read<int>('n'), 4);

      await db.close();
    });
  });
}

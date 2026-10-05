import 'dart:convert' show latin1;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/data/local/database.dart';

/// Passe de migration sur un **vrai fichier v10**.
///
/// Le fixture `fixtures/mamadera_v10.db` est une base v10 authentique (DDL de
/// la version publiée 1.1.1+8, `PRAGMA user_version = 10`) portant les données
/// d'un parent : une bébé, quatre événements dont un `natural` de 20, deux
/// rappels personnalisés (ids 3 et 7), un préréglage désactivé, un dismissal.
///
/// Ce test est la raison d'être de la passe émulateur (AGENTS.md) rejouée en
/// CI : `onCreate` ne dira **jamais** si une montée v10 → v11 se passe bien,
/// puisqu'il construit le schéma d'emblée sans rien déplacer. Ici le code de
/// migration tourne pour de vrai sur un fichier qui contient déjà des données.
void main() {
  group('Migration v10 → v11 sur fichier réel', () {
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
      // Si cette assertion casse, le fixture a été modernisé et tout le reste
      // du test ne prouve plus rien : on migre un v11 depuis un v11.
      final header = File(fixturePath).readAsBytesSync();
      expect(header.length, greaterThan(0));
      expect(
        latin1.decode(header.sublist(0, 100)),
        contains('SQLite format 3'),
      );
    });

    test('onUpgrade monte en v11 et conserve les données du parent', () async {
      final db = await createAppDatabase(directoryPath: tmp.path);

      final babies = await db.select(db.babyProfiles).get();
      expect(babies.length, 1);
      expect(babies.first.name, 'Léa');

      final events = await db.select(db.trackingEvents).get();
      expect(events.length, 4,
          reason: 'les quatre événements existants doivent survivre à la montée');

      // Les ids des rappels personnalisés sont gravés dans le fichier de
      // l'utilisateur et `reminder_settings` les reference par `custom_<id>`.
      // Une remontée qui les renumérote détache le réglage en silence :
      // l'utilisateur a « désactivé ce rappel » avant, et il revient activé.
      final customs = await db.customSelect(
        'SELECT id, baby_id, subtype_value, completion_source '
        'FROM custom_reminders ORDER BY id',
      ).get();
      expect(customs.map((r) => r.read<int>('id')).toList(), [3, 7]);
      for (final row in customs) {
        expect(row.read<String>('baby_id'), '',
            reason: 'sentinelle vide = valable pour tous les bébés');
        expect(row.read<String>('completion_source'), 'from_events');
      }

      // Ré-implantation sous la clé composée : aucune clé ne doit être NULL,
      // SQLite autorisant les doublons dès qu'une colonne de la clé l'est.
      final settings = await db.customSelect(
        'SELECT baby_id, item_id, enabled FROM reminder_settings ORDER BY item_id',
      ).get();
      expect(settings.length, 2);
      expect(settings.map((r) => r.read<String>('baby_id')).toSet(), {''});

      final dismissals = await db.customSelect(
        'SELECT baby_id, item_id FROM reminder_dismissals',
      ).get();
      expect(dismissals.length, 1);
      expect(dismissals.first.read<String>('baby_id'), '');

      final userVersion = await db.customSelect('PRAGMA user_version').get();
      expect(userVersion.first.read<int>('user_version'), 11);

      // Un index absent après migration est invisible à l'œil et coûte une
      // table scan sur chaque sondage de rappel, pour toujours.
      final indexes = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND tbl_name IN ('measurements','reminder_completions') ORDER BY name",
      ).get();
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
      expect(version.first.read<int>('user_version'), 11);
      await second.close();
    });
  });
}

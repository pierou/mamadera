import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/export/data/repositories/export_repository_impl.dart';

/// Fake de chiffrement déterministe : `enc:<texte>` → `<texte>`.
/// Toute valeur commençant par `BAD:` (ou tout texte non chiffrable)
/// déchiffre en null — cas clé perdue/rotée.
class _FakeEncryption extends EncryptionService {
  @override
  String encrypt(String plainText) => 'enc:$plainText';

  @override
  String? decrypt(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return null;
    if (!cipherText.startsWith('enc:')) return null;
    return cipherText.substring('enc:'.length);
  }
}

void main() {
  group('ExportRepositoryImpl', () {
    late AppDatabase database;
    late _FakeEncryption encryption;
    late ExportRepositoryImpl repository;

    setUp(() async {
      final connection = LazyDatabase(NativeDatabase.memory);
      database = AppDatabase(connection);
      // Déclenche la migration pour créer les tables avant toute lecture.
      await database.select(database.reminderDismissals).get();
      encryption = _FakeEncryption();
      repository = ExportRepositoryImpl(database: database, encryption: encryption);
    });

    tearDown(() async {
      await database.close();
    });

    Future<void> seedFullDatabase() async {
      await database.insertBabyProfile(
        BabyProfilesCompanion.insert(
          id: 'baby_1',
          name: 'Bébé Test',
          birthDate: 1700000000000, // millisecondes — nombre rond de l'audit
        ),
      );
      // timestamp stocké en secondes → 1700000000000 ms = 1700000000 s
      final timestamp = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      await database.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'miam',
          timestamp: timestamp,
          subtype: const Value('natural'),
          notes: Value(encryption.encrypt('100 ml vers 8h')),
          babyId: const Value('baby_1'),
          quantity: const Value(100),
        ),
      );
      await database.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'caca',
          timestamp: timestamp,
          wasteType: const Value('caca'),
          color: const Value('meconium'),
          texture: const Value('pateuse'),
          babyId: const Value(null), // row orpheline : doit être exportée
        ),
      );
      await database.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'dodo',
          timestamp: timestamp,
          duration: const Value(60),
          notes: const Value('BAD:rotated-key-ciphertext'),
          babyId: const Value('baby_1'),
        ),
      );
      await database.customStatement(
        'INSERT INTO reminder_settings (item_id, enabled) VALUES (?, ?)',
        ['vitaminD', 1],
      );
      await database.into(database.customReminders).insert(
        CustomRemindersCompanion.insert(
          id: const Value(1),
          label: 'Crème du change',
          subtypeValue: 'nettoyage_nez',
          frequency: 'every_n_days',
          intervalDays: const Value(3),
        ),
      );
      // Le rappel éteint porte la clé de ce rappel personnalisé : c'est le
      // couple qui doit se retrouver à la lecture, pas deux listes séparées.
      await database.customStatement(
        'INSERT INTO reminder_settings (item_id, enabled) VALUES (?, ?)',
        ['custom_1', 0],
      );
      await database.into(database.reminderDismissals).insert(
        ReminderDismissalsCompanion.insert(
          itemId: 'vitaminK',
          dismissedAt: timestamp,
        ),
      );
    }

    group('buildExportJson — base complète', () {
      test('contient les cinq tables avec les bons counts', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;

        final counts = doc['counts'] as Map<String, dynamic>;
        expect(counts['babyProfiles'], 1);
        expect(counts['trackingEvents'], 3);
        expect(counts['customReminders'], 1);
        expect(counts['reminderSettings'], 2);
        expect(counts['reminderDismissals'], 1);
        expect((doc['babyProfiles'] as List).length, 1);
        expect((doc['trackingEvents'] as List).length, 3);
        expect((doc['customReminders'] as List).length, 1);
        expect((doc['reminderSettings'] as List).length, 2);
        expect((doc['reminderDismissals'] as List).length, 1);

        // Un tableau exporté dont le count divergerait serait une sauvegarde
        // menteuse : les deux chiffres viennent de la même lecture.
        final declared = await repository.counts();
        expect(declared.customReminders, counts['customReminders']);
        expect(declared.reminderSettings, counts['reminderSettings']);
      });

      test('métadonnées de document correctes', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;

        expect(doc['exportFormatVersion'], 1);
        expect(doc['generator'], 'mamadera');
        // Informationnel : suivi de la version réelle du schéma, pas un
        // contrat de l'export (un bump de schéma ne doit pas casser ce test).
        expect(doc['databaseSchemaVersion'], database.schemaVersion);
        expect((doc['exportedAt'] as String).endsWith('Z'), isTrue);
        expect(doc.containsKey('appVersion'), isTrue);
        // Jamais de clé, de préférence, de chemin ni d'identifiant d'appareil.
        expect(doc.containsKey('key'), isFalse);
        expect(doc.containsKey('preferences'), isFalse);
        final raw = await repository.buildExportJson();
        expect(raw.contains('/var/'), isFalse);
        expect(raw.contains('/private/'), isFalse);
      });

      test('chaque ligne d\'événement est présente, babyId null inclus', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final events = (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        final orphan = events.where((e) => e['babyId'] == null).toList();
        expect(orphan, hasLength(1));
        expect(orphan.first['type'], 'caca');
        expect(orphan.first['color'], 'meconium');
        expect(orphan.first['texture'], 'pateuse');
      });

      // Une sauvegarde qui omet silencieusement une colonne n'en est pas une :
      // toute ligne exportée porte la clé texture, null compris.
      test('la clé texture est présente sur toutes les lignes exportées', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final events = (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        expect(events, isNotEmpty);
        for (final event in events) {
          expect(event.containsKey('texture'), isTrue,
              reason: 'ligne ${event['type']} exportée sans la clé texture');
        }
        // Une ligne sans consistance s'exporte en null explicite.
        final sleep = events.firstWhere((e) => e['type'] == 'dodo');
        expect(sleep['texture'], isNull);
      });

      test('notes déchiffrées en texte lisible', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final events = (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        final feeding = events.firstWhere((e) => e['type'] == 'miam');
        expect(feeding['notes'], '100 ml vers 8h');
        expect(feeding.containsKey('notesUndecryptable'), isFalse);
      });

      test('ciphertext indisponible → notes null + notesUndecryptable, ligne sans note → pas de flag', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final events = (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        final sleep = events.firstWhere((e) => e['type'] == 'dodo');
        expect(sleep['notes'], isNull);
        expect(sleep['notesUndecryptable'], isTrue);

        // Ligne qui n'a JAMAIS eu de note : null sans flag, comme avant.
        final diaper = events.firstWhere((e) => e['type'] == 'caca');
        expect(diaper['notes'], isNull);
        expect(diaper.containsKey('notesUndecryptable'), isFalse);
      });

      test('timestamp en secondes, birthDate en millisecondes', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final events = (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();
        final profiles = (doc['babyProfiles'] as List).cast<Map<String, dynamic>>();

        expect(events.first['timestampEpochSeconds'], 1700000000);
        expect(events.first['timestampUtc'], '2023-11-14T22:13:20.000Z');
        expect(profiles.first['birthDateEpochMs'], 1700000000000);
        expect(profiles.first['birthDateUtc'], '2023-11-14T22:13:20.000Z');
      });

      test('les rangs de rappels sont exportés avec secondes + ISO', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final settings = (doc['reminderSettings'] as List).cast<Map<String, dynamic>>();
        final dismissals = (doc['reminderDismissals'] as List).cast<Map<String, dynamic>>();

        expect(dismissals.single['itemId'], 'vitaminK');
        expect(dismissals.single['dismissedAtEpochSeconds'], 1700000000);
        expect(dismissals.single['dismissedAtUtc'], '2023-11-14T22:13:20.000Z');
        // Deux lignes de réglages depuis que le rappel personnalisé seedé est
        // éteint : on vise la préréglée par sa clé, pas par sa position.
        expect(
          settings.firstWhere((s) => s['itemId'] == 'vitaminD')['enabled'],
          isTrue,
        );
      });

      test('un rappel éteint sort de la sauvegarde en false, pas effacé', () async {
        // Depuis l'écran Réglages → Rappels, une ligne `enabled = 0` est le cas
        // courant : SQLite la stocke en 0, une restauration doit retrouver false.
        await database.customStatement(
          'INSERT INTO reminder_settings (item_id, enabled) VALUES (?, ?)',
          ['vitamine_d', 0],
        );

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final settings = (doc['reminderSettings'] as List).cast<Map<String, dynamic>>();

        expect(settings.single['itemId'], 'vitamine_d');
        expect(settings.single['enabled'], isFalse);
        expect((doc['counts'] as Map<String, dynamic>)['reminderSettings'], 1);
      });

      // Un rappel personnalisé éteint est stocké sous la clé `custom_<id>` : si
      // la ligne de définition n'est pas exportée, la clé ne pointe plus rien à
      // la restauration et le rappel revient hanté.
      test('l\'extinction d\'un rappel personnalisé reste rattachée à sa définition', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final settings = (doc['reminderSettings'] as List).cast<Map<String, dynamic>>();
        final reminders = (doc['customReminders'] as List).cast<Map<String, dynamic>>();

        expect(reminders.single['id'], 1);
        expect(
          settings.firstWhere((s) => s['itemId'] == 'custom_1')['enabled'],
          isFalse,
        );
      });

      // Le rythme s'exporte en code brut, pas en libellé traduit : un fichier
      // créé en français doit se relire à l'identique sur un téléphone espagnol.
      test('le rythme d\'un rappel personnalisé s\'exporte en code brut', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final reminders = (doc['customReminders'] as List).cast<Map<String, dynamic>>();

        expect(reminders.single, {
          'id': 1,
          'label': 'Crème du change',
          'subtypeValue': 'nettoyage_nez',
          'frequency': 'every_n_days',
          'intervalDays': 3,
        });
      });

      // Un rythme mensuel n'a pas d'intervalle : la clé doit quand même être
      // présente, pour qu'un lecteur de sauvegarde n'ait pas à deviner.
      test('un rappel mensuel exporte intervalDays null plutôt que d\'omettre la clé', () async {
        await database.into(database.customReminders).insert(
          CustomRemindersCompanion.insert(
            label: 'Crème des pieds',
            subtypeValue: 'autre',
            frequency: 'monthly',
          ),
        );

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final reminders = (doc['customReminders'] as List).cast<Map<String, dynamic>>();

        expect(reminders.single.containsKey('intervalDays'), isTrue);
        expect(reminders.single['intervalDays'], isNull);
        expect(reminders.single['frequency'], 'monthly');
      });
    });

    group('base vide', () {
      test('counts tous à zéro et JSON valide', () async {
        final counts = await repository.counts();

        expect(counts.babyProfiles, 0);
        expect(counts.trackingEvents, 0);
        expect(counts.customReminders, 0);
        expect(counts.reminderSettings, 0);
        expect(counts.reminderDismissals, 0);
        expect(counts.isEmpty, isTrue);

        final doc = jsonDecode(await repository.buildExportJson()) as Map<String, dynamic>;
        final jsonCounts = doc['counts'] as Map<String, dynamic>;
        expect(jsonCounts['babyProfiles'], 0);
        expect(jsonCounts['trackingEvents'], 0);
        expect(jsonCounts['customReminders'], 0);
        expect(jsonCounts['reminderSettings'], 0);
        expect(jsonCounts['reminderDismissals'], 0);
        expect((doc['trackingEvents'] as List), isEmpty);
        // Table vide exportée en tableau vide : une clé absente se lirait comme
        // « ancienne version de l'app », pas comme « aucun rappel ».
        expect((doc['customReminders'] as List), isEmpty);
      });
    });
  });
}

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/export/data/repositories/export_repository_impl.dart';

/// Deterministic encryption spoof: `enc:<text>` → `<text>`.
/// Any value that starts with `BAD:` (or any text that cannot be interpreted as a number).
/// Decryption failed – key lost/rotated.
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
      // Trigger the migration process to create the tables before any data is read.
      await database.select(database.reminderDismissals).get();
      encryption = _FakeEncryption();
      repository =
          ExportRepositoryImpl(database: database, encryption: encryption);
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
      // timestamp stored in seconds → 1700000000000 ms = 1700000000 s.
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      await database.insertEvent(
        TrackingEventsCompanion.insert(
          unit: 'ml',
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
          unit: 'ml',

          type: 'caca',
          timestamp: timestamp,
          wasteType: const Value('caca'),
          color: const Value('meconium'),
          texture: const Value('pateuse'),
          babyId: const Value(null), // orphan row: must be exported.
        ),
      );
      await database.insertEvent(
        TrackingEventsCompanion.insert(
          unit: 'min',
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
              subtypeValue: const Value('nettoyage_nez'),
              frequency: 'every_n_days',
              intervalDays: const Value(3),
            ),
          );
      // Loose recall (M4): No related care, manual completion.
      await database.into(database.customReminders).insert(
            CustomRemindersCompanion.insert(
              id: const Value(2),
              label: 'Vitamine du soir',
              subtypeValue: const Value(null),
              completionSource: const Value('manual'),
              frequency: 'weekly',
            ),
          );
      // The reminder itself holds the key to this personalized reminder: it is the...
      // A couple should be presented as a single entity, not as two separate lists.
      await database.customStatement(
        'INSERT INTO reminder_settings (item_id, enabled) VALUES (?, ?)',
        ['custom_1', 0],
      );
      // Scoped setting for baby (M4): The `baby_id` column must be preserved.
      // Instead of focusing on internal collaboration, prioritize export activities.
      await database.customStatement(
        'INSERT INTO reminder_settings (baby_id, item_id, enabled) VALUES (?, ?, ?)',
        ['baby_1', 'vitamine_d', 1],
      );
      await database.into(database.reminderDismissals).insert(
            ReminderDismissalsCompanion.insert(
              itemId: 'vitaminK',
              dismissedAt: timestamp,
            ),
          );
      await database.into(database.reminderDismissals).insert(
            ReminderDismissalsCompanion.insert(
              babyId: const Value('baby_1'),
              itemId: 'vitamine_d',
              dismissedAt: timestamp,
            ),
          );
      await database.into(database.measurements).insert(
            MeasurementsCompanion.insert(
              id: const Value(101),
              babyId: const Value('baby_1'),
              kind: 'poids',
              value: encryption.encrypt('3400'),
              unit: 'g',
              recordedAt: timestamp,
              notes: Value(encryption
                  .encrypt('Première pesée')), // nombre rond de l'audit
            ),
          );
      // Orphaned measure: the export function never filters.
      await database.into(database.measurements).insert(
            MeasurementsCompanion.insert(
              id: const Value(102),
              kind: 'taille',
              value: encryption.encrypt('48'),
              unit: 'cm',
              recordedAt: timestamp,
            ),
          );
      // Key turned: the counter starts at zero, as indicated by the flag.
      await database.into(database.measurements).insert(
            MeasurementsCompanion.insert(
              id: const Value(103),
              babyId: const Value('baby_1'),
              kind: 'temperature',
              value: 'BAD:rotated-key-ciphertext',
              unit: 'degC',
              recordedAt: timestamp,
            ),
          );
      await database.into(database.reminderCompletions).insert(
            ReminderCompletionsCompanion.insert(
              itemId: 'custom_1',
              completedAt: timestamp,
            ),
          );
      await database.into(database.reminderCompletions).insert(
            ReminderCompletionsCompanion.insert(
              babyId: const Value('baby_1'),
              itemId: 'custom_2',
              completedAt: timestamp,
            ),
          );
    }

    group('buildExportJson — base complète', () {
      test('contient les sept tables avec les bons counts', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;

        final counts = doc['counts'] as Map<String, dynamic>;
        expect(counts['babyProfiles'], 1);
        expect(counts['trackingEvents'], 3);
        expect(counts['customReminders'], 2);
        expect(counts['reminderSettings'], 3);
        expect(counts['reminderDismissals'], 2);
        expect(counts['measurements'], 3);
        expect(counts['reminderCompletions'], 2);
        expect((doc['babyProfiles'] as List).length, 1);
        expect((doc['trackingEvents'] as List).length, 3);
        expect((doc['customReminders'] as List).length, 2);
        expect((doc['reminderSettings'] as List).length, 3);
        expect((doc['reminderDismissals'] as List).length, 2);
        expect((doc['measurements'] as List).length, 3);
        expect((doc['reminderCompletions'] as List).length, 2);

        // A table that is exported but has a different row count would be a backup.
        // liar: both figures come from the same source.
        final declared = await repository.counts();
        expect(declared.customReminders, counts['customReminders']);
        expect(declared.reminderSettings, counts['reminderSettings']);
        expect(declared.measurements, counts['measurements']);
        expect(declared.reminderCompletions, counts['reminderCompletions']);
      });

      test('métadonnées de document correctes', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;

        // Format 3 (v12): Each event has its own `unit`. Format 2 (M4).
        // It added the two new sections and the `babyId` fields; a...
        // The reader for this build only accepts values above 3, and no values below 3.
        expect(doc['exportFormatVersion'], 3);
        expect(doc['generator'], 'mamadera');
        // Informational: Tracks the actual version of the schema, not a mock-up.
        // export contract (a schema change should not break this test).
        expect(doc['databaseSchemaVersion'], database.schemaVersion);
        expect((doc['exportedAt'] as String).endsWith('Z'), isTrue);
        expect(doc.containsKey('appVersion'), isTrue);
        // Ideally, avoid using keys, paths, or device identifiers.
        expect(doc.containsKey('key'), isFalse);
        expect(doc.containsKey('preferences'), isFalse);
        final raw = await repository.buildExportJson();
        expect(raw.contains('/var/'), isFalse);
        expect(raw.contains('/private/'), isFalse);
      });

      test('chaque ligne d\'événement est présente, babyId null inclus',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final events =
            (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        final orphan = events.where((e) => e['babyId'] == null).toList();
        expect(orphan, hasLength(1));
        expect(orphan.first['type'], 'caca');
        expect(orphan.first['color'], 'meconium');
        expect(orphan.first['texture'], 'pateuse');
      });

      // A backup that silently omits a column is not a true backup.
      // Every line exported includes the "texture" key, with a value of "null".
      test('la clé texture est présente sur toutes les lignes exportées',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final events =
            (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        expect(events, isNotEmpty);
        for (final event in events) {
          expect(event.containsKey('texture'), isTrue,
              reason: 'ligne ${event['type']} exportée sans la clé texture');
        }
        // A line without substance is exported as a null value.
        final sleep = events.firstWhere((e) => e['type'] == 'dodo');
        expect(sleep['texture'], isNull);
      });

      test('notes déchiffrées en texte lisible', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final events =
            (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        final feeding = events.firstWhere((e) => e['type'] == 'miam');
        expect(feeding['notes'], '100 ml vers 8h');
        expect(feeding.containsKey('notesUndecryptable'), isFalse);
      });

      test(
          'ciphertext indisponible → notes null + notesUndecryptable, ligne sans note → pas de flag',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final events =
            (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();

        final sleep = events.firstWhere((e) => e['type'] == 'dodo');
        expect(sleep['notes'], isNull);
        expect(sleep['notesUndecryptable'], isTrue);

        // This line has never received a rating: it's currently marked as "null," with no flags, just like before.
        final diaper = events.firstWhere((e) => e['type'] == 'caca');
        expect(diaper['notes'], isNull);
        expect(diaper.containsKey('notesUndecryptable'), isFalse);
      });

      test('timestamp en secondes, birthDate en millisecondes', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final events =
            (doc['trackingEvents'] as List).cast<Map<String, dynamic>>();
        final profiles =
            (doc['babyProfiles'] as List).cast<Map<String, dynamic>>();

        expect(events.first['timestampEpochSeconds'], 1700000000);
        expect(events.first['timestampUtc'], '2023-11-14T22:13:20.000Z');
        expect(profiles.first['birthDateEpochMs'], 1700000000000);
        expect(profiles.first['birthDateUtc'], '2023-11-14T22:13:20.000Z');
      });

      test('les rangs de rappels sont exportés avec secondes + ISO et babyId',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final settings =
            (doc['reminderSettings'] as List).cast<Map<String, dynamic>>();
        final dismissals =
            (doc['reminderDismissals'] as List).cast<Map<String, dynamic>>();

        // Three configuration options are available since the personalized reminder feature was implemented.
        // extinguished: it is set using its key, not by its position.
        final sharedDismissal =
            dismissals.firstWhere((d) => d['itemId'] == 'vitaminK');
        expect(sharedDismissal['babyId'], '');
        expect(sharedDismissal['dismissedAtEpochSeconds'], 1700000000);
        expect(sharedDismissal['dismissedAtUtc'], '2023-11-14T22:13:20.000Z');
        // The cloned individual carries the baby, while the shared individual acts as a guardian.
        final scopedSetting =
            settings.firstWhere((s) => s['itemId'] == 'vitamine_d');
        expect(scopedSetting['babyId'], 'baby_1');
        expect(scopedSetting['enabled'], isTrue);
        expect(
          settings.firstWhere((s) => s['itemId'] == 'vitaminD')['babyId'],
          '',
        );
        expect(
          dismissals.firstWhere((d) => d['itemId'] == 'vitamine_d')['babyId'],
          'baby_1',
        );
      });

      test('un rappel éteint sort de la sauvegarde en false, pas effacé',
          () async {
        // From the Settings screen, specifically the Reminders section, if the line `enabled = 0` is present, it means that reminders are disabled.
        // Currently: SQLite stores it as 0, so a restore operation should return "false".
        await database.customStatement(
          'INSERT INTO reminder_settings (item_id, enabled) VALUES (?, ?)',
          ['vitamine_d', 0],
        );

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final settings =
            (doc['reminderSettings'] as List).cast<Map<String, dynamic>>();

        expect(settings.single['itemId'], 'vitamine_d');
        expect(settings.single['enabled'], isFalse);
        expect((doc['counts'] as Map<String, dynamic>)['reminderSettings'], 1);
      });

      // A personalized reminder that has been dismissed is stored under the key `custom_<id>`: if...
      // The definition line is not being exported, and the key no longer points to anything.
      // The restoration and recall process keeps coming back to haunt me.
      test(
          'l\'extinction d\'un rappel personnalisé reste rattachée à sa définition',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final settings =
            (doc['reminderSettings'] as List).cast<Map<String, dynamic>>();
        final reminders =
            (doc['customReminders'] as List).cast<Map<String, dynamic>>();

        expect(
          reminders.firstWhere((r) => r['id'] == 1)['id'],
          1,
        );
        expect(
          settings.firstWhere((s) => s['itemId'] == 'custom_1')['enabled'],
          isFalse,
        );
      });

      // The rhythm is exported as raw code, not as a translated label: a file.
      // Content created in French must be displayed identically on a Spanish phone.
      test(
          'le rythme d\'un rappel personnalisé s\'exporte en code brut, babyId et completionSource compris',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final reminders =
            (doc['customReminders'] as List).cast<Map<String, dynamic>>();

        expect(reminders.firstWhere((r) => r['id'] == 1), {
          'id': 1,
          'label': 'Crème du change',
          'subtypeValue': 'nettoyage_nez',
          'frequency': 'every_n_days',
          'intervalDays': 3,
          'babyId': '',
          'completionSource': 'from_events',
        });
        // Detached: The `subtypeValue` being null indicates that this is a reminder without a specific subtype.
        // soin (D2), et l'export ne l'invente pas en 'from_events'.
        expect(reminders.firstWhere((r) => r['id'] == 2), {
          'id': 2,
          'label': 'Vitamine du soir',
          'subtypeValue': null,
          'frequency': 'weekly',
          'intervalDays': null,
          'babyId': '',
          'completionSource': 'manual',
        });
      });

      // A monthly rhythm doesn't have a defined interval; the key still needs to be...
      // It is presented clearly so that a user restoring data doesn't have to guess.
      test(
          'un rappel mensuel exporte intervalDays null plutôt que d\'omettre la clé',
          () async {
        await database.into(database.customReminders).insert(
              CustomRemindersCompanion.insert(
                label: 'Crème des pieds',
                subtypeValue: const Value('autre'),
                frequency: 'monthly',
              ),
            );

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final reminders =
            (doc['customReminders'] as List).cast<Map<String, dynamic>>();

        expect(reminders.single.containsKey('intervalDays'), isTrue);
        expect(reminders.single['intervalDays'], isNull);
        expect(reminders.single['frequency'], 'monthly');
      });
    });

    group('mesures (M4)', () {
      test('value et notes partent déchiffrées, orphelines comprises',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final rows = (doc['measurements'] as List).cast<Map<String, dynamic>>();

        final weight = rows.firstWhere((m) => m['id'] == 101);
        expect(weight['value'], '3400');
        expect(weight['notes'], 'Première pesée');
        expect(weight['babyId'], 'baby_1');
        expect(weight['kind'], 'poids');
        expect(weight['unit'], 'g');
        expect(weight['recordedAtEpochSeconds'], 1700000000);
        expect(weight['recordedAtUtc'], '2023-11-14T22:13:20.000Z');

        // Orphaned: null babyId, exported as orphaned events.
        final height = rows.firstWhere((m) => m['id'] == 102);
        expect(height['babyId'], isNull);
        expect(height['notes'], isNull);
        expect(height.containsKey('notesUndecryptable'), isFalse);
      });

      test(
          'ciphertext indisponible → value null + valueUndecryptable, ligne saine → pas de flag',
          () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final rows = (doc['measurements'] as List).cast<Map<String, dynamic>>();

        final bad = rows.firstWhere((m) => m['id'] == 103);
        expect(bad['value'], isNull);
        expect(bad['valueUndecryptable'], isTrue);

        final good = rows.firstWhere((m) => m['id'] == 101);
        expect(good.containsKey('valueUndecryptable'), isFalse);
      });

      test('achèvements manuels exportés sans id, babyId compris', () async {
        await seedFullDatabase();

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final rows =
            (doc['reminderCompletions'] as List).cast<Map<String, dynamic>>();

        expect(rows, hasLength(2));
        final shared = rows.firstWhere((c) => c['babyId'] == '');
        expect(shared['itemId'], 'custom_1');
        expect(shared['completedAtEpochSeconds'], 1700000000);
        expect(shared.containsKey('id'), isFalse);
        expect(
          rows.firstWhere((c) => c['babyId'] == 'baby_1')['itemId'],
          'custom_2',
        );
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
        expect(counts.measurements, 0);
        expect(counts.reminderCompletions, 0);
        expect(counts.isEmpty, isTrue);

        final doc = jsonDecode(await repository.buildExportJson())
            as Map<String, dynamic>;
        final jsonCounts = doc['counts'] as Map<String, dynamic>;
        expect(jsonCounts['babyProfiles'], 0);
        expect(jsonCounts['trackingEvents'], 0);
        expect(jsonCounts['customReminders'], 0);
        expect(jsonCounts['reminderSettings'], 0);
        expect(jsonCounts['reminderDismissals'], 0);
        expect(jsonCounts['measurements'], 0);
        expect(jsonCounts['reminderCompletions'], 0);
        expect((doc['trackingEvents'] as List), isEmpty);
        // Empty table exported as an empty table: a missing key would be interpreted as...
        // "Older version of the app," not like "no reminders."
        expect((doc['customReminders'] as List), isEmpty);
        expect((doc['measurements'] as List), isEmpty);
        expect((doc['reminderCompletions'] as List), isEmpty);
      });
    });
  });
}

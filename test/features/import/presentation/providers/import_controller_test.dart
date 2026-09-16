// Tests du contrôleur d'import : le document inspecté doit être EXACTEMENT le
// document restauré, un refus ne peut rien attendre ensuite, et le restore ne
// doit jamais invalider `databaseProvider` (pas de deuxième connexion).

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/features/import/data/repositories/import_repository_impl.dart';
import 'package:mamadera/features/import/domain/repositories/import_repository.dart';
import 'package:mamadera/features/import/presentation/providers/import_providers.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Fake de chiffrement identité : le contrôleur n'observe pas le chiffrement,
/// il ne faut juste jamais toucher le keychain.
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

AppDatabase _openDatabase() {
  final database = AppDatabase(LazyDatabase(NativeDatabase.memory));
  // Force onCreate pour que toutes les tables existent avant la première
  // requête.
  database.select(database.reminderDismissals).get();
  return database;
}

/// Un document analysé, typé, que le faux repository peut restituer.
ParsedExport _sampleParsed() => ParsedExport(
      babyProfiles: [
        const ImportedBabyProfile(
          id: 'baby_1',
          name: 'Bébé Test',
          birthDateEpochMs: 1700000000000,
          isActive: true,
        ),
      ],
      trackingEvents: [
        ImportedTrackingEvent(
          id: 1,
          type: 'miam',
          timestamp: DateTime.utc(2023, 11, 14, 22, 13, 20),
          duration: 10,
          subtype: 'natural',
          notes: '100 ml vers 8h',
          wasteType: null,
          color: null,
          texture: null,
          babyId: 'baby_1',
          quantity: 100,
        ),
      ],
      customReminders: [
        const ImportedCustomReminder(
          id: 4,
          label: 'Nettoyage nez du soir',
          subtypeValue: 'nettoyage_nez',
          frequency: 'every_n_days',
          intervalDays: 2,
        ),
      ],
      reminderSettings: const [
        ImportedReminderSetting(itemId: 'custom_4', enabled: true),
      ],
      reminderDismissals: [
        ImportedReminderDismissal(
          itemId: 'vitamine_d',
          dismissedAt: DateTime.utc(2023, 11, 14, 22, 13, 20),
        ),
      ],
    );

/// Faux repository scripté : on décide à l'avance ce que l'analyse et la
/// restauration renvoient ou lèvent, et chaque document remis à `restore` est
/// capturé pour la vérification d'identité.
class _ScriptedImportRepository extends ImportRepository {
  _ScriptedImportRepository({
    this.parseResult,
    this.parseError,
    this.restoreError,
  });

  final ParsedExport? parseResult;
  final Object? parseError;
  final Object? restoreError;
  final ImportCounts restoreResult = const ImportCounts(
    babyProfiles: 1,
    trackingEvents: 1,
    customReminders: 1,
    reminderSettings: 1,
    reminderDismissals: 1,
  );

  int parseCalls = 0;
  int restoreCalls = 0;
  final List<ParsedExport> restoredDocuments = <ParsedExport>[];

  @override
  Future<ParsedExport> parseExport(String json) async {
    parseCalls++;
    final error = parseError;
    if (error != null) throw error;
    return parseResult!;
  }

  @override
  Future<ImportCounts> restore(ParsedExport parsed) async {
    restoreCalls++;
    restoredDocuments.add(parsed);
    final error = restoreError;
    if (error != null) throw error;
    return restoreResult;
  }
}

/// Un document JSON valide que le vrai repository doit accepter.
Map<String, dynamic> validDocument() => <String, dynamic>{
      'exportFormatVersion': 1,
      'generator': 'mamadera',
      'appVersion': '1.1.0',
      'databaseSchemaVersion': 10,
      'exportedAt': '2023-11-14T22:13:20.000Z',
      'counts': <String, dynamic>{
        'babyProfiles': 1,
        'trackingEvents': 1,
        'customReminders': 1,
        'reminderSettings': 1,
        'reminderDismissals': 1,
      },
      'babyProfiles': [
        <String, dynamic>{
          'id': 'baby_1',
          'name': 'Bébé Test',
          'birthDateEpochMs': 1700000000000,
          'birthDateUtc': '2023-11-14T22:13:20.000Z',
          'isActive': true,
        },
      ],
      'trackingEvents': [
        <String, dynamic>{
          'id': 1,
          'type': 'miam',
          'timestampEpochSeconds': 1700000000,
          'timestampUtc': '2023-11-14T22:13:20.000Z',
          'durationMinutes': 10,
          'subtype': 'natural',
          'notes': '100 ml vers 8h',
          'wasteType': null,
          'color': null,
          'texture': null,
          'babyId': 'baby_1',
          'quantity': 100,
        },
      ],
      'customReminders': [
        <String, dynamic>{
          'id': 4,
          'label': 'Nettoyage nez du soir',
          'subtypeValue': 'nettoyage_nez',
          'frequency': 'every_n_days',
          'intervalDays': 2,
        },
      ],
      'reminderSettings': [
        <String, dynamic>{'itemId': 'custom_4', 'enabled': true},
      ],
      'reminderDismissals': [
        <String, dynamic>{
          'itemId': 'vitamine_d',
          'dismissedAtEpochSeconds': 1700000000,
          'dismissedAtUtc': '2023-11-14T22:13:20.000Z',
        },
      ],
    };

String _jsonOf(Map<String, dynamic> document) => jsonEncode(document);

void main() {
  group('ImportController — faux repository', () {
    late ProviderContainer container;
    late _ScriptedImportRepository repository;
    late ImportController controller;

    setUp(() {
      repository = _ScriptedImportRepository(parseResult: _sampleParsed());
      container = ProviderContainer(
        overrides: [
          importRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      controller = container.read(importControllerProvider.notifier);
    });

    tearDown(() => container.dispose);

    test('un fichier refusé laisse rien en attente : ImportRejected puis applyRestore renvoie ImportIdle',
        () async {
      repository = _ScriptedImportRepository(
        parseError: const ImportFormatException(
          ImportRejectionReason.newerFormatVersion,
        ),
      );

      final outcome = await controller.inspectFile('{}');

      expect(outcome, isA<ImportRejected>());
      expect((outcome as ImportRejected).reason,
          ImportRejectionReason.newerFormatVersion);
      expect(container.read(importControllerProvider).value,
          isA<ImportRejected>());

      // Le refus a jeté tout document en attente : aucun restore fantôme.
      final idle = await controller.applyRestore();
      expect(idle, const ImportIdle());
      expect(repository.restoreCalls, 0);
    });

    test('un fichier valide donne un résumé avec les bons compteurs', () async {
      final outcome = await controller.inspectFile('nimporte quel json');

      expect(outcome, isA<ImportSummaryReady>());
      final counts = (outcome as ImportSummaryReady).counts;
      expect(counts.babyProfiles, 1);
      expect(counts.trackingEvents, 1);
      expect(counts.customReminders, 1);
      expect(counts.reminderSettings, 1);
      expect(counts.reminderDismissals, 1);
      expect(container.read(importControllerProvider).value,
          isA<ImportSummaryReady>());
      expect(repository.restoreCalls, 0,
          reason: 'l\'inspection ne doit rien écrire');
    });

    test('applyRestore sans rien en attente renvoie ImportIdle, jamais un succès fantôme',
        () async {
      final outcome = await controller.applyRestore();

      expect(outcome, const ImportIdle());
      expect(repository.restoreCalls, 0);
      expect(container.read(importControllerProvider).value, const ImportIdle());
    });

    test('inspect puis apply : le restauré est IDENTIQUE à l\'inspecté', () async {
      final parsed = _sampleParsed();
      repository = _ScriptedImportRepository(parseResult: parsed);

      await controller.inspectFile('{}');
      final outcome = await controller.applyRestore();

      expect(outcome, isA<ImportSuccess>());
      final counts = (outcome as ImportSuccess).counts;
      expect(counts, repository.restoreResult,
          reason: 'les compteurs affichés sont ceux réellement écrits');
      expect(container.read(importControllerProvider).value, isA<ImportSuccess>());

      expect(repository.restoreCalls, 1);
      expect(identical(repository.restoredDocuments.single, parsed), isTrue,
          reason:
              'le parent doit voir exactement ce qui sera écrit, pas un re-parse');
    });

    test('applyRestore appelé deux fois : la deuxième passe renvoie ImportIdle',
        () async {
      await controller.inspectFile('{}');
      final first = await controller.applyRestore();
      expect(first, isA<ImportSuccess>());

      final second = await controller.applyRestore();

      expect(second, const ImportIdle());
      expect(repository.restoreCalls, 1);
    });

    test('un restore qui lève une exception renvoie ImportFailed sans crash',
        () async {
      repository = _ScriptedImportRepository(
        parseResult: _sampleParsed(),
        restoreError: StateError('disque plein'),
      );
      await controller.inspectFile('{}');

      final outcome = await controller.applyRestore();

      expect(outcome, const ImportFailed());
      expect(container.read(importControllerProvider).value, const ImportFailed());
    });

    test('cancel après un inspect valide : le suivant applyRestore renvoie ImportIdle',
        () async {
      await controller.inspectFile('{}');
      expect(controller.state.value, isA<ImportSummaryReady>());

      controller.cancel();

      expect(controller.state.value, const ImportIdle());
      final outcome = await controller.applyRestore();
      expect(outcome, const ImportIdle());
      expect(repository.restoreCalls, 0);
    });
  });

  group('ImportController — vrai repository, vraie base', () {
    test(
        'un restore conserve la même instance AppDatabase et '
        'rafraîchit les providers liés à la base', () async {
      final database = _openDatabase();
      addTearDown(database.close);
      final encryption = _FakeEncryption();
      final realRepository =
          ImportRepositoryImpl(database: database, encryption: encryption);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) async => database),
          encryptionServiceProvider.overrideWith((ref) async => encryption),
          importRepositoryProvider.overrideWith((ref) async => realRepository),
        ],
      );
      addTearDown(container.dispose);

      // Une ligne ancienne qui doit disparaître au restore.
      await database.insertEvent(TrackingEventsCompanion.insert(
        type: 'dodo',
        timestamp: DateTime.utc(2024, 1, 1),
      ));

      final before = await container.read(databaseProvider.future);
      final controller = container.read(importControllerProvider.notifier);

      final inspected = await controller.inspectFile(_jsonOf(validDocument()));
      expect(inspected, isA<ImportSummaryReady>());
      final outcome = await controller.applyRestore();
      expect(outcome, isA<ImportSuccess>());

      // Un restore ne ferme ni ne supprime le fichier : invalider
      // `databaseProvider` ouvrirait une deuxième connexion (et un deuxième
      // isolate en arrière-plan) par restore, alors que ce contrôleur
      // continuerait d'utiliser la première. La même instance doit donc
      // sortir du provider.
      final after = await container.read(databaseProvider.future);
      expect(identical(before, after), isTrue,
          reason: 'pas de deuxième connexion par restore');

      // Les providers invalidés par le contrôleur re-lisent le contenu
      // restauré, pas la ligne ancienne.
      final history = await container
          .read(historyNotifierProvider(HistoryFilter.all).future);
      expect(history, hasLength(1));
      expect(history.single.trackingType, TrackingType.miam);
      final active = await container.read(activeBabyProvider.future);
      expect(active?.id, 'baby_1');
    });
  });
}

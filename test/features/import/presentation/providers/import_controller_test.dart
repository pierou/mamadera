// Import controller tests: the document being inspected must be EXACTLY the...
// Once a document has been restored, any subsequent refusal cannot be overturned, and the restoration process itself cannot be challenged.
// It should never invalidate the `databaseProvider` (no second connection should be established).

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
import 'package:mamadera/features/history/domain/history_row.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/features/import/data/repositories/import_repository_impl.dart';
import 'package:mamadera/features/import/domain/repositories/import_repository.dart';
import 'package:mamadera/features/import/presentation/providers/import_providers.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';

import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Identity encryption spoofing: the controller does not detect the encryption.
/// You should never, under any circumstances, touch the keychain.
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
  // Ensure that all tables exist before the first execution.
  // query.
  database.select(database.reminderDismissals).get();
  return database;
}

/// A document that has been analyzed and categorized, which the fake repository can return.
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
          // The original file did not specify any units; the parser assigns them.
          // The one the parent sees ("natural" → ml), they will never guess.
          unit: QuantityUnit.ml,
        ),
      ],
      customReminders: [
        const ImportedCustomReminder(
          id: 4,
          label: 'Nettoyage nez du soir',
          subtypeValue: 'nettoyage_nez',
          frequency: 'every_n_days',
          intervalDays: 2,
          babyId: '',
          completionSource: 'from_events',
        ),
      ],
      reminderSettings: const [
        ImportedReminderSetting(babyId: '', itemId: 'custom_4', enabled: true),
      ],
      reminderDismissals: [
        ImportedReminderDismissal(
          babyId: '',
          itemId: 'vitamine_d',
          dismissedAt: DateTime.utc(2023, 11, 14, 22, 13, 20),
        ),
      ],
    );

/// Scripted fake repository: We predetermine what the analysis and...
/// restoration commands either return or raise an exception, and each document passed to `restore` is.
/// Captured for identity verification.
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
    measurements: 1,
    reminderCompletions: 1,
    appSettings: 0,
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

/// A valid JSON document, in format 2 (M4), which the actual repository must...
/// accepter.
Map<String, dynamic> validDocument() => <String, dynamic>{
      'exportFormatVersion': 2,
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
        'measurements': 1,
        'reminderCompletions': 1,
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
        <String, dynamic>{'babyId': '', 'itemId': 'custom_4', 'enabled': true},
      ],
      'reminderDismissals': [
        <String, dynamic>{
          'babyId': '',
          'itemId': 'vitamine_d',
          'dismissedAtEpochSeconds': 1700000000,
          'dismissedAtUtc': '2023-11-14T22:13:20.000Z',
        },
      ],
      'measurements': [
        <String, dynamic>{
          'id': 101,
          'babyId': 'baby_1',
          'kind': 'poids',
          'value': '3400',
          'unit': 'g',
          'recordedAtEpochSeconds': 1700000000,
          'recordedAtUtc': '2023-11-14T22:13:20.000Z',
          'notes': 'Première pesée',
        },
      ],
      'reminderCompletions': [
        <String, dynamic>{
          'babyId': '',
          'itemId': 'custom_4',
          'completedAtEpochSeconds': 1700000000,
          'completedAtUtc': '2023-11-14T22:13:20.000Z',
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

    test(
        'un fichier refusé laisse rien en attente : ImportRejected puis applyRestore renvoie ImportIdle',
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

      // The rejection cleared all pending documents; there were no "ghost" restores.
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
      expect(counts.measurements, 0);
      expect(counts.reminderCompletions, 0);
      expect(container.read(importControllerProvider).value,
          isA<ImportSummaryReady>());
      expect(repository.restoreCalls, 0,
          reason: 'l\'inspection ne doit rien écrire');
    });

    test(
        'applyRestore sans rien en attente renvoie ImportIdle, jamais un succès fantôme',
        () async {
      final outcome = await controller.applyRestore();

      expect(outcome, const ImportIdle());
      expect(repository.restoreCalls, 0);
      expect(
          container.read(importControllerProvider).value, const ImportIdle());
    });

    test('inspect puis apply : le restauré est IDENTIQUE à l\'inspecté',
        () async {
      final parsed = _sampleParsed();
      repository = _ScriptedImportRepository(parseResult: parsed);

      await controller.inspectFile('{}');
      final outcome = await controller.applyRestore();

      expect(outcome, isA<ImportSuccess>());
      final counts = (outcome as ImportSuccess).counts;
      expect(counts, repository.restoreResult,
          reason: 'les compteurs affichés sont ceux réellement écrits');
      expect(
          container.read(importControllerProvider).value, isA<ImportSuccess>());

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
      expect(
          container.read(importControllerProvider).value, const ImportFailed());
    });

    test(
        'cancel après un inspect valide : le suivant applyRestore renvoie ImportIdle',
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

      // An old line that needs to be removed during the restoration process.
      await database.insertEvent(TrackingEventsCompanion.insert(
        unit: 'min',
        type: 'dodo',
        timestamp: DateTime.utc(2024, 1, 1),
      ));

      final before = await container.read(databaseProvider.future);
      final controller = container.read(importControllerProvider.notifier);

      final inspected = await controller.inspectFile(_jsonOf(validDocument()));
      expect(inspected, isA<ImportSummaryReady>());
      final outcome = await controller.applyRestore();
      expect(outcome, isA<ImportSuccess>());

      // A restore operation does not close or delete the file; it invalidates it.
      // `databaseProvider` would open a second connection (and a second...
      // isolate in the background) using the "restore" function, while this controller...
      // would continue to use the first one. Therefore, the same instance should...
      // sortir du provider.
      final after = await container.read(databaseProvider.future);
      expect(identical(before, after), isTrue,
          reason: 'pas de deuxième connexion par restore');

      // The providers that have been invalidated by the controller will re-read the content.
      // Restored, but not the original design.
      final history = await container
          .read(historyNotifierProvider(HistoryFilter.all).future);
      // Unified timeline: imported event + imported measurement (version 12:).
      // The measurements appear in the "all" filter.
      expect(history, hasLength(2));
      expect((history.first as EventHistoryRow).event.trackingType,
          TrackingType.miam);
      expect(history.last, isA<MeasurementHistoryRow>());
      final active = await container.read(activeBabyProvider.future);
      expect(active?.id, 'baby_1');

      // Both M4 tables have been restored, including the data.
      final measurements = await database.getAllMeasurements();
      expect(measurements, hasLength(1));
      expect(measurements.single.value, startsWith('enc:'));
      expect(encryption.decrypt(measurements.single.value), '3400');
      expect(
        encryption.decrypt(measurements.single.notes),
        'Première pesée',
      );
      expect(await database.getAllReminderCompletions(), hasLength(1));
    });
  });
}

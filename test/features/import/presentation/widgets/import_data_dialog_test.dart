// ignore_for_file: lines_longer_than_80_chars
// Testing the restaurant dialogue: the destructive confirmation must be implemented.
// After the parent has viewed the actual content of the file, and no details...
// Internal techniques (exceptions, paths, notes) should not be displayed.

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/import/data/repositories/import_repository_impl.dart';
import 'package:mamadera/features/import/domain/repositories/import_repository.dart';
import 'package:mamadera/features/import/presentation/providers/import_providers.dart';
import 'package:mamadera/features/import/presentation/widgets/import_data_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

const _title = 'Restaurer depuis une sauvegarde';
const _confirm = 'Choisir un fichier…';
const _cancel = 'Annuler';
const _proceed = 'Restaurer';
const _close = 'Fermer';

/// Identity encryption spoofing: the content of the notes only passes through...
/// test variables, never the keychain.
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

/// Instrumented repository: it counts the calls to prove that the...
/// The warning phase does not trigger any access.
class _RecordingImportRepository extends ImportRepositoryImpl {
  _RecordingImportRepository(
      {required super.database, required super.encryption});

  int parseCalls = 0;
  int restoreCalls = 0;

  @override
  Future<ParsedExport> parseExport(String json) async {
    parseCalls++;
    return super.parseExport(json);
  }

  @override
  Future<ImportCounts> restore(ParsedExport parsed) async {
    restoreCalls++;
    return super.restore(parsed);
  }
}

/// True repository, but restoration fails, displaying an error message.
class _ThrowingRestoreRepository extends ImportRepositoryImpl {
  _ThrowingRestoreRepository(
      {required super.database, required super.encryption});

  @override
  Future<ImportCounts> restore(ParsedExport parsed) async {
    throw StateError('simulated write failure');
  }
}

/// A valid JSON document that the actual repository will accept, including the following lines:
/// le test veut imposer.
Map<String, dynamic> validDocument({
  List<dynamic>? babyProfiles,
  List<dynamic>? trackingEvents,
  int formatVersion = 2,
  int schemaVersion = 10,
  String? generator,
}) {
  final profiles = babyProfiles ??
      [
        <String, dynamic>{
          'id': 'baby_1',
          'name': 'Bébé Test',
          'birthDateEpochMs': 1700000000000,
          'birthDateUtc': '2023-11-14T22:13:20.000Z',
          'isActive': true,
        },
      ];
  final events = trackingEvents ??
      [
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
      ];
  return <String, dynamic>{
    'exportFormatVersion': formatVersion,
    'generator': generator ?? 'mamadera',
    'appVersion': '1.1.0',
    'databaseSchemaVersion': schemaVersion,
    'exportedAt': '2023-11-14T22:13:20.000Z',
    'counts': <String, dynamic>{
      'babyProfiles': profiles.length,
      'trackingEvents': events.length,
      'customReminders': 1,
      'reminderSettings': 1,
      'reminderDismissals': 1,
      'measurements': 1,
      'reminderCompletions': 1,
    },
    'babyProfiles': profiles,
    'trackingEvents': events,
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
}

String _jsonOf(Map<String, dynamic> document) => jsonEncode(document);

/// Open the dialogue on a truly in-memory basis and a genuine...
/// `ImportRepositoryImpl` (or the repository created by the test), without...
/// Never directly access the `FilePicker`: file reading must be done through the designated interface.
/// `readBackup`.
Future<AppDatabase> _pumpDialog(
  WidgetTester tester, {
  Future<String?> Function()? readBackup,
  ImportRepository Function(AppDatabase database, EncryptionService encryption)?
      buildRepository,
}) async {
  final connection = LazyDatabase(NativeDatabase.memory);
  final database = AppDatabase(connection);
  addTearDown(database.close);
  // Ensure that all tables exist before the first execution.
  // query.
  database.select(database.reminderDismissals).get();
  final encryption = _FakeEncryption();
  final repository = buildRepository?.call(database, encryption) ??
      ImportRepositoryImpl(database: database, encryption: encryption);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) async => database),
        encryptionServiceProvider.overrideWith((ref) async => encryption),
        importRepositoryProvider.overrideWith((ref) async => repository),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ImportDataDialog(readBackup: readBackup),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('ouvrir'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return database;
}

/// The analysis is performed within a background isolation chamber, and the resulting signal is received on the...
/// True event loop: `tester.runAsync` triggers it, and it continues to run.
/// The difference is simply that of a "dummy" clock. It continues to run as long as the phase...
/// The next item is not displayed, as the real-time duration is limited.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
}

Future<void> _chooseFile(WidgetTester tester) async {
  await tester.tap(find.text(_confirm));
  await tester.pump();
}

/// Texte de l'avertissement destructif de la phase d'alerte.
Finder _warningFinder() => find.textContaining(
      'supprimera définitivement toutes les données actuellement sur cet appareil',
    );

void main() {
  group("ImportDataDialog — phase d'alerte", () {
    testWidgets(
        "l'avertissement et les deux boutons s'affichent ; annuler ferme sans rien appeler",
        (tester) async {
      late _RecordingImportRepository recorder;
      await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument()),
        buildRepository: (database, encryption) {
          recorder = _RecordingImportRepository(
            database: database,
            encryption: encryption,
          );
          return recorder;
        },
      );

      expect(find.text(_title), findsOneWidget);
      expect(_warningFinder(), findsOneWidget);
      expect(find.text(_confirm), findsOneWidget);
      expect(find.text(_cancel), findsOneWidget);

      await tester.tap(find.text(_cancel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_title), findsNothing);
      expect(recorder.parseCalls, 0,
          reason: "annuler à la phase d'alerte ne doit rien lire ni analyser");
      expect(recorder.restoreCalls, 0);
    });

    testWidgets(
        "annulation du choix de fichier : retour à l'alerte, base intacte",
        (tester) async {
      final database = await _pumpDialog(tester, readBackup: () async => null);

      await _chooseFile(tester);
      await _pumpUntil(tester, _warningFinder());
      await tester.pump();

      // The discussion was always escalating, always reaching a point of heightened tension.
      expect(find.text(_title), findsOneWidget);
      expect(_warningFinder(), findsOneWidget);
      expect(find.text(_confirm), findsOneWidget);
      expect(await database.getAllBabyProfiles(), isEmpty);
      expect(await database.getAllTrackingEvents(), isEmpty);
    });
  });

  group('ImportDataDialog — résumé et restauration', () {
    testWidgets('un fichier valide affiche le résumé avec ses vrais compteurs',
        (tester) async {
      await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument()),
      );

      await _chooseFile(tester);
      await _pumpUntil(
        tester,
        find.textContaining('1 profil(s) bébé, 1 événement(s) et 1 rappel(s)'),
      );

      expect(
        find.textContaining(
          'Ce fichier contient 1 profil(s) bébé, 1 événement(s) et 1 rappel(s) personnalisé(s)',
        ),
        findsOneWidget,
      );
      expect(find.text(_proceed), findsOneWidget);
      expect(find.text(_cancel), findsOneWidget);
    });

    testWidgets(
        'résumé puis Restaurer : succès avec les compteurs et lignes écrites',
        (tester) async {
      final database = await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument()),
      );

      await _chooseFile(tester);
      await _pumpUntil(
        tester,
        find.textContaining('1 profil(s) bébé, 1 événement(s) et 1 rappel(s)'),
      );
      await tester.tap(find.text(_proceed));
      await _pumpUntil(
        tester,
        find.textContaining(
            'Restauration terminée : 1 profil(s) et 1 événement(s)'),
      );

      expect(find.text(_close), findsOneWidget);
      // The database actually contains the lines of the file.
      final profiles = await database.getAllBabyProfiles();
      expect(profiles, hasLength(1));
      expect(profiles.single.id, 'baby_1');
      expect(await database.getAllTrackingEvents(), hasLength(1));
      expect(await database.getAllCustomReminders(), hasLength(1));
      expect(await database.getAllReminderSettings(), hasLength(1));
      expect(await database.getAllReminderDismissals(), hasLength(1));
      expect(await database.getAllMeasurements(), hasLength(1));
      expect(await database.getAllReminderCompletions(), hasLength(1));
    });

    testWidgets(
        "événements sans profil : le résumé porte l'avertissement supplémentaire",
        (tester) async {
      await _pumpDialog(
        tester,
        readBackup: () async =>
            _jsonOf(validDocument(babyProfiles: const <dynamic>[])),
      );

      await _chooseFile(tester);
      await _pumpUntil(
        tester,
        find.textContaining('0 profil(s) bébé, 1 événement(s) et 1 rappel(s)'),
      );

      expect(
          find.textContaining('ne contient aucun profil bébé'), findsOneWidget);
    });

    testWidgets(
        'annuler au résumé : le dialogue ferme, plus rien ne peut être restauré',
        (tester) async {
      final database = await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument()),
      );

      await _chooseFile(tester);
      await _pumpUntil(
        tester,
        find.textContaining('1 profil(s) bébé, 1 événement(s) et 1 rappel(s)'),
      );
      await tester.tap(find.text(_cancel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_title), findsNothing);

      // The pending document was discarded due to cancellation: a late application.
      // Without a re-inspection, it can no longer be restored.
      final container = ProviderScope.containerOf(
        tester.element(find.text('ouvrir')),
        listen: false,
      );
      final controller = container.read(importControllerProvider.notifier);
      final outcome = await controller.applyRestore();
      expect(outcome, const ImportIdle());
      expect(await database.getAllBabyProfiles(), isEmpty);
      expect(await database.getAllTrackingEvents(), isEmpty);
    });
  });

  group('ImportDataDialog — rejets et échecs', () {
    Future<void> expectResult(WidgetTester tester, Finder message) async {
      await _chooseFile(tester);
      await _pumpUntil(tester, message);
      expect(find.text(_close), findsOneWidget);
    }

    testWidgets('JSON invalide : message générique, base intacte',
        (tester) async {
      final database =
          await _pumpDialog(tester, readBackup: () async => 'not json at all');

      await expectResult(tester, find.textContaining('Fichier non reconnu'));
      expect(await database.getAllBabyProfiles(), isEmpty);
      expect(await database.getAllTrackingEvents(), isEmpty);
    });

    testWidgets("fichier d'un autre générateur : message dédié",
        (tester) async {
      await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument(generator: 'other-app')),
      );

      await expectResult(tester, find.textContaining('créé par Mamadera'));
    });

    testWidgets('exportFormatVersion plus récente : message dédié',
        (tester) async {
      // Format 3 (v12, with a `unit` field for each event) is the format used in this build:
      // It's number 4 that represents the unknown of the future.
      await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument(formatVersion: 4)),
      );

      await expectResult(tester, find.textContaining('version plus récente'));
    });

    testWidgets("un fichier de format 1 (avant M4) se résume et restaure",
        (tester) async {
      // Document 2, truncated to format 1: sections and M4 count keys.
      // That's what the previous application actually displayed.
      final doc = validDocument(formatVersion: 1);
      doc.remove('measurements');
      doc.remove('reminderCompletions');
      final counts = doc['counts'] as Map<String, dynamic>;
      counts.remove('measurements');
      counts.remove('reminderCompletions');

      final database = await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(doc),
      );

      await _chooseFile(tester);
      await _pumpUntil(
        tester,
        find.textContaining('1 profil(s) bébé, 1 événement(s) et 1 rappel(s)'),
      );
      await tester.tap(find.text(_proceed));
      await _pumpUntil(
        tester,
        find.textContaining(
            'Restauration terminée : 1 profil(s) et 1 événement(s)'),
      );

      // New sections that are missing will appear as blank; existing lines will be displayed correctly.
      // within the shared scope.
      expect(await database.getAllMeasurements(), isEmpty);
      expect(await database.getAllReminderCompletions(), isEmpty);
      expect((await database.getAllCustomReminders()).single.babyId, '');
      expect((await database.getAllReminderSettings()).single.babyId, '');
    });

    testWidgets('databaseSchemaVersion plus récente : message dédié',
        (tester) async {
      await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument(schemaVersion: 999)),
      );

      await expectResult(
        tester,
        find.textContaining('données plus récentes que cette version'),
      );
    });

    testWidgets(
        "fichier trop lourd : même ligne générique qu'un fichier invalide",
        (tester) async {
      await _pumpDialog(
        tester,
        readBackup: () async => throw const ImportFormatException(
            ImportRejectionReason.fileTooLarge),
      );

      await expectResult(tester, find.textContaining('Fichier non reconnu'));
    });

    testWidgets(
        'restauration en échec : on dit que les données actuelles sont intactes',
        (tester) async {
      final database = await _pumpDialog(
        tester,
        readBackup: () async => _jsonOf(validDocument()),
        buildRepository: (db, encryption) => _ThrowingRestoreRepository(
          database: db,
          encryption: encryption,
        ),
      );
      // A pre-existing line: it must survive the failure.
      await database.insertEvent(TrackingEventsCompanion.insert(
        unit: 'min',
        type: 'dodo',
        timestamp: DateTime.utc(2024, 1, 1),
      ));

      await _chooseFile(tester);
      await _pumpUntil(
        tester,
        find.textContaining('1 profil(s) bébé, 1 événement(s) et 1 rappel(s)'),
      );
      await tester.tap(find.text(_proceed));
      await _pumpUntil(
        tester,
        find.textContaining('Vos données actuelles sont intactes'),
      );

      expect(find.text(_close), findsOneWidget);
      final events = await database.getAllTrackingEvents();
      expect(events, hasLength(1));
      expect(events.single.type, 'dodo');
    });

    testWidgets(
        "aucun texte d'exception, chemin de fichier ou note ne fuit à l'écran",
        (tester) async {
      const marker = 'MARKER_NOTE_NE_JAMAIS_VISIBLE_17';
      final document = validDocument(
        trackingEvents: [
          <String, dynamic>{
            'id': 1,
            'type': 'bain',             // Unknown file type: the entire file is rejected.
            'timestampEpochSeconds': 1700000000,
            'notes': marker,
          },
        ],
      );
      await _pumpDialog(tester, readBackup: () async => _jsonOf(document));

      await expectResult(tester, find.textContaining('Fichier non reconnu'));

      final allText = find
          .byType(Text)
          .evaluate()
          .map((element) => (element.widget as Text).data ?? '')
          .toList();
      final joined = allText.join('\n');
      expect(joined, isNot(contains(marker)),
          reason: "le contenu d'une note ne doit jamais atteindre l'UI");
      expect(joined, isNot(contains('FormatException')));
      expect(joined, isNot(contains('ImportRejectionReason')));
    });
  });
}

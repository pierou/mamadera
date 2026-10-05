import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/export/data/repositories/export_repository_impl.dart';
import 'package:mamadera/features/import/data/repositories/import_repository_impl.dart';
import 'package:mamadera/features/import/domain/repositories/import_repository.dart';

/// Deterministic fake: `enc:<texte>` → `<texte>`, same as the export tests, so a
/// round trip proves the two features agree rather than that AES works.
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
  // Forces onCreate so every table exists before the first statement.
  database.select(database.reminderDismissals).get();
  return database;
}

/// A document the exporter would have written, with whatever a test wants to
/// override. Built as a map (not by string surgery) so each negative case
/// changes exactly one thing.
Map<String, dynamic> validDocument({
  List<dynamic>? babyProfiles,
  List<dynamic>? trackingEvents,
  List<dynamic>? customReminders,
  List<dynamic>? reminderSettings,
  List<dynamic>? reminderDismissals,
  List<dynamic>? measurements,
  List<dynamic>? reminderCompletions,
  Map<String, dynamic>? counts,
  int formatVersion = 2,
  int schemaVersion = 10,
  String? generator,
}) {
  final profiles = babyProfiles ??
      [
        {
          'id': 'baby_1',
          'name': 'Bébé Test',
          'birthDateEpochMs': 1700000000000,
          'birthDateUtc': '2023-11-14T22:13:20.000Z',
          'isActive': true,
        },
      ];
  final events = trackingEvents ??
      [
        {
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
  final reminders = customReminders ??
      [
        {
          'id': 4,
          'label': 'Nettoyage nez du soir',
          'subtypeValue': 'nettoyage_nez',
          'frequency': 'every_n_days',
          'intervalDays': 2,
          'babyId': '',
          'completionSource': 'from_events',
        },
      ];
  final settings = reminderSettings ??
      [
        {'babyId': '', 'itemId': 'custom_4', 'enabled': true},
      ];
  final dismissals = reminderDismissals ??
      [
        {
          'babyId': '',
          'itemId': 'vitamine_d',
          'dismissedAtEpochSeconds': 1700000000,
          'dismissedAtUtc': '2023-11-14T22:13:20.000Z',
        },
      ];
  final measureRows = measurements ?? const <dynamic>[];
  final completionRows = reminderCompletions ?? const <dynamic>[];
  return <String, dynamic>{
    'exportFormatVersion': formatVersion,
    'generator': generator ?? 'mamadera',
    'appVersion': '1.1.0',
    'databaseSchemaVersion': schemaVersion,
    'exportedAt': '2023-11-14T22:13:20.000Z',
    'counts': counts ??
        <String, dynamic>{
          'babyProfiles': profiles.length,
          'trackingEvents': events.length,
          'customReminders': reminders.length,
          'reminderSettings': settings.length,
          'reminderDismissals': dismissals.length,
          'measurements': measureRows.length,
          'reminderCompletions': completionRows.length,
        },
    'babyProfiles': profiles,
    'trackingEvents': events,
    'customReminders': reminders,
    'reminderSettings': settings,
    'reminderDismissals': dismissals,
    'measurements': measureRows,
    'reminderCompletions': completionRows,
  };
}

/// Un document de **format 1** : ce qu'écrivait l'app avant M4. Pas de
/// sections `measurements`/`reminderCompletions`, pas de clés correspondantes
/// dans `counts`, pas de `babyId` sur réglages/rejets/rappels, pas de
/// `completionSource`. La restauration doit le lire en entier, absences
/// comprises.
Map<String, dynamic> formatOneDocument() => <String, dynamic>{
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
        {
          'id': 'baby_1',
          'name': 'Bébé Test',
          'birthDateEpochMs': 1700000000000,
          'birthDateUtc': '2023-11-14T22:13:20.000Z',
          'isActive': true,
        },
      ],
      'trackingEvents': [
        {
          'id': 1,
          'type': 'miam',
          'timestampEpochSeconds': 1700000000,
          'timestampUtc': '2023-11-14T22:13:20.000Z',
          'notes': '100 ml vers 8h',
          'babyId': 'baby_1',
          'quantity': 100,
        },
      ],
      'customReminders': [
        {
          'id': 4,
          'label': 'Nettoyage nez du soir',
          'subtypeValue': 'nettoyage_nez',
          'frequency': 'every_n_days',
          'intervalDays': 2,
        },
      ],
      'reminderSettings': [
        {'itemId': 'custom_4', 'enabled': true},
      ],
      'reminderDismissals': [
        {
          'itemId': 'vitamine_d',
          'dismissedAtEpochSeconds': 1700000000,
          'dismissedAtUtc': '2023-11-14T22:13:20.000Z',
        },
      ],
    };

String _jsonOf(Map<String, dynamic> document) => jsonEncode(document);

/// Runs [body] against a database pre-filled with [document]'s content and
/// asserts the tables are byte-for-byte the same afterwards — the shape every
/// rejection test needs.
Future<void> expectRejected({
  required Map<String, dynamic> document,
  required ImportRejectionReason reason,
  String? section,
}) async {
  final database = _openDatabase();
  addTearDown(database.close);
  final encryption = _FakeEncryption();
  final repository =
      ImportRepositoryImpl(database: database, encryption: encryption);

  // A file must fail *before* touching anything, so seed a known state first.
  final seeded =
      await repository.restore(await repository.parseExport(_jsonOf(validDocument())));
  final before = await _allCounts(database);

  ImportFormatException? captured;
  try {
    await repository.parseExport(_jsonOf(document));
  } on ImportFormatException catch (error) {
    captured = error;
  }
  expect(captured, isA<ImportFormatException>(),
      reason: 'expected a rejection for ${reason.name}');
  expect(captured?.reason, reason);
  if (section != null) {
    expect(captured?.section, section);
  }

  // Nothing was written: the parse half cannot reach the database at all.
  expect(await _allCounts(database), before,
      reason: 'a rejected file must leave the database untouched');
  expect(seeded.trackingEvents, greaterThan(0));
}

Future<Map<String, int>> _allCounts(AppDatabase database) async => {
      'babyProfiles': (await database.getAllBabyProfiles()).length,
      'trackingEvents': (await database.getAllTrackingEvents()).length,
      'customReminders': (await database.getAllCustomReminders()).length,
      'reminderSettings': (await database.getAllReminderSettings()).length,
      'reminderDismissals': (await database.getAllReminderDismissals()).length,
      'measurements': (await database.getAllMeasurements()).length,
      'reminderCompletions':
          (await database.getAllReminderCompletions()).length,
    };

void main() {
  group('ImportRepositoryImpl.parseExport', () {
    late AppDatabase database;
    late _FakeEncryption encryption;
    late ImportRepositoryImpl repository;

    setUp(() {
      database = _openDatabase();
      encryption = _FakeEncryption();
      repository =
          ImportRepositoryImpl(database: database, encryption: encryption);
    });

    tearDown(() async => database.close());

    test('accepts the document the exporter writes', () async {
      final source = _openDatabase();
      addTearDown(source.close);
      await _seedRichDatabase(source, encryption);
      final exported =
          await ExportRepositoryImpl(database: source, encryption: encryption)
              .buildExportJson();

      final parsed = await repository.parseExport(exported);

      expect(parsed.babyProfiles, hasLength(2));
      expect(parsed.trackingEvents, hasLength(3));
      expect(parsed.customReminders.length, 2);
      expect(parsed.measurements, hasLength(2));
      expect(parsed.reminderCompletions, hasLength(2));
      // Notes arrive as the plaintext the exporter wrote, not as ciphertext.
      expect(
        parsed.trackingEvents.map((event) => event.notes),
        contains('100 ml vers 8h'),
      );
    });

    test('rejects text that is not JSON', () async {
      final before = await _allCounts(database);
      await expectLater(
        repository.parseExport('not json at all'),
        throwsA(isA<ImportFormatException>().having((error) => error.reason,
            'reason', ImportRejectionReason.invalidJson)),
      );
      await expectLater(
        repository.parseExport('[1, 2, 3]'),
        throwsA(isA<ImportFormatException>().having((error) => error.reason,
            'reason', ImportRejectionReason.invalidJson)),
      );
      expect(await _allCounts(database), before,
          reason: 'a parse failure cannot write anything');
    });

    test('rejects a file from another generator', () async {
      await expectRejected(
        document: validDocument(generator: 'other-app'),
        reason: ImportRejectionReason.notAMamaderaFile,
      );
    });

    test('rejects a format version it does not know', () async {
      await expectRejected(
        document: validDocument(formatVersion: 3),
        reason: ImportRejectionReason.newerFormatVersion,
      );
    });

    test('still accepts a format-1 document: new sections absent read as empty',
        () async {
      final parsed =
          await repository.parseExport(_jsonOf(formatOneDocument()));

      expect(parsed.babyProfiles, hasLength(1));
      expect(parsed.trackingEvents, hasLength(1));
      expect(parsed.measurements, isEmpty);
      expect(parsed.reminderCompletions, isEmpty);
      // Absence de `babyId` = partagé, absence de `completionSource` =
      // `from_events`.
      expect(parsed.reminderSettings.single.babyId, '');
      expect(parsed.reminderDismissals.single.babyId, '');
      expect(parsed.customReminders.single.babyId, '');
      expect(parsed.customReminders.single.completionSource,
          'from_events');
    });

    test('rejects a format-1 file that grew a measurement row it does not declare in counts',
        () async {
      final document = formatOneDocument()
        ..['measurements'] = [
          <String, dynamic>{
            'id': 101,
            'kind': 'poids',
            'value': '3400',
            'unit': 'g',
            'recordedAtEpochSeconds': 1700000000,
          },
        ];
      await expectRejected(
        document: document,
        reason: ImportRejectionReason.countsMismatch,
        section: 'measurements',
      );
    });

    test('rejects a malformed measurement row (unknown kind)', () async {
      await expectRejected(
        document: validDocument(measurements: [
          <String, dynamic>{
            'id': 101,
            'kind': 'poidsx',
            'value': '3400',
            'unit': 'g',
            'recordedAtEpochSeconds': 1700000000,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'measurements',
      );
    });

    test('rejects a non-numeric measurement value', () async {
      await expectRejected(
        document: validDocument(measurements: [
          <String, dynamic>{
            'id': 101,
            'kind': 'poids',
            'value': 'environ 3 kg',
            'unit': 'g',
            'recordedAtEpochSeconds': 1700000000,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'measurements',
      );
    });

    test('rejects an undecryptable measurement value: there is no number to restore',
        () async {
      await expectRejected(
        document: validDocument(measurements: [
          <String, dynamic>{
            'id': 103,
            'kind': 'temperature',
            'value': null,
            'unit': 'degC',
            'recordedAtEpochSeconds': 1700000000,
            'valueUndecryptable': true,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'measurements',
      );
    });

    test('rejects a duplicate measurement id', () async {
      await expectRejected(
        document: validDocument(measurements: [
          <String, dynamic>{
            'id': 101,
            'kind': 'poids',
            'value': '3400',
            'unit': 'g',
            'recordedAtEpochSeconds': 1700000000,
          },
          <String, dynamic>{
            'id': 101,
            'kind': 'taille',
            'value': '48',
            'unit': 'cm',
            'recordedAtEpochSeconds': 1700000000,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'measurements',
      );
    });

    test('rejects a duplicated setting for the same baby while the other baby may keep the same item',
        () async {
      await expectRejected(
        document: validDocument(reminderSettings: [
          <String, dynamic>{
            'babyId': 'baby_1',
            'itemId': 'miam',
            'enabled': true,
          },
          <String, dynamic>{
            'babyId': 'baby_2',
            'itemId': 'miam',
            'enabled': false,
          },
          <String, dynamic>{
            'babyId': 'baby_1',
            'itemId': 'miam',
            'enabled': false,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'reminderSettings',
      );
    });

    test('keeps the same item legal under two babies', () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        reminderSettings: [
          <String, dynamic>{
            'babyId': 'baby_1',
            'itemId': 'miam',
            'enabled': true,
          },
          <String, dynamic>{
            'babyId': 'baby_2',
            'itemId': 'miam',
            'enabled': false,
          },
        ],
      )));

      expect(parsed.reminderSettings, hasLength(2));
    });

    test(
        'rejects a databaseSchemaVersion newer than the installed schema '
        'rather than dropping its unknown columns', () async {
      await expectRejected(
        document: validDocument(schemaVersion: 99),
        reason: ImportRejectionReason.newerSchemaVersion,
      );
    });

    test('rejects a missing table section', () async {
      final document = validDocument()..remove('reminderDismissals');
      await expectRejected(
        document: document,
        reason: ImportRejectionReason.missingTable,
        section: 'reminderDismissals',
      );
    });

    test('rejects counts that disagree with the payload', () async {
      await expectRejected(
        document: validDocument(counts: <String, dynamic>{
          'babyProfiles': 1,
          'trackingEvents': 99,
          'customReminders': 1,
          'reminderSettings': 1,
          'reminderDismissals': 1,
        }),
        reason: ImportRejectionReason.countsMismatch,
        section: 'trackingEvents',
      );
    });

    test('rejects a file with nothing to restore', () async {
      await expectRejected(
        document: validDocument(
          babyProfiles: const <dynamic>[],
          trackingEvents: const <dynamic>[],
          counts: const <String, dynamic>{
            'babyProfiles': 0,
            'trackingEvents': 0,
            'customReminders': 1,
            'reminderSettings': 1,
            'reminderDismissals': 1,
          },
        ),
        reason: ImportRejectionReason.emptyFile,
      );
    });

    test('rejects an unknown event type', () async {
      await expectRejected(
        document: validDocument(trackingEvents: [
          <String, dynamic>{
            'id': 1,
            'type': 'bain',
            'timestampEpochSeconds': 1700000000,
            'timestampUtc': '2023-11-14T22:13:20.000Z',
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'trackingEvents',
      );
    });

    test('rejects duplicate event ids', () async {
      await expectRejected(
        document: validDocument(trackingEvents: [
          <String, dynamic>{
            'id': 7,
            'type': 'miam',
            'timestampEpochSeconds': 1700000000,
          },
          <String, dynamic>{
            'id': 7,
            'type': 'dodo',
            'timestampEpochSeconds': 1700000100,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'trackingEvents',
      );
    });

    test('rejects a timestamp outside 1990-2100', () async {
      await expectRejected(
        document: validDocument(trackingEvents: [
          <String, dynamic>{
            'id': 1,
            'type': 'miam',
            // Milliseconds where seconds were expected: lands in 1970+.
            'timestampEpochSeconds': 1700000000000,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'trackingEvents',
      );
    });

    test('rejects an unknown custom reminder subtypeValue', () async {
      await expectRejected(
        document: validDocument(customReminders: [
          <String, dynamic>{
            'id': 1,
            'label': 'Soir',
            'subtypeValue': 'soin_inventé',
            'frequency': 'daily',
            'intervalDays': null,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'customReminders',
      );
    });

    test('rejects an interval of zero days', () async {
      await expectRejected(
        document: validDocument(customReminders: [
          <String, dynamic>{
            'id': 1,
            'label': 'Soir',
            'subtypeValue': 'vitamine_d',
            'frequency': 'every_n_days',
            'intervalDays': 0,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'customReminders',
      );
    });

    test('rejects a label longer than the column allows', () async {
      await expectRejected(
        document: validDocument(customReminders: [
          <String, dynamic>{
            'id': 1,
            'label': 'a' * 61,
            'subtypeValue': 'vitamine_d',
            'frequency': 'daily',
            'intervalDays': null,
          },
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'customReminders',
      );
    });

    test('rejects duplicate reminder item ids within one baby', () async {
      await expectRejected(
        document: validDocument(reminderSettings: [
          <String, dynamic>{'babyId': '', 'itemId': 'miam', 'enabled': true},
          <String, dynamic>{'babyId': '', 'itemId': 'miam', 'enabled': false},
        ]),
        reason: ImportRejectionReason.invalidRow,
        section: 'reminderSettings',
      );
    });

    test('parses the ISO fallback when the epoch field is absent', () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        trackingEvents: [
          <String, dynamic>{
            'id': 3,
            'type': 'dodo',
            'timestampUtc': '2023-11-14T22:13:20.000Z',
          },
        ],
        reminderDismissals: [
          <String, dynamic>{
            'itemId': 'vitamine_k',
            'dismissedAtUtc': '2023-11-14T22:13:20.000Z',
          },
        ],
      )));

      expect(parsed.trackingEvents.single.timestamp.toUtc(),
          DateTime.utc(2023, 11, 14, 22, 13, 20));
      expect(parsed.reminderDismissals.single.dismissedAt.toUtc(),
          DateTime.utc(2023, 11, 14, 22, 13, 20));
    });

    test('defaults a missing isActive to true, matching the column default',
        () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        babyProfiles: [
          <String, dynamic>{
            'id': 'baby_9',
            'name': 'Sans isActive',
            'birthDateEpochMs': 1700000000000,
          },
        ],
      )));

      expect(parsed.babyProfiles.single.isActive, isTrue);
    });

    test('enforceBackupSizeLimit refuses an oversized file before reading it',
        () {
      expect(
        () => enforceBackupSizeLimit(knownLength: maxBackupBytes + 1),
        throwsA(isA<ImportFormatException>().having(
            (error) => error.reason, 'reason', ImportRejectionReason.fileTooLarge)),
      );
      // Unknown length is only judged once the bytes are in memory.
      enforceBackupSizeLimit(knownLength: null, actualBytes: 12);
      expect(
        () => enforceBackupSizeLimit(knownLength: null, actualBytes: maxBackupBytes + 1),
        throwsA(isA<ImportFormatException>()),
      );
    });
  });

  group('ImportRepositoryImpl.restore', () {
    late AppDatabase database;
    late _FakeEncryption encryption;
    late ImportRepositoryImpl repository;

    setUp(() {
      database = _openDatabase();
      encryption = _FakeEncryption();
      repository =
          ImportRepositoryImpl(database: database, encryption: encryption);
    });

    tearDown(() async => database.close());

    test('round trip: export then restore reproduces every table', () async {
      final source = _openDatabase();
      addTearDown(source.close);
      await _seedRichDatabase(source, encryption);
      final exported =
          await ExportRepositoryImpl(database: source, encryption: encryption)
              .buildExportJson();

      final counts =
          await repository.restore(await repository.parseExport(exported));

      expect(counts.babyProfiles, 2);
      expect(counts.trackingEvents, 3);
      expect(counts.customReminders, 2);
      expect(counts.reminderSettings, 3);
      expect(counts.reminderDismissals, 1);
      expect(counts.measurements, 2);
      expect(counts.reminderCompletions, 2);

      // Same rows, same ids, same instants.
      final restoredEvents = await database.getAllTrackingEvents();
      final sourceEvents = await source.getAllTrackingEvents();
      expect(
        _sortedById(restoredEvents)
            .map((row) => (row.id, row.type, row.timestamp, row.babyId)),
        _sortedById(sourceEvents)
            .map((row) => (row.id, row.type, row.timestamp, row.babyId)),
      );
      expect(
        await database.getAllBabyProfiles(),
        await source.getAllBabyProfiles(),
      );
      final restoredReminders = await database.getAllCustomReminders();
      final linked = restoredReminders.firstWhere((r) => r.id == 4);
      expect(linked.frequency, 'every_n_days');
      expect(linked.intervalDays, 2);
      // Détaché (M4) : la restauration re-dérive `manual` de `subtypeValue`
      // null et installe la portée par bébé.
      final detached = restoredReminders.firstWhere((r) => r.id == 5);
      expect(detached.subtypeValue, isNull);
      expect(detached.completionSource, 'manual');
      expect(detached.babyId, 'baby_1');
      expect(
        (await database.getAllReminderSettings()).map((row) => row.itemId),
        containsAll(<String>['custom_4', 'vitamine_k', 'custom_5']),
      );
      expect(
        (await database.getAllReminderSettings())
            .firstWhere((row) => row.itemId == 'custom_5')
            .babyId,
        'baby_1',
      );

      // Mesures : ids préservés, chiffres re-chiffrés, notes comprises.
      final restoredMeasurements = await database.getAllMeasurements();
      final weight =
          restoredMeasurements.firstWhere((row) => row.id == 101);
      expect(weight.babyId, 'baby_1');
      expect(weight.kind, 'poids');
      expect(weight.unit, 'g');
      expect(weight.value, startsWith('enc:'));
      expect(encryption.decrypt(weight.value), '3400');
      expect(encryption.decrypt(weight.notes), 'Première pesée');
      final height =
          restoredMeasurements.firstWhere((row) => row.id == 102);
      expect(height.babyId, 'baby_2');
      expect(height.notes, isNull);

      // Achèvements : la portée par bébé et la sentinelle partagée survivent.
      final restoredCompletions = await database.getAllReminderCompletions();
      expect(restoredCompletions.map((row) => (row.babyId, row.itemId)),
          containsAll(<(String, String)>[
            ('', 'custom_4'),
            ('baby_1', 'custom_5'),
          ]));
    });

    test(
        'export, restore, export again: the two documents are identical — '
        'the guard against the two halves drifting apart', () async {
      final source = _openDatabase();
      addTearDown(source.close);
      await _seedRichDatabase(source, encryption);
      final exporter =
          ExportRepositoryImpl(database: source, encryption: encryption);
      final first = await exporter.buildExportJson();

      await repository.restore(await repository.parseExport(first));

      // La cible est une base restaurée, pas la source : on l'exporte avec son
      // propre repository. Les deux moitiés ne se connaissent que par le JSON.
      final second = await ExportRepositoryImpl(
        database: database,
        encryption: encryption,
      ).buildExportJson();

      // Le document exporte des valeurs **en clair** (conception assumée, see
      // the file dartdoc) : le renouvellement du IV à la restauration est donc
      // invisible ici. La seule chose qui bouge légitimement est l'horodatage.
      // Tout le reste doit être le même document, octet pour octet.
      expect(
        _withoutVolatileFields(second),
        equals(_withoutVolatileFields(first)),
        reason: 'un champ écrit par l''exporteur ne survit pas au passage '
            'restauration puis réexport : le format des sauvegardes vient de '
            'diverger en silence',
      );
    });

    test('a solid food event survives export → restore → export with its subtype and quantity intact', () async {
      // Le sous-type 'solid' n'a pas de whitelist de validation dans l'import :
      // il doit donc survivre intact, comme n'importe quelle valeur
      // d'alimentation (pas de conversion silencieuse ni de rejet).
      final source = _openDatabase();
      addTearDown(source.close);
      await source.insertEvent(TrackingEventsCompanion.insert(
        type: 'miam',
        subtype: const Value('solid'),
        quantity: const Value(40.0),
        timestamp: DateTime.utc(2024, 3, 1, 12),
      ));
      final first =
          await ExportRepositoryImpl(database: source, encryption: encryption)
              .buildExportJson();

      await repository.restore(await repository.parseExport(first));

      final restored = (await database.getAllTrackingEvents()).single;
      expect(restored.type, 'miam');
      expect(restored.subtype, 'solid');
      expect(restored.quantity, 40.0);

      // Re-export : le document reste stable, sous-type et quantité intacts.
      final second = await ExportRepositoryImpl(
        database: database,
        encryption: encryption,
      ).buildExportJson();
      expect(_withoutVolatileFields(second), equals(_withoutVolatileFields(first)));
    });

    test('format 1: a pre-M4 backup restores into shared rows, empty new tables',
        () async {
      final counts =
          await repository.restore(await repository.parseExport(
        _jsonOf(formatOneDocument()),
      ));

      expect(counts.babyProfiles, 1);
      expect(counts.trackingEvents, 1);
      expect(counts.customReminders, 1);
      expect(counts.measurements, 0);
      expect(counts.reminderCompletions, 0);

      final reminder = (await database.getAllCustomReminders()).single;
      expect(reminder.babyId, '');
      expect(reminder.completionSource, 'from_events');
      expect(reminder.subtypeValue, 'nettoyage_nez');
      expect((await database.getAllReminderSettings()).single.babyId, '');
      expect((await database.getAllReminderDismissals()).single.babyId, '');
      expect(await database.getAllMeasurements(), isEmpty);
      expect(await database.getAllReminderCompletions(), isEmpty);
    });

    test('export → restore → export is the same document', () async {
      final source = _openDatabase();
      addTearDown(source.close);
      await _seedRichDatabase(source, encryption);
      final exporter =
          ExportRepositoryImpl(database: source, encryption: encryption);
      final first = await exporter.buildExportJson();

      final target = _openDatabase();
      addTearDown(target.close);
      final targetRepository =
          ImportRepositoryImpl(database: target, encryption: encryption);
      await targetRepository.restore(await targetRepository.parseExport(first));
      final second =
          await ExportRepositoryImpl(database: target, encryption: encryption)
              .buildExportJson();

      expect(
        _withoutVolatileFields(second),
        _withoutVolatileFields(first),
        reason: 'a restore must not reinterpret any stored value',
      );
    });

    test('replace semantics: rows absent from the file are gone', () async {
      await _seedRichDatabase(database, encryption);
      final exported =
          await ExportRepositoryImpl(database: database, encryption: encryption)
              .buildExportJson();
      // Then add a row that no file mentions.
      await database.insertEvent(TrackingEventsCompanion.insert(
        type: 'dodo',
        timestamp: DateTime.utc(2024, 1, 1),
      ));
      expect((await database.getAllTrackingEvents()).length, 4);

      await repository.restore(await repository.parseExport(exported));

      expect((await database.getAllTrackingEvents()).length, 3);
    });

    test('notes are stored as ciphertext again, decrypting to the file text',
        () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument()));

      await repository.restore(parsed);

      final stored = (await database.getAllTrackingEvents()).single;
      // The fake writes 'enc:…' — proving the plaintext never reached the row.
      expect(stored.notes, startsWith('enc:'));
      expect(encryption.decrypt(stored.notes), '100 ml vers 8h');
    });

    test('a fresh database continues its numbering after the restored ids',
        () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        trackingEvents: [
          <String, dynamic>{
            'id': 41,
            'type': 'miam',
            'timestampEpochSeconds': 1700000000,
          },
          <String, dynamic>{
            'id': 42,
            'type': 'dodo',
            'timestampEpochSeconds': 1700000100,
          },
        ],
      )));

      await repository.restore(parsed);
      final nextId = await database.insertEvent(TrackingEventsCompanion.insert(
        type: 'caca',
        timestamp: DateTime.utc(2024, 2, 2),
      ));

      expect(nextId, 43);
    });

    test(
        'a database that already used a higher id never reuses or collides: '
        'sqlite_sequence is monotonic, not restored', () async {
      await database.insertEvent(TrackingEventsCompanion.insert(
        id: const Value(900),
        type: 'miam',
        timestamp: DateTime.utc(2024, 1, 1),
      ));
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        trackingEvents: [
          <String, dynamic>{
            'id': 2,
            'type': 'dodo',
            'timestampEpochSeconds': 1700000000,
          },
        ],
      )));

      await repository.restore(parsed);
      final nextId = await database.insertEvent(TrackingEventsCompanion.insert(
        type: 'caca',
        timestamp: DateTime.utc(2024, 2, 2),
      ));

      // DELETE FROM does not reset sqlite_sequence, so the counter keeps the
      // highest id this device ever used rather than the file's.
      expect(nextId, greaterThan(900));
      expect((await database.getAllTrackingEvents()).map((row) => row.id),
          contains(nextId));
    });

    test('promotes the oldest profile when the file has none active', () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        babyProfiles: [
          <String, dynamic>{
            'id': 'b_late',
            'name': 'Grand',
            'birthDateEpochMs': 1700000000000,
            'isActive': false,
          },
          <String, dynamic>{
            'id': 'b_early',
            'name': 'Ainé',
            'birthDateEpochMs': 1600000000000,
            'isActive': false,
          },
        ],
      )));

      await repository.restore(parsed);

      final active = await database.getActiveBabyProfile();
      expect(active?.id, 'b_early');
    });

    test('leaves an active profile alone', () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        babyProfiles: [
          <String, dynamic>{
            'id': 'b_late',
            'name': 'Grand',
            'birthDateEpochMs': 1700000000000,
            'isActive': true,
          },
          <String, dynamic>{
            'id': 'b_early',
            'name': 'Ainé',
            'birthDateEpochMs': 1600000000000,
            'isActive': false,
          },
        ],
      )));

      await repository.restore(parsed);

      expect((await database.getActiveBabyProfile())?.id, 'b_late');
    });

    test('a file with events and no profile restores without inventing one',
        () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        babyProfiles: const <dynamic>[],
        counts: const <String, dynamic>{
          'babyProfiles': 0,
          'trackingEvents': 1,
          'customReminders': 1,
          'reminderSettings': 1,
          'reminderDismissals': 1,
        },
      )));

      final counts = await repository.restore(parsed);

      expect(counts.babyProfiles, 0);
      expect(await database.getAllBabyProfiles(), isEmpty);
      expect((await database.getAllTrackingEvents()).length, 1);
    });

    test('orphans keep the babyId the file gave them', () async {
      final parsed = await repository.parseExport(_jsonOf(validDocument(
        trackingEvents: [
          <String, dynamic>{
            'id': 5,
            'type': 'miam',
            'timestampEpochSeconds': 1700000000,
            'babyId': 'baby_of_deleted_child',
          },
        ],
      )));

      await repository.restore(parsed);

      expect((await database.getAllTrackingEvents()).single.babyId,
          'baby_of_deleted_child');
    });

    test(
        'a write the database itself rejects rolls the whole restore back',
        () async {
      await repository.restore(await repository.parseExport(
          _jsonOf(validDocument())));
      final before = await _allCounts(database);
      expect(before['trackingEvents'], 1);

      // A ParsedExport built by hand, bypassing the parser, so the *database*
      // rejects the label (withLength(max: 60)) after the deletes have run.
      final impossible = ParsedExport(
        babyProfiles: [
          const ImportedBabyProfile(
            id: 'newborn',
            name: 'Nouveau',
            birthDateEpochMs: 1700000000000,
            isActive: true,
          ),
        ],
        trackingEvents: [
          ImportedTrackingEvent(
            id: 77,
            type: 'miam',
            timestamp: DateTime.utc(2024, 3, 3),
            duration: null,
            subtype: 'natural',
            notes: 'note qui ne survivra pas',
            wasteType: null,
            color: null,
            texture: null,
            babyId: 'newborn',
            quantity: null,
          ),
        ],
        customReminders: [
          ImportedCustomReminder(
            id: 1,
            label: 'x' * 200,
            subtypeValue: 'vitamine_d',
            frequency: 'daily',
            intervalDays: null,
            babyId: '',
            completionSource: 'from_events',
          ),
        ],
        reminderSettings: const [
          ImportedReminderSetting(babyId: '', itemId: 'miam', enabled: false),
        ],
        reminderDismissals: const [],
      );

      await expectLater(repository.restore(impossible), throwsA(anything));

      expect(
        await _allCounts(database),
        before,
        reason: 'a half-applied restore must not exist',
      );
      expect((await database.getAllBabyProfiles()).map((row) => row.id),
          isNot(contains('newborn')));
    });
  });
}

/// Drops the fields that legitimately differ between two exports (clock,
/// appVersion) so the rest can be compared as data.
Object _withoutVolatileFields(String document) {
  final decoded = jsonDecode(document) as Map<String, dynamic>;
  decoded.remove('exportedAt');
  decoded.remove('appVersion');
  return decoded;
}

/// Plain selects have no guaranteed order, so comparisons are id-keyed.
List<TrackingEvent> _sortedById(List<TrackingEvent> rows) =>
    [...rows]..sort((a, b) => a.id.compareTo(b.id));

/// Two profiles, three events (one with a note, one orphan, one diaper with
/// every column set), a custom reminder, its setting and a dismissal.
Future<void> _seedRichDatabase(AppDatabase database,
    EncryptionService encryption) async {
  final birth = 1700000000000;
  final timestamp = DateTime.fromMillisecondsSinceEpoch(birth, isUtc: true);
  await database.insertBabyProfile(BabyProfilesCompanion.insert(
    id: 'baby_1',
    name: 'Bébé Test',
    birthDate: birth,
    isActive: const Value(true),
  ));
  await database.insertBabyProfile(BabyProfilesCompanion.insert(
    id: 'baby_2',
    name: 'Deuxième',
    birthDate: birth + 1000,
    isActive: const Value(false),
  ));
  await database.insertEvent(TrackingEventsCompanion.insert(
    id: const Value(11),
    type: 'miam',
    timestamp: timestamp,
    subtype: const Value('natural'),
    notes: Value(encryption.encrypt('100 ml vers 8h')),
    babyId: const Value('baby_1'),
    quantity: const Value(100),
  ));
  await database.insertEvent(TrackingEventsCompanion.insert(
    id: const Value(12),
    type: 'caca',
    timestamp: timestamp,
    wasteType: const Value('caca'),
    color: const Value('meconium'),
    texture: const Value('pateuse'),
    babyId: const Value('baby_2'),
  ));
  await database.insertEvent(TrackingEventsCompanion.insert(
    id: const Value(13),
    type: 'dodo',
    timestamp: timestamp,
    duration: const Value(50),
    babyId: const Value('baby_ghost'),
  ));
  await database.into(database.customReminders).insert(
        CustomRemindersCompanion.insert(
          id: const Value(4),
          label: 'Nettoyage nez du soir',
          subtypeValue: const Value('nettoyage_nez'),
          frequency: 'every_n_days',
          intervalDays: const Value(2),
        ),
      );
  // Rappel détaché scopé par bébé (M4) : la restauration doit re-dériver
  // `manual` et garder la portée.
  await database.into(database.customReminders).insert(
        CustomRemindersCompanion.insert(
          id: const Value(5),
          babyId: const Value('baby_1'),
          label: 'Vitamine du soir',
          subtypeValue: const Value(null),
          completionSource: const Value('manual'),
          frequency: 'weekly',
        ),
      );
  await database.into(database.reminderSettings).insert(
        ReminderSettingsCompanion.insert(itemId: 'custom_4', enabled: true),
      );
  await database.into(database.reminderSettings).insert(
        ReminderSettingsCompanion.insert(itemId: 'vitamine_k', enabled: false),
      );
  await database.into(database.reminderSettings).insert(
        ReminderSettingsCompanion.insert(
          babyId: const Value('baby_1'),
          itemId: 'custom_5',
          enabled: true,
        ),
      );
  await database.into(database.reminderDismissals).insert(
        ReminderDismissalsCompanion.insert(
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
          notes: Value(encryption.encrypt('Première pesée')),
        ),
      );
  await database.into(database.measurements).insert(
        MeasurementsCompanion.insert(
          id: const Value(102),
          babyId: const Value('baby_2'),
          kind: 'taille',
          value: encryption.encrypt('48'),
          unit: 'cm',
          recordedAt: timestamp,
        ),
      );
  await database.into(database.reminderCompletions).insert(
        ReminderCompletionsCompanion.insert(
          itemId: 'custom_4',
          completedAt: timestamp,
        ),
      );
  await database.into(database.reminderCompletions).insert(
        ReminderCompletionsCompanion.insert(
          babyId: const Value('baby_1'),
          itemId: 'custom_5',
          completedAt: timestamp,
        ),
      );
}

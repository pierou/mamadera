// ignore_for_file: avoid_print
/// Release gate — v1.3.1 (build 15): the two iPhone bugs reported 2026-11-08.
///
/// ## Why this file exists
///
/// Both defects were invisible to the unit suite because each one lives in the
/// seam between two components that are each individually correct:
///
/// * **Case 1** — first launch, parent types only a name, confirms, and the
///   baby never appears under Settings → Babies. `OnboardingDialog._saveProfile`
///   refreshed `activeBabyProvider` and `anyBabyExistsProvider` but not
///   `babyProfileListProvider`, which is the provider `BabyProfileSection`
///   watches — and that keep-alive provider had *already* been resolved to the
///   empty list by the first-frame reminder sync. No widget test spans the
///   sheet, the lifecycle sync and the Menu, so nothing caught it.
/// * **Case 2** — a backup written by a real device was refused outright.
///   `reminder_completions` is an append-only journal of "done" taps, so the
///   same `(babyId, itemId)` legitimately repeats; the importer enforced the
///   uniqueness rule that belongs to `reminderDismissals`, whose primary key
///   that pair really is. Every family that used a daily custom reminder for
///   more than one day had an unrestorable backup.
///
/// Case 1 is asserted here through the **real widget tree** — the same
/// `MyApp`, the same `ProviderScope`, the same `ReminderLifecycleSyncWidget`
/// that primes the stale cache on a cold start, on a device. Case 2 runs the
/// importer against a real drift database on the device's own SQLite.
///
/// ## Run
///
/// ```bash
/// flutter test integration_test/gate_v131_fixes.dart --no-uninstall -d emulator-5554
/// ```
///
/// `--no-uninstall` keeps the captures: they are written inside the app sandbox
/// and extracted from the host with
///
/// ```bash
/// adb -s emulator-5554 exec-out run-as com.pvjio.mamadera \
///   cat app_flutter/gate/<name>.png > <name>.png
/// ```
///
/// `[GATE]` lines are the pass/fail record quoted in the PR description.
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/import/data/repositories/import_repository_impl.dart';
import 'package:mamadera/features/import/domain/repositories/import_repository.dart';
import 'package:path_provider/path_provider.dart';

import 'test_utils.dart';

/// Deterministic stand-in for the keystore-backed service: this gate is about
/// which rows survive a restore, not about AES.
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

/// Writes a PNG into the app's Documents so the host can extract it.
///
/// Relative paths raise `errno 30 Read-only file system` on iOS, hence
/// `getApplicationDocumentsDirectory()` (same helper `pickers_gate_rc2` uses).
Future<void> capture(WidgetTester tester, String name) async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle(const Duration(milliseconds: 400));

  final bytes = await binding.takeScreenshot(name);
  final documents = await getApplicationDocumentsDirectory();
  final dir = io.Directory('${documents.path}/gate');
  await dir.create(recursive: true);
  final file = io.File('${dir.path}/$name.png');
  await file.writeAsBytes(bytes);
  print('[CAPTURE] ✓ ${file.path} (${bytes.length} bytes)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('v1.3.1 gate — first launch with only a name', () {
    testWidgets('case 1: the name reaches Settings → Babies', (tester) async {
      // The real app, real providers, empty database: exactly the state a
      // parent's phone is in when the sheet opens. `babyExistsOverride: false`
      // leaves `anyBabyExistsProvider` unstubbed so the sheet really appears.
      await pumpMamadera(tester, babyExistsOverride: false);
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget,
          reason: 'the onboarding sheet should be open on a fresh install');
      print('[GATE] case1 sheet open, 1 TextField');
      await capture(tester, 'v131-01-onboarding-sheet');

      // The reported interaction: a name and nothing else. The birth date is
      // left at the value the sheet shows, which is what the user did.
      await tester.enterText(nameField, 'Lea');
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      print('[GATE] case1 confirmed "Lea" with the default birth date');

      // The sheet is gone and the profile is the active baby — the header
      // proves the row exists in the database, so what follows cannot fail for
      // a different reason.
      expect(find.byType(TextField), findsNothing,
          reason: 'the sheet must close after a successful save');
      expect(find.text('Lea'), findsWidgets,
          reason: 'the home header reads the active baby');
      print(
          '[GATE] case1 home header shows "Lea" → profile is in the database');

      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle();
      await capture(tester, 'v131-02-menu-baby-section');

      // The bug: this section rendered `babyProfileListProvider`'s cached empty
      // list, so it said "No baby profiles yet" above a database that held the
      // profile the parent had just typed.
      expect(find.text('No baby profiles yet'), findsNothing,
          reason: 'Settings still renders the stale empty list — the profile '
              'exists in the database but is invisible until an app restart');
      final tiles = find.text('Lea');
      expect(tiles, findsWidgets,
          reason: 'the baby row is missing from Settings → Babies');
      print('[GATE] case1 PASS — Settings lists "Lea" without a restart');
    });
  });

  group('v1.3.1 gate — the journal a real device writes', () {
    testWidgets('case 2: repeated (babyId, itemId) completions restore',
        (tester) async {
      final database = AppDatabase(
        LazyDatabase(() async => NativeDatabase.memory()),
      );
      addTearDown(database.close);
      // Force onCreate so every table exists before the first statement.
      await database.select(database.reminderDismissals).get();

      // Four taps on one daily custom reminder, four days apart — the exact
      // shape of `mamadera-export-20261108-094149.json` from the iPhone, which
      // carries four `custom_1` rows. No unique constraint exists on this
      // journal (`id` is the primary key), so all four are legal rows.
      const epoch = [1793392839, 1793410636, 1793559392, 1793837193];
      final document = <String, dynamic>{
        'exportFormatVersion': 4,
        'generator': 'mamadera',
        'appVersion': '1.3.1',
        'databaseSchemaVersion': database.schemaVersion,
        'exportedAt': '2026-11-08T08:41:49.185921Z',
        'counts': <String, dynamic>{
          'babyProfiles': 1,
          'trackingEvents': 1,
          'customReminders': 1,
          'reminderSettings': 0,
          'reminderDismissals': 0,
          'measurements': 0,
          'reminderCompletions': epoch.length,
          'appSettings': 0,
        },
        'babyProfiles': [
          {
            'id': '1791835830965',
            'name': 'Lea',
            'birthDateEpochMs': 1779400800000,
            'birthDateUtc': '2026-05-21T22:00:00.000Z',
            'isActive': true,
          },
        ],
        'trackingEvents': [
          {
            'id': 1,
            'type': 'sante',
            'timestampEpochSeconds': 1792105066,
            'timestampUtc': '2026-10-15T22:57:46.000Z',
            'durationMinutes': null,
            'subtype': 'vitamine_d',
            'notes': null,
            'wasteType': null,
            'color': null,
            'texture': null,
            'babyId': '1791835830965',
            'quantity': null,
            'unit': 'ml',
          },
        ],
        'customReminders': [
          {
            'id': 1,
            'label': 'Noter les cacas du jour',
            'subtypeValue': null,
            'frequency': 'daily',
            'intervalDays': null,
            'babyId': '1791835830965',
            'completionSource': 'manual',
          },
        ],
        'reminderSettings': <dynamic>[],
        'reminderDismissals': <dynamic>[],
        'measurements': <dynamic>[],
        'appSettings': <dynamic>[],
        'reminderCompletions': [
          for (final at in epoch)
            {
              'babyId': '1791835830965',
              'itemId': 'custom_1',
              'completedAtEpochSeconds': at,
              'completedAtUtc':
                  DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true)
                      .toIso8601String(),
            },
        ],
      };

      final repository = ImportRepositoryImpl(
        database: database,
        encryption: _FakeEncryption(),
      );

      ImportRejectionReason? rejection;
      try {
        final parsed = await repository.parseExport(jsonEncode(document));
        final counts = await repository.restore(parsed);
        expect(counts.reminderCompletions, epoch.length);
        print('[GATE] case2 parsed+restored: ${counts.reminderCompletions} '
            'journal rows for one (babyId, itemId)');
      } on ImportFormatException catch (error) {
        rejection = error.reason;
      }

      expect(rejection, isNull,
          reason: 'the backup a real device writes was refused as '
              '"${rejection?.name}" — that is the v1.3.1 restore bug');

      final rows = await database.getAllReminderCompletions();
      expect(rows, hasLength(epoch.length));
      expect(rows.map((row) => row.itemId).toSet(), {'custom_1'});
      // Fresh auto-increment ids: the journal carries no id in the document.
      expect(rows.map((row) => row.id).toSet(), hasLength(epoch.length));
      print('[GATE] case2 PASS — ${rows.length} rows on the device, ids '
          '${rows.map((row) => row.id).join(',')}');

      // The other half of the asymmetry: `reminder_dismissals` has that pair as
      // its primary key, so a file repeating it is a duplicate row.
      Object? dismissedTwice;
      try {
        await repository.parseExport(jsonEncode(<String, dynamic>{
          ...document,
          'reminderDismissals': [
            <String, dynamic>{
              'babyId': '1791835830965',
              'itemId': 'vitamine_d',
              'dismissedAtEpochSeconds': 1792065524,
            },
            <String, dynamic>{
              'babyId': '1791835830965',
              'itemId': 'vitamine_d',
              'dismissedAtEpochSeconds': 1792151924,
            },
          ],
          'counts': <String, dynamic>{
            ...document['counts']! as Map<String, dynamic>,
            'reminderDismissals': 2,
          },
        }));
      } on ImportFormatException catch (error) {
        dismissedTwice = error.reason;
      }
      expect(dismissedTwice, ImportRejectionReason.invalidRow,
          reason: 'a dismissal repeated for one baby is a duplicate primary '
              'key and must still reject the file');
      print('[GATE] case2 dismissals still reject a duplicate pair');
    });
  });
}

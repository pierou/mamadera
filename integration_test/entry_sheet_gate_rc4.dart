// ignore_for_file: avoid_print
/// Entry-sheet gate v1.2.1-rc.4: the last measured value shows without a label.
///
/// ## Why this file exists
///
/// rc.4 changes how the measurement entry sheet presents the parent's last
/// measurement: the header used to read "Dernière : 36,8 °C" (fr) / "Last: 36.8 °C"
/// (en); it now reads the value directly, "36,8 °C" — exactly like the type's
/// reference value already did when no measurement exists. The `value`
/// placeholder key `growthSheetLastValueHint` is gone from the three ARB files.
///
/// This file provides the device evidence, per the AGENTS.md release gate:
/// the touched screen (the entry sheet) on the smallest target and a normal
/// one, with a prior measurement seeded, plus the manual entry path
/// (record a measurement, then export and inspect the JSON).
///
/// ## Lancement
///
/// Both targets use `flutter test` (not `flutter drive` — see the rc.2 gate
/// header for why):
///
/// ```bash
/// # Android — AVD Small_Phone, 360×640 dp, the narrowest target device.
/// flutter test integration_test/entry_sheet_gate_rc4.dart -d emulator-5554
/// # Android — a normal-sized device.
/// flutter test integration_test/entry_sheet_gate_rc4.dart -d <pixel_10_pro_id>
/// ```
///
/// PNG files land in the app's **Documents** directory, then leave the
/// sandbox: `adb exec-out run-as <app> cat .../Documents/gate/<name>.png`.
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' hide TrackingEvent;
import 'package:mamadera/features/export/data/repositories/export_repository_impl.dart';
import 'package:mamadera/features/growth/data/repositories/measurement_repository_impl.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';
import 'package:mamadera/main.dart';
import 'package:path_provider/path_provider.dart';

import 'test_utils.dart';

/// Fixture baby id — a proper noun, identical in every locale.
const _babyId = 'baby-gate-rc4';

/// Prior measurements — round-ish numbers, one per kind.
const _lastWeightG = 6120;
const _lastHeightCm = 60.5;
const _lastTempC = 37.2;

/// Live database and encryption: the export case re-reads the database with
/// the SAME `EncryptionService` instance the app was given — two instances
/// can encrypt with different keys when secure storage is unavailable, which
/// would make every measurement read "unreadable".
AppDatabase? _liveDb;
late EncryptionService _liveEncryption;

/// One baby, one measurement per kind: every entry sheet has a "last value"
/// to display.
Future<(AppDatabase, EncryptionService)> _seededEnv() async {
  final db = AppDatabase(NativeDatabase.memory());
  final encryption = EncryptionService();
  await encryption.initialize();

  final now = DateTime.now();
  await db.insertBabyProfile(
    BabyProfilesCompanion.insert(
      id: _babyId,
      name: 'Léa',
      birthDate: now.subtract(const Duration(days: 87)).millisecondsSinceEpoch,
      isActive: const Value(true),
    ),
  );

  // Through the repository, never a raw insert: `value` and `notes` are
  // encrypted.
  final measurements = MeasurementRepositoryImpl(
    database: db,
    encryption: encryption,
  );
  Future<void> measure(MeasureKind kind, double value, Duration ago) =>
      measurements.add(
        babyId: _babyId,
        kind: kind,
        value: value,
        recordedAt: now.subtract(ago),
      );

  await measure(
      MeasureKind.poids, _lastWeightG.toDouble(), const Duration(days: 3));
  await measure(MeasureKind.taille, _lastHeightCm, const Duration(days: 10));
  await measure(MeasureKind.temperature, _lastTempC, const Duration(hours: 20));

  return (db, encryption);
}

/// Pumps the real app on the fixture, in [locale].
Future<void> pumpSeededApp(WidgetTester tester,
    {required String locale}) async {
  if (_liveDb != null) {
    await _liveDb!.close();
    _liveDb = null;
  }
  final (db, encryption) = await _seededEnv();
  _liveDb = db;
  _liveEncryption = encryption;

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsApp.debugAllowBannerOverride = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(() => ConfigurableLocaleNotifier(locale)),
        appPreferencesProvider.overrideWith(AcceptedTermsNotifier.new),
        anyBabyExistsProvider.overrideWith(BabyExistsNotifier.new),
        databaseProvider.overrideWith((ref) async => db),
        encryptionServiceProvider.overrideWith((ref) async => encryption),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Opens the entry sheet for [label] from the home screen (the growth
/// buttons carry the kind label: "Poids"/"Weight"…).
Future<void> openEntrySheet(WidgetTester tester, String label) async {
  await tester.tap(findByKey(TestKeys.homeTab));
  await tester.pumpAndSettle(const Duration(seconds: 1));
  // `.last`: the label also appears in the growth section title.
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// The whole point of rc.4, asserted on the sheet:
///
/// - the sheet header shows [bareValue] — the value, nothing in front of it;
/// - [forbidden] ("Dernière" / "Last:") appears nowhere on the screen;
/// - the slider sits on the last measurement, the text field is still empty
///   and Save disabled (a cursor position is not an input — rc.3's rule);
/// - nothing overflows.
void expectBareLastValue(
  WidgetTester tester, {
  required String bareValue,
  required String forbidden,
  required double sliderValue,
  required String surface,
}) {
  expect(
    find.descendant(
      of: find.byType(QuantityPickerInline),
      matching: find.text(bareValue),
    ),
    findsOneWidget,
    reason: "$surface : l'en-tête doit lire « $bareValue » seul",
  );
  expect(
    find.textContaining(forbidden),
    findsNothing,
    reason:
        "$surface : l'étiquette « $forbidden » doit être absente de l'écran",
  );
  expect(
    tester.widgetList<Slider>(find.byType(Slider)).single.value,
    sliderValue,
    reason: '$surface : le curseur part de la dernière mesure',
  );
  final field = tester.widget<TextField>(
    find.descendant(
      of: find.byType(QuantityPickerInline),
      matching: find.byType(TextField),
    ),
  );
  expect(field.controller!.text, isEmpty,
      reason: '$surface : le champ reste vide sans saisie réelle');
  final save = tester.widget<ElevatedButton>(
    find
        .ancestor(
          of: find.text('Enregistrer'),
          matching: find.byType(ElevatedButton),
        )
        .first,
  );
  expect(save.onPressed, isNull,
      reason: '$surface : Enregistrer reste désarmé sans saisie');
  expect(tester.takeException(), isNull,
      reason: '$surface : aucun overflow ni exception au rendu');
  print('[GATE] $surface → en-tête « $bareValue », curseur à $sliderValue, '
      'champ vide, enregistrer désarmé — « $forbidden » absent');
}

/// Capture: the app writes the PNG to its Documents directory; the host
/// copies it out of the sandbox (`adb exec-out run-as` on Android).
///
/// [convert] stays true for the FIRST capture of a test: the binding
/// converts the Flutter surface to an image once per test, a second call
/// asserts "Surface already converted". Later shots grab the (already
/// converted) surface directly.
Future<void> capture(WidgetTester tester, String name,
    {bool convert = true}) async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  if (convert) {
    await binding.convertFlutterSurfaceToImage();
  }
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
  group('Porte rc.4 — dernière mesure sans étiquette', () {
    testWidgets("fr · poids : l'en-tête lit « 6,12 kg »", (tester) async {
      await pumpSeededApp(tester, locale: 'fr');
      await openEntrySheet(tester, 'Poids');

      expectBareLastValue(
        tester,
        bareValue: '6,12 kg',
        forbidden: 'Dernière',
        sliderValue: _lastWeightG.toDouble(),
        surface: 'poids · fr',
      );
      await capture(tester, '01_fiche_poids_fr');
    });

    testWidgets("fr · température : l'en-tête lit « 37,2 °C »", (tester) async {
      await pumpSeededApp(tester, locale: 'fr');
      await openEntrySheet(tester, 'Température');

      expectBareLastValue(
        tester,
        bareValue: '37,2 °C',
        forbidden: 'Dernière',
        sliderValue: _lastTempC,
        surface: 'température · fr',
      );
      await capture(tester, '02_fiche_temperature_fr');
    });

    testWidgets("fr · taille : l'en-tête lit « 60,5 cm »", (tester) async {
      await pumpSeededApp(tester, locale: 'fr');
      await openEntrySheet(tester, 'Taille');

      expectBareLastValue(
        tester,
        bareValue: '60,5 cm',
        forbidden: 'Dernière',
        sliderValue: _lastHeightCm,
        surface: 'taille · fr',
      );
      await capture(tester, '03_fiche_taille_fr');
    });

    testWidgets('en · poids : the header reads "6.12 kg", no "Last:"',
        (tester) async {
      await pumpSeededApp(tester, locale: 'en');
      await openEntrySheet(tester, 'Weight');

      expect(
        find.descendant(
          of: find.byType(QuantityPickerInline),
          matching: find.text('6.12 kg'),
        ),
        findsOneWidget,
        reason: 'weight · en : the header must read "6.12 kg" alone',
      );
      expect(find.textContaining('Last:'), findsNothing,
          reason: 'weight · en : the "Last:" label is gone');
      expect(tester.widgetList<Slider>(find.byType(Slider)).single.value,
          _lastWeightG.toDouble(),
          reason: 'weight · en : the slider starts on the last measurement');
      expect(tester.takeException(), isNull,
          reason: 'weight · en : no overflow or exception');
      print('[GATE] poids · en → header "6.12 kg", no "Last:" label');
      await capture(tester, '04_entry_sheet_en');
    });

    testWidgets('saisie manuelle puis export : le nombre survit',
        (tester) async {
      await pumpSeededApp(tester, locale: 'fr');
      await openEntrySheet(tester, 'Poids');

      // The parent's path: the field is empty, the keyboard sets the exact
      // value, then Save arms.
      await tester.enterText(
        find.descendant(
          of: find.byType(QuantityPickerInline),
          matching: find.byType(TextField),
        ),
        '6135',
      );
      await tester.pumpAndSettle();
      expect(find.text('6135 g'), findsWidgets);
      await capture(tester, '05_saisie_poids');

      final saveLabel = find.text('Enregistrer');
      final save = find.ancestor(
        of: saveLabel,
        matching: find.byType(ElevatedButton),
      );
      expect(
        tester.widget<ElevatedButton>(save.first).onPressed,
        isNotNull,
        reason: 'la saisie au clavier doit armer Enregistrer',
      );
      await tester.ensureVisible(save.first);
      await tester.pumpAndSettle();
      await tester.tap(save.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      // Plain text finder: a `.first`-wrapped finder throws on an empty
      // tree instead of matching `findsNothing`.
      expect(saveLabel, findsNothing,
          reason: 'la fiche doit se fermer sur enregistrement');

      // Home shows the new value without leaving the screen (rc.3's refresh).
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(
        find.text('6,135 kg'),
        findsWidgets,
        reason: "l'accueil suit la nouvelle mesure",
      );
      await capture(tester, '06_home_apres_saisie', convert: false);

      // The exported document is inspected here, not in the share sheet:
      // a missing or stale measurement would not be visible on screen.
      final source = await ExportRepositoryImpl(
        database: _liveDb!,
        encryption: _liveEncryption,
      ).buildExportJson();
      final gateDir = io.Directory(
          '${(await getApplicationDocumentsDirectory()).path}/gate');
      await gateDir.create(recursive: true);
      await io.File('${gateDir.path}/export.json').writeAsString(source);

      final doc = jsonDecode(source) as Map<String, dynamic>;
      final measurements =
          (doc['measurements'] as List<dynamic>).cast<Map<String, dynamic>>();
      // `value` is stored (and exported) as the decimal string of the number
      // in its base unit: accept either shape, compare as a number.
      double parsed(Object? raw) =>
          raw is num ? raw.toDouble() : double.parse(raw as String);
      expect(
        measurements
            .any((m) => m['kind'] == 'poids' && parsed(m['value']) == 6135),
        isTrue,
        reason: 'le 6135 tapé au clavier doit être le 6135 exporté',
      );
      print('[GATE] export → format ${doc['exportFormatVersion']}, '
          '${measurements.length} mesures, 6135 g présent');
    });
  });
}

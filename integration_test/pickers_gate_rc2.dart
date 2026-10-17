// ignore_for_file: avoid_print
/// Control panel v1.2.1-rc.2: Only one slider per input field.
///
/// ## Why this file exists.
///
/// The "rough/precise" pair (BACKLOG B2) was introduced in version 1.2.1.
/// The `QuantityPickerInline` shared widget: a single parameter, with five display elements.
/// touched by a stroke - new grip, edition of a grip, edition of a...
/// siesta, new measure, edit a measure. Open on a device, the...
/// The document posed the question, "Which of the two should I move?" without providing an answer.
/// respond; therefore, the pair is removed (docs/BACKLOG.md B2).
///
/// This file provides visual and numerical proof of the withdrawal. For each...
/// on the surface, it checks that there is **exactly one** `Slider` element, and that it covers...
/// **The entire** beach (and not just a recentered window), and the labels.
/// The "Rough" / "Precise" (French) options have been removed, but the plus/minus buttons are still present.
/// and that no rendering errors (specifically, `RenderFlex` overflow errors) are raised.
/// The overflow is silent in unit tests that report their own results.
/// viewport, but it's not displayed on a real screen.
///
/// Final test: the complete manual control scheme – use the cursor to aim, and +/- to adjust.
/// quantum, keyboard for entering the exact value – then the document is exported and inspected.
/// It's transmitted byte by byte. It's the same document that the sharing panel receives.
/// A backup that omits a section is a faulty backup, and nothing...
/// It displays the signal on the screen.
///
/// ## Lancement
///
/// Both platforms use `flutter test` (while `flutter drive` raises...).
/// "Binding is already initialized" on target `integration_test`):
///
/// ```bash
/// # iOS - Simulator started.
/// flutter test integration_test/pickers_gate_rc2.dart -d <udid>
/// # Android — AVD Small_Phone, 360x640 dp, the narrowest target device.
/// flutter test integration_test/pickers_gate_rc2.dart -d emulator-5554
/// ```
///
/// PNG files are stored in the app's **Documents** directory (using the `path_provider` package).
/// (Relative path raises `errno 30` on iOS), then exits the sandbox:
/// iOS uses the container's host path, while Android uses...
/// `adb exec-out run-as <app> cat .../Documents/gate/08_historique.png`.
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
import 'package:mamadera/features/history/presentation/widgets/history_tile.dart';
import 'package:mamadera/features/history/presentation/widgets/measurement_history_tile.dart';
import 'package:mamadera/main.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:path_provider/path_provider.dart';

import 'test_utils.dart';

/// Fixture baby id — a proper noun, identical in every locale.
const _babyId = 'baby-gate';

/// Live base and encryption: the final step re-reads the base to produce...
/// the exported document, using the **same** `EncryptionService` instance as...
/// The app—two instances encrypt data using different keys when...
/// Secure storage is not available, and as a result, everything appears as "unreadable."
AppDatabase? _liveDb;
late EncryptionService _liveEncryption;

/// Routine: a nap, a feeding, a diaper change, a skincare routine, and the...
/// three steps – to enable the display of content on all five surfaces without showing a blank screen.
Future<(AppDatabase, EncryptionService)> _seededEnv() async {
  final db = AppDatabase(NativeDatabase.memory());
  final encryption = EncryptionService();
  await encryption.initialize();

  final now = DateTime.now();
  await db.insertBabyProfile(
    BabyProfilesCompanion.insert(
      id: _babyId,
      name: 'Léa',
      birthDate:
          now.subtract(const Duration(days: 87)).millisecondsSinceEpoch,
      isActive: const Value(true),
    ),
  );

  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'min',
      type: 'dodo',
      timestamp: now.subtract(const Duration(hours: 3)),
      duration: const Value(95),
      quantity: const Value(95),
      babyId: const Value(_babyId),
    ),
  );
  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'ml',
      type: 'miam',
      subtype: const Value('artificial'),
      timestamp: now.subtract(const Duration(hours: 4)),
      quantity: const Value(110),
      babyId: const Value(_babyId),
    ),
  );
  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'ml',
      type: 'caca',
      timestamp: now.subtract(const Duration(hours: 5)),
      wasteType: const Value('pipi'),
      color: const Value('jaune_clair'),
      babyId: const Value(_babyId),
    ),
  );
  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'ml',
      type: 'sante',
      subtype: const Value('nettoyage_nez'),
      timestamp: now.subtract(const Duration(hours: 6)),
      babyId: const Value(_babyId),
    ),
  );

  // Through the repository, never a raw insert: `value` and `notes` are
  // The numbers are scrambled, and a line of text appears on the screen, but it is unreadable.
  final measurements = MeasurementRepositoryImpl(
    database: db,
    encryption: encryption,
  );
  Future<void> measure(
    MeasureKind kind,
    double value,
    Duration ago,
  ) =>
      measurements.add(
        babyId: _babyId,
        kind: kind,
        value: value,
        recordedAt: now.subtract(ago),
      );

  await measure(MeasureKind.poids, 6120, const Duration(days: 3));
  await measure(MeasureKind.taille, 60.5, const Duration(days: 10));
  await measure(MeasureKind.temperature, 37.2, const Duration(hours: 20));

  return (db, encryption);
}

/// Apply the real-world application to the fixture, in French: the labels have been removed.
/// ("Crude" / "Precise") are French terms, and it is in this language that the...
/// soustraction doit se constater.
Future<void> pumpSeededApp(WidgetTester tester) async {
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
        localeProvider.overrideWith(() => ConfigurableLocaleNotifier('fr')),
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

/// The single cursor for the current surface.
Slider _theSlider(WidgetTester tester) =>
    tester.widgetList<Slider>(find.byType(Slider)).single;

/// A single cursor, full range, no labels, approximately present, nothing that disrupts the flow.
/// The `print` statement provides the cryptographic proof, which is stored in the `docs/release-evidence/` directory.
void expectOneFullRangeSlider(String surface, WidgetTester tester) {
  expect(find.byType(Slider), findsOneWidget,
      reason: '$surface : un seul curseur — la paire B2 est retirée');

  for (final caption in ['Grossier', 'Précis', 'Coarse', 'Fine', 'Grueso', 'Fino']) {
    expect(find.text(caption), findsNothing,
        reason: '$surface : la légende « $caption » doit avoir disparu');
  }

  expect(find.byIcon(Icons.add_circle_outline), findsOneWidget,
      reason: "$surface : le stepper ± reste le nudge d'un quantum");
  expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
  expect(tester.takeException(), isNull,
      reason: '$surface : aucun overflow ni exception au rendu');

  final slider = _theSlider(tester);
  print('[GATE] $surface → 1 slider, min=${slider.min} max=${slider.max} '
      'divisions=${slider.divisions} value=${slider.value}');
}

/// Capture: The app writes to its documents directory, and then saves the PNG files.
/// came out of the sandbox (iOS simulator: a path from the host;).
/// Android emulator: `adb exec-out run-as`. Two pitfalls identified here:
/// writing to a relative path raises `errno 30 Read-only file system` on
/// On iOS, and when using `flutter drive` with a target of `integration_test`, an error is raised.
/// `Binding is already initialized to LiveTestWidgetsFlutterBinding` — hence
/// On one hand, the `path_provider` package; on the other hand, `flutter test`; you can't have one without the other.
/// l'autre.
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

/// Scroll the page (drag from the bottom to the top) until [tile] is.
/// in the tree, forcing the construction of the loose tiles at the bottom.
/// the frieze. Independent of `scrollUntilVisible`: the latter only scrolls if the...
/// The tile is missing from the tree, and its scrollable resolution is not set.
/// (`tester.element`) raises the "No element" message on the screen.  A drag-and-drop action...
/// It displays raw coordinates in the Scrollable area without processing them. It does nothing if the...
/// The tile is already visible (on a large screen, like an iPhone).
Future<void> _scrollReveal(WidgetTester tester, Finder tile) async {
  final size = tester.getSize(find.byType(MaterialApp));
  final from = Offset(size.width / 2, size.height * 0.8);
  for (var i = 0; i < 50 && tile.evaluate().isEmpty; i++) {
    await tester.dragFrom(from, const Offset(0, -220));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }
}

/// Opens the first event tile of the specified type in the unified timeline.
Future<void> openEventTile(
    WidgetTester tester, bool Function(TrackingEvent) matches) async {
  final tile =
      find.byWidgetPredicate((w) => w is HistoryTile && matches(w.event));
  // The carousel is a lazy list: on a small screen (Small_Phone), it displays a...
  // The old entry is outside the viewport, so it's not present in the widget tree.
  // It forces you to build it **before** asserting its existence; otherwise, the `findsWidgets` function...
  // The previous query failed due to a lack of data, not due to an error in the data itself.
  await _scrollReveal(tester, tile);
  expect(tile, findsWidgets, reason: 'aucune tuile du type demandé en base');
  // The reveal only guarantees the construction, not the visibility: the tile.
  // It might be located within the tree, but outside the visible area of the screen, and the tap gesture is therefore registered in an empty space.
  // (`warnIfMissed`) - This occurred at the specified temperature, in the middle of the band.
  await tester.ensureVisible(tile.first);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  await tester.tap(tile.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Open the editing sheet for the [kind] measure in the timeline.
Future<void> openMeasurementTile(WidgetTester tester, MeasureKind kind) async {
  final tile = find.byWidgetPredicate((w) =>
      w is MeasurementHistoryTile && w.measurement.kind == kind);
  // The same issue as with `openEventTile`: the duration (3 days) and the temperature (20 hours).
  // are the oldest measurements, and therefore located at the bottom of the scale.
  // Outside the viewport on Small_Phone, these elements are displayed above the iPhone.
  await _scrollReveal(tester, tile);
  expect(tile, findsWidgets,
      reason: 'aucune tuile de mesure ${kind.name} en base');
  // `ensureVisible` before the tap: the tile being constructed may remain hidden.
  // viewport and tap rate (see `openEventTile`).
  await tester.ensureVisible(tile.first);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  await tester.tap(tile.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

bool _isFeeding(TrackingEvent e) => e.map((_) => false,
    feeding: (_) => true,
    sleep: (_) => false,
    diaper: (_) => false,
    health: (_) => false);

bool _isSleep(TrackingEvent e) => e.map((_) => false,
    feeding: (_) => false,
    sleep: (_) => true,
    diaper: (_) => false,
    health: (_) => false);

void main() {
  group('Porte rc.2 — un curseur par saisie', () {
    testWidgets('nouvelle prise (miam)', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expectOneFullRangeSlider('prise · nouvelle', tester);
      // By default (v1.2.1): the range represents minutes.
      expect(_theSlider(tester).max, 120, reason: 'tétée en minutes 0–120');
      expect(_theSlider(tester).divisions, 120, reason: 'un cran par minute');

      await capture(tester, '01_prise_nouvelle');
    });

    testWidgets("édition d'une prise depuis l'historique", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openEventTile(tester, _isFeeding);

      expectOneFullRangeSlider('prise · édition', tester);
      expect(_theSlider(tester).max, 300, reason: 'biberon 0–300 ml');
      expect(_theSlider(tester).divisions, 30, reason: 'pas de 10 ml');
      expect(find.text('110 ml'), findsWidgets);

      await capture(tester, '02_prise_edition');
    });

    testWidgets("édition d'une sieste depuis l'historique", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openEventTile(tester, _isSleep);

      expectOneFullRangeSlider('sieste · édition', tester);
      expect(_theSlider(tester).max, 480, reason: 'durée 0–480 min');
      expect(_theSlider(tester).divisions, 96, reason: 'pas de 5 min');

      await capture(tester, '03_sieste_edition');
    });

    testWidgets('nouvelle mesure de poids', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Poids').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expectOneFullRangeSlider('poids · nouvelle', tester);
      expect(_theSlider(tester).min, 200);
      expect(_theSlider(tester).max, 20000);
      expect(_theSlider(tester).divisions, 1980,
          reason: "le pas de 10 g reste — c'est la fenêtre fine qui part");

      await capture(tester, '04_poids_nouvelle');
    });

    testWidgets("édition d'une mesure de poids", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openMeasurementTile(tester, MeasureKind.poids);

      expectOneFullRangeSlider('poids · édition', tester);
      expect(_theSlider(tester).min, 200);
      expect(_theSlider(tester).max, 20000);

      await capture(tester, '05_poids_edition');
    });

    testWidgets("édition d'une température au dixième", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openMeasurementTile(tester, MeasureKind.temperature);

      expectOneFullRangeSlider('température · édition', tester);
      expect(_theSlider(tester).min, 33);
      expect(_theSlider(tester).max, 42);
      expect(_theSlider(tester).divisions, 90,
          reason: 'pas de 0,1 °C sur toute la plage');
      expect(find.text('37,2 °C'), findsWidgets);

      await capture(tester, '06_temperature_edition');
    });

    testWidgets('saisie manuelle puis export : le nombre survit',
        (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // The path a parent takes when recording a feeding: the slider aims.
      // The "+" and "-" buttons adjust the quantity, while the keyboard sets the exact value.
      final box = tester.getRect(find.byType(Slider));
      final before = _theSlider(tester).value;
      await tester.dragFrom(box.center - const Offset(30, 0),
          const Offset(90, 0));
      await tester.pumpAndSettle();
      expect(_theSlider(tester).value, greaterThan(before),
          reason: 'le curseur unique doit encore déplacer la valeur');


      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '22');
      await tester.pumpAndSettle();
      expect(find.text('22 min'), findsWidgets);
      await capture(tester, '07_prise_saisie');

      // Diagnosis: Is the button armed? (If not, the trigger will not activate, and...)
      // (Silence does not indicate a recording.)
      final confirmFinder = find.text('Confirmer');
      expect(confirmFinder, findsOneWidget);
      // The sheet scrolls: without `ensureVisible`, the tap gesture goes into empty space.
      // outside the viewport, and the button, although armed, doesn't trigger immediately – it's...
      // This is what caused this stage to fail after three attempts.
      await tester.ensureVisible(confirmFinder);
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(
        find.ancestor(of: confirmFinder, matching: find.byType(ElevatedButton)),
      );
      print('[GATE] confirmer armé=${button.onPressed != null} '
          'quantité affichée=${find.textContaining('min').evaluate().length}');

      await tester.tap(confirmFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(confirmFinder, findsNothing,
          reason: 'la feuille doit se fermer sur enregistrement');

      final rows = await _liveDb!.getAllTrackingEvents();
      print('[GATE] base après enregistrement → '
          '${rows.map((r) => '${r.type}/${r.unit}/${r.quantity}').join(', ')}');

      // The exported document, reviewed here, contains the same content as the app.
      // It relies on the sharing panel, and a missing section will not be indicated.
      // not on the screen.
      final source = await ExportRepositoryImpl(
        database: _liveDb!,
        encryption: _liveEncryption,
      ).buildExportJson();
      // The document is also included in the app's documentation; that's where you can find it.
      // proof that can be exported, showing what the sharing panel would have received.
      // (emerged from the sandbox, just like the screenshots).
      final gateDir =
          io.Directory('${(await getApplicationDocumentsDirectory()).path}/gate');
      await gateDir.create(recursive: true);
      await io.File('${gateDir.path}/export.json').writeAsString(source);
      final doc = jsonDecode(source) as Map<String, dynamic>;
      final events = (doc['trackingEvents'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(doc.containsKey('measurements'), isTrue,
          reason: 'une table exportée sans être listée est une sauvegarde fausse');
      // Evidence that can be found in the newspaper before the statement: this is what the document...
      // It truly contains, line by line.
      print('[GATE] export lignes → '
          '${events.map((e) => '${e['type']}/${e['unit']}/${e['quantity']}').join(', ')}');
      expect(
          events.any((e) => e['unit'] == 'min' && (e['quantity'] as num) == 22),
          isTrue,
          reason: 'le 22 tapé au clavier doit être le 22 exporté');
      print('[GATE] export → format ${doc['exportFormatVersion']}, '
          '${events.length} événements, '
          '${(doc['measurements'] as List<dynamic>).length} mesures, '
          '22 min présent');
    });

    testWidgets("frise d'historique : la sieste se lit en « Durée » seule",
        (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // The fixture nap carries 95 min in BOTH `quantity` AND `duration`
      // (as the app actually states); the tiles should only make them a pair.
      // Sometimes, with the straightforward description of a "goodnight" message – and the date of the unfortunate incident.
      // The most recent entry is on its own line (not "13/10/2026 21:32" followed by...).
      // bloc unique).
      expect(find.text('Durée: 95 min'), findsOneWidget);
      expect(find.text('Quantité: 95 min'), findsNothing);
      expect(find.text('Quantité : 95 min'), findsNothing);

      expect(tester.takeException(), isNull,
          reason: 'aucun overflow ni exception sur la frise (cible étroite)');

      await capture(tester, '08_historique');
    });
  });
}

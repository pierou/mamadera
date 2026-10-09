// ignore_for_file: avoid_print
/// Screenshot capture integration test for store submission images.
///
/// Uses widget tester taps to navigate and captures screenshots via
/// [IntegrationTestWidgetsFlutterBinding.takeScreenshot]. On Android, this API
/// uses MethodChannel to get actual PNG bytes from native side (not flutter_driver).
///
/// ## Seeded fixture (v1.2.0)
///
/// Every shot is captured against a **populated** database, not the empty
/// in-memory one. `createInMemoryDb()` in `test_utils.dart` returns a fresh
/// empty DB, which renders Home without pills or reminders, History with its
/// empty-state text and `/growth` with `growthEmptyState` — the store would
/// advertise empty screens. The accepted uploads in `screenshots/android/` are
/// populated, so a re-run had to reproduce that population. The fixture mirrors
/// the iOS driver target (`lib/asc_driver_main.dart`): the same 3-month-old
/// baby "Léa", the same day of events, plus a growth trajectory.
///
/// `pumpMamadera` and `test_utils.dart` are deliberately NOT modified — they
/// are shared with the other integration tests, whose assertions assume an
/// empty database. Only this file pumps the seeded scope.
///
/// The seed writes through `MeasurementRepositoryImpl` with the SAME
/// `EncryptionService` instance the app is given via
/// `encryptionServiceProvider`: `EncryptionService.initialize()` falls back to a
/// volatile in-memory key when secure storage is unavailable, so two instances
/// could encrypt and decrypt with different keys and every seeded value would
/// read "unreadable".
///
/// Run with:
/// ```bash
/// flutter drive \
///   --target=integration_test/screenshot_capture.dart \
///   --driver=test_driver/screenshot_capture.driver.dart \
///   -d emulator-5554
/// ```
library;

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
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/growth/data/repositories/measurement_repository_impl.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/main.dart';

import 'test_utils.dart';

/// Id of the seeded baby — a proper noun, identical in every locale.
const _babyId = 'baby-store';

/// Seeds an in-memory database and an [EncryptionService] sharing one key.
Future<(AppDatabase, EncryptionService)> _seededEnv() async {
  final db = AppDatabase(NativeDatabase.memory());
  final encryption = EncryptionService();
  await encryption.initialize();

  final now = DateTime.now();
  final birth = now.subtract(const Duration(days: 87));

  await db.insertBabyProfile(
    BabyProfilesCompanion.insert(
      id: _babyId,
      name: 'Léa',
      birthDate: birth.millisecondsSinceEpoch,
      isActive: const Value(true),
    ),
  );

  Future<void> sleep(DateTime start, double minutes) => db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'dodo',
          timestamp: start,
          duration: Value(minutes),
          quantity: Value(minutes),
          babyId: const Value(_babyId),
        ),
      );

  Future<void> feed(DateTime at, {bool artificial = false, double? ml}) =>
      db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'miam',
          timestamp: at,
          subtype: Value(artificial ? 'artificial' : 'natural'),
          quantity: Value(ml),
          babyId: const Value(_babyId),
        ),
      );

  Future<void> diaper(
    DateTime at, {
    required String wasteType,
    String? color,
    String? texture,
  }) =>
      db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'caca',
          timestamp: at,
          wasteType: Value(wasteType),
          color: Value(color),
          texture: Value(texture),
          babyId: const Value(_babyId),
        ),
      );

  Future<void> care(DateTime at, String subtype) => db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'sante',
          timestamp: at,
          subtype: Value(subtype),
          babyId: const Value(_babyId),
        ),
      );

  // Night + naps
  await sleep(now.subtract(const Duration(hours: 16)), 460);
  await sleep(now.subtract(const Duration(hours: 25)), 90);
  await sleep(now.subtract(const Duration(hours: 2, minutes: 30)), 80);
  // Feedings
  await feed(now.subtract(const Duration(hours: 11)));
  await feed(now.subtract(const Duration(hours: 8)), artificial: true, ml: 110);
  await feed(now.subtract(const Duration(hours: 6)));
  await feed(now.subtract(const Duration(hours: 3)), artificial: true, ml: 120);
  await feed(now.subtract(const Duration(hours: 4)));
  // Diapers
  await diaper(now.subtract(const Duration(hours: 14)),
      wasteType: 'caca', color: 'jaune_moutarde', texture: 'pateuse');
  await diaper(now.subtract(const Duration(hours: 5)),
      wasteType: 'pipi', color: 'jaune_clair');
  await diaper(now.subtract(const Duration(hours: 1)),
      wasteType: 'les_deux',
      color: 'incolore|jaune_moutarde',
      texture: 'grumeleuse');
  // Health
  await care(now.subtract(const Duration(hours: 4, minutes: 30)), 'nettoyage_nez');
  await care(now.subtract(const Duration(hours: 26)), 'vitamine_d');

  // Growth (v1.2.0) — encrypted through the repository, in base units.
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

  await measure(MeasureKind.poids, 3900, const Duration(days: 80));
  await measure(MeasureKind.poids, 4600, const Duration(days: 55));
  await measure(MeasureKind.poids, 5300, const Duration(days: 30));
  await measure(MeasureKind.poids, 5750, const Duration(days: 14));
  await measure(MeasureKind.poids, 6120, const Duration(days: 3));
  await measure(MeasureKind.poids, 6180, const Duration(hours: 20));
  await measure(MeasureKind.taille, 51, const Duration(days: 80));
  await measure(MeasureKind.taille, 56, const Duration(days: 45));
  await measure(MeasureKind.taille, 60.5, const Duration(days: 10));
  await measure(MeasureKind.temperature, 36.8, const Duration(days: 20));
  await measure(MeasureKind.temperature, 37.2, const Duration(days: 2));

  return (db, encryption);
}

/// Pumps the real app on the seeded fixture, in English.
///
/// Deliberately does NOT call `pumpMamadera`: with `useInMemoryDb: false` that
/// helper skips the `databaseProvider` override altogether and would read the
/// device's real file database, and without it the fixture would be empty.
///
/// The database of the previous test is closed first: each test pumps a fresh
/// app, and leaving the old in-memory `AppDatabase` alive makes drift warn
/// ("created the database class AppDatabase multiple times … might corrupt the
/// database"). Closing is honest hygiene, not `dontWarnAboutMultipleDatabases`.
AppDatabase? _liveDb;

Future<void> pumpSeededApp(WidgetTester tester) async {
  if (_liveDb != null) {
    await _liveDb!.close();
    _liveDb = null;
  }
  final (db, encryption) = await _seededEnv();
  _liveDb = db;
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // `flutter drive` builds a DEBUG APK, which draws the red diagonal DEBUG
  // ribbon in the top-right corner. The accepted uploads in
  // screenshots/android/ are ribbon-free (verified 0 reddish pixels), so the
  // banner must be suppressed here — at the widget-binding level, in test code,
  // never by touching the app. Without this line every Android shot ships with
  // the ribbon on it.
  WidgetsApp.debugAllowBannerOverride = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(() => ConfigurableLocaleNotifier('en')),
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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Store Screenshots', () {
    /// Capture a screenshot via the binding's takeScreenshot. Since Flutter
    /// 3.44 the PNG bytes are returned in-band (test reportData) and saved to
    /// screenshots/android/ by the driver — nothing is written on the device.
    Future<void> captureScreen(
      IntegrationTestWidgetsFlutterBinding binding,
      String name,
      WidgetTester tester,
    ) async {
      // Convert the Android display surface to an image so takeScreenshot
      // captures the actual rendered UI rather than a blank canvas.
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();

      // takeScreenshot triggers the native screenshot callback registered
      // in the driver. We save the PNG bytes to disk inside the test.
      await binding.takeScreenshot(name);

      // Print a marker so we can track progress in the terminal output.
      print('[CAPTURE] ✓ $name');
    }

    // ─── Main Navigation Screenshots ───────────────────────────────────────

    testWidgets('home.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify home screen track buttons are visible.
      expectUnique(tester, TestKeys.trackMiam);
      expectUnique(tester, TestKeys.trackSante);

      await captureScreen(binding, 'home', tester);
    });

    testWidgets('history.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.pumpAndSettle();

      // Navigate to history tab.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify history tab is active.
      expectUnique(tester, TestKeys.historyTab);

      await captureScreen(binding, 'history', tester);
    });

    testWidgets('menu.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.pumpAndSettle();

      // Navigate to menu tab.
      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify menu tab is active.
      expectUnique(tester, TestKeys.menuTab);

      await captureScreen(binding, 'menu', tester);
    });

    // ─── Feature Dialog Screenshots ────────────────────────────────────────

    // NOTE: tab selection survives pumpWidget re-pumps (the stateful shell
    // is not replaced), so a previous test can end the app on another tab.
    // Every dialog test taps the home tab first to make the track buttons
    // exist regardless of test order.

    testWidgets('feeding_dialog.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap the feeding track button.
      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'feeding_dialog', tester);
    });

    testWidgets('sleep_diagram.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap the sleep track button.
      await tester.tap(findByKey(TestKeys.trackDodo));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'sleep_diagram', tester);
    });

    testWidgets('diaper_dialog.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap the diaper track button.
      await tester.tap(findByKey(TestKeys.trackCaca));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'diaper_dialog', tester);
    });

    testWidgets('health_diagram.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap the health track button.
      await tester.tap(findByKey(TestKeys.trackSante));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'health_diagram', tester);
    });

    // v1.2.0 — the growth screen, opened from the Menu ("Growth" tile, English
    // locale here). The tile label doubles as a section header, so the finder
    // is scoped to the ListTile.
    //
    // LAST ON PURPOSE: `/growth` is a pushed top-level route with no bottom
    // navigation (router.dart:139, outside the ShellRoute), and tab/route state
    // survives pumpWidget re-pumps — the documented gotcha below. A test that
    // ran after this one found no `home-tab` to tap and failed.
    testWidgets('growth.png', (tester) async {
      await pumpSeededApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final tile = find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Growth'),
      );
      await tester.scrollUntilVisible(tile, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(tile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The screen must show real values, never the empty state — exact
      // string, `find.text` does not do substring matching.
      expect(find.text('Growth'), findsWidgets);
      expect(find.text('No measurements yet.'), findsNothing);

      await captureScreen(binding, 'growth', tester);
    });
  });
}

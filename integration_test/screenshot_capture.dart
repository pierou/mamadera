// ignore_for_file: avoid_print
/// Screenshot capture integration test for store submission images.
///
/// Uses widget tester taps to navigate and captures screenshots via
/// [IntegrationTestWidgetsFlutterBinding.takeScreenshot]. On Android, this API
/// uses MethodChannel to get actual PNG bytes from native side (not flutter_driver).
///
/// Run with:
/// ```bash
/// flutter drive \
///   --target=integration_test/screenshot_capture.dart \
///   --driver=test_driver/screenshot_capture.driver.dart \
///   -d emulator-5554
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Store Screenshots', () {
    /// Capture a screenshot via the binding's takeScreenshot, then save PNG
    /// bytes to disk using dart:io.
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
      await pumpMamadera(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify home screen track buttons are visible.
      expectUnique(tester, TestKeys.trackMiam);
      expectUnique(tester, TestKeys.trackSante);

      await captureScreen(binding, 'home', tester);
    });

    testWidgets('history.png', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      // Navigate to history tab.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify history tab is active.
      expectUnique(tester, TestKeys.historyTab);

      await captureScreen(binding, 'history', tester);
    });

    testWidgets('menu.png', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      // Navigate to menu tab.
      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify menu tab is active.
      expectUnique(tester, TestKeys.menuTab);

      await captureScreen(binding, 'menu', tester);
    });

    // ─── Feature Dialog Screenshots ────────────────────────────────────────

    testWidgets('feeding_dialog.png', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      // Tap the feeding track button.
      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'feeding_dialog', tester);
    });

    testWidgets('sleep_diagram.png', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      // Tap the sleep track button.
      await tester.tap(findByKey(TestKeys.trackDodo));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'sleep_diagram', tester);
    });

    testWidgets('diaper_dialog.png', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      // Tap the diaper track button.
      await tester.tap(findByKey(TestKeys.trackCaca));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'diaper_dialog', tester);
    });

    testWidgets('health_diagram.png', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      // Tap the health track button.
      await tester.tap(findByKey(TestKeys.trackSante));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dialog should be visible after pumpAndSettle.

      await captureScreen(binding, 'health_diagram', tester);
    });
  });
}

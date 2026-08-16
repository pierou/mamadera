/// Store Screenshot Capture Driver Test
/// 
/// Captures high-quality PNG screenshots of key app screens for App Store & Google Play submission.
/// Run with: flutter drive --target=lib/driver_main.dart --driver=test_driver/store_screenshots.dart -d "iPhone 17"
library;

import 'dart:io' as io;

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

// Semantic keys matching integration_test/test_utils.dart TestKeys class.
class _Keys {
  _Keys._();

  // Bottom navigation tabs
  static const String homeTab = 'home-tab';
  static const String historyTab = 'history-tab';
  static const String menuTab = 'menu-tab';

  // Track buttons on HomeScreen
  static const String trackMiam = 'track-miam';
  static const String trackSante = 'track-sante';
  static const String trackCaca = 'track-caca';
  static const String trackDodo = 'track-dodo';
}

// ignore_for_file: avoid_print,unused_element,unused_field

void main() {
  group('Store Screenshot Capture', () {
    late FlutterDriver driver;
    const iosDir = 'screenshots/ios';
    const androidDir = 'screenshots/android';

    setUpAll(() async {
      print('[SETUP] Connecting to Flutter Driver...');
      driver = await FlutterDriver.connect();

      // Give app time to boot, initialize database, and attach root widget.
      await Future<void>.delayed(const Duration(seconds: 5));

      // Wait for home tab to appear in semantics tree before proceeding.
      print('[SETUP] Waiting for bottom navigation...');
      try {
        await driver.waitFor(find.byValueKey(_Keys.homeTab),
            timeout: const Duration(seconds: 15));
        print('[OK] Home tab found.');
      } on Exception catch (e) {
        print('[WARN] Could not wait for home tab: $e');
      }

      // Ensure directories exist.
      io.Directory(iosDir).createSync(recursive: true);
      io.Directory(androidDir).createSync(recursive: true);

      print('[OK] Connected & ready.');
    });

    tearDownAll(() async {
      print('[TEARDOWN] Disconnecting from Flutter Driver...');
      await driver.close();
    });

    Future<void> captureScreen(String filename) async {
      // Small delay to ensure UI has settled.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final screenshot = await driver.screenshot();
      
      for (final dir in [iosDir, androidDir]) {
        final filePath = '$dir/$filename';
        await io.File(filePath).writeAsBytes(screenshot);
        print('[SCREENSHOT] Saved $filePath (${screenshot.length} bytes)');
      }
    }

    /// Navigate to home tab and wait for animations to settle.
    Future<void> goToHome() async {
      final homeFinder = find.byValueKey(_Keys.homeTab);
      // Wait for the button to be available in semantics tree first.
      await driver.waitFor(homeFinder, timeout: const Duration(seconds: 10));
      print('[NAV] Tapping home tab...');
      await driver.tap(homeFinder);
      await driver.waitUntilNoTransientCallbacks(
        timeout: const Duration(seconds: 5),
      );
      // Extra pause for any lingering animations.
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }

    test('1. Capture Home Screen', () async {
      print('\n=== 1. Home Screen ===');

      // Ensure we're on home tab first (with wait for semantics).
      await goToHome();
      
      await captureScreen('home.png');
    });

    test('2. Capture History Tab', () async {
      print('\n=== 2. History Tab ===');

      // Tap history tab.
      await driver.tap(find.byValueKey(_Keys.historyTab));
      await driver.waitUntilNoTransientCallbacks(
        timeout: const Duration(seconds: 5),
      );

      await captureScreen('history.png');
    });

    test('3. Capture Menu/Settings Tab', () async {
      print('\n=== 3. Menu/Settings Tab ===');

      // Tap menu tab.
      await driver.tap(find.byValueKey(_Keys.menuTab));
      await driver.waitUntilNoTransientCallbacks(
        timeout: const Duration(seconds: 5),
      );

      await captureScreen('menu.png');
    });

    test('4. Capture Feeding Dialog', () async {
      print('\n=== 4. Feeding (Miam) Dialog ===');

      // Navigate to home first.
      await goToHome();

      try {
        final miamFinder = find.byValueKey(_Keys.trackMiam);
        await driver.waitFor(miamFinder, timeout: const Duration(seconds: 5));
        print('[TAP] Opening feeding dialog...');
        await driver.tap(miamFinder);
        await driver.waitUntilNoTransientCallbacks(
          timeout: const Duration(seconds: 5),
        );

        await captureScreen('feeding.png');
      } on Exception catch (e) {
        print('[WARN] Feeding dialog capture failed: $e');
      }
    });

    test('5. Capture Sleep Dialog', () async {
      print('\n=== 5. Sleep (Dodo) Dialog ===');

      await goToHome();

      try {
        final dodoFinder = find.byValueKey(_Keys.trackDodo);
        await driver.waitFor(dodoFinder, timeout: const Duration(seconds: 5));
        print('[TAP] Opening sleep dialog...');
        await driver.tap(dodoFinder);
        await driver.waitUntilNoTransientCallbacks(
          timeout: const Duration(seconds: 5),
        );

        await captureScreen('sleep.png');
      } on Exception catch (e) {
        print('[WARN] Sleep dialog capture failed: $e');
      }
    });

    test('6. Capture Diaper Dialog', () async {
      print('\n=== 6. Diaper (Caca) Dialog ===');

      await goToHome();

      try {
        final cacaFinder = find.byValueKey(_Keys.trackCaca);
        await driver.waitFor(cacaFinder, timeout: const Duration(seconds: 5));
        print('[TAP] Opening diaper dialog...');
        await driver.tap(cacaFinder);
        await driver.waitUntilNoTransientCallbacks(
          timeout: const Duration(seconds: 5),
        );

        await captureScreen('diaper.png');
      } on Exception catch (e) {
        print('[WARN] Diaper dialog capture failed: $e');
      }
    });

    test('7. Capture Health Dialog', () async {
      print('\n=== 7. Health (Santé) Dialog ===');

      await goToHome();

      try {
        final santeFinder = find.byValueKey(_Keys.trackSante);
        await driver.waitFor(santeFinder, timeout: const Duration(seconds: 5));
        print('[TAP] Opening health dialog...');
        await driver.tap(santeFinder);
        await driver.waitUntilNoTransientCallbacks(
          timeout: const Duration(seconds: 5),
        );

        await captureScreen('health.png');
      } on Exception catch (e) {
        print('[WARN] Health dialog capture failed: $e');
      }

      print('\n🎉 Store screenshots are ready in:');
      print('   • $iosDir/ (for App Store Connect)');
      print('   • $androidDir/ (for Google Play Console)');
    });
  });
}

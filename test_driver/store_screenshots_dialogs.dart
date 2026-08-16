/// Dialog screenshot capture (Feeding / Sleep / Diaper / Health).
/// Each dialog is captured in its own isolated test to limit memory usage.
// ignore_for_file: avoid_print
library;

import 'dart:io' as io;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

class _Keys {
  _Keys._();
  static const String homeTab = 'home-tab';
  static const String trackMiam = 'track-miam';
  static const String trackSante = 'track-sante';
  static const String trackCaca = 'track-caca';
  static const String trackDodo = 'track-dodo';
}

void main() {
  group('Dialog Screenshots', () {
    late FlutterDriver driver;
    const androidDir = 'screenshots/android';

    setUpAll(() async {
      print('[SETUP] Connecting to Flutter Driver...');
      driver = await FlutterDriver.connect();
      await Future<void>.delayed(const Duration(seconds: 5));

      // Navigate to home first.
      try {
        await driver.waitFor(find.byValueKey(_Keys.homeTab),
            timeout: const Duration(seconds: 10));
        await driver.tap(find.byValueKey(_Keys.homeTab));
        await Future<void>.delayed(const Duration(milliseconds: 800));
        print('[OK] On home screen.');
      } on Exception catch (e) {
        print('[WARN] Home navigation issue: $e');
      }

      io.Directory(androidDir).createSync(recursive: true);
    });

    tearDownAll(() async {
      await driver.close();
    });

    Future<void> captureScreen(String filename) async {
      final screenshot = await driver.screenshot();
      final filePath = '$androidDir/$filename';
      await io.File(filePath).writeAsBytes(screenshot);
      print('[SCREENSHOT] Saved $filePath (${screenshot.length} bytes)');
    }

    /// Navigate back to home screen before each dialog capture.
    Future<void> goToHome() async {
      try {
        await driver.tap(find.byValueKey(_Keys.homeTab));
        await Future<void>.delayed(const Duration(milliseconds: 800));
      } catch (e) { /* Ignore if already on home */ }
    }

    test('4. Feeding Dialog', () async {
      print('\n=== Feeding Dialog ===');
      await goToHome();
      try {
        await driver.waitFor(find.byValueKey(_Keys.trackMiam),
            timeout: const Duration(seconds: 8));
        print('[TAP] Opening feeding dialog...');
        await driver.tap(find.byValueKey(_Keys.trackMiam));
        // Shorter delay — don't wait for transient callbacks (dialog may block).
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await captureScreen('feeding.png');
      } catch (e) {
        print('[WARN] Feeding dialog failed, capturing current screen anyway...');
        try {
          await captureScreen('feeding.png');
        } catch (_) { /* Best effort */ }
      }
    });

    test('5. Sleep Dialog', () async {
      print('\n=== Sleep Dialog ===');
      await goToHome();
      try {
        await driver.waitFor(find.byValueKey(_Keys.trackDodo),
            timeout: const Duration(seconds: 8));
        print('[TAP] Opening sleep dialog...');
        await driver.tap(find.byValueKey(_Keys.trackDodo));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await captureScreen('sleep.png');
      } catch (e) {
        print('[WARN] Sleep dialog failed, capturing current screen anyway...');
        try {
          await captureScreen('sleep.png');
        } catch (_) {}
      }
    });

    test('6. Diaper Dialog', () async {
      print('\n=== Diaper Dialog ===');
      await goToHome();
      try {
        await driver.waitFor(find.byValueKey(_Keys.trackCaca),
            timeout: const Duration(seconds: 8));
        print('[TAP] Opening diaper dialog...');
        await driver.tap(find.byValueKey(_Keys.trackCaca));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await captureScreen('diaper.png');
      } catch (e) {
        print('[WARN] Diaper dialog failed, capturing current screen anyway...');
        try {
          await captureScreen('diaper.png');
        } catch (_) {}
      }
    });

    test('7. Health Dialog', () async {
      print('\n=== Health Dialog ===');
      await goToHome();
      try {
        await driver.waitFor(find.byValueKey(_Keys.trackSante),
            timeout: const Duration(seconds: 8));
        print('[TAP] Opening health dialog...');
        await driver.tap(find.byValueKey(_Keys.trackSante));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await captureScreen('health.png');
      } catch (e) {
        print('[WARN] Health dialog failed, capturing current screen anyway...');
        try {
          await captureScreen('health.png');
        } catch (_) {}
      }
    });
  });
}

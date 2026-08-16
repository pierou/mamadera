/// Main navigation screenshot capture (Home / History / Menu tabs).
// ignore_for_file: avoid_print
library;

import 'dart:io' as io;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Main Navigation Screenshots', () {
    late FlutterDriver driver;
    const androidDir = 'screenshots/android';

    setUpAll(() async {
      print('[SETUP] Connecting to Flutter Driver...');
      driver = await FlutterDriver.connect();

      // Give app time to boot completely.
      await Future<void>.delayed(const Duration(seconds: 15));

      io.Directory(androidDir).createSync(recursive: true);

      // Capture the current state (should be clean home screen with onboarding skipped).
      final debugShot = await driver.screenshot();
      await io.File('$androidDir/_debug_ready.png').writeAsBytes(debugShot);
      print('[DEBUG] Ready screenshot saved (${debugShot.length} bytes)');
    });
    tearDownAll(() async {
      await driver.close();
    });

    Future<void> captureScreen(String filename) async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final screenshot = await driver.screenshot();
      final filePath = '$androidDir/$filename';
      await io.File(filePath).writeAsBytes(screenshot);
      print('[SCREENSHOT] Saved $filePath (${screenshot.length} bytes)');
    }

    test('1. Home Screen', () async {
      // We should already be on home screen after boot delay. Just capture directly.
      await captureScreen('home.png');
    });

    test('2. History Tab', () async {
      try {
        await driver.tap(find.byValueKey('history-tab'), timeout: const Duration(seconds: 10));
        print('[TAP] History tab tap succeeded!');
      } catch (e) {
        print('[ERROR] Tap failed for history tab: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await captureScreen('history.png');
    });

    test('3. Menu/Settings Tab', () async {
      try {
        await driver.tap(find.byValueKey('menu-tab'), timeout: const Duration(seconds: 10));
        print('[TAP] Menu tab tap succeeded!');
      } catch (e) {
        print('[ERROR] Tap failed for menu tab: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await captureScreen('menu.png');
    });
  });
}
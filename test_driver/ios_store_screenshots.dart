// ignore_for_file: avoid_print
/// iOS App Store Screenshot Capture (3 screens)
/// 
/// Captures Home, History, and Feeding dialog screenshots for Apple App Store submission.
/// Run with: flutter drive --target=lib/driver_main.dart --driver=test_driver/ios_store_screenshots.dart -d "iPhone 17"
library;

import 'dart:io' as io;

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

class _Keys {
  _Keys._();
  static const String homeTab = 'home-tab';
  static const String historyTab = 'history-tab';
  static const String trackMiam = 'track-miam';
}

void main() {
  group('iOS App Store Screenshots', () {
    late FlutterDriver driver;
    const iosDir = 'screenshots/ios/appstore';

    setUpAll(() async {
      print('[SETUP] Connecting to Flutter Driver...');
      driver = await FlutterDriver.connect();

      // Give app time to boot and initialize.
      await Future<void>.delayed(const Duration(seconds: 5));

      // Wait for home tab in semantics tree.
      print('[SETUP] Waiting for bottom navigation...');
      try {
        await driver.waitFor(
          find.byValueKey(_Keys.homeTab),
          timeout: const Duration(seconds: 15),
        );
        print('[OK] Home tab found.');
      } on Exception catch (e) {
        print('[WARN] Could not wait for home tab: $e');
      }

      io.Directory(iosDir).createSync(recursive: true);
      print('[OK] Connected & ready.');
    });

    tearDownAll(() async {
      await driver.close();
    });

    Future<void> captureScreen(String filename) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final screenshot = await driver.screenshot();
      final filePath = '$iosDir/$filename';
      await io.File(filePath).writeAsBytes(screenshot);
      print('[SCREENSHOT] Saved $filePath (${screenshot.length} bytes)');
    }

    Future<void> goToHome() async {
      await driver.waitFor(
        find.byValueKey(_Keys.homeTab),
        timeout: const Duration(seconds: 10),
      );
      await driver.tap(find.byValueKey(_Keys.homeTab));
      await driver.waitUntilNoTransientCallbacks(
        timeout: const Duration(seconds: 5),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }

    test('1. Home Screen', () async {
      print('\n=== 1. Home Screen ===');
      await goToHome();
      await captureScreen('home.png');
    });

    test('2. History Tab', () async {
      print('\n=== 2. History Tab ===');
      await driver.tap(find.byValueKey(_Keys.historyTab));
      await driver.waitUntilNoTransientCallbacks(
        timeout: const Duration(seconds: 5),
      );
      await captureScreen('history.png');
    });

    test('3. Feeding Dialog', () async {
      print('\n=== 3. Feeding Dialog ===');
      await goToHome();
      try {
        final miamFinder = find.byValueKey(_Keys.trackMiam);
        await driver.waitFor(miamFinder, timeout: const Duration(seconds: 5));
        await driver.tap(miamFinder);
        await driver.waitUntilNoTransientCallbacks(
          timeout: const Duration(seconds: 5),
        );
        await captureScreen('feeding.png');
      } on Exception catch (e) {
        print('[WARN] Feeding dialog failed, capturing home instead: $e');
        await goToHome();
        await captureScreen('feeding.png');
      }
    });
  });
}

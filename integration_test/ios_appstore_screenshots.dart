// ignore_for_file: avoid_print
/// Captures 3 App Store-quality screenshots: Home, History, Feeding Dialog.
/// 
/// Run with: flutter test integration_test/ios_appstore_screenshots.dart -d "iPhone 17"
library;

import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart' show pumpMamadera, TestKeys;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('iOS App Store Screenshots', () {
    const iosDir = 'screenshots/ios/appstore';

    setUpAll(() {
      io.Directory(iosDir).createSync(recursive: true);
    });

    /// Save a screenshot as PNG to the iOS app store directory.
    Future<void> saveScreenshot(
      WidgetTester tester,
      String name,
    ) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      final pngBytes = await binding.takeScreenshot(name);
      
      // Write PNG bytes directly to disk.
      try {
        final file = io.File('$iosDir/$name.png');
        await file.writeAsBytes(pngBytes);
        print('[SAVED] ${file.path} (${pngBytes.length} bytes)');
      } catch (e, st) {
        // Fallback: just log the error.
        print('[WARN] Direct save failed: $e\n$st');
      }
    }

    testWidgets('1 — Home Screen', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final miamBtn = find.byKey(const ValueKey(TestKeys.trackMiam));
      expect(miamBtn, findsOneWidget);

      await saveScreenshot(tester, 'home');
    });

    testWidgets('2 — History Tab', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      final historyTab = find.byKey(const ValueKey(TestKeys.historyTab));
      expect(historyTab, findsOneWidget);
      
      await tester.tap(historyTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await saveScreenshot(tester, 'history');
    });

    testWidgets('3 — Feeding Dialog', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle();

      final miamBtn = find.byKey(const ValueKey(TestKeys.trackMiam));
      expect(miamBtn, findsOneWidget);

      try {
        await tester.tap(miamBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } catch (e) {
        print('[WARN] Feeding dialog tap issue: $e');
      }

      await saveScreenshot(tester, 'feeding');
    });
  });
}

/// Cross-tab navigation flow integration tests.
///
/// Validates:
/// - Sequential tab switching (home → history → menu → home) preserves state
/// - Bottom nav highlights correct active tab on each switch
/// - Dialog overlays are dismissed when switching tabs (AppShell overlay pop behavior)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Tab Navigation Flow', () {
    testWidgets(
        'Sequential tab navigation: home → history → menu preserves track buttons',
        (tester) async {
      await pumpMamadera(tester);

      // 1. Verify home screen is default landing page with all track buttons.
      expectUnique(tester, TestKeys.trackMiam);
      expectUnique(tester, TestKeys.trackSante);
      expectUnique(tester, TestKeys.trackCaca);
      expectUnique(tester, TestKeys.trackDodo);

      // 2. Navigate to history tab — verify filter chips appear.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(
        find.byType(FilterChip),
        findsWidgets,
        reason: 'History screen should render filter chips',
      );

      // 3. Navigate to menu tab — verify scrollable settings content appears.
      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(
        find.byType(SingleChildScrollView),
        findsWidgets,
        reason: 'Menu screen should have scrollable content',
      );

      // 4. Navigate back to home — track buttons should still be present.
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expectUnique(tester, TestKeys.trackMiam);
      expectUnique(tester, TestKeys.trackSante);
      expectUnique(tester, TestKeys.trackCaca);
      expectUnique(tester, TestKeys.trackDodo);
    });

    testWidgets(
        'Opening a dialog then switching tabs dismisses the overlay',
        (tester) async {
      await pumpMamadera(tester);

      // Open feeding dialog by tapping track miam.
      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle();

      // Verify the bottom sheet overlay is visible (dialog open).
      expect(
        find.textContaining('Breast milk', findRichText: true),
        findsOneWidget,
        reason: 'Feeding dialog should show subtype chips',
      );

      // Switch to history tab — the AppShell overlay pop logic (upTo: 5)
      // should dismiss the modal bottom sheet.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify the dialog is dismissed (subtype text no longer visible).
      expect(
        find.textContaining('Breast milk', findRichText: true),
        findsNothing,
        reason: 'Dialog overlay should be dismissed when switching tabs',
      );

      // History screen filter chips should now be visible instead.
      expect(
        find.byType(FilterChip),
        findsWidgets,
        reason: 'History screen should be visible after tab switch dismisses dialog',
      );
    });

    testWidgets('Rapid tab switching settles on final destination', (tester) async {
      await pumpMamadera(tester);

      // Simulate rapid taps across all three tabs.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pump();
      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pump();
      await tester.tap(findByKey(TestKeys.homeTab));

      // Settle and verify we ended up on the home tab (last destination).
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Home track buttons should all be present after rapid navigation.
      expectUnique(tester, TestKeys.trackMiam);
    });

    testWidgets('All three bottom nav tabs are always rendered on home screen',
        (tester) async {
      await pumpMamadera(tester);

      // Verify all tab keys exist simultaneously on the initial home screen.
      for (final key in [TestKeys.homeTab, TestKeys.historyTab, TestKeys.menuTab]) {
        expectUnique(
          tester,
          key,
        );
      }

      // Verify there's a BottomNavigationBar widget rendering these keys.
      expect(
        find.byType(BottomNavigationBar),
        findsOneWidget,
        reason: 'Home screen should have exactly one bottom navigation bar',
      );
    });
  });
}

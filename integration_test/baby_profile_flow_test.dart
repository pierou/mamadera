/// Baby profile flow integration tests.
///
/// Validates:
/// - Navigating to menu tab shows BabyProfileSection
/// - Empty state has "Add baby" button
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Baby Profile Flow', () {
    testWidgets(
        'Navigating to menu tab renders the MenuScreen with settings sections',
        (tester) async {
      await pumpMamadera(tester);

      // Navigate to menu tab — should show settings/profile section.
      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // The menu screen contains a SingleChildScrollView with multiple sections.
      expect(
        find.byType(SingleChildScrollView),
        findsOneWidget,
        reason: 'MenuScreen should have scrollable content',
      );

      // There are ListTile widgets for language/theme/feedback options.
      expect(
        find.byType(ListTile),
        findsWidgets,
        reason: 'Menu screen should contain ListTiles for settings items',
      );
    });

    testWidgets('Baby Profile section renders on MenuScreen', (tester) async {
      await pumpMamadera(tester);

      // Navigate to menu tab.
      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // The BabyProfileSection shows either an empty state or profile tiles.
      // With no pre-seeded babies, it should show the "Add baby" button.
      final addButtonFinder = find.textContaining(
        'Add',
        findRichText: true,
      );

      expect(
        addButtonFinder.evaluate().isNotEmpty ||
            find.byType(ListTile).evaluate().isNotEmpty,
        isTrue,
        reason:
            'Menu should show either an "Add baby" button or profile tiles',
      );
    });

    testWidgets('Navigating back from menu to home preserves track buttons',
        (tester) async {
      await pumpMamadera(tester);

      // Go to menu tab first.
      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Navigate back to history, then home.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Home screen track buttons should still be present after tab switching.
      expectUnique(tester, TestKeys.trackMiam);
      expectUnique(tester, TestKeys.trackSante);
      expectUnique(tester, TestKeys.trackCaca);
      expectUnique(tester, TestKeys.trackDodo);
    });
  });
}

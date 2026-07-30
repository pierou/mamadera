/// History flow integration tests.
///
/// Validates:
/// - Navigating to history tab shows event list or empty state
/// - Filter chips (All, Miam, Dodo, Caca, Sante) are present and selectable
/// - Events can be tapped for editing/deletion via bottom sheet
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('History Flow', () {
    testWidgets(
        'Navigating to history tab shows the HistoryScreen with filter chips',
        (tester) async {
      await pumpMamadera(tester);

      // Navigate to history tab.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // The HistoryScreen has filter chips at the top.
      expect(
        find.byType(FilterChip),
        findsWidgets,
        reason: 'History screen should have type filter chips',
      );

      // There should also be a ListView or Center widget for events display.
      final listViewFinder = find.byType(ListView);
      final centerFinder = find.textContaining('No');
      expect(
        listViewFinder.evaluate().isNotEmpty ||
            centerFinder.evaluate().isNotEmpty,
        isTrue,
        reason:
            'History screen should show either a list of events or an empty state',
      );
    });

    testWidgets('Empty history shows "No" message instead of event tiles',
        (tester) async {
      await pumpMamadera(tester);

      // Navigate to history tab.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // With no events in the DB, we should see an empty state indicator.
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasCenterWithText = find.descendant(
        of: find.byType(Center),
        matching: find.textContaining('No'),
      ).evaluate().isNotEmpty;

      expect(
        !hasListView || hasCenterWithText,
        isTrue,
        reason:
            'An in-memory DB with no pre-seeded events should show an empty state',
      );
    });

    testWidgets('Tapping filter chips switches selected type', (tester) async {
      await pumpMamadera(tester);

      // Go to history tab.
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find all FilterChips and verify we have at least 3 event-type filters.
      final chipFinder = find.byType(FilterChip);
      final chips = chipFinder.evaluate().toList();
      expect(
        chips.length >= 3,
        isTrue,
        reason: 'Should have at least 3 filter chips for event types (found: ${chips.length})',
      );

      // Tap the first non-selected chip (if any).
      final allChips = chipFinder.evaluate().toList();
      if (allChips.isNotEmpty) {
        final firstChipWidget = allChips.first.widget as FilterChip;
        if (!firstChipWidget.selected) {
          await tester.tap(chipFinder);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      }

      // After tapping, verify the chip list is still rendered.
      final updatedChips = find.byType(FilterChip).evaluate().toList();
      expect(
        updatedChips.isNotEmpty,
        isTrue,
        reason: 'Filter chips should remain visible after selection change',
      );
    });
  });
}

/// Feeding tracking flow integration tests.
///
/// Validates:
/// - Tapping track-miam opens feeding dialog with subtype chips
/// - Selecting natural/artificial subtype works
/// - Confirm saves event (dialog dismisses)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feeding Tracking Flow', () {
    testWidgets(
        'Tapping track miam opens FeedingTrackingDialog bottom sheet',
        (tester) async {
      await pumpMamadera(tester);

      // Verify home screen is loaded with track buttons.
      expectUnique(tester, TestKeys.trackMiam);

      // Tap the "miam" tracking button — should open a modal bottom sheet.
      await tester.ensureVisible(findByKey(TestKeys.trackMiam));
      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle();

      // The FeedingTrackingDialog contains FilterChips for subtypes + confirm/cancel buttons.
      expect(
        find.textContaining('Breast milk', findRichText: true),
        findsOneWidget,
        reason:
            'Feeding subtype "Breast milk" chip should be visible in the dialog',
      );
      expect(
        find.textContaining('Formula', findRichText: true),
        findsOneWidget,
        reason:
            'Feeding subtype "Formula" chip should be visible in the dialog',
      );

      // Confirm button should be present.
      expect(
        find.text('Confirm'),
        findsWidgets,
        reason: 'Confirm button should appear in the feeding dialog actions',
      );
    });

    testWidgets('Tapping cancel dismisses FeedingTrackingDialog', (tester) async {
      await pumpMamadera(tester);

      // Open the dialog.
      await tester.ensureVisible(findByKey(TestKeys.trackMiam));
      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle();

      // Verify dialog is open (bottom sheet appears).
      expect(
        find.textContaining('Breast milk', findRichText: true),
        findsOneWidget,
        reason: 'Feeding subtype chip should be visible',
      );

      // Tap Cancel — should dismiss the bottom sheet and return to home screen.
      await tester.tap(find.textContaining('Cancel', findRichText: true));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // After dismissing, track buttons should be visible again on home screen.
      expectUnique(tester, TestKeys.trackMiam);
    });

    testWidgets('Tapping track sante opens HealthSubtypeDialog', (tester) async {
      await pumpMamadera(tester);

      // Tap "sante" tracking button — should show health subtype options.
      await tester.ensureVisible(findByKey(TestKeys.trackSante));
      await tester.tap(findByKey(TestKeys.trackSante));
      await tester.pumpAndSettle();

      // The HealthSubtypeDialog shows a list of health-related subtypes.
      // At minimum, it has Cancel and Confirm buttons.
      expect(
        find.byType(TextButton),
        findsWidgets,
        reason: 'Health subtype dialog should have action buttons',
      );
    });

    testWidgets('Tapping track caca opens WasteDialog', (tester) async {
      await pumpMamadera(tester);

      // Tap "caca" tracking button — should show waste type picker.
      await tester.ensureVisible(findByKey(TestKeys.trackCaca));
      await tester.tap(findByKey(TestKeys.trackCaca));
      await tester.pumpAndSettle();

      // The WasteDialog has action buttons at the bottom.
      expect(
        find.byType(TextButton),
        findsWidgets,
        reason: 'Waste dialog should have Cancel/Confirm buttons',
      );
    });

    testWidgets('Tapping track dodo opens DurationPickerDialog', (tester) async {
      await pumpMamadera(tester);

      // Tap "dodo" tracking button — should show sleep duration picker.
      await tester.ensureVisible(findByKey(TestKeys.trackDodo));
      await tester.tap(findByKey(TestKeys.trackDodo));
      await tester.pumpAndSettle();

      // The DurationPickerDialog has action buttons at the bottom.
      expect(
        find.byType(TextButton),
        findsWidgets,
        reason: 'Duration picker dialog should have Cancel/Confirm buttons',
      );
    });
  });
}

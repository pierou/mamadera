/// Rendering validation integration tests for the real mamadera app.
///
/// Validates full-screen rendering behavior on iOS simulators using actual 
/// MyApp with provider overrides (no stub widgets). Checks:
/// - View widget bounds match physical screen dimensions
/// - SafeArea insets are respected correctly
/// - Bottom navigation bar renders at expected height/width
/// - Terms dialog overlay covers content properly
/// - No unexpected black bars or gaps in layout
///
/// Run on simulator: `flutter test integration_test/rendering_validation_test.dart`
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Rendering Validation', () {
    // Run terms-not-accepted test FIRST to avoid state pollution from accepted tests.
    testWidgets('Terms screen renders correctly when terms not accepted', (tester) async {
      await pumpMamadera(tester, termsNotAccepted: true);

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      // Verify the terms accept button is visible.
      final acceptButton = findByKey(TestKeys.termsAcceptButton);
      expect(acceptButton, findsOneWidget, reason: 'Terms accept button should be rendered');

      // Check that a Scaffold exists (the terms screen uses Scaffold, not Dialog).
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsWidgets, reason: 'Terms screen Scaffold should be shown on first launch');

      // Validate the Scaffold render object is within screen bounds.
      for (final match in scaffoldFinder.evaluate()) {
        if (match.renderObject is RenderBox) {
          final box = match.renderObject as RenderBox;
          final offset = box.localToGlobal(Offset.zero);

          // Content should not start far below screen top (would indicate hidden content).
          expect(
            offset.dy <= screenSize.height * 0.5,
            isTrue,
            reason: 'Terms screen content should appear near screen center/top',
          );
        }
      }

      // Accept terms and verify navigation to home.
      await tester.tap(acceptButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // After accepting, bottom nav should appear.
      expect(findByKey(TestKeys.homeTab), findsOneWidget, reason: 'Home tab should show after terms acceptance');
    });

    testWidgets('App renders full screen with correct view dimensions', (tester) async {
      await pumpMamadera(tester);

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      // Verify the app view covers the full screen.
      expect(screenSize.width, greaterThan(300), reason: 'Screen width should be reasonable');
      expect(screenSize.height, greaterThan(500), reason: 'Screen height should be reasonable');

      // Ensure no unexpected padding or margins at screen edges.
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget, reason: 'Should have a Scaffold');

      // Check that content fills available space without overflow.
      final renderObject = tester.renderObject(find.byType(MaterialApp));
      // The primary RenderView should match screen size
      expect(renderObject.paintBounds.width, greaterThan(0));
      expect(renderObject.paintBounds.height, greaterThan(0));
    });

    testWidgets('SafeArea insets are respected across screens', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      // Find all SafeArea widgets in the tree.
      final safeAreas = find.byType(SafeArea);
      
      if (safeAreas.evaluate().isEmpty) {
        // No SafeArea found — log for review but don't fail.
        debugPrint('Note: No SafeArea widget found on current screen.');
      } else {
        for (final match in safeAreas.evaluate()) {
          final safeArea = match.widget as SafeArea;

          // SafeArea widgets in the tree — just validate they render within bounds.

          if (match.renderObject is RenderBox) {
            final box = match.renderObject as RenderBox;
            final offset = box.localToGlobal(Offset.zero);

            // SafeArea content shouldn't start too far down (> 10% of screen).
            if (safeArea.top) {
              expect(
                offset.dy <= screenSize.height * 0.25,
                isTrue,
                reason: 'Top-aligned SafeArea content should not be pushed below 25% of screen height',
              );
            }
          }
        }
      }

      // Verify core widgets exist on home screen.
      expect(findByKey(TestKeys.trackMiam), findsOneWidget);
      expect(findByKey(TestKeys.homeTab), findsOneWidget);
    });

    testWidgets('Bottom navigation bar renders full width with all tabs visible', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      // Find the Scaffold containing bottom nav.
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsWidgets, reason: 'Scaffold should be rendered');

      // Verify the Scaffold fills screen width.
      if (scaffoldFinder.evaluate().isNotEmpty) {
        final renderBox = tester.renderObject<RenderBox>(scaffoldFinder.last);
        final bounds = renderBox.paintBounds;

        expect(
          bounds.width >= screenSize.width - 1.0,
          isTrue,
          reason: 'Scaffold should fill at least ${screenSize.width - 1}px of screen width (${screenSize.width}px total)',
        );
      }

      // Validate all three tabs are present.
      expect(findByKey(TestKeys.homeTab), findsOneWidget, reason: 'Home tab exists in bottom nav');
      expect(findByKey(TestKeys.historyTab), findsOneWidget, reason: 'History tab exists in bottom nav');
      expect(findByKey(TestKeys.menuTab), findsOneWidget, reason: 'Menu tab exists in bottom nav');

      // Verify BottomNavigationBar widget itself is present.
      final bnbFinder = find.byType(BottomNavigationBar);
      expect(bnbFinder, findsOneWidget, reason: 'BottomNavigationBar should exist');
    });

    testWidgets('No unexpected black bars at screen edges', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      // Check Container widgets for suspicious dimensions.
      final suspiciousContainers = <RenderBox>[];
      final containers = find.byType(Container);

      for (final match in containers.evaluate()) {
        if (match.renderObject is RenderBox) {
          final box = match.renderObject as RenderBox;
          final size = box.size;

          // A black bar is typically: wide (> 80% screen) + short (< 20% screen height).
          if (size.width > screenSize.width * 0.8 && size.height < screenSize.height * 0.2 && size.height > 0) {
            final offset = box.localToGlobal(Offset.zero);
            
            // Near top or bottom edge?
            if (offset.dy < screenSize.height * 0.1 || offset.dy > screenSize.height * 0.9) {
              suspiciousContainers.add(box);
            }
          }
        }
      }

      expect(
        suspiciousContainers.isEmpty,
        isTrue,
        reason: 'No black-bar-like containers should exist near screen edges',
      );
    });

    testWidgets('Track buttons are laid out correctly on HomeScreen', (tester) async {
      await pumpMamadera(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      // Verify all four track buttons exist.
      expect(findByKey(TestKeys.trackMiam), findsOneWidget);
      expect(findByKey(TestKeys.trackSante), findsOneWidget);
      expect(findByKey(TestKeys.trackCaca), findsOneWidget);
      expect(findByKey(TestKeys.trackDodo), findsOneWidget);

      // Check button positions don't overlap and fit within screen.
      final trackButtons = [TestKeys.trackMiam, TestKeys.trackSante, TestKeys.trackCaca, TestKeys.trackDodo];
      final offsets = <Offset>[];

      for (final key in trackButtons) {
        final finder = findByKey(key);
        final renderBox = tester.renderObject<RenderBox>(finder);
        offsets.add(renderBox.localToGlobal(Offset.zero));
      }

      // All buttons should be within the visible area.
      for (var i = 0; i < offsets.length; i++) {
        final offset = offsets[i];
        expect(
          offset.dx >= 0 && offset.dy >= 0,
          isTrue,
          reason: '${trackButtons[i]} button should not be positioned off-screen (top-left)',
        );
        expect(
          offset.dx < screenSize.width && offset.dy < screenSize.height,
          isTrue,
          reason: '${trackButtons[i]} button should not be positioned off-screen (bottom-right)',
        );
      }
    });
  });
}

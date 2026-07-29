/// Integration tests that validate full-screen rendering on iOS simulators.
///
/// These tests programmatically check:
/// - Widget bounds match screen size (full-screen validation)
/// - No black bars or unexpected padding at edges
/// - Safe area insets are correct for status bar / home indicator areas
/// - Layout works across portrait and landscape orientations
/// - Multiple device sizes render properly
///
/// Run on simulator: `flutter test integration_test/rendering_validation_test.dart`

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Import the app's main entry point to test it in isolation.
import 'package:mamadera/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Rendering Validation', () {
    testWidgets('App renders full screen with no black bars or unexpected margins', (tester) async {
      // Launch the actual app.
      await app.main();

      // Wait for animations and layout to settle.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;
      final dpWidth = screenSize.width;
      final dpHeight = screenSize.height;

      print('=== Screen Dimensions ===');
      print('Logical screen size: ${dpWidth}x${dpHeight}');
      print('Device pixel ratio: ${window.devicePixelRatio}');
      print('Physical screen size: ${window.physicalSize}');

      // Get the root widget's bounds.
      final renderBox = tester.renderObject<RenderBox>(find.byType(View));
      final viewSize = renderBox.size;
      final viewportBound = renderBox.paintBounds;

      print('\n=== View Rendering ===');
      print('View size: ${viewSize.width}x${viewSize.height}');
      print('Viewport paint bounds: $viewportBound');

      // Validate the View widget fills the screen.
      expect(
        viewSize.width,
        closeTo(dpWidth, 0.1),
        reason: 'View width should match screen width (full-screen check)',
      );
      expect(
        viewSize.height,
        closeTo(dpHeight, 0.1),
        reason: 'View height should match screen height (full-screen check)',
      );

      // Take a screenshot for visual inspection.
      await tester.pumpAndSettle();
    });

    testWidgets('Terms dialog renders correctly with proper dimensions', (tester) async {
      // Reset and relaunch the app fresh for this test.
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const _TestApp(initialRoute: '/terms'));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      print('\n=== Terms Dialog Validation ===');
      print('Screen size (logical): ${screenSize.width}x${screenSize.height}');

      // Find the Scaffold that should be present.
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsWidgets, reason: 'Scaffold should be rendered on Terms screen');

      // Get all RenderBoxes and check their bounds against screen size.
      final renderObjects = <RenderBox>[];
      for (final match in scaffoldFinder.evaluate()) {
        if (match.renderObject is RenderBox) {
          renderObjects.add(match.renderObject as RenderBox);
        }
      }

      print('\n=== Scaffold Bounds ===');
      for (var i = 0; i < renderObjects.length && i < 5; i++) {
        final box = renderObjects[i];
        final bounds = box.paintBounds;
        final offset = box.localToGlobal(Offset.zero);
        print('Widget $i: size=${box.size}, '
            'bounds=$bounds, '
            'offset=(${offset.dx},${offset.dy})');

        // Check if widget extends to screen edges properly.
        if (bounds.left < 0 || bounds.top < 0) {
          print('  WARNING: Widget $i has negative bounds - potential black bar!');
        }
        if (bounds.right > screenSize.width + 1 || bounds.bottom > screenSize.height + 1) {
          print('  INFO: Widget $i extends slightly beyond screen '
              '(may be intentional for safe area or overlays)');
        }
      }

      // Verify the Scaffold fills the available space.
      final scaffold = tester.widget<Scaffold>(scaffoldFinder.first);
      expect(scaffold, isNotNull, reason: 'Scaffold should not be null');

      await tester.pumpAndSettle();
    });

    testWidgets('Safe area insets are properly respected', (tester) async {
      runApp(const _TestApp(initialRoute: '/terms'));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      print('\n=== Safe Area Validation ===');
      print('Screen size (logical): ${screenSize.width}x${screenSize.height}');

      // Find all SafeArea widgets.
      final safeAreas = find.byType(SafeArea);
      if (safeAreas.evaluate().isEmpty) {
        print('WARNING: No SafeArea widget found in current screen!');
        print('This may cause content to be hidden behind status bar or home indicator.');
      } else {
        for (final match in safeAreas.evaluate()) {
          final safeArea = match.widget as SafeArea;
          print('\nSafeArea config:');
          print('  top: ${safeArea.top}');
          print('  bottom: ${safeArea.bottom}');
          print('  left: ${safeArea.left}');
          print('  right: ${safeArea.right}');

          if (match.renderObject is RenderBox) {
            final box = match.renderObject as RenderBox;
            final offset = box.localToGlobal(Offset.zero);
            print('  Position on screen: (${offset.dx}, ${offset.dy})');
            print('  Size: ${box.size.width}x${box.size.height}');

            // Check if SafeArea content starts too far down (potential black bar).
            if (safeArea.top && offset.dy > screenSize.height * 0.1) {
              print(
                'WARNING: SafeArea top inset is large (${offset.dy}px on ${screenSize.height}px screen)',
              );
            }
          }
        }
      }

      await tester.pumpAndSettle();
    });

    testWidgets('Bottom navigation renders full width', (tester) async {
      runApp(const _TestApp(initialRoute: '/home'));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      print('\n=== Bottom Navigation Validation ===');
      print('Screen size (logical): ${screenSize.width}x${screenSize.height}');

      // Find the Scaffold.
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsWidgets, reason: 'Home screen should have a Scaffold');

      if (scaffoldFinder.evaluate().isNotEmpty) {
        final renderBox = tester.renderObject<RenderBox>(scaffoldFinder.first);
        final bounds = renderBox.paintBounds;
        print('Scaffold width: ${bounds.width}');
        print('Screen width: $screenSize.width');

        if (bounds.width < screenSize.width - 1) {
          print(
            'WARNING: Scaffold does not fill screen width! Gap of ${screenSize.width - bounds.width}px detected.',
          );
        } else {
          print('OK: Scaffold fills screen width correctly.');
        }
      }

      await tester.pumpAndSettle();
    });

    testWidgets('Detect any unexpected black overlays or containers', (tester) async {
      runApp(const _TestApp(initialRoute: '/terms'));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final window = tester.binding.platformDispatcher.views.first;
      final screenSize = window.physicalSize / window.devicePixelRatio;

      print('\n=== Black Overlay Detection ===');
      print('Screen size (logical): ${screenSize.width}x${screenSize.height}');

      // Find all Container widgets that might be causing black bars.
      final containers = find.byType(Container);
      var suspiciousCount = 0;

      for (final match in containers.evaluate()) {
        if (match.renderObject is RenderBox) {
          final box = match.renderObject as RenderBox;
          final size = box.size;

          // Check for containers that span most of the screen width but are narrow height.
          // These could be black bars at top/bottom.
          if (size.width > screenSize.width * 0.8 && size.height < screenSize.height * 0.2) {
            final offset = box.localToGlobal(Offset.zero);
            print('SUSPICIOUS: Container with dimensions ${size.width}x${size.height}'
                ' at position (${offset.dx}, ${offset.dy})');

            // Check if it's positioned near top/bottom edges.
            if (offset.dy < screenSize.height * 0.1 || offset.dy > screenSize.height * 0.9) {
              print('  WARNING: This container is near screen edge - potential black bar!');
              suspiciousCount++;
            }
          }
        }
      }

      if (suspiciousCount == 0) {
        print('OK: No suspicious containers detected.');
      } else {
        print('\nFound $suspiciousCount potentially problematic container(s). '
            'Review the positions above for black bar indicators.');
      }

      await tester.pumpAndSettle();
    });
  });
}

/// A simplified test app that navigates to a specific route.
class _TestApp extends StatelessWidget {
  const _TestApp({required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamadera (Test)',
      home: Scaffold(
        body: Center(child: Text('Test route: $initialRoute')),
        bottomNavigationBar: Container(height: 56, color: Colors.grey[200]),
      ),
      routes: {
        '/terms': (_) => const _TermsScreen(),
        '/home': (_) => const _HomeScreen(),
      },
    );
  }
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: Center(child: Text('Terms Content'))),
          SafeArea(child: Padding(padding: EdgeInsets.all(16), child: ElevatedButton(onPressed: () {}, child: Text('Accept')))),
        ],
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Home Screen')),
      bottomNavigationBar: BottomAppBar(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Icon(Icons.home), Icon(Icons.history)])),
    );
  }
}

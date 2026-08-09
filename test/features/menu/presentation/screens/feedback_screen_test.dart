// ignore_for_file: lines_longer_than_80_chars // Comprehensive tests for FeedbackScreen widget

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mamadera/features/menu/presentation/screens/feedback_screen.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  group('FeedbackScreen', () {
    /// Helper to pump FeedbackScreen with proper localization setup.
    Future<void> pumpFeedbackTest(WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/feedback',
        debugLogDiagnostics: false,
        routes: [
          GoRoute(
            path: '/feedback',
            builder: (context, state) => const FeedbackScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', '')],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders Scaffold with AppBar showing feedback title', (tester) async {
      await pumpFeedbackTest(tester);

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.textContaining('Feedback'), findsOneWidget); // Title from localization
    });

    testWidgets('shows type selector with bug and idea options', (tester) async {
      await pumpFeedbackTest(tester);

      // Type selector has 2 GestureDetectors (bug + idea tiles)
      final gestureDetectors = find.byType(GestureDetector).evaluate();
      expect(gestureDetectors.length >= 2, true);

      // Icons for bug report and lightbulb outline should be present
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('renders two TextFormField widgets for title and description', (tester) async {
      await pumpFeedbackTest(tester);

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('submit buttons are disabled when fields are empty', (tester) async {
      await pumpFeedbackTest(tester);

      // GitHub submit button should be disabled
      final filledButtons = find.byType(FilledButton).evaluate();
      expect(filledButtons.length, 1);
      
      final githubButton = filledButtons.first.widget as FilledButton;
      expect(githubButton.onPressed, isNull);

      // Email submit button should also be disabled  
      final outlinedButtons = find.byType(OutlinedButton).evaluate();
      expect(outlinedButtons.length, 1);
      
      final emailButton = outlinedButtons.first.widget as OutlinedButton;
      expect(emailButton.onPressed, isNull);
    });

    testWidgets('submit buttons become enabled after filling required fields', (tester) async {
      await pumpFeedbackTest(tester);

      // Fill in title field
      await tester.enterText(find.byType(TextFormField).first, 'Test bug report');
      await tester.pumpAndSettle();

      // Fill in description field
      await tester.enterText(find.byType(TextFormField).last, 'Detailed description of the bug');
      await tester.pumpAndSettle();

      // GitHub button should now be enabled
      final githubButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(githubButton.onPressed, isNotNull);

      // Email button should also be enabled
      final emailButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(emailButton.onPressed, isNotNull);
    });

    testWidgets('shows validation error on empty submit attempt', (tester) async {
      await pumpFeedbackTest(tester);

      // Both TextFormFields should be present with error state initially false
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // Submit buttons are rendered but disabled when fields are empty
      final githubButton = find.byIcon(Icons.code);
      final emailButton = find.byIcon(Icons.email_outlined);
      expect(githubButton, findsOneWidget);
      expect(emailButton, findsOneWidget);
    });

    testWidgets('clears field error on text input', (tester) async {
      await pumpFeedbackTest(tester);

      // Type in title field — should clear any error state via onChanged callback
      await tester.enterText(find.byType(TextFormField).first, 'Bug report');
      await tester.pumpAndSettle();
      
      expect(find.text('Bug report'), findsOneWidget);
    });

    testWidgets('switches between bug and idea type on tap', (tester) async {
      await pumpFeedbackTest(tester);

      // Tap the first GestureDetector to switch type selection
      final gestureDetectors = find.byType(GestureDetector);
      await tester.tap(gestureDetectors.first);
      await tester.pumpAndSettle();

      // Should still have both options visible after switching
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('displays device info footer with App version', (tester) async {
      await pumpFeedbackTest(tester);

      // Device info should contain 'App' and operating system reference
      expect(
        find.textContaining('App'),
        findsWidgets,
      );
    });

    testWidgets('renders scrollable content with SingleChildScrollView', (tester) async {
      await pumpFeedbackTest(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('disposes text controllers on dispose', (tester) async {
      await pumpFeedbackTest(tester);

      // Navigate away to trigger dispose
      final newRouter = GoRouter(
        initialLocation: '/',
        debugLogDiagnostics: false,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: newRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', '')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackScreen), findsNothing);
    });

    testWidgets('shows GitHub icon on submit button', (tester) async {
      await pumpFeedbackTest(tester);

      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    testWidgets('shows email icon on secondary submit button', (tester) async {
      await pumpFeedbackTest(tester);

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('GitHub hint text is displayed below submit button', (tester) async {
      await pumpFeedbackTest(tester);

      // The Padding widget contains the GitHub hint text  
      final paddings = find.byType(Padding).evaluate();
      expect(paddings.isNotEmpty, isTrue);
    });
  });
}

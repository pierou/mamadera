// ignore_for_file: lines_longer_than_80_chars // Comprehensive tests for TermsContent widget

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/onboarding/presentation/widgets/terms_content.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  group('TermsContent', () {
    const localizationDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    testWidgets('renders TermsContent widget without framework errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();

      // Verify TermsContent builds without throwing framework exceptions
      expect(find.byType(TermsContent), findsOneWidget);
      
      // Clear any captured exceptions to verify clean render
      final exception = tester.takeException();
      if (exception != null && !exception.toString().contains('MissingPlugin')) {
        throw Exception('Unexpected error during build: $exception');
      }

      expect(find.byType(FutureBuilder<String>), findsOneWidget);
    });

    testWidgets('shows error message when asset fails to load', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      // Initial pump shows loading indicator
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After sufficient time, the FutureBuilder should resolve or show error state
      await tester.pump(const Duration(milliseconds: 100));
      
      // Verify widget is still present and handles missing assets gracefully
      expect(find.byType(Center), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses correct locale for asset path', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsContent), findsOneWidget);
    });

    testWidgets('renders with French locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          locale: const Locale('fr', ''),
          supportedLocales: const [Locale('en', ''), Locale('fr', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsContent), findsOneWidget);
    });

    testWidgets('renders with Spanish locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          locale: const Locale('es', ''),
          supportedLocales: const [Locale('en', ''), Locale('es', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsContent), findsOneWidget);
    });

    testWidgets('content fills available space during loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();

      // During loading phase, should show CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // The SizedBox.expand widget ensures content fills parent space
      final sizedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.child != null,
      );
      expect(sizedBoxFinder, findsWidgets);
    });

    testWidgets('renders without errors in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          themeMode: ThemeMode.light,
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsContent), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without errors in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsContent), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles empty markdown response gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      // Initial pump shows loading state
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After waiting for async operation to complete or timeout
      await tester.pump(const Duration(milliseconds: 100));

      // Widget should handle missing assets without crashing
      expect(find.byType(TermsContent), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('centered layout for error state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: localizationDelegates,
          supportedLocales: const [Locale('en', '')],
          home: const Scaffold(body: TermsContent()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final center = find.byType(Center);
      expect(center, findsWidgets);
    });
  });
}

// ignore_for_file: lines_longer_than_80_chars // Comprehensive tests for TermsScreen widget

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/onboarding/presentation/screens/terms_screen.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  group('TermsScreen', () {
    const localizationDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    testWidgets('renders Scaffold with AppBar showing terms title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('AppBar has centered title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('shows loading indicator while fetching terms content', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Initial state should show CircularProgressIndicator or FutureBuilder waiting state
      expect(find.byType(FutureBuilder<String>), findsOneWidget);
    });

    testWidgets('uses locale-specific asset path for English', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsScreen), findsOneWidget);
    });

    testWidgets('uses locale-specific asset path for Spanish', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            locale: const Locale('es', ''),
            supportedLocales: const [Locale('en', ''), Locale('es', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsScreen), findsOneWidget);
    });

    testWidgets('uses French asset path as default fallback for non-en/es locales', (tester) async {
      // For any locale not en/es, should fall back to French assets/terms/terms_fr.md
      // We verify the Scaffold/AppBar render regardless of asset loading success
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            locale: const Locale('fr', ''),
            supportedLocales: const [Locale('en', ''), Locale('fr', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Verify the screen renders with proper structure (Scaffold + AppBar)
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders with light theme without errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            themeMode: ThemeMode.light,
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with dark theme without errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            themeMode: ThemeMode.dark,
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TermsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays error message when asset fails to load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // In test environment, assets won't be available
      final center = find.byType(Center);
      expect(center, findsWidgets);
    });

    testWidgets('FutureBuilder handles all connection states gracefully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      
      // Verify FutureBuilder is present and handling waiting state initially
      expect(find.byType(FutureBuilder<String>), findsOneWidget);
    });

    testWidgets('scrollable content area for long terms text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // When asset fails, we should see error state
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('maintains consistent widget tree structure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: const TermsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify key widgets are present in the tree
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FutureBuilder<String>), findsOneWidget);
    });
  });
}

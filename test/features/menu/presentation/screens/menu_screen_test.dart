import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/menu/presentation/screens/menu_screen.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  group('MenuScreen', () {
    Future<void> pumpMenuScreen({required WidgetTester tester}) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('fr'),
            supportedLocales: [Locale('fr'), Locale('en')],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MenuScreen(),
          ),
        ),
      );
    }

    testWidgets('affiche le titre', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('affiche la section profils bébé', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Bébés'), findsOneWidget);
    });

    testWidgets('affiche la section langue', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Langue'), findsOneWidget);
    });

    testWidgets('affiche les options de langue', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('affiche la section thème', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Thème'), findsOneWidget);
    });

    testWidgets('affiche les options de thème', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Système'), findsOneWidget);
      expect(find.text('Clair'), findsOneWidget);
      expect(find.text('Sombre'), findsOneWidget);
    });

    testWidgets('affiche la zone danger', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Zone de danger'), findsOneWidget);
    });

    testWidgets('affiche le bouton réinitialisation base de données', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Réinitialiser la base de données'), findsOneWidget);
    });
  });
}

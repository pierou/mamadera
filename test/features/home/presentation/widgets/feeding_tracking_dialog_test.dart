import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';
import 'package:mamadera/features/home/presentation/widgets/feeding_tracking_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  group('FeedingTrackingDialog', () {
    // Helper pour pump le dialog et attendre la fin du rendu
    Future<void> pumpDialog(WidgetTester tester) => tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('fr'),
          supportedLocales: [Locale('fr')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: FeedingTrackingDialog()),
        ),
      ),
    );

    testWidgets('affiche le titre et les labels', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.text('Suivre l\'Alimentation'), findsOneWidget);
      expect(find.text('Type d\'Alimentation'), findsOneWidget);
      expect(find.text('Quantité'), findsOneWidget);
    });

    testWidgets('affiche les 2 sous-types d\'alimentation', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.text('Lait Maternel'), findsOneWidget);
      expect(find.text('Lait Artificiel'), findsOneWidget);
    });

    testWidgets('sous-type par défaut est naturel (lait maternel)', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Le premier FilterChip (Lait Maternel) doit être sélectionné
      final naturalChip = find.widgetWithText(FilterChip, 'Lait Maternel');
      final chipState = tester.widget<FilterChip>(naturalChip);
      expect(chipState.selected, isTrue);

      // Et le second non sélectionné
      final artificialChip = find.widgetWithText(FilterChip, 'Lait Artificiel');
      final chipArtificial = tester.widget<FilterChip>(artificialChip);
      expect(chipArtificial.selected, isFalse);
    });

    testWidgets('sélectionner lait artificiel change le subtype sélectionné', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Cliquer sur Lait Artificiel
      await tester.tap(find.text('Lait Artificiel'));
      await tester.pumpAndSettle();

      // Maintenant c'est Lait Artificiel qui est sélectionné
      final artificialChip = find.widgetWithText(FilterChip, 'Lait Artificiel');
      final chipState = tester.widget<FilterChip>(artificialChip);
      expect(chipState.selected, isTrue);

      // Et Lait Maternel n'est plus sélectionné
      final naturalChip = find.widgetWithText(FilterChip, 'Lait Maternel');
      final chipNatural = tester.widget<FilterChip>(naturalChip);
      expect(chipNatural.selected, isFalse);
    });

    testWidgets('affiche QuantityPickerInline widget', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.byType(QuantityPickerInline), findsOneWidget);
    });

    testWidgets('affiche la quantité par défaut à 0 ml', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.text('0 ml'), findsOneWidget);
    });

    testWidgets('affiche les boutons Annuler et Confirmer', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
    });

    testWidgets('bouton Confirmer est présent et cliquable', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Vérifier que le dialog est affiché
      expect(find.text('Suivre l\'Alimentation'), findsOneWidget);

      // Le bouton Confirmer doit être présent
      final confirmButton = find.text('Confirmer');
      expect(confirmButton, findsOneWidget);

      // Cliquer sur Confirmer ne devrait pas crasher
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
    });

    testWidgets('changer de subtype puis confirmer fonctionne', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Changer vers Lait Artificiel (artificial)
      await tester.tap(find.text('Lait Artificiel'));
      await tester.pumpAndSettle();

      // Vérifier que Lait Artificiel est sélectionné
      final artificialChip = find.widgetWithText(FilterChip, 'Lait Artificiel');
      final chipState = tester.widget<FilterChip>(artificialChip);
      expect(chipState.selected, isTrue);

      // Cliquer sur Confirmer devrait fonctionner sans crash
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
    });

    testWidgets('bouton Annuler est présent et cliquable', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Le bouton Annuler doit être présent
      final cancelButton = find.text('Annuler');
      expect(cancelButton, findsOneWidget);

      // Cliquer sur Annuler ne devrait pas crasher
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();
    });

    // ── Accessibility tests ──────────────────────────────────────

    testWidgets('has Semantics on FilterChip buttons', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Verify Semantics widgets exist for chip buttons
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: FeedingTrackingDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Suivre l\'Alimentation'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: FeedingTrackingDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Suivre l\'Alimentation'), findsOneWidget);
    });

    // ── Localization tests ───────────────────────────────────────

    testWidgets('renders correctly in English locale', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: const [Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: FeedingTrackingDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Track Feeding'), findsOneWidget);
      expect(find.text('Breast milk'), findsOneWidget);
      expect(find.text('Formula'), findsOneWidget);
    });

    testWidgets('renders correctly in Spanish locale', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: const [Locale('es')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: FeedingTrackingDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Registrar Alimentación'), findsOneWidget);
      expect(find.text('Leche Materna'), findsOneWidget);
    });
  });
}

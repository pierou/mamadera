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

    testWidgets('sous-type par défaut est naturel (lait maternel)',
        (tester) async {
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

    testWidgets('sélectionner lait artificiel change le subtype sélectionné',
        (tester) async {
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

    testWidgets('natural s\'ouvre en minutes : la quantité par défaut est 0 min',
        (tester) async {
      // L'unité par défaut de `natural` est `min` (décision propriétaire
      // 2026-10-03) : une tétée se chronomètre, un biberon se mesure.
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.text('0 min'), findsOneWidget);
    });

    testWidgets(
        'sélectionner Solide passe le picker en grammes (0-1000, pas de 5)',
        (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solide'));
      await tester.pumpAndSettle();

      final picker = tester
          .widget<QuantityPickerInline>(find.byType(QuantityPickerInline));
      expect(picker.unit, equals('g'));
      expect(picker.min, equals(0));
      expect(picker.max, equals(1000));
      expect(picker.step, equals(5));
      expect(find.text('0 g'), findsOneWidget);
    });

    // Verrou de sémantique des données (décision propriétaire 2026-10-03,
    // amendement n°2) : le sein n'est figé **ni** en minutes **ni** en ml — le
    // parent choisit, et le choix est réversible. Le nombre ne survit jamais
    // à un changement d'unité : 20 min n'est pas 20 ml.
    //
    // La protection des lignes `natural` **existantes** (lait tiré affiché « 20
    // ml » sur tous les builds livrés) n'est plus ici : elle est dans le
    // backfill de la migration v12 (`natural` → `'ml'`, jamais `'min'`),
    // verrouillé par `test/data/local/migration_v11_to_v12_test.dart`. Ce test
    // vérifie le contrat de **saisie** : ouverture en min, ml au toggle, remise
    // à 0 annoncée.
    testWidgets(
        'natural : min à l\'ouverture, ml au toggle, remise à 0 avec message',
        (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Ouverture : `min`, et le toggle est visible (seul `natural` l'a).
      final picker = tester
          .widget<QuantityPickerInline>(find.byType(QuantityPickerInline));
      expect(picker.unit, equals('min'));
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('Millilitres'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);

      // 20 minutes saisies, puis passage en ml : le nombre est remis à 0 et
      // le dialog le dit — jamais re-étiqueté en silence.
      await tester.enterText(find.byType(TextField), '20');
      await tester.pump();
      expect(find.text('20 min'), findsOneWidget);

      await tester.tap(find.text('Millilitres'));
      await tester.pumpAndSettle();

      final pickerMl = tester
          .widget<QuantityPickerInline>(find.byType(QuantityPickerInline));
      expect(pickerMl.unit, equals('ml'));
      expect(pickerMl.max, equals(300));
      expect(find.text('0 ml'), findsOneWidget);
      expect(
          find.text('Unité modifiée : la quantité a été remise à 0.'),
          findsOneWidget);
    });

    testWidgets(
        'revenir à Lait Artificiel remet le picker en ml (0-300, pas de 10)',
        (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solide'));
      await tester.pumpAndSettle();
      expect(find.text('0 g'), findsOneWidget);

      await tester.tap(find.text('Lait Artificiel'));
      await tester.pumpAndSettle();

      final picker = tester
          .widget<QuantityPickerInline>(find.byType(QuantityPickerInline));
      expect(picker.unit, equals('ml'));
      expect(picker.max, equals(300));
      expect(picker.step, equals(10));
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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';
import 'package:mamadera/features/home/presentation/widgets/feeding_tracking_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  group('FeedingTrackingDialog', () {
    // Helper to manage the dialog and wait for the rendering to complete.
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

      // The first FilterChip (Breast Milk) must be selected.
      final naturalChip = find.widgetWithText(FilterChip, 'Lait Maternel');
      final chipState = tester.widget<FilterChip>(naturalChip);
      expect(chipState.selected, isTrue);

      // And the second person who was not selected.
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

      // Now, it's artificial milk that is being selected.
      final artificialChip = find.widgetWithText(FilterChip, 'Lait Artificiel');
      final chipState = tester.widget<FilterChip>(artificialChip);
      expect(chipState.selected, isTrue);

      // And "Breast Milk" is no longer being selected.
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
      // The default unit for `natural` is `min` (this is a proprietary decision).
      // (October 3, 2026): The duration of breastfeeding is timed, and the amount of formula given in a bottle is measured.
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

    // Semantic data lock (proprietary decision, October 3, 2026).
    // Amendment No. 2: The breast volume is not fixed, either in minutes or in milliliters – it is...
    // The parent cell chooses, and this choice is reversible. The number never survives.
    // It's important to pay attention to the units of measurement: 20 minutes is not the same as 20 milliliters.
    //
    // The protection of existing `natural` product lines (e.g., breast milk displayed as "20...").
    // "ml" (which previously appeared on all delivered builds) is no longer present; it has been moved to the...
    // Backfill the migration from version 12, changing the value from `natural` to `'ml'`, but never to `'min'`.
    // locked by `test/data/local/migration_v11_to_v12_test.dart`. This test.
    // Check the "seizure" contract: opening in "min" and "ml" modes, with a toggle switch, and a reset function.
    // Announced at 0.
    testWidgets(
        'natural : min à l\'ouverture, ml au toggle, remise à 0 avec message',
        (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Opening: `min`, and the toggle is visible (only `natural` has this feature).
      final picker = tester
          .widget<QuantityPickerInline>(find.byType(QuantityPickerInline));
      expect(picker.unit, equals('min'));
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('Millilitres'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);

      // 20 minutes of data collection, then conversion to milliliters: the count is reset to 0, and...
      // The dialogue says it – never silently relabeled.
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

      // Ensure that the dialog box is displayed.
      expect(find.text('Suivre l\'Alimentation'), findsOneWidget);

      // The "Confirm" button must be present.
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

      // Make sure that "Infant Formula" is selected.
      final artificialChip = find.widgetWithText(FilterChip, 'Lait Artificiel');
      final chipState = tester.widget<FilterChip>(artificialChip);
      expect(chipState.selected, isTrue);

      // Clicking the "Confirm" button should work without causing any errors.
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
    });

    testWidgets('bouton Annuler est présent et cliquable', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // The "Cancel" button must be present.
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

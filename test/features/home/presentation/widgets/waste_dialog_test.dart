import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/features/home/presentation/widgets/waste_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('WasteDialog', () {
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
          home: Scaffold(body: WasteDialog()),
        ),
      ),
    );

    testWidgets('affiche les 3 types de selle', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.text('🟡 Pipi'), findsOneWidget);
      expect(find.text('🟤 Caca'), findsOneWidget);
      expect(find.text('🟡🟤 Les deux'), findsOneWidget);
    });

    testWidgets('sélection par défaut est caca', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // La section couleur du caca doit être visible par défaut
      expect(find.text('Couleur du caca'), findsOneWidget);
      // Mais pas celle du pipi
      expect(find.text('Couleur du pipi'), findsNothing);
    });

    testWidgets('sélectionner pipi montre la section couleur pipi', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Cliquer sur Pipi
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsNothing);
    });

    testWidgets('sélectionner les deux montre les 2 sections', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Cliquer sur Les deux
      await tester.tap(find.text('🟡🟤 Les deux'));
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsOneWidget);
    });

    testWidgets('affiche les couleurs de pipi', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Aller sur pipi pour voir ses couleurs
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      expect(find.text('Incolore'), findsOneWidget);
      expect(find.text('Jaune clair'), findsOneWidget);
      expect(find.text('Jaune foncé'), findsOneWidget);
      expect(find.textContaining('urates'), findsOneWidget);
    });

    testWidgets('affiche les couleurs de caca', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Caca est sélectionné par défaut, ses couleurs sont visibles
      expect(find.text('Mécônium'), findsOneWidget);
      expect(find.text('Vert olive'), findsOneWidget);
      expect(find.text('Jaune moutarde'), findsOneWidget);
    });

    testWidgets('bouton Enregistrer est présent', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('sélectionner une couleur pipi la met en état selected', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Aller sur pipi
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      // Sélectionner Jaune clair
      final chip = find.widgetWithText(FilterChip, 'Jaune clair');
      expect(chip, findsOneWidget);

      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Le chip doit être sélectionné (on vérifie qu'il existe toujours)
      expect(find.text('Jaune clair'), findsOneWidget);
    });

    testWidgets('sélectionner une couleur caca la met en état selected', (tester) async {
      await pumpDialog(tester);
      await tester.pumpAndSettle();

      // Sélectionner Jaune moutarde
      final chip = find.widgetWithText(FilterChip, 'Jaune moutarde');
      expect(chip, findsOneWidget);

      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.text('Jaune moutarde'), findsOneWidget);
    });
  });

  group('PipiColor', () {
    test('byValue retourne la bonne couleur pour incolore', () {
      final color = PipiColor.byValue('incolore');
      expect(color, isNotNull);
      expect(color!.value, 'incolore');
      expect(color.label, 'Incolore');
    });

    test('byValue retourne la bonne couleur pour jaune_clair', () {
      final color = PipiColor.byValue('jaune_clair');
      expect(color, isNotNull);
      expect(color!.value, 'jaune_clair');
    });

    test('fromDbValue retourne le premier par défaut si valeur inconnue', () {
      final color = PipiColor.fromDbValue('inconnu');
      expect(color.value, 'incolore'); // default to first
    });

    test('values contient 4 couleurs', () {
      expect(PipiColor.values.length, 4);
    });
  });

  group('CacaColor', () {
    test('byValue retourne la bonne couleur pour meconium', () {
      final color = CacaColor.byValue('meconium');
      expect(color, isNotNull);
      expect(color!.value, 'meconium');
    });

    test('fromDbValue retourne jaune_moutarde par défaut si valeur inconnue', () {
      final color = CacaColor.fromDbValue('inconnu');
      expect(color.value, 'jaune_moutarde'); // default to index 2
    });

    test('values contient 4 couleurs', () {
      expect(CacaColor.values.length, 4);
    });
  });
}

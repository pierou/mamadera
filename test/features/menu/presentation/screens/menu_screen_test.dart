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

    testWidgets('affiche la section rappels et sa tuile', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));

      // Le titre de section et le libellé de la tuile sont différents : une
      // seule occurrence de « Rappels » à l'écran.
      expect(find.text('Rappels'), findsOneWidget);
      expect(find.text('Choisir les rappels affichés'), findsOneWidget);
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

    testWidgets('affiche la tuile export au-dessus du reset et ouvre la boîte de dialogue', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Exporter mes données'), findsOneWidget);
      expect(find.text('Sauvegarde JSON de toutes vos données'), findsOneWidget);

      // La zone danger est sous le pli : rendre la tuile visible avant de tap.
      await tester.ensureVisible(find.text('Exporter mes données'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Exporter mes données'));
      // Pas de pumpAndSettle : la section profils affiche un indicateur de
      // chargement en boucle (provider DB non résolu en test), ce qui le ferait
      // expirer. Le dialogue s'anime en < 500 ms : des pumps fixes suffisent.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // La boîte de dialogue montre l'avertissement de confidentialité
      // AVANT toute action, plus les boutons annuler/confirmer.
      expect(
        find.text('Ce fichier contiendra toutes vos données, y compris les notes de santé en texte lisible. Vous choisissez où l\'enregistrer : rien n\'est envoyé automatiquement.'),
        findsOneWidget,
      );
      expect(find.text('Exporter'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('affiche la tuile restauration entre export et reset et ouvre le dialogue import', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Restaurer depuis une sauvegarde'), findsOneWidget);
      expect(find.text('Réinitialiser la base de données'), findsOneWidget);

      // Ordre vertical de la zone danger : export, puis restauration, puis reset.
      final exportY = tester.getCenter(find.text('Exporter mes données')).dy;
      final restoreY = tester.getCenter(find.text('Restaurer depuis une sauvegarde')).dy;
      final resetY = tester.getCenter(find.text('Réinitialiser la base de données')).dy;
      expect(restoreY, greaterThan(exportY));
      expect(resetY, greaterThan(restoreY));

      // La zone danger est sous le pli : rendre la tuile visible avant de tap.
      await tester.ensureVisible(find.text('Restaurer depuis une sauvegarde'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Restaurer depuis une sauvegarde'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // String propre au dialogue : l'avertissement destructif, avant toute action.
      expect(
        find.textContaining('supprimera définitivement toutes les données actuellement sur cet appareil'),
        findsOneWidget,
      );
      expect(find.text('Choisir un fichier…'), findsOneWidget);
    });

    testWidgets('la tuile reset est toujours présente et ouvre sa confirmation', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Réinitialiser la base de données'), findsOneWidget);

      await tester.ensureVisible(find.text('Réinitialiser la base de données'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Réinitialiser la base de données'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Réinitialiser la base de données ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });
  });
}

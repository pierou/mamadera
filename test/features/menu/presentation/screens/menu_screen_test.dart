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

    testWidgets('affiche la section croissance et sa tuile', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      // The heading "Growth" serves as both the section header and the title for the tile.
      expect(find.text('Croissance'), findsNWidgets(2));
      expect(find.byIcon(Icons.straighten), findsOneWidget);
    });

    testWidgets('affiche la section rappels et sa tuile', (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));

      // The section title and the tile label are different: a...
      // This is the only instance of the word "Recalls" that appears on the screen.
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

    testWidgets('affiche le bouton réinitialisation base de données',
        (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Réinitialiser la base de données'), findsOneWidget);
    });

    testWidgets(
        'affiche la tuile export au-dessus du reset et ouvre la boîte de dialogue',
        (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Exporter mes données'), findsOneWidget);
      expect(
          find.text('Sauvegarde JSON de toutes vos données'), findsOneWidget);

      // The danger zone is located under the fold: make the tile visible before tapping.
      await tester.ensureVisible(find.text('Exporter mes données'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Exporter mes données'));
      // No pumpAndSettle: The profiles section displays an indicator of...
      // (In testing, the provider database was not resolved, which would cause) a continuous loading process.
      // expire. The dialogue becomes interactive in under 500 milliseconds: fixed pumps are sufficient.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The dialog box displays the privacy warning.
      // Before taking any action, please use the "cancel" or "confirm" buttons.
      expect(
        find.text(
            'Ce fichier contiendra toutes vos données, y compris les notes de santé en texte lisible. Vous choisissez où l\'enregistrer : rien n\'est envoyé automatiquement.'),
        findsOneWidget,
      );
      expect(find.text('Exporter'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets(
        'affiche la tuile restauration entre export et reset et ouvre le dialogue import',
        (tester) async {
      await pumpMenuScreen(tester: tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Restaurer depuis une sauvegarde'), findsOneWidget);
      expect(find.text('Réinitialiser la base de données'), findsOneWidget);

      // The vertical order of operations for the danger zone is: export, then restore, then reset.
      final exportY = tester.getCenter(find.text('Exporter mes données')).dy;
      final restoreY =
          tester.getCenter(find.text('Restaurer depuis une sauvegarde')).dy;
      final resetY =
          tester.getCenter(find.text('Réinitialiser la base de données')).dy;
      expect(restoreY, greaterThan(exportY));
      expect(resetY, greaterThan(restoreY));

      // The danger zone is located under the fold: make the tile visible before tapping.
      await tester.ensureVisible(find.text('Restaurer depuis une sauvegarde'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Restaurer depuis une sauvegarde'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // A key element of effective communication: the destructive warning, preceding any action.
      expect(
        find.textContaining(
            'supprimera définitivement toutes les données actuellement sur cet appareil'),
        findsOneWidget,
      );
      expect(find.text('Choisir un fichier…'), findsOneWidget);
    });

    testWidgets('la tuile reset est toujours présente et ouvre sa confirmation',
        (tester) async {
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

    group('language change confirmation (B11)', () {
      Future<void> pumpLocale(
        WidgetTester tester,
        String locale,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: Locale(locale),
              supportedLocales: const [
                Locale('fr'),
                Locale('en'),
                Locale('es')
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const MenuScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The tree is still built in the source locale when the snackbar is
      // read — the rebuild in the target locale happens on the next frame.
      // The confirmation must therefore be resolved in the target locale.
      //
      // The tap handler awaits the locale service (persistence), so the tap
      // runs on the real event loop via `runAsync`; the fake zone would
      // freeze the file I/O and the handler would never finish.
      testWidgets('fr -> en: the snackbar reads in English, not French',
          (tester) async {
        await pumpLocale(tester, 'fr');

        await tester.ensureVisible(find.text('English'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          await tester.tap(find.text('English'));
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pump();

        expect(find.text('Language changed'), findsOneWidget);
        expect(find.text('Langue changée'), findsNothing);
      });

      testWidgets('fr -> es: the snackbar reads in Spanish, not French',
          (tester) async {
        await pumpLocale(tester, 'fr');

        await tester.ensureVisible(find.text('Español'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          await tester.tap(find.text('Español'));
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pump();

        expect(find.text('Idioma cambiado'), findsOneWidget);
        expect(find.text('Langue changée'), findsNothing);
      });

      testWidgets('en -> fr: the snackbar reads in French, not English',
          (tester) async {
        await pumpLocale(tester, 'en');

        await tester.ensureVisible(find.text('Français'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          await tester.tap(find.text('Français'));
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pump();

        expect(find.text('Langue changée'), findsOneWidget);
        expect(find.text('Language changed'), findsNothing);
      });
    });
  });
}

// ignore_for_file: avoid_print
/// Gate de version v1.2.1 — pass de montée sur le build CORRIGÉ, par-dessus
/// la base fichier écrite par le build précédent (`rc2_seed.dart` exécuté
/// dans le worktree @ 7bbe237).
///
/// Chaque `testWidgets` re-pomp l'app complète SANS override de base : la
/// `mamadera.db` du fichier de l'appareil est celle du build rc.2, c'est elle
/// qui doit être lue, migrée (ici : même version de schéma) et affichée.
///
/// Ce que le pass prouve, dans l'ordre :
///  1. l'ancien contenu est visible après la montée (data survived) ;
///  2. la feuille de saisie part de la DERNIÈRE mesure (hint « Last: » +
///     premier cran du ±) et l'accueil se met à jour après enregistrement —
///     les deux défauts v1.2.1 du rapport ;
///  3. la température, valeur du rapport (36,8 °C), part bien de 36,8 et le
///     « Annuler » ne laisse rien derrière ;
///  4. corriger une mesure depuis l'historique met l'accueil à jour
///     (invalidation) ;
///  5. supprimer une mesure depuis l'historique met l'accueil à jour ;
///  6. le chemin manuel de saisie fonctionne : allaitement, sommeil, mesure ;
///  7. l'export s'exécute : la feuille de partage est offerte, le fichier
///     JSON reste sur l'appareil (inspecté côté hôte, voir le rapport).
///
/// Les captures d'écran reviennent via `reportData` et sont écrites par
/// `test_driver/v121_upgrade_verify.driver.dart`.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'test_utils.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Capture d'écran : la conversion surface→image est un état du binding
  /// par instance d'app — une nouvelle `pumpWidget` la remet à zéro, mais
  /// une deuxième conversion dans la même instance lève l'assertion
  /// « Surface already converted » alors que takeScreenshot fonctionne quand
  /// même. On tente donc la conversion et on encaisse cette assertion-là.
  Future<void> shot(String name, WidgetTester tester) async {
    try {
      await binding.convertFlutterSurfaceToImage();
      // ignore: avoid_catching_errors — on encaisse l'assertion du binding.
    } on AssertionError catch (e) {
      if (!e.message.toString().contains('already converted')) rethrow;
    }
    await tester.pump();
    await binding.takeScreenshot(name);
    print('[SHOT] $name');
  }

  group('v1.2.1 upgrade pass — previous-build data on the new build', () {
    testWidgets('1. home shows the seeded measurements after the upgrade',
        (tester) async {
      WidgetsApp.debugAllowBannerOverride = false;
      await pumpMamadera(tester, useInMemoryDb: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Emma'), findsOneWidget,
          reason: 'le bébé semé est actif après la montée');
      // Une dernière mesure par grande : le contenu du build précédent est
      // lu par le nouveau, ni perdu ni « non lisible ».
      expect(find.text('3.9 kg'), findsOneWidget, reason: 'poids 3900 g');
      expect(find.text('52.5 cm'), findsOneWidget, reason: 'taille 52,5 cm');
      expect(find.text('36.8 °C'), findsOneWidget, reason: 'température 36,8');

      await shot('01-home-after-upgrade', tester);
    });

    testWidgets(
        '2. weight sheet starts from the last measurement and home refreshes '
        'on save', (tester) async {
      WidgetsApp.debugAllowBannerOverride = false;
      await pumpMamadera(tester, useInMemoryDb: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const ValueKey('measure-poids')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Le hint affiche la dernière mesure — pas la valeur de référence.
      expect(find.text('Last: 3.9 kg'), findsOneWidget,
          reason: 'l’en-tête cite la dernière mesure, 3900 g');

      // Avant le correctif le ± ajoutait depuis 3500 (→ 3510). Ici : depuis
      // 3900 (→ 3910) — le curseur est assis sur la dernière valeur.
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      expect(find.text('3910 g'), findsOneWidget,
          reason: 'le premier cran part de 3900, pas de 3500');

      await shot('02-weight-sheet-cursor', tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // La feuille se ferme et l’accueil affiche la nouvelle valeur sans
      // aucune navigation — le second défaut du rapport.
      expect(find.textContaining('Measurement saved'), findsWidgets);
      expect(find.text('3.91 kg'), findsWidgets,
          reason: 'la ligne de l’accueil a suivi le 3910 g');
      await shot('03-home-after-save', tester);
    });

    testWidgets('3. temperature starts from the last 36.8; cancel keeps it',
        (tester) async {
      WidgetsApp.debugAllowBannerOverride = false;
      await pumpMamadera(tester, useInMemoryDb: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const ValueKey('measure-temperature')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Last: 36.8 °C'), findsOneWidget,
          reason: 'le rapport de défaut portait sur la température');

      // Décimales : le premier cran donne 36,9 — avant le correctif il
      // donnait 37,1 (partant de 37,0).
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      expect(find.text('36.9 °C'), findsOneWidget,
          reason: 'le pas 0,1 part de 36,8, pas de 37,0');

      await shot('04-temperature-sheet-cursor', tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('36.8 °C'), findsOneWidget,
          reason: 'l’annulation n’a rien écrit');
    });

    testWidgets('4. editing a measurement from history refreshes home',
        (tester) async {
      WidgetsApp.debugAllowBannerOverride = false;
      await pumpMamadera(tester, useInMemoryDb: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // La ligne enregistrée au test 2 (3910 g) figure dans la chronologie.
      final row = find.text('3.91 kg');
      expect(row, findsOneWidget, reason: 'la mesure du test 2 est là');
      await shot('05-history-with-measurements', tester);

      await tester.tap(row);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Edit weight'), findsOneWidget);
      expect(find.text('3910 g'), findsOneWidget,
          reason: 'la fiche pré-remplit la valeur de la ligne');
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      expect(find.text('3920 g'), findsOneWidget);
      await shot('06-edit-sheet', tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('3.92 kg'), findsWidgets,
          reason: 'la chronologie a rechargé la valeur corrigée');

      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('3.92 kg'), findsOneWidget,
          reason: 'l’accueil a suivi la correction (invalidation)');
      await shot('07-home-after-edit', tester);
    });

    testWidgets('5. deleting a measurement from history refreshes home',
        (tester) async {
      WidgetsApp.debugAllowBannerOverride = false;
      await pumpMamadera(tester, useInMemoryDb: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final row = find.text('3.92 kg');
      expect(row, findsOneWidget, reason: 'la ligne corrigée est là');
      await tester.tap(row);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Edit weight'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('3.92 kg'), findsNothing,
          reason: 'la ligne supprimée a disparu de la chronologie');

      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('3.9 kg'), findsOneWidget,
          reason: 'la dernière mesure redevient 3900 g sur l’accueil');
      await shot('08-home-after-delete', tester);
    });

    testWidgets('6. manual entry: a feeding and a sleep are recorded',
        (tester) async {
      WidgetsApp.debugAllowBannerOverride = false;
      await pumpMamadera(tester, useInMemoryDb: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Retour forcé à l'onglet accueil : un test précédent peut être mort
      // ailleurs, et chaque pumpWidget repart de splash mais rien ne coûte
      // de s'assurer d'être bien sur la grille.
      final homeTab = findByKey(TestKeys.homeTab);
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Allaitement : sous-type par défaut (sein), quantité nulle.
      final miam = findByKey(TestKeys.trackMiam);
      if (miam.evaluate().isEmpty) {
        final visibles = find.byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .whereType<String>()
            .take(40)
            .join(' | ');
        print('[DEBUG] track-miam absent — textes visibles : $visibles');
      }
      expect(miam, findsWidgets, reason: 'le bouton allaitement est là');
      await tester.tap(miam.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await shot('09-feeding-dialog', tester);
      // Sur les petites tailles d’écran le bouton Confirm est sous le pli :
      // la fiche défile (SingleChildScrollView), l’utilisateur scrolle —
      // le test aussi, sinon le tap rate silencieusement.
      final confirmFeeding = find.text('Confirm');
      await tester.ensureVisible(confirmFeeding);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(confirmFeeding);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('Breast milk'), findsWidgets,
          reason: 'la fiche de retour confirme l’allaitement');

      // Sommeil : durée par défaut, confirmation.
      await tester.tap(findByKey(TestKeys.trackDodo));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await shot('10-sleep-dialog', tester);
      final confirmSleep = find.text('Confirm');
      await tester.ensureVisible(confirmSleep);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(confirmSleep);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('Sleep ·'), findsWidgets,
          reason: 'la fiche de retour confirme le sommeil');
    });

    testWidgets('7. export: the share sheet is offered', (tester) async {
      WidgetsApp.debugAllowBannerOverride = false;
      // Fake de plateforme AVANT toute interaction : SharePlus.instance est
      // un static final qui capture SharePlatform.instance à son premier
      // accès, et seul ce flux export l'accède dans l'app.
      SharePlatform.instance = shareStash;
      await pumpMamadera(tester, useInMemoryDb: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(findByKey(TestKeys.menuTab));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // « Export my data » est sous le pli du menu : un tap sans scroll
      // manquerait silencieusement (les coordonnées tombent hors écran).
      final exportItem = find.text('Export my data');
      await tester.ensureVisible(exportItem);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(exportItem);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Export my data'), findsWidgets,
          reason: 'le titre du dialogue est ouvert (tuile + titre)');
      await shot('11-export-dialog', tester);

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(find.text('Export complete'), findsOneWidget,
          reason: 'l’export s’est terminé ; le contenu a été capturé');
      await shot('12-export-complete', tester);

      // Le fichier d’export est supprimé par le `finally` du contrôleur juste
      // après le partage : le fake de plateforme l’a lu à l’instant `share()`
      // — c’est cette copie que le hôte inspectera (troisième exigence du
      // pass : exporter et examiner le JSON). Sans ce fake, le chooser
      // Android resterait ouvert et le spinner du dialogue empêche tout
      // pumpAndSettle.
      final doc = shareStash.content;
      expect(doc, isNotNull, reason: 'le JSON a été capturé au moment du share');
      print('[EXPORT] ${shareStash.params?.files?.single.path} ');
      expect(doc!, contains('"exportFormatVersion"'));
      expect(doc, contains('"babyProfiles"'));
      expect(doc, contains('"trackingEvents"'));
      expect(doc, contains('"measurements"'));
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['exportedJson'] = doc;
    });
  });
}

/// Plateforme de partage fausse pour le pass de montée : capture le
/// paramètre `share` (dont le chemin du fichier) et son contenu au moment
/// exact où l'app partagent — avant que le `finally` du contrôleur ne
/// supprime le fichier. Même mécanique que `_RecordingSharePlatform` des
/// tests unitaires de `shareExport`.
class _StashingSharePlatform extends SharePlatform {
  ShareParams? params;
  String? content;

  @override
  Future<ShareResult> share(ShareParams p) async {
    params = p;
    final file = File(p.files!.single.path);
    content = file.existsSync() ? file.readAsStringSync() : null;
    return const ShareResult('integration-pass', ShareResultStatus.success);
  }
}

final shareStash = _StashingSharePlatform();

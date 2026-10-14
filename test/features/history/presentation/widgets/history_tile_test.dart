import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/history/presentation/widgets/history_tile.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';

/// Charge Roboto (la police Android de l'app) dans le processus de test.
///
/// Sans cela, Flutter rend le texte en Ahem, dont chaque glyphe est un
/// carré de la taille de la police — environ 2× plus large que Roboto. Les
/// tests géométriques (débordement) doivent s'appuyer sur des métriques
/// réelles. Les polices proviennent du cache du SDK Flutter
/// (`bin/cache/artifacts/material_fonts`), le même que l'émulateur Android.
Future<void> _loadRobotoFont() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  const dir = 'bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final name in const ['Roboto-Regular.ttf', 'Roboto-Medium.ttf']) {
    final file = File('$flutterRoot/$dir/$name');
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await loader.load();
}

void main() {
  /// Helper: pump HistoryTile inside a minimal MaterialApp + ProviderScope with FR locale.
  Future<void> pumpTile(WidgetTester tester, TrackingEvent event,
      {VoidCallback? onTap}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: HistoryTile(
              event: event,
              time: '15/06/2024 10:30',
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  group('HistoryTile — Icone par type d\'événement', () {
    testWidgets('FeedingEvent → lunch_dining icon', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural),
      );
      expect(find.byIcon(Icons.lunch_dining), findsOneWidget);
    });

    testWidgets('SleepEvent → nightlight icon', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(
            unit: QuantityUnit.min,
            timestamp: DateTime.utc(2024),
            duration: 30.0),
      );
      expect(find.byIcon(Icons.nightlight), findsOneWidget);
    });

    testWidgets('DiaperEvent pipi → water_drop_outlined icon', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.pipi),
      );
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    });

    testWidgets('DiaperEvent lesDeux → wb_sunny icon', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
            timestamp: DateTime.utc(2024), wasteType: WasteType.lesDeux),
      );
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('DiaperEvent caca → water_drop icon', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.caca),
      );
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('HealthEvent → favorite icon', (tester) async {
      await pumpTile(
        tester,
        HealthEvent(
            timestamp: DateTime.utc(2024),
            subtype: HealthSubtype.nettoyageYeux),
      );
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('HistoryTile — Type label par événement', () {
    testWidgets('FeedingEvent → "Nourriture"', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural),
      );
      expect(find.text('Nourriture'), findsOneWidget);
    });

    testWidgets('SleepEvent → "Sommeil"', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(
            unit: QuantityUnit.min,
            timestamp: DateTime.utc(2024),
            duration: 30.0),
      );
      expect(find.text('Sommeil'), findsOneWidget);
    });

    testWidgets('DiaperEvent pipi → "Pipi"', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.pipi),
      );
      expect(find.text('Pipi'), findsOneWidget);
    });

    testWidgets('DiaperEvent lesDeux → "Pipi & Caca"', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
            timestamp: DateTime.utc(2024), wasteType: WasteType.lesDeux),
      );
      expect(find.text('Pipi & Caca'), findsOneWidget);
    });

    testWidgets('DiaperEvent caca → "Caca"', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.caca),
      );
      expect(find.text('Caca'), findsOneWidget);
    });

    testWidgets('HealthEvent → subtype label', (tester) async {
      await pumpTile(
        tester,
        HealthEvent(
            timestamp: DateTime.utc(2024),
            subtype: HealthSubtype.nettoyageYeux),
      );
      // context.l resolves to FR locale which returns "Nettoyage des yeux" for healthSubtypeNameetyageYeux
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
    });
  });

  group('HistoryTile — Durée affichée', () {
    testWidgets('FeedingEvent sans durée → pas de "Durée" text',
        (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.artificial),
      );
      // Feeding events no longer display duration on history tiles
      expect(find.textContaining('Durée'), findsNothing);
    });

    testWidgets('SleepEvent avec durée → "Durée: X min"', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(
            unit: QuantityUnit.min,
            timestamp: DateTime.utc(2024),
            duration: 180.0),
      );
      expect(find.text('Durée: 180 min'), findsOneWidget);
    });

    testWidgets('DiaperEvent sans durée → pas de "Durée" text', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.pipi),
      );
      expect(find.textContaining('Durée'), findsNothing);
    });

    testWidgets('HealthEvent sans durée → pas de "Durée" text', (tester) async {
      await pumpTile(
        tester,
        HealthEvent(
            timestamp: DateTime.utc(2024), subtype: HealthSubtype.vitamineD),
      );
      expect(find.textContaining('Durée'), findsNothing);
    });
  });

  group('HistoryTile — Unité de quantité (FeedingEvent)', () {
    // Le suffixe suit le sous-type : un purée s'affiche en grammes, un
    // biberon en millilitres — jamais l'inverse.
    testWidgets('aliment solide → quantité en grammes', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.g,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.solid,
            quantity: 40),
      );
      expect(find.text('Quantité : 40 g'), findsOneWidget);
    });

    testWidgets('biberon → quantité en ml', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.artificial,
            quantity: 120),
      );
      expect(find.text('Quantité : 120 ml'), findsOneWidget);
    });
  });

  group('HistoryTile — Notes affichées', () {
    testWidgets('FeedingEvent avec notes → notes visibles (sauf HealthEvent)',
        (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural,
            notes: 'Notes de test'),
      );
      expect(find.text('Notes de test'), findsOneWidget);
    });

    testWidgets('SleepEvent avec notes → notes visibles', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(
            unit: QuantityUnit.min,
            timestamp: DateTime.utc(2024),
            duration: 30.0,
            notes: 'Dodo paisible'),
      );
      expect(find.text('Dodo paisible'), findsOneWidget);
    });

    testWidgets('DiaperEvent avec notes → notes visibles', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
            timestamp: DateTime.utc(2024),
            wasteType: WasteType.pipi,
            notes: 'Bon pipi'),
      );
      expect(find.text('Bon pipi'), findsOneWidget);
    });

    testWidgets('Événement sans notes → pas de texte vide', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural),
      );
      expect(find.text(''), findsNothing);
    });
  });

  group('HistoryTile — Indicateurs de couleur (DiaperEvent)', () {
    testWidgets('pipiColor → indicateur de couleur circulaire', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2024),
          wasteType: WasteType.pipi,
          pipiColor: pipiColorJauneClair,
        ),
      );

      // Color indicator containers (16x16 circles) — also matches CircleAvatar, so expect 2 total
      final colorContainers = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      // At least the one color indicator circle should be present (+ CircleAvatar)
      expect(colorContainers.evaluate().length, greaterThanOrEqualTo(1));
    });

    testWidgets('pipiColor + cacaColor → deux indicateurs', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2024),
          wasteType: WasteType.lesDeux,
          pipiColor: pipiColorJauneClair,
          cacaColor: cacaColorJauneMoutarde,
        ),
      );

      final colorContainers = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      // 2 color indicators + CircleAvatar = at least 3
      expect(colorContainers.evaluate().length, greaterThanOrEqualTo(3));
    });

    testWidgets('DiaperEvent sans couleurs → pas d\'indicateurs',
        (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.caca),
      );
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('FeedingEvent → pas d\'indicateurs de couleur', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.artificial),
      );
      expect(find.byType(Wrap), findsNothing);
    });
  });

  group('HistoryTile — onTap et icône d\'édition', () {
    testWidgets('avec onTap → icône edit_outlined visible', (tester) async {
      bool tapped = false;
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural),
        onTap: () => tapped = true,
      );
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Tap the tile and verify callback fires
      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });

    testWidgets('sans onTap → pas d\'icône edit', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.artificial),
      );
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });

  group('HistoryTile — Timestamp affiché', () {
    testWidgets('time est affiché sur **deux** lignes (date / heure)',
        (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural),
      );
      // Depuis la v1.2.1, la date anglaise reprend les minutes (« 09:32 PM »)
      // : sur la plus petite cible elle tenait plus large que le titre et la
      // ligne débordait de 12 px. On la coupe donc en date (ligne 1) et heure
      // (ligne 2). Le libellé d'une seule ligne n'existe plus.
      expect(find.text('15/06/2024'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('15/06/2024 10:30'), findsNothing);
    });
  });

  group('HistoryTile — Sommeil : une seule ligne de valeur', () {
    // L'app enregistre les minutes de la sieste dans `quantity` ET `duration`
    // (même valeur). La tuile ne doit pas les rendre deux fois (« Quantité : 45 min »
    // + « Durée : 45 min ») : « Durée » est le libellé naturel d'une sieste.
    testWidgets('SleepEvent avec quantité → « Durée » sans « Quantité »',
        (tester) async {
      await pumpTile(
        tester,
        SleepEvent(
            unit: QuantityUnit.min,
            timestamp: DateTime.utc(2024),
            duration: 45.0,
            quantity: 45.0),
      );
      expect(find.text('Durée: 45 min'), findsOneWidget);
      expect(find.textContaining('Quantité'), findsNothing);
    });

    testWidgets('FeedingEvent conserve sa ligne « Quantité »', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural,
            quantity: 120),
      );
      expect(find.text('Quantité : 120 ml'), findsOneWidget);
      expect(find.textContaining('Durée'), findsNothing);
    });
  });

  group('HistoryTile — Pas de débordement (plus petite cible)', () {
    // Small_Phone : 720x1280 px @ 320 dpi = 360x640 dp. C'est sur cette
    // largeur, avec le format anglais le plus large, que la date sur une
    // seule ligne faisait déborder le titre.
    testWidgets('date anglaise avec minutes à 360 dp → aucun overflow',
        (tester) async {
      // Roboto (la police Android de l'app) et non Ahem : Ahem rend chaque
      // glyphe carré (largeur = taille), environ 2× plus large que Roboto,
      // et ferait déborder à 360 dp ce qui tient sur un vrai Small_Phone.
      // Avec la police réelle, ce test reproduit la géométrie de
      // l'appareil : la date sur une seule ligne (v1.2.1) y débordait de
      // ~12 px, les deux lignes non.
      await _loadRobotoFont();
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: const [Locale('en')],
            // Le thème de l'app, en police Roboto (celle de l'appareil).
            // `textTheme`/`primaryTextTheme` sont les thèmes entièrement
            // résolus (styles par défaut compris), donc `.apply` couvre
            // toutes les tailles.
            theme: AppTheme.lightTheme.copyWith(
              textTheme: AppTheme.lightTheme.textTheme
                  .apply(fontFamily: 'Roboto'),
              primaryTextTheme: AppTheme.lightTheme.primaryTextTheme
                  .apply(fontFamily: 'Roboto'),
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: HistoryTile(
                event: FeedingEvent(
                    unit: QuantityUnit.ml,
                    timestamp: DateTime.utc(2026, 10, 13),
                    subtype: FeedingSubtype.natural,
                    quantity: 120),
                // onTap non nul : sur l'écran d'historique réel, la tuile
                // ouvre la dialog d'édition, donc le bloc de fin porte
                // l'icône (et son espacement) comme sur l'appareil.
                time: '10/13/2026 09:32 PM',
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // En mode debug, un débordement de `RenderFlex` est signalé via
      // `FlutterError.reportError`, que le binding de test capture : il est
      // renvoyé par `takeException()` (et fait échouer le test sinon). C'est
      // la garde contre le « RIGHT OVERFLOWED BY 12 PIXELS » vu sur Small_Phone.
      expect(tester.takeException(), isNull,
          reason: 'la tuile déborde sur la plus petite cible (Small_Phone)');
    });
  });

  group('HistoryTile — Tooltip sur couleur', () {
    testWidgets('pipiColor → tooltip avec label de la couleur', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2024),
          wasteType: WasteType.pipi,
          pipiColor: pipiColorJauneClair,
        ),
      );

      // Tooltip widget should be present wrapping the color indicator
      expect(find.byType(Tooltip), findsOneWidget);
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
            home: Scaffold(
              body: HistoryTile(
                event: FeedingEvent(
                    unit: QuantityUnit.ml,
                    timestamp: DateTime.utc(2024),
                    subtype: FeedingSubtype.natural),
                time: '15/06/2024 10:30',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Nourriture'), findsOneWidget);
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
            home: Scaffold(
              body: HistoryTile(
                event: FeedingEvent(
                    unit: QuantityUnit.ml,
                    timestamp: DateTime.utc(2024),
                    subtype: FeedingSubtype.natural),
                time: '15/06/2024 10:30',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Nourriture'), findsOneWidget);
    });

    testWidgets('has Semantics widgets for accessibility', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(
            unit: QuantityUnit.ml,
            timestamp: DateTime.utc(2024),
            subtype: FeedingSubtype.natural),
      );
      expect(find.byType(Semantics), findsWidgets);
    });
  });

  group('HistoryTile — Consistance de la selle', () {
    testWidgets('la texture enregistrée est affichée sur la ligne',
        (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2024),
          wasteType: WasteType.caca,
          stoolTexture: stoolTexturePateuse,
        ),
      );

      expect(find.text('Pâteuse'), findsOneWidget);
    });

    // Les changes notées avant la v9 n'ont pas de texture : la ligne ne doit
    // pas inventer un cran ni afficher une ligne vide.
    testWidgets('aucune ligne de texture pour une couche sans texture',
        (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2024),
          wasteType: WasteType.caca,
          cacaColor: cacaColorJauneMoutarde,
        ),
      );

      expect(find.text('Pâteuse'), findsNothing);
      expect(find.text('Aqueuse'), findsNothing);
      // Les indicateurs de couleur existants restent affichés (une couleur est
      // rendue en pastille + Tooltip, pas en texte).
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('un événement non-couche n\'affiche aucune texture',
        (tester) async {
      await pumpTile(
        tester,
        SleepEvent(
            unit: QuantityUnit.min,
            timestamp: DateTime.utc(2024),
            duration: 45),
      );

      expect(find.text('Moulée'), findsNothing);
    });
  });
}

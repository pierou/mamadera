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

/// Load the Roboto font (the Android font used by the app) during the testing process.
///
/// Otherwise, Flutter renders the text in Ahem, where each glyph is a...
/// font size square — approximately 2 times wider than Roboto. The...
/// Geometric tests (overflow) should be based on metrics.
/// These are real fonts, sourced from the Flutter SDK's repository.
/// (`/`bin/cache/artifacts/material_fonts``), which is the same directory used by the Android emulator.
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
    // The suffix follows the subtype: a puree is displayed in grams, a...
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
      // Since version 1.2.1, the English date format now includes the minutes ("09:32 PM").
      // Regarding the smallest target, it was wider than the title and the...
      // The line was overflowing by 12 pixels. Therefore, it was split into two lines: one for the date (line 1) and one for the time.
      // (line 2). The single-line description no longer exists.
      expect(find.text('15/06/2024'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('15/06/2024 10:30'), findsNothing);
    });
  });

  group('HistoryTile — Sommeil : une seule ligne de valeur', () {
    // The app records the `duration` of the nap in both the `quantity` and "duration" fields.
    // (same value). The tiles should not display the quantity twice ("Quantity: 45 min").
    // + "Duration: 45 minutes"): "Duration" is the natural term used to describe a nap.
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
    // Small_Phone: 720x1280 pixels at 320 dpi = 360x640 dp. This is based on...
    // width, using the widest English format, including the date on...
    // Only one line was causing the title to overflow.
    testWidgets('date anglaise avec minutes à 360 dp → aucun overflow',
        (tester) async {
      // Roboto (the font used in the app, not Ahem): Ahem makes each...
      // Square glyph (width equals height), approximately twice as wide as Roboto.
      // and would overflow at 360 dp, which is the size that fits on a real Small_Phone.
      // Using the actual font, this test replicates the geometry of...
      // The device: the date was displayed on a single line (v1.2.1), causing it to overflow.
      // Approximately 12 pixels, but not for both lines.
      await _loadRobotoFont();
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: const [Locale('en')],
            // The app's theme uses the Roboto font (the default font on the device).
            // `textTheme`/`primaryTextTheme` are complete theme sets.
            // resolved (including default styles), so `.apply` covers everything.
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
                // `onTap` is not null: on the actual history screen, the tile...
                // It opens the editing dialog, so the end block is displayed.
                // The icon (and its spacing) should appear as it does on the device.
                time: '10/13/2026 09:32 PM',
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // In debug mode, a `RenderFlex` overflow is reported via...
      // `FlutterError.reportError`, which is captured by the test binding: it is...
      // thrown by `takeException()` (and causes the test to fail if it is). This is...
      // The issue is related to "RIGHT OVERFLOWED BY 12 PIXELS" which was observed on the Small_Phone device.
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

    // Changes made before version 9 do not have a texture; the line should...
    // Do not insert any blank lines or extra spaces.
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
      // The existing color indicators remain displayed (a color indicates...).
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

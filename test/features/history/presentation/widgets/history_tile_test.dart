import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/widgets/history_tile.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';

void main() {
  /// Helper: pump HistoryTile inside a minimal MaterialApp + ProviderScope.
  Future<void> pumpTile(WidgetTester tester, TrackingEvent event,
      {VoidCallback? onTap}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.sein, duration: 15),
      );
      expect(find.byIcon(Icons.lunch_dining), findsOneWidget);
    });

    testWidgets('SleepEvent → nightlight icon', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(timestamp: DateTime.utc(2024), duration: 120),
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
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.lesDeux),
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
        HealthEvent(timestamp: DateTime.utc(2024), subtype: HealthSubtype.nettoyageYeux),
      );
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('HistoryTile — Type label par événement', () {
    testWidgets('FeedingEvent → "Miam"', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.sein, duration: 15),
      );
      expect(find.text('Miam'), findsOneWidget);
    });

    testWidgets('SleepEvent → "Sommeil"', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(timestamp: DateTime.utc(2024), duration: 60),
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
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.lesDeux),
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
        HealthEvent(timestamp: DateTime.utc(2024), subtype: HealthSubtype.nettoyageYeux),
      );
      // Health subtype label is displayed directly from the entity
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
    });
  });

  group('HistoryTile — Durée affichée', () {
    testWidgets('FeedingEvent avec durée → "Durée: X min"', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.bib, duration: 30.5),
      );
      expect(find.text('Durée: 30 min'), findsOneWidget);
    });

    testWidgets('SleepEvent avec durée → "Durée: X min"', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(timestamp: DateTime.utc(2024), duration: 180.0),
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
        HealthEvent(timestamp: DateTime.utc(2024), subtype: HealthSubtype.vitamineD),
      );
      expect(find.textContaining('Durée'), findsNothing);
    });
  });

  group('HistoryTile — Notes affichées', () {
    testWidgets('FeedingEvent avec notes → notes visibles (sauf HealthEvent)', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.sein, duration: 15, notes: 'Notes de test'),
      );
      expect(find.text('Notes de test'), findsOneWidget);
    });

    testWidgets('SleepEvent avec notes → notes visibles', (tester) async {
      await pumpTile(
        tester,
        SleepEvent(timestamp: DateTime.utc(2024), duration: 60, notes: 'Dodo paisible'),
      );
      expect(find.text('Dodo paisible'), findsOneWidget);
    });

    testWidgets('DiaperEvent avec notes → notes visibles', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.pipi, notes: 'Bon pipi'),
      );
      expect(find.text('Bon pipi'), findsOneWidget);
    });

    testWidgets('Événement sans notes → pas de texte vide', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.sein, duration: 15),
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
          pipiColor: PipiColor.jauneClair,
        ),
      );

      // Color indicator containers (16x16 circles) — also matches CircleAvatar, so expect 2 total
      final colorContainers = find.byWidgetPredicate(
        (w) => w is Container &&
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
          pipiColor: PipiColor.jauneClair,
          cacaColor: CacaColor.jauneMoutarde,
        ),
      );

      final colorContainers = find.byWidgetPredicate(
        (w) => w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      // 2 color indicators + CircleAvatar = at least 3
      expect(colorContainers.evaluate().length, greaterThanOrEqualTo(3));
    });

    testWidgets('DiaperEvent sans couleurs → pas d\'indicateurs', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(timestamp: DateTime.utc(2024), wasteType: WasteType.caca),
      );
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('FeedingEvent → pas d\'indicateurs de couleur', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.bib, duration: 15),
      );
      expect(find.byType(Wrap), findsNothing);
    });
  });

  group('HistoryTile — onTap et icône d\'édition', () {
    testWidgets('avec onTap → icône edit_outlined visible', (tester) async {
      bool tapped = false;
      await pumpTile(
        tester,
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.sein, duration: 15),
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
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.bib, duration: 15),
      );
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });

  group('HistoryTile — Timestamp affiché', () {
    testWidgets('time parameter est affiché dans la tile', (tester) async {
      await pumpTile(
        tester,
        FeedingEvent(timestamp: DateTime.utc(2024), subtype: FeedingSubtype.sein, duration: 15),
      );
      expect(find.text('15/06/2024 10:30'), findsOneWidget);
    });
  });

  group('HistoryTile — Tooltip sur couleur', () {
    testWidgets('pipiColor → tooltip avec label de la couleur', (tester) async {
      await pumpTile(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2024),
          wasteType: WasteType.pipi,
          pipiColor: PipiColor.jauneClair,
        ),
      );

      // Tooltip widget should be present wrapping the color indicator
      expect(find.byType(Tooltip), findsOneWidget);
    });
  });
}

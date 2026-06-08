import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/widgets/history_tile.dart';

void main() {
  group('HistoryTile', () {
    // Helper pour pump un HistoryTile dans un MaterialApp
    Widget buildTile({required String type, required String time, String? notes, double? duration}) {
      return MaterialApp(
        home: Scaffold(
          body: HistoryTile(type: type, time: time, notes: notes, duration: duration),
        ),
      );
    }

    group('Affiche l\'icône correcte par type', () {
      testWidgets('miam → Icons.lunch_dining', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:00'));
        expect(find.byIcon(Icons.lunch_dining), findsOneWidget);
      });

      testWidgets('dodo → Icons.nightlight', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'dodo', time: '22:00'));
        expect(find.byIcon(Icons.nightlight), findsOneWidget);
      });

      testWidgets('caca → Icons.water_drop', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'caca', time: '14:30'));
        expect(find.byIcon(Icons.water_drop), findsOneWidget);
      });

      testWidgets('sante → Icons.favorite', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00'));
        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('type inconnu → Icons.circle', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'inconnu', time: '12:00'));
        expect(find.byIcon(Icons.circle), findsOneWidget);
      });
    });

    group('Affiche le label de type traduit', () {
      testWidgets('miam → "Miam"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:00'));
        expect(find.text('Miam'), findsOneWidget);
      });

      testWidgets('dodo → "Sommeil"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'dodo', time: '22:00'));
        expect(find.text('Sommeil'), findsOneWidget);
      });

      testWidgets('caca → "Caca"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'caca', time: '14:30'));
        expect(find.text('Caca'), findsOneWidget);
      });

      testWidgets('sante sans sous-type → "Santé"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00'));
        expect(find.text('Santé'), findsOneWidget);
      });

      testWidgets('type inconnu → retourne le type brut', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'autre', time: '12:00'));
        expect(find.text('autre'), findsOneWidget);
      });
    });

    group('Affiche la durée si présente', () {
      testWidgets('durée affichée quand non nulle', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'dodo', time: '22:00', duration: 45.7));
        expect(find.text('Durée: 45 min'), findsOneWidget);
      });

      testWidgets('durée non affichée quand nulle', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'dodo', time: '22:00'));
        expect(find.textContaining('Durée'), findsNothing);
      });

      testWidgets('durée arrondie à l\'entier inférieur avec toInt()', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'dodo', time: '22:00', duration: 12.9));
        expect(find.text('Durée: 12 min'), findsOneWidget);
      });
    });

    group('Affiche les notes conditionnellement', () {
      testWidgets('notes affichées pour type non-sante avec notes', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:00', notes: 'Lait maternel'));
        expect(find.text('Lait maternel'), findsOneWidget);
      });

      testWidgets('notes masquées pour type sante (sous-type géré par label)', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'nettoyage_yeux'));
        expect(find.text('Nettoyage des yeux'), findsOneWidget);
        // La note brute ne doit pas apparaître en subtitle
        final subtitles = tester.widgetList<Text>(find.byType(Text)).map((e) => e.data).toList();
        expect(subtitles.contains('nettoyage_yeux'), isFalse);
      });

      testWidgets('notes masquées quand vides', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:00', notes: ''));
        expect(find.textContaining('Lait'), findsNothing);
      });

      testWidgets('notes masquées quand null', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'caca', time: '14:30'));
        final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
        // Seuls le label et l'heure doivent être présents, pas de notes fantômes
        expect(textWidgets.where((t) => t.data == null), isEmpty);
      });

      testWidgets('notes + durée affichées ensemble', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'dodo', time: '22:00', notes: 'Sieste', duration: 30));
        expect(find.text('Durée: 30 min'), findsOneWidget);
        expect(find.text('Sieste'), findsOneWidget);
      });
    });

    group('Gère les sous-types santé', () {
      testWidgets('nettoyage_yeux → "Nettoyage des yeux"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'nettoyage_yeux'));
        expect(find.text('Nettoyage des yeux'), findsOneWidget);
      });

      testWidgets('nettoyage_nombril → "Nettoyage du nombril"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'nettoyage_nombril'));
        expect(find.text('Nettoyage du nombril'), findsOneWidget);
      });

      testWidgets('nettoyage_visage → "Nettoyage du visage"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'nettoyage_visage'));
        expect(find.text('Nettoyage du visage'), findsOneWidget);
      });

      testWidgets('nettoyage_nez → "Nettoyage du nez"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'nettoyage_nez'));
        expect(find.text('Nettoyage du nez'), findsOneWidget);
      });

      testWidgets('vitamine_d → "Vitamine D"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'vitamine_d'));
        expect(find.text('Vitamine D'), findsOneWidget);
      });

      testWidgets('vitamine_k → "Vitamine K"', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'vitamine_k'));
        expect(find.text('Vitamine K'), findsOneWidget);
      });

      testWidgets('sous-type inconnu → affiche la note brute comme label', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'autre_soin'));
        expect(find.text('autre_soin'), findsOneWidget);
      });

      testWidgets('sante avec sous-type et durée → les deux affichés', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'sante', time: '08:00', notes: 'vitamine_d', duration: 5));
        expect(find.text('Vitamine D'), findsOneWidget);
        expect(find.text('Durée: 5 min'), findsOneWidget);
      });
    });

    group('Affiche l\'heure correctement', () {
      testWidgets('l\'heure est affichée en trailing', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:30'));
        expect(find.text('10:30'), findsOneWidget);
      });

      testWidgets('différents formats d\'heure sont préservés', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'dodo', time: '23h45'));
        expect(find.text('23h45'), findsOneWidget);
      });
    });

    group('Structure du widget', () {
      testWidgets('contient un Card wrapper', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:00'));
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('contient un ListTile', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:00'));
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('contient un CircleAvatar pour l\'icône', (WidgetTester tester) async {
        await tester.pumpWidget(buildTile(type: 'miam', time: '10:00'));
        expect(find.byType(CircleAvatar), findsOneWidget);
      });
    });
  });
}

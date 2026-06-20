import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/presentation/widgets/duration_picker_dialog.dart';

void main() {
  group('DurationPickerDialog', () {
    // Helper pour pump le dialog dans un MaterialApp minimal
    Future<void> pumpDialog(WidgetTester tester, DurationPickerDialog dialog) =>
        tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: Scaffold(body: dialog))),
        );

    testWidgets('affiche "30 min" par défaut quand initialMinutes non spécifié', (tester) async {
      final completer = Completer<double>();
      await pumpDialog(tester, DurationPickerDialog(onDurationSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(find.text('Durée du sommeil'), findsOneWidget);
      // 30 min est la valeur par défaut de initialMinutes (widget default param)
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('slider drag met à jour l\'affichage de la durée', (tester) async {
      final completer = Completer<double>();
      await pumpDialog(tester, DurationPickerDialog(onDurationSelected: completer.complete));
      await tester.pumpAndSettle();

      // Slider part de 30 min → affichage initial "30 min"
      expect(find.text('30 min'), findsOneWidget);

      // Drag le slider vers la droite pour augmenter (~60 min)
      final slider = find.byType(Slider);
      await tester.dragFrom(tester.getCenter(slider), const Offset(150, 0));
      await tester.pumpAndSettle();

      // La valeur affichée n'est plus "30 min" (elle a changé suite au drag)
      expect(find.text('30 min'), findsNothing);
    });

    testWidgets('bouton confirmer appelle onDurationSelected avec la valeur courante', (tester) async {
      final completer = Completer<double>();
      await pumpDialog(tester, DurationPickerDialog(onDurationSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(completer.isCompleted, isFalse); // pas encore appelé

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(await completer.future, equals(30.0)); // valeur par défaut du slider
    });

    testWidgets('bouton annuler ne déclenche pas onDurationSelected', (tester) async {
      final completer = Completer<double>();
      await pumpDialog(tester, DurationPickerDialog(onDurationSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(completer.isCompleted, isFalse); // pas encore appelé

      await tester.tap(find.text('Annuler'));
      // Navigator.pop() dans un test sans route → ErrorDialog, on ignore et on vérifie le callback
      try {
        await tester.pumpAndSettle();
      } catch (e) {
        // pop sur une route vide peut lever une exception en contexte de test isolé
      }

      expect(completer.isCompleted, isFalse); // callback jamais appelé
    });

    testWidgets('affiche le format heures:minutes pour des durées > 60 min', (tester) async {
      // initialMinutes à 75 → doit afficher "1h15" et non "75 min"
      await pumpDialog(
        tester,
        DurationPickerDialog(initialMinutes: 75, onDurationSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      // Le format heures:minutes doit être utilisé pour >60 min, pas "75 min"
      expect(find.text('1h15'), findsOneWidget);
      expect(find.text('75 min'), findsNothing);
    });

    testWidgets('initialMinutes custom est respecté au démarrage', (tester) async {
      await pumpDialog(
        tester,
        DurationPickerDialog(initialMinutes: 45, onDurationSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      // 45 min doit être affiché directement (pas "30 min")
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('30 min'), findsNothing);
    });
  });
}

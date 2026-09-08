import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:mamadera/core/widgets/event_date_time_field.dart';
import 'package:mamadera/features/home/presentation/widgets/duration_picker_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Lit la date affichée par le champ de date du dialog (format fr FR : dd/MM/yyyy HH:mm).
DateTime _readFieldDate(WidgetTester tester) {
  final text = tester.widgetList<Text>(
    find.descendant(
      of: find.byType(EventDateTimeField),
      matching: find.byType(Text),
    ),
  ).last.data!;
  return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').parseStrict(text);
}

/// Valide le dialogue de date (ou d'heure) ouvert au-dessus du dialog.
Future<void> _tapOk(WidgetTester tester) async {
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}


void main() {
  group('DurationPickerDialog', () {
    // Helper pour pump le dialog dans un MaterialApp minimal
    Future<void> pumpDialog(WidgetTester tester, DurationPickerDialog dialog) =>
        tester.pumpWidget(
          ProviderScope(child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: dialog),
          )),
        );

    testWidgets('affiche "30 min" par défaut quand initialMinutes non spécifié', (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(tester, DurationPickerDialog(onSleepSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(find.text('Durée du sommeil'), findsOneWidget);
      // 30 min est la valeur par défaut de initialMinutes (widget default param)
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('slider drag met à jour l\'affichage de la durée', (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(tester, DurationPickerDialog(onSleepSelected: completer.complete));
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

    testWidgets('bouton confirmer appelle onSleepSelected avec la valeur courante', (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(tester, DurationPickerDialog(onSleepSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(completer.isCompleted, isFalse); // pas encore appelé

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect((await completer.future).minutes, equals(30.0)); // valeur par défaut du slider
    });

    testWidgets('bouton annuler ne déclenche pas onSleepSelected', (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(tester, DurationPickerDialog(onSleepSelected: completer.complete));
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
        DurationPickerDialog(initialMinutes: 75, onSleepSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      // Le format heures:minutes doit être utilisé pour >60 min, pas "75 min"
      expect(find.text('1h15'), findsOneWidget);
      expect(find.text('75 min'), findsNothing);
    });

    testWidgets('initialMinutes custom est respecté au démarrage', (tester) async {
      await pumpDialog(
        tester,
        DurationPickerDialog(initialMinutes: 45, onSleepSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      // 45 min doit être affiché directement (pas "30 min")
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('30 min'), findsNothing);
    });

    // ── Date de sieste (défaut = instant de saisie moins la durée) ──

    group('date de début de sieste', () {
      testWidgets('le champ de date est affiché', (tester) async {
        await pumpDialog(
          tester,
          DurationPickerDialog(onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EventDateTimeField), findsOneWidget);
      });

      testWidgets('par défaut la date vaut « maintenant - durée »', (tester) async {
        final before = DateTime.now();
        await pumpDialog(
          tester,
          DurationPickerDialog(initialMinutes: 30, onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        final start = _readFieldDate(tester);
        final expected = DateTime.now().subtract(const Duration(minutes: 30));

        // Tolérance d'une minute : l'affichage est arrondi à la minute.
        expect(
          start.difference(expected).inSeconds.abs(),
          lessThan(65),
          reason: 'start=$start attendu≈$expected (fenêtre $before→maintenant)',
        );
      });

      testWidgets('changer la durée décale la date tant qu’elle n’est pas épinglée',
          (tester) async {
        await pumpDialog(
          tester,
          DurationPickerDialog(initialMinutes: 30, onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        final startAt30 = _readFieldDate(tester);

        // Drag le slider vers la droite : la durée augmente (> 30 min).
        await tester.dragFrom(tester.getCenter(find.byType(Slider)), const Offset(150, 0));
        await tester.pumpAndSettle();

        final startLater = _readFieldDate(tester);
        expect(startLater.isBefore(startAt30), isTrue,
            reason: 'une sieste plus longue doit commencer plus tôt');
      });

      testWidgets('une date choisie manuellement ne bouge plus quand la durée change',
          (tester) async {
        await pumpDialog(
          tester,
          DurationPickerDialog(initialMinutes: 30, onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        // Épingler la date : on valide le sélecteur de date puis celui d'heure.
        await tester.tap(find.byType(EventDateTimeField));
        await tester.pumpAndSettle();
        await _tapOk(tester); // jour sélectionné
        await _tapOk(tester); // heure conservée

        final pinned = _readFieldDate(tester);

        await tester.dragFrom(tester.getCenter(find.byType(Slider)), const Offset(150, 0));
        await tester.pumpAndSettle();

        expect(_readFieldDate(tester), equals(pinned),
            reason: 'le choix explicite du parent prime sur la durée');
      });

      testWidgets('confirmer renvoie la date déduite et la durée', (tester) async {
        final completer = Completer<SleepSelection>();
        await pumpDialog(
          tester,
          DurationPickerDialog(initialMinutes: 45, onSleepSelected: completer.complete),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        final result = await completer.future;
        expect(result.minutes, 45.0);
        expect(
          result.start.difference(DateTime.now().subtract(const Duration(minutes: 45))).inSeconds.abs(),
          lessThan(65),
        );
      });
    });
  });
}

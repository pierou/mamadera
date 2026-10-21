import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:mamadera/core/widgets/event_date_time_field.dart';
import 'package:mamadera/features/home/presentation/widgets/duration_picker_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Reads the date displayed in the date field of the dialog box (format: dd/MM/yyyy HH:mm).
DateTime _readFieldDate(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(EventDateTimeField),
          matching: find.byType(Text),
        ),
      )
      .last
      .data!;
  return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').parseStrict(text);
}

/// Validates the date (or time) selection dialog that is currently open above the dialog box.
Future<void> _tapOk(WidgetTester tester) async {
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  group('DurationPickerDialog', () {
    // Helper function to display a dialog within a minimal MaterialApp.
    Future<void> pumpDialog(WidgetTester tester, DurationPickerDialog dialog) =>
        tester.pumpWidget(
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
            home: Scaffold(body: dialog),
          )),
        );

    testWidgets('affiche "30 min" par défaut quand initialMinutes non spécifié',
        (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(
          tester, DurationPickerDialog(onSleepSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(find.text('Durée du sommeil'), findsOneWidget);
      // The default value for "initialMinutes" (a widget default parameter) is 30 minutes.
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('slider drag met à jour l\'affichage de la durée',
        (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(
          tester, DurationPickerDialog(onSleepSelected: completer.complete));
      await tester.pumpAndSettle();

      // Slider part de 30 min → affichage initial "30 min"
      expect(find.text('30 min'), findsOneWidget);

      // Drag the slider to the right to increase the duration (approximately 60 minutes).
      final slider = find.byType(Slider);
      await tester.dragFrom(tester.getCenter(slider), const Offset(150, 0));
      await tester.pumpAndSettle();

      // The displayed value is no longer "30 min" (it has changed after the update).
      expect(find.text('30 min'), findsNothing);
    });

    testWidgets(
        'bouton confirmer appelle onSleepSelected avec la valeur courante',
        (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(
          tester, DurationPickerDialog(onSleepSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(completer.isCompleted, isFalse); // Not yet called.

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect((await completer.future).minutes,
          equals(30.0)); // Default slider value.
    });

    testWidgets('bouton annuler ne déclenche pas onSleepSelected',
        (tester) async {
      final completer = Completer<SleepSelection>();
      await pumpDialog(
          tester, DurationPickerDialog(onSleepSelected: completer.complete));
      await tester.pumpAndSettle();

      expect(completer.isCompleted, isFalse); // Not yet called.

      await tester.tap(find.text('Annuler'));
      // `Navigator.pop()` in a test without a route → `ErrorDialog`, we ignore it and verify the callback.
      try {
        await tester.pumpAndSettle();
      } catch (e) {
        // A "pop" operation on an empty data structure can raise an exception in an isolated testing environment.
      }

      expect(completer.isCompleted, isFalse); // Callback never called.
    });

    testWidgets('affiche le format heures:minutes pour des durées > 60 min',
        (tester) async {
      // initialMinutes set to 75 → should display "1h15" (1 hour 15 minutes) and not "75 min".
      await pumpDialog(
        tester,
        DurationPickerDialog(initialMinutes: 75, onSleepSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      // The format "hours:minutes" should be used for durations greater than 60 minutes, not "75 min."
      expect(find.text('1h15'), findsOneWidget);
      expect(find.text('75 min'), findsNothing);
    });

    testWidgets('initialMinutes custom est respecté au démarrage',
        (tester) async {
      await pumpDialog(
        tester,
        DurationPickerDialog(initialMinutes: 45, onSleepSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      // The duration of 45 minutes must be displayed directly (not "30 minutes").
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('30 min'), findsNothing);
    });

    // ── Nap time (default = current time minus the duration) ──

    group('date de début de sieste', () {
      testWidgets('le champ de date est affiché', (tester) async {
        await pumpDialog(
          tester,
          DurationPickerDialog(onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EventDateTimeField), findsOneWidget);
      });

      testWidgets('par défaut la date vaut « maintenant - durée »',
          (tester) async {
        final before = DateTime.now();
        await pumpDialog(
          tester,
          DurationPickerDialog(initialMinutes: 30, onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        final start = _readFieldDate(tester);
        final expected = DateTime.now().subtract(const Duration(minutes: 30));

        // Tolerance of one minute: the display is rounded to the nearest minute.
        expect(
          start.difference(expected).inSeconds.abs(),
          lessThan(65),
          reason: 'start=$start attendu≈$expected (fenêtre $before→maintenant)',
        );
      });

      testWidgets(
          'changer la durée décale la date tant qu’elle n’est pas épinglée',
          (tester) async {
        await pumpDialog(
          tester,
          DurationPickerDialog(initialMinutes: 30, onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        final startAt30 = _readFieldDate(tester);

        // Drag the slider to the right: the duration will increase (more than 30 minutes).
        await tester.dragFrom(
            tester.getCenter(find.byType(Slider)), const Offset(150, 0));
        await tester.pumpAndSettle();

        final startLater = _readFieldDate(tester);
        expect(startLater.isBefore(startAt30), isTrue,
            reason: 'une sieste plus longue doit commencer plus tôt');
      });

      testWidgets(
          'une date choisie manuellement ne bouge plus quand la durée change',
          (tester) async {
        await pumpDialog(
          tester,
          DurationPickerDialog(initialMinutes: 30, onSleepSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        // Confirm the date: We validate both the date picker and the time selector.
        await tester.tap(find.byType(EventDateTimeField));
        await tester.pumpAndSettle();
        await _tapOk(tester); // Selected date.
        await _tapOk(tester); // Time kept.

        final pinned = _readFieldDate(tester);

        await tester.dragFrom(
            tester.getCenter(find.byType(Slider)), const Offset(150, 0));
        await tester.pumpAndSettle();

        expect(_readFieldDate(tester), equals(pinned),
            reason: 'le choix explicite du parent prime sur la durée');
      });

      testWidgets('confirmer renvoie la date déduite et la durée',
          (tester) async {
        final completer = Completer<SleepSelection>();
        await pumpDialog(
          tester,
          DurationPickerDialog(
              initialMinutes: 45, onSleepSelected: completer.complete),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        final result = await completer.future;
        expect(result.minutes, 45.0);
        expect(
          result.start
              .difference(DateTime.now().subtract(const Duration(minutes: 45)))
              .inSeconds
              .abs(),
          lessThan(65),
        );
      });
    });
  });
}

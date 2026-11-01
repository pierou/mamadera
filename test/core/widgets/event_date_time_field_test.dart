import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/widgets/event_date_time_field.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  DateTime? selected;

  Future<void> pumpField(
    WidgetTester tester, {
    required DateTime value,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
  }) async {
    selected = null;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: EventDateTimeField(
            value: value,
            title: title,
            firstDate: firstDate,
            lastDate: lastDate,
            onChanged: (date) => selected = date,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Tap on the line to open the date/time selector.
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byType(EventDateTimeField));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('EventDateTimeField', () {
    testWidgets('affiche le titre par défaut et la date formatée',
        (tester) async {
      await pumpField(tester, value: DateTime(2026, 3, 14, 8, 5));

      expect(find.text('Date et heure'), findsOneWidget);
      expect(find.text('14/03/2026 08:05'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('le titre personnalisé remplace le titre par défaut',
        (tester) async {
      await pumpField(
        tester,
        value: DateTime(2026, 3, 14, 8, 5),
        title: 'Date de la sieste',
      );

      expect(find.text('Date de la sieste'), findsOneWidget);
      expect(find.text('Date et heure'), findsNothing);
    });

    testWidgets('un tap ouvre le sélecteur de date', (tester) async {
      await pumpField(tester, value: DateTime(2026, 3, 14, 8, 5));

      await openPicker(tester);

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(selected, isNull);
    });

    testWidgets('annuler le sélecteur de date ne notifie pas', (tester) async {
      await pumpField(tester, value: DateTime(2026, 3, 14, 8, 5));

      await openPicker(tester);
      await tapText(tester, 'Annuler');

      expect(selected, isNull);
    });

    testWidgets(
        'choisir un jour puis annuler l’heure garde ce jour et l’heure précédente',
        (tester) async {
      await pumpField(tester, value: DateTime(2026, 3, 14, 8, 5));

      await openPicker(tester);
      await tester.tap(find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('20'),
      ));
      await tester.pumpAndSettle();
      await tapText(tester, 'OK'); // → time selector
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tapText(tester, 'Annuler');

      expect(selected, DateTime(2026, 3, 20, 8, 5));
    });

    testWidgets('valider l’heure notifie le jour choisi avec cette heure',
        (tester) async {
      await pumpField(tester, value: DateTime(2026, 3, 14, 8, 5));

      await openPicker(tester);
      await tester.tap(find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('20'),
      ));
      await tester.pumpAndSettle();
      await tapText(tester, 'OK');

      // The time selector defaults to the current time in the field (08:05):
      // To confirm it, the system must send a notification on the chosen date and time.
      await tapText(tester, 'OK');

      expect(selected, DateTime(2026, 3, 20, 8, 5));
    });

    testWidgets('une valeur hors intervalle ouvre quand même le sélecteur',
        (tester) async {
      // Timestamp earlier than firstDate: If no initial date is set, display the date picker.
      // The assertion fails, and the transaction is not completed.
      await pumpField(
        tester,
        value: DateTime(2000, 1, 1, 6, 0),
        firstDate: DateTime(2026, 1, 1),
        lastDate: DateTime(2026, 12, 31),
      );

      await openPicker(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('la valeur est bornée à lastDate quand elle est dans le futur',
        (tester) async {
      await pumpField(
        tester,
        value: DateTime(2030, 1, 1, 6, 0),
        firstDate: DateTime(2026, 1, 1),
        lastDate: DateTime(2026, 12, 31),
      );

      await openPicker(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/features/reminders/presentation/widgets/reminder_end_picker.dart';

/// The "end at an age" control (B33, D-R5).
///
/// There was no test for this widget at all, which is how it shipped as four
/// identical `− + − +` squares whose only distinction was a Tooltip a touch user
/// never sees. So this file pins the thing whose absence was the defect — that the
/// unit is written on the control — and then pins what the buttons actually do,
/// because "two of the four move twelve" is exactly the kind of surprise a label
/// is supposed to prevent.
void main() {
  final born = DateTime(2026, 1, 15);

  /// Pump the picker with an age-form end of [months], in [locale].
  ///
  /// The picker is a section, not a screen: it needs localizations and nothing
  /// else, which is why it is pumped bare rather than through a screen harness.
  Future<List<int?>> pumpPicker(
    WidgetTester tester, {
    required int months,
    String locale = 'fr',
    DateTime? birthDate,
  }) async {
    final written = <int?>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [Locale('fr'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ReminderEndPicker(
            birthDate: birthDate ?? born,
            endDate: null,
            endAgeMonths: months,
            onChanged: ({DateTime? endDate, int? endAgeMonths}) =>
                written.add(endAgeMonths),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return written;
  }

  /// The row of one unit — label and its two buttons share a `Row`.
  Finder unitRow(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(Row),
      );

  /// The tappable button of one unit and direction. `find.byIcon` matches the
  /// `Icon` inside the button, so reading `onPressed` needs the ancestor.
  Finder stepButton(String unit, IconData icon) => find.ancestor(
        of: find.descendant(of: unitRow(unit), matching: find.byIcon(icon)),
        matching: find.byType(IconButton),
      );

  bool isDisabled(WidgetTester tester, String unit, IconData icon) =>
      tester.widget<IconButton>(stepButton(unit, icon)).onPressed == null;

  group('ReminderEndPicker, the age stepper', () {
    testWidgets('the unit is written on the control, not in a tooltip',
        (tester) async {
      await pumpPicker(tester, months: 30);

      expect(find.text('Années'), findsOneWidget);
      expect(find.text('Mois'), findsOneWidget);
      // "2 years 6 months" of a 30-month end, each value next to its own unit.
      expect(
        find.descendant(
          of: unitRow('Années'),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: unitRow('Mois'), matching: find.text('6')),
        findsOneWidget,
        reason: 'the value sits between the two buttons that move it',
      );
      // One canonical month count leaves the widget (D-R5), and the total stays
      // visible so the two rows can be checked against it.
      expect(find.text('30 mois'), findsOneWidget);
    });

    testWidgets('the English units render, so the labels are real l10n',
        (tester) async {
      await pumpPicker(tester, months: 30, locale: 'en');

      expect(find.text('Years'), findsOneWidget);
      expect(find.text('Months'), findsOneWidget);
    });

    testWidgets('a screen reader gets unit and direction together',
        (tester) async {
      await pumpPicker(tester, months: 30);

      // An IconButton reads its tooltip aloud, so this is the spoken label: a
      // bare "Incrémenter" would leave a blind parent guessing what magnitude.
      expect(find.byTooltip('Années · Incrémenter'), findsOneWidget);
      expect(find.byTooltip('Mois · Incrémenter'), findsOneWidget);
      expect(find.byTooltip('Années · Décrémenter'), findsOneWidget);
      expect(
        find.byTooltip('2y +'),
        findsNothing,
        reason: 'the untranslated English tooltip is what shipped by mistake',
      );
    });

    testWidgets('the years row moves twelve months, the months row one',
        (tester) async {
      final written = await pumpPicker(tester, months: 30);

      await tester.tap(
        find.descendant(
          of: unitRow('Années'),
          matching: find.byIcon(Icons.add_circle_outline),
        ),
      );
      await tester.pumpAndSettle();
      expect(written.last, 42, reason: 'one year, not one month');

      await tester.tap(
        find.descendant(
          of: unitRow('Mois'),
          matching: find.byIcon(Icons.remove_circle_outline),
        ),
      );
      await tester.pumpAndSettle();
      expect(written.last, 29);
    });

    testWidgets('nothing can step below zero or above the ceiling',
        (tester) async {
      await pumpPicker(tester, months: 0);
      expect(
        isDisabled(tester, 'Années', Icons.remove_circle_outline),
        isTrue,
        reason: 'no years to take away at zero',
      );
      expect(isDisabled(tester, 'Mois', Icons.remove_circle_outline), isTrue);

      await pumpPicker(tester, months: 180);
      expect(
        isDisabled(tester, 'Années', Icons.add_circle_outline),
        isTrue,
        reason: '180 months is the stored ceiling (D-R5)',
      );
      expect(isDisabled(tester, 'Mois', Icons.add_circle_outline), isTrue);
    });

    testWidgets('a one-month-old baby is months alone', (tester) async {
      await pumpPicker(tester, months: 1);

      expect(
        find.descendant(of: unitRow('Années'), matching: find.text('0')),
        findsOneWidget,
        reason: 'the years row stays visible at zero rather than disappearing',
      );
      expect(
        find.descendant(of: unitRow('Mois'), matching: find.text('1')),
        findsOneWidget,
      );
      expect(find.text('1 mois'), findsOneWidget);
    });
  });
}

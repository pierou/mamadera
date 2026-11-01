import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';

/// The online quantity selector.
///
/// Why this file didn't exist before but now does: the widget was displaying...
/// `value.round()`, so a temperature entered as `37.5` would be displayed as `38` – in.
/// A health app isn't just a rounding error; it's a false answer – and its...
/// The field was rejecting the comma; `double.tryParse` only recognized the period.
/// A French-speaking parent who types "37.5" sees nothing happen and believes that...
/// It recorded a temperature that the app had never received before.
Widget _host(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

/// Stateful minimal parent: returns the value to the picker, just as a regular parent would.
/// The actual screens (setState) are essential for testing the display after...
/// A single tap and a long press for repetition.
class _EchoPicker extends StatefulWidget {
  const _EchoPicker({required this.initial, this.onChanged});

  final double initial;
  final void Function(double)? onChanged;

  @override
  State<_EchoPicker> createState() => _EchoPickerState();
}

class _EchoPickerState extends State<_EchoPicker> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  void didUpdateWidget(covariant _EchoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A re-pump with a new `initial` state starts from scratch, like a fresh screen.
    // qui rouvre la feuille.
    if (oldWidget.initial != widget.initial) _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return QuantityPickerInline(
      unit: '°C',
      min: 33,
      max: 42,
      divisions: 90,
      decimals: 1,
      step: 0.1,
      value: _value,
      onValueChanged: (value) {
        widget.onChanged?.call(value);
        setState(() => _value = value);
      },
    );
  }
}

void main() {
  group('QuantityPickerInline — décimales', () {
    testWidgets('une température saisie à la virgule est enregistrée',
        (tester) async {
      double? received;
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: '°C',
          min: 33,
          max: 42,
          divisions: 18,
          decimals: 1,
          value: 36.5,
          onValueChanged: (value) => received = value,
        ),
      ));

      await tester.enterText(find.byType(TextField), '37,5');
      await tester.pump();

      // Without the normalization of the comma, the `received` value remains null: the parent.
      // It entered a value that the app silently ignored.
      expect(received, 37.5);
    });

    testWidgets('la valeur se lit avec une virgule en français',
        (tester) async {
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: '°C',
          min: 33,
          max: 42,
          divisions: 18,
          decimals: 1,
          value: 37.5,
          onValueChanged: (_) {},
        ),
      ));

      // On the screen of a French parent, the number `37.5` is displayed as "thirty-seven point".
      // "five": the comma is not just for decoration; it's essential for reading.
      expect(find.text('37,5 °C'), findsWidgets);
      expect(find.text('38 °C'), findsNothing);
    });

    testWidgets('le champ ne réécrit pas ce qui est en cours de saisie',
        (tester) async {
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: '°C',
          min: 33,
          max: 42,
          divisions: 18,
          decimals: 1,
          value: 36.5,
          onValueChanged: (_) {},
        ),
      ));

      final field = find.byType(TextField);
      await tester.enterText(field, '37,5');
      await tester.pump();
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: '°C',
          min: 33,
          max: 42,
          divisions: 18,
          decimals: 1,
          value: 37.5,
          onValueChanged: (_) {},
        ),
      ));
      await tester.pump();

      // The value received (37.5) is already represented by the text entered.
      // (`37,5`): replacing it with `37.5` would break the entry in progress.
      expect(tester.widget<TextField>(field).controller!.text, '37,5');
    });
  });

  group('QuantityPickerInline — millilitres (comportement historique)', () {
    testWidgets('sans décimale, rien ne change : entier au caractère près',
        (tester) async {
      double? received;
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: 'ml',
          min: 0,
          max: 250,
          divisions: 50,
          value: 120,
          onValueChanged: (value) => received = value,
        ),
      ));

      expect(find.text('120 ml'), findsWidgets);

      await tester.enterText(find.byType(TextField), '135');
      await tester.pump();
      expect(received, 135);
    });

    testWidgets('le clavier reste numérique sans décimale', (tester) async {
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: 'ml',
          min: 0,
          max: 250,
          divisions: 50,
          value: 120,
          onValueChanged: (_) {},
        ),
      ));

      final keyboard =
          tester.widget<TextField>(find.byType(TextField)).keyboardType;
      expect(keyboard, TextInputType.number);
    });

    testWidgets('avec décimales, le clavier autorise le séparateur décimal',
        (tester) async {
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: '°C',
          min: 33,
          max: 42,
          divisions: 18,
          decimals: 1,
          value: 36.5,
          onValueChanged: (_) {},
        ),
      ));

      final keyboard =
          tester.widget<TextField>(find.byType(TextField)).keyboardType;
      expect(keyboard, isNotNull);
      expect(keyboard, isNot(TextInputType.number));
    });

    testWidgets('accent par défaut : le vert du biberon', (tester) async {
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: 'ml',
          min: 0,
          max: 250,
          divisions: 50,
          value: 120,
          onValueChanged: (_) {},
        ),
      ));

      final slider = tester.widget<Slider>(find.byType(Slider));
      final theme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(theme.data.thumbColor, AppTheme.miam);
      expect(slider.divisions, 50);
    });
  });

  group('QuantityPickerInline — steppers (+/-)', () {
    Finder addButton() => find.byIcon(Icons.add_circle_outline);
    Finder minusButton() => find.byIcon(Icons.remove_circle_outline);

    testWidgets('tap + increments by step, tap - decrements by step',
        (tester) async {
      await tester.pumpWidget(_host(const _EchoPicker(initial: 37.2)));
      await tester.pumpAndSettle();

      await tester.tap(addButton());
      await tester.pumpAndSettle();
      expect(find.text('37,3 °C'), findsWidgets);

      await tester.tap(minusButton());
      await tester.pumpAndSettle();
      expect(find.text('37,2 °C'), findsWidgets);
    });

    /// The material of the button is [InkResponse], which handles the tap and the...
    /// long press (repetition) and the simulated tap from the screen reader.
    InkResponse controlOf(WidgetTester tester, Finder icon) =>
        tester.widget<InkResponse>(
            find.ancestor(of: icon, matching: find.byType(InkResponse)));

    testWidgets('at the bound the button is disabled and the value is clamped',
        (tester) async {
      await tester.pumpWidget(_host(const _EchoPicker(initial: 42)));
      await tester.pumpAndSettle();

      // Disabled at the terminal: no tap, and no armed repetition. And never masked.
      // The control mechanism must remain active throughout the process; otherwise, the layout will be compromised.
      // jumps at the touch of the parent.
      final atMax = controlOf(tester, addButton());
      expect(atMax.onTap, isNull);
      expect(atMax.onLongPress, isNull);
      expect(addButton(), findsOneWidget);

      expect(controlOf(tester, minusButton()).onTap, isNotNull);
      expect(controlOf(tester, minusButton()).onLongPress, isNotNull,
          reason: 'hors borne, le long-appui doit armer la répétition');

      await tester.pumpWidget(_host(const _EchoPicker(initial: 33)));
      await tester.pumpAndSettle();
      expect(controlOf(tester, minusButton()).onTap, isNull);
      expect(controlOf(tester, minusButton()).onLongPress, isNull);
      expect(controlOf(tester, addButton()).onTap, isNotNull);
    });

    testWidgets(
        'decimals 1: three taps up from 37,2 display 37,5, not 37,500000000000004',
        (tester) async {
      await tester.pumpWidget(_host(const _EchoPicker(initial: 37.2)));
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(addButton());
        await tester.pumpAndSettle();
      }

      // The trap with floating-point numbers: we assert the result of the calculation, not the number itself.
      expect(find.text('37,5 °C'), findsWidgets);
      expect(find.textContaining('00000004'), findsNothing);
    });

    testWidgets('typed value is honoured: enter 37,4, tap +, expect 37,5',
        (tester) async {
      await tester.pumpWidget(_host(const _EchoPicker(initial: 36.5)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '37,4');
      await tester.pumpAndSettle();

      await tester.tap(addButton());
      await tester.pumpAndSettle();
      expect(find.text('37,5 °C'), findsWidgets);
    });

    testWidgets('step == null renders no stepper', (tester) async {
      await tester.pumpWidget(_host(
        QuantityPickerInline(
          unit: 'ml',
          min: 0,
          max: 300,
          divisions: 30,
          value: 120,
          onValueChanged: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets(
        'long-press repeats the increment and the timer is cancelled on dispose',
        (tester) async {
      double? lastReceived;
      await tester.pumpWidget(_host(_EchoPicker(
        initial: 37.2,
        onChanged: (value) => lastReceived = value,
      )));
      await tester.pumpAndSettle();

      // Long press: Activates after a timeout (approximately 500 milliseconds) and repeats every 120 milliseconds.
      final gesture = await tester.startGesture(tester.getCenter(addButton()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();

      // Several notches are required (at least 1 immediate notch, plus approximately 8 repeated notches within 1 second).
      expect(lastReceived, isNotNull);
      expect(lastReceived, greaterThanOrEqualTo(37.5),
          reason: 'la répétition au long-appui doit produire plusieurs crans');

      // Disassembly: An uncancelled timer would trigger an event after being deployed and concealed.
      // an exception (or would leave a pending timer at the end of the test).
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('QuantityPickerInline — un seul curseur', () {
    // The "coarse/fine" dual slider control (BACKLOG B2) has been removed: on...
    // A data entry form with two sliders presents the question: "Which one should I choose?"
    // "move?" without adjusting it, and the stepper motor only learned about the stepper motor itself.
    // and the input field was already active. The cursor is a device that...
    // It aims to cover the entire range; the precision comes from the ± symbol and the keyboard.
    testWidgets('une grande plage garde un slider unique, sans légende',
        (tester) async {
      await tester.pumpWidget(_host(const _EchoPicker(initial: 37)));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Grossier'), findsNothing);
      expect(find.text('Précis'), findsNothing);
    });

    testWidgets('le curseur couvre toute la plage, le ± règle le cran',
        (tester) async {
      await tester.pumpWidget(_host(const _EchoPicker(initial: 37)));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 33, reason: 'borne basse de la température');
      expect(slider.max, 42,
          reason: 'le curseur ne se coupe plus sur une fenêtre');
      expect(slider.divisions, 90);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('37,1 °C'), findsWidgets);
    });
  });
}

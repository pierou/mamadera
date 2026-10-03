import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';

/// Le sélecteur de quantité en ligne.
///
/// Pourquoi ce fichier existait pas et existe maintenant : le widget affichait
/// `value.round()`, donc une température saisie `37,5` s'affichait `38` — dans
/// une app de santé ce n'est pas un arrondi, c'est une réponse fausse — et son
/// champ refusait la virgule, `double.tryParse` ne connaissant que le point.
/// Un parent francophone qui tape `37,5` ne voit rien se passer, et croit avoir
/// enregistré une température que l'app n'a jamais reçue.
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

/// Parent étatful minimal : renvoie la valeur au picker comme le feraient
/// les vrais écrans (setState), indispensable pour tester l'affichage après
/// un tap et la répétition au long-appui.
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
    // Un re-pump avec un nouvel `initial` repart de zéro, comme un écran
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

      // Sans la normalisation de la virgule, `received` reste null : le parent
      // a tapé une valeur que l'app a ignorée en silence.
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

      // `37.5` sur l'écran d'un parent français se lit « trente-sept point
      // cinq » : la virgule n'est pas de la décoration, c'est la lecture.
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

      // La valeur reçue (37.5) est déjà représentée par le texte saisi
      // (« 37,5 ») : le remplacer par « 37.5 » casserait la saisie en cours.
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

    /// Le contrôle Material du bouton : [InkResponse], qui porte le tap, le
    /// long-appui (répétition) et le tap simulé du lecteur d'écran.
    InkResponse controlOf(WidgetTester tester, Finder icon) =>
        tester.widget<InkResponse>(
            find.ancestor(of: icon, matching: find.byType(InkResponse)));

    testWidgets('at the bound the button is disabled and the value is clamped',
        (tester) async {
      await tester.pumpWidget(_host(const _EchoPicker(initial: 42)));
      await tester.pumpAndSettle();

      // Désactivé à la borne : ni tap, ni répétition armée. Et jamais masqué —
      // le contrôle doit rester présent dans l'arbre, sinon la mise en page
      // saute sous le doigt du parent.
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

      // Le piège du flottant : on assert la chaîne rendue, pas le nombre.
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

      // Long-appui : démarre après le timeout (~500 ms), répète toutes les 120 ms.
      final gesture =
          await tester.startGesture(tester.getCenter(addButton()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();

      // Plusieurs crans minimum (1 immédiat + ~8 répétitions sur 1 s).
      expect(lastReceived, isNotNull);
      expect(lastReceived, greaterThanOrEqualTo(37.5),
          reason: 'la répétition au long-appui doit produire plusieurs crans');

      // Démontage : un timer non annulé ferait feu après dispose et cacherait
      // une exception (ou laisserait un timer pending en fin de test).
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}

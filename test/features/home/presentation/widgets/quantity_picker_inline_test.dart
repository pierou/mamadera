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
}

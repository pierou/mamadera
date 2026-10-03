import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';

void main() {
  group('MeasureKind bounds', () {
    test('poids range is 200 to 20000 g, inclusive', () {
      expect(MeasureKind.poids.min, 200);
      expect(MeasureKind.poids.max, 20000);
      expect(MeasureKind.poids.decimals, 0);
    });

    test('taille range is 30 to 110 cm, one decimal', () {
      expect(MeasureKind.taille.min, 30);
      expect(MeasureKind.taille.max, 110);
      expect(MeasureKind.taille.decimals, 1);
    });

    test('temperature range is 33 to 42 degC, one decimal', () {
      expect(MeasureKind.temperature.min, 33);
      expect(MeasureKind.temperature.max, 42);
      expect(MeasureKind.temperature.decimals, 1);
    });

    test('contains is inclusive on both bounds', () {
      for (final kind in MeasureKind.values) {
        expect(kind.contains(kind.min), isTrue, reason: 'min of $kind');
        expect(kind.contains(kind.max), isTrue, reason: 'max of $kind');
      }
    });

    test('one step outside either bound is rejected', () {
      expect(MeasureKind.poids.contains(199), isFalse);
      expect(MeasureKind.poids.contains(20001), isFalse);
      expect(MeasureKind.taille.contains(29.9), isFalse);
      expect(MeasureKind.taille.contains(110.1), isFalse);
      expect(MeasureKind.temperature.contains(32.9), isFalse);
      expect(MeasureKind.temperature.contains(42.1), isFalse);
    });

    test('slider divisions span the whole range at the kind\'s step', () {
      expect(MeasureKind.poids.step, 10);
      expect(MeasureKind.poids.divisions, 1980);
      expect(MeasureKind.taille.step, 1);
      expect(MeasureKind.taille.divisions, 80);
      // Le dixième de degré : un cran de 0,5 ferait enregistrer 37,5 là où le
      // thermomètre affichait 37,4. Dans une app de suivi, une mesure arrondie
      // n'est pas une mesure — c'est une mesure fausse, dans le sens qui peut
      // compter (le seuil de fièvre d'un nourrisson).
      expect(MeasureKind.temperature.step, 0.1);
      expect(MeasureKind.temperature.divisions, 90);
      // Le pas ne franchit jamais la précision affichée : sinon le slider
      // produit des valeurs que l'écran puis la base ne sauraient rendre.
      for (final kind in MeasureKind.values) {
        // `decimals` vaut 0 ou 1 dans cette release : le pas minimal est
        // l'unité ou le dixième, et le slider ne descend jamais sous lui.
        final minStep = kind.decimals == 0 ? 1.0 : 0.1;
        expect(
          kind.step >= minStep,
          isTrue,
          reason: '${kind.dbValue}: pas plus fin que son affichage',
        );
      }
    });
  });

  group('MeasureKind storage values', () {
    test('dbValue matches the measurements.kind column contract', () {
      expect(MeasureKind.poids.dbValue, 'poids');
      expect(MeasureKind.taille.dbValue, 'taille');
      expect(MeasureKind.temperature.dbValue, 'temperature');
    });

    test('unit matches the measurements.unit column contract', () {
      expect(MeasureKind.poids.unit, 'g');
      expect(MeasureKind.taille.unit, 'cm');
      expect(MeasureKind.temperature.unit, 'degC');
    });

    test('displayUnit shows degrees for temperature only', () {
      expect(MeasureKind.poids.displayUnit, 'g');
      expect(MeasureKind.taille.displayUnit, 'cm');
      expect(MeasureKind.temperature.displayUnit, '°C');
    });

    test('byValue translates stored kinds, null for unknown', () {
      expect(MeasureKind.byValue('poids'), MeasureKind.poids);
      expect(MeasureKind.byValue('taille'), MeasureKind.taille);
      expect(MeasureKind.byValue('temperature'), MeasureKind.temperature);
      expect(MeasureKind.byValue('inconnu'), isNull);
      expect(MeasureKind.byValue(null), isNull);
    });
  });

  group('MeasureKind.format', () {
    test('poids above 1000 g is shown in kg with a French decimal comma', () {
      expect(MeasureKind.poids.format(3400, localeName: 'fr'), '3,4 kg');
      expect(MeasureKind.poids.format(20000, localeName: 'fr'), '20 kg');
    });

    test('poids at or below 1000 g stays in integer grams', () {
      expect(MeasureKind.poids.format(1000, localeName: 'fr'), '1000 g');
      expect(MeasureKind.poids.format(200, localeName: 'en'), '200 g');
    });

    test('poids in kg uses the locale decimal separator', () {
      expect(MeasureKind.poids.format(3400, localeName: 'en'), '3.4 kg');
    });

    test('taille keeps one decimal with the locale separator', () {
      expect(MeasureKind.taille.format(50.3, localeName: 'fr'), '50,3 cm');
      expect(MeasureKind.taille.format(50.3, localeName: 'en'), '50.3 cm');
    });

    test('temperature keeps one decimal and a degree symbol', () {
      expect(MeasureKind.temperature.format(36.5, localeName: 'fr'), '36,5 °C');
      expect(MeasureKind.temperature.format(36.5, localeName: 'es'), '36,5 °C');
    });
  });
}

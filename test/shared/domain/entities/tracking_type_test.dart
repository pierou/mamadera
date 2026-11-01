// ignore_for_file: lines_longer_than_80_chars // Tests for readable labels and parsing of TrackingType.

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('TrackingType', () {
    group('.label doit retourner la chaîne lisible pour chaque enum', () {
      test('miam → "Miam"', () {
        expect(TrackingType.miam.label, 'Miam');
      });

      test('sante → "Santé"', () {
        expect(TrackingType.sante.label, 'Santé');
      });

      test('caca → "Caca"', () {
        expect(TrackingType.caca.label, 'Caca');
      });

      test('dodo → "Dodo"', () {
        expect(TrackingType.dodo.label, 'Dodo');
      });
    });

    group('.fromString() doit parser les entrées valides', () {
      test('une entrée minuscule exacte retourne l\'enum correspondant (miam)',
          () {
        expect(TrackingType.fromString('miam'), TrackingType.miam);
      });

      test('une autre entrée valide retourne l\'enum attendu (dodo)', () {
        expect(TrackingType.fromString('dodo'), TrackingType.dodo);
      });
    });

    group('.fromString() doit être insensible à la casse et aux accents', () {
      // The switch statement handles both "health" and "sante" by using `.toLowerCase()`, so it accounts for variations in capitalization.
      // Whether accented, in uppercase, or a combination of both, all characters must be rendered correctly.
      test(
          'SANTÉ, Santé, sante retournent TrackingType.sante ; CACA retourne caca',
          () {
        expect(TrackingType.fromString('SANTÉ'), TrackingType.sante);
        expect(TrackingType.fromString('Santé'), TrackingType.sante);
        expect(TrackingType.fromString('sante'), TrackingType.sante);

        // Also, verify that the case sensitivity setting is correct for another enumeration.
        expect(TrackingType.fromString('CACA'), TrackingType.caca);
      });
    });

    group('.fromString() doit fallback vers miam pour une entrée inconnue', () {
      test('une chaîne non reconnue retourne TrackingType.miam par défaut', () {
        expect(TrackingType.fromString('inconnu'), TrackingType.miam);
      });
    });
  });
}

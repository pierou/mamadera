// ignore_for_file: lines_longer_than_80_chars // Tests des labels lisibles et du parsing de TrackingType

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
      test('une entrée minuscule exacte retourne l\'enum correspondant (miam)', () {
        expect(TrackingType.fromString('miam'), TrackingType.miam);
      });

      test('une autre entrée valide retourne l\'enum attendu (dodo)', () {
        expect(TrackingType.fromString('dodo'), TrackingType.dodo);
      });
    });

    group('.fromString() doit être insensible à la casse et aux accents', () {
      // Le switch gère 'santé' || 'sante' via .toLowerCase(), donc les variantes
      // accentuées, majuscules ou mixtes doivent toutes résoudre correctement.
      test('SANTÉ, Santé, sante retournent TrackingType.sante ; CACA retourne caca', () {
        expect(TrackingType.fromString('SANTÉ'), TrackingType.sante);
        expect(TrackingType.fromString('Santé'), TrackingType.sante);
        expect(TrackingType.fromString('sante'), TrackingType.sante);

        // Vérifie aussi l'insensibilité à la casse sur un autre enum.
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

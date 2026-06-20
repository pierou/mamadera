import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('WasteType.dbValue', () {
    test('pipi → "pipi"', () {
      expect(WasteType.pipi.dbValue, equals('pipi'));
    });

    test('caca → "caca"', () {
      expect(WasteType.caca.dbValue, equals('caca'));
    });

    test('lesDeux → "les_deux"', () {
      expect(WasteType.lesDeux.dbValue, equals('les_deux'));
    });
  });

  group('WasteType.fromDbValue() – valeurs valides', () {
    test('"pipi" → WasteType.pipi', () {
      expect(WasteType.fromDbValue('pipi'), equals(WasteType.pipi));
    });

    test('"caca" → WasteType.caca', () {
      expect(WasteType.fromDbValue('caca'), equals(WasteType.caca));
    });

    // Accepte les variantes "les_deux" et "lesdeux". On teste le cas canonique.
    test('"les_deux" → WasteType.lesDeux', () {
      expect(
        WasteType.fromDbValue('les_deux'),
        equals(WasteType.lesDeux),
      );
    });
  });

  group('WasteType.fromDbValue() – valeurs invalides retournent null', () {
    test('null → null', () {
      expect(WasteType.fromDbValue(null), isNull);
    });

    test('"'' (vide) → null', () {
      expect(WasteType.fromDbValue(''), isNull);
    });

    test('"inconnu" → null', () {
      expect(WasteType.fromDbValue('inconnu'), isNull);
    });
  });

  group('WasteType.fromDbValueOrDefault() – fallback caca', () {
    // Quand la valeur est invalide (null, vide ou inconnue), on retombe sur caca.
    test('valeur nulle → WasteType.caca par défaut', () {
      expect(
        WasteType.fromDbValueOrDefault(null),
        equals(WasteType.caca),
      );
    });

    test('"'' (vide) → WasteType.caca par défaut', () {
      expect(
        WasteType.fromDbValueOrDefault(''),
        equals(WasteType.caca),
      );
    });

    test('valeur inconnue → WasteType.caca par défaut', () {
      expect(
        WasteType.fromDbValueOrDefault('bidule'),
        equals(WasteType.caca),
      );
    });

    // Vérifie aussi que les valeurs valides ne sont pas écrasées.
    test('"pipi" → WasteType.pipi (pas écrasé par le fallback)', () {
      expect(
        WasteType.fromDbValueOrDefault('pipi'),
        equals(WasteType.pipi),
      );
    });

    test('"les_deux" → WasteType.lesDeux (pas écrasé par le fallback)', () {
      expect(
        WasteType.fromDbValueOrDefault('les_deux'),
        equals(WasteType.lesDeux),
      );
    });
  });

  group('WasteType – round-trip dbValue → fromDbValue', () {
    // Vérifie que chaque enum passe par la DB et revient intact.
    test('pipi → "pipi" → pipi', () {
      expect(
        WasteType.fromDbValue(WasteType.pipi.dbValue),
        equals(WasteType.pipi),
      );
    });

    test('caca → "caca" → caca', () {
      expect(
        WasteType.fromDbValue(WasteType.caca.dbValue),
        equals(WasteType.caca),
      );
    });

    test('lesDeux → "les_deux" → lesDeux', () {
      expect(
        WasteType.fromDbValue(WasteType.lesDeux.dbValue),
        equals(WasteType.lesDeux),
      );
    });
  });

  group('WasteType.fromDbValue() – insensible à la casse', () {
    test('"PIPI" → WasteType.pipi (majuscules)', () {
      expect(WasteType.fromDbValue('PIPI'), equals(WasteType.pipi));
    });

    test('"CACA" → WasteType.caca (majuscules)', () {
      expect(WasteType.fromDbValue('CACA'), equals(WasteType.caca));
    });
  });
}

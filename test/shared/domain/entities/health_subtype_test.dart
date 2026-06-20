// Tests de l'entité HealthSubtype.
// Couverture :
// - byValue() retourne le bon subtype pour chaque valeur connue (6)
// - byValue() retourne null pour une valeur inconnue (1)
// - .values contient exactement 6 éléments (1)

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('HealthSubtype', () {
    // ── byValue() retourne le bon subtype pour chaque valeur connue ────
    test("byValue('nettoyage_yeux') → nettoyageYeux", () {
      expect(
        HealthSubtype.byValue('nettoyage_yeux'),
        equals(HealthSubtype.nettoyageYeux),
      );
    });

    test("byValue('nettoyage_nombril') → nettoyageNombril", () {
      expect(
        HealthSubtype.byValue('nettoyage_nombril'),
        equals(HealthSubtype.nettoyageNombril),
      );
    });

    test("byValue('nettoyage_visage') → nettoyageVisage", () {
      expect(
        HealthSubtype.byValue('nettoyage_visage'),
        equals(HealthSubtype.nettoyageVisage),
      );
    });

    test("byValue('nettoyage_nez') → nettoyageNez", () {
      expect(
        HealthSubtype.byValue('nettoyage_nez'),
        equals(HealthSubtype.nettoyageNez),
      );
    });

    test("byValue('vitamine_d') → vitamineD", () {
      expect(
        HealthSubtype.byValue('vitamine_d'),
        equals(HealthSubtype.vitamineD),
      );
    });

    test("byValue('vitamine_k') → vitamineK", () {
      expect(
        HealthSubtype.byValue('vitamine_k'),
        equals(HealthSubtype.vitamineK),
      );
    });

    // ── byValue() retourne null pour une valeur inconnue ────────────────
    test("byValue('inconnu') → null", () {
      expect(HealthSubtype.byValue('inconnu'), isNull);
    });

    // ── .values contient exactement 6 éléments ──────────────────────────
    test('.values.length == 6', () {
      expect(HealthSubtype.values.length, equals(6));
    });
  });
}

// Tests for the HealthSubtype entity.
// Couverture :
// - `byValue()` returns the correct subtype for each known value (6).
// - `byValue()` returns null for an unknown value (1).
// - The `.values` attribute contains exactly 6 elements (1).

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('HealthSubtype', () {
    // ── `byValue()` returns the correct subtype for each known value. ────
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

    // ── `byValue()` returns null for an unknown value.
    test("byValue('inconnu') → null", () {
      expect(HealthSubtype.byValue('inconnu'), isNull);
    });

    // -- .values contains exactly 6 elements ──────────────────────────
    test('.values.length == 6', () {
      expect(HealthSubtype.values.length, equals(6));
    });
  });
}

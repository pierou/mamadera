/// Tests de l'entité CacaColor.
/// Couverture :
/// - byValue() retourne la bonne instance pour chaque valeur DB connue (4)
/// - byValue() retourne null pour null, vide et inconnu (1 combiné)
/// - fromDbValue() retourne la bonne instance pour les valeurs connues (4)
/// - fromDbValue() fallback sur jauneMoutarde pour null, vide et inconnu (1 combiné)
/// - .values contient exactement 4 éléments (1)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('CacaColor', () {
    // ── byValue() retourne la bonne instance pour chaque valeur connue ────
    test("byValue('meconium') → CacaColor.meconium", () {
      expect(CacaColor.byValue('meconium'), equals(CacaColor.meconium));
    });

    test("byValue('vert_olive') → CacaColor.vertOlive", () {
      expect(CacaColor.byValue('vert_olive'), equals(CacaColor.vertOlive));
    });

    test("byValue('jaune_moutarde') → CacaColor.jauneMoutarde", () {
      expect(
        CacaColor.byValue('jaune_moutarde'),
        equals(CacaColor.jauneMoutarde),
      );
    });

    test("byValue('jaune_clair') → CacaColor.jauneClair", () {
      expect(CacaColor.byValue('jaune_clair'), equals(CacaColor.jauneClair));
    });

    // ── byValue() retourne null pour les entrées invalides ────────────────
    test("byValue(null/''/'inconnu') → null", () {
      expect(CacaColor.byValue(null), isNull);
      expect(CacaColor.byValue(''), isNull);
      expect(CacaColor.byValue('inconnu'), isNull);
    });

    // ── fromDbValue() retourne la bonne instance pour les valeurs connues ──
    test("fromDbValue('meconium') → CacaColor.meconium", () {
      expect(
        CacaColor.fromDbValue('meconium'),
        equals(CacaColor.meconium),
      );
    });

    test("fromDbValue('vert_olive') → CacaColor.vertOlive", () {
      expect(
        CacaColor.fromDbValue('vert_olive'),
        equals(CacaColor.vertOlive),
      );
    });

    // ── fromDbValue() fallback sur [jauneMoutarde] pour les entrées invalides ──
    test("fromDbValue(null/''/'inconnu') → CacaColor.jauneMoutarde", () {
      expect(
        CacaColor.fromDbValue(null),
        equals(CacaColor.jauneMoutarde),
      );
      expect(
        CacaColor.fromDbValue(''),
        equals(CacaColor.jauneMoutarde),
      );
      expect(
        CacaColor.fromDbValue('inconnu'),
        equals(CacaColor.jauneMoutarde),
      );
    });

    // ── .values contient exactement 4 éléments ────────────────────────────
    test('.values.length == 4', () {
      expect(CacaColor.values.length, equals(4));
    });
  });
}

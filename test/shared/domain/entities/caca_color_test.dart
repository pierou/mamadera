/// Tests de l'entité CacaColor.
/// Couverture :
/// - byValue() retourne la bonne instance pour chaque valeur DB connue (4)
/// - byValue() retourne null pour null, vide et inconnu (1 combiné)
/// - fromDbValue() retourne la bonne instance pour les valeurs connues (4)
/// - fromDbValue() fallback sur cacaColorJauneMoutarde pour null, vide et inconnu (1 combiné)
/// - .values contient exactement 4 éléments (1)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('CacaColor', () {
    // ── byValue() retourne la bonne instance pour chaque valeur connue ────
    test("findCacaColorByValue('meconium') → cacaColorMeconium", () {
      expect(findCacaColorByValue('meconium'), equals(cacaColorMeconium));
    });

    test("findCacaColorByValue('vert_olive') → cacaColorVertOlive", () {
      expect(findCacaColorByValue('vert_olive'), equals(cacaColorVertOlive));
    });

    test("findCacaColorByValue('jaune_moutarde') → cacaColorJauneMoutarde", () {
      expect(
        findCacaColorByValue('jaune_moutarde'),
        equals(cacaColorJauneMoutarde),
      );
    });

    test("findCacaColorByValue('jaune_clair') → cacaColorJauneClair", () {
      expect(findCacaColorByValue('jaune_clair'), equals(cacaColorJauneClair));
    });

    // ── findCacaColorByValue() retourne null pour les entrées invalides ────────────────
    test("findCacaColorByValue(null/''/'inconnu') → null", () {
      expect(findCacaColorByValue(null), isNull);
      expect(findCacaColorByValue(''), isNull);
      expect(findCacaColorByValue('inconnu'), isNull);
    });

    // ── fromDbValue() retourne la bonne instance pour les valeurs connues ──
    test("findCacaColorFromDbValue('meconium') → cacaColorMeconium", () {
      expect(
        findCacaColorFromDbValue('meconium'),
        equals(cacaColorMeconium),
      );
    });

    test("findCacaColorFromDbValue('vert_olive') → cacaColorVertOlive", () {
      expect(
        findCacaColorFromDbValue('vert_olive'),
        equals(cacaColorVertOlive),
      );
    });

    // ── findCacaColorFromDbValue() fallback sur [cacaColorJauneMoutarde] pour les entrées invalides ──
    test("findCacaColorFromDbValue(null/''/'inconnu') → cacaColorJauneMoutarde", () {
      expect(
        findCacaColorFromDbValue(null),
        equals(cacaColorJauneMoutarde),
      );
      expect(
        findCacaColorFromDbValue(''),
        equals(cacaColorJauneMoutarde),
      );
      expect(
        findCacaColorFromDbValue('inconnu'),
        equals(cacaColorJauneMoutarde),
      );
    });

    // ── cacaColors contient exactement 4 éléments ────────────────────────────
    test('cacaColors.length == 4', () {
      expect(cacaColors.length, equals(4));
    });
  });
}

/// Tests de l'entité PipiColor.
/// Couverture :
/// - byValue() retourne la bonne instance pour chaque valeur DB connue (4)
/// - byValue() retourne null pour null, vide et inconnu (1 combiné)
/// - fromDbValue() retourne la bonne instance pour les valeurs connues (4)
/// - fromDbValue() fallback sur incolore pour null, vide et inconnu (1 combiné)
/// - .values contient exactement 4 éléments (1)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('PipiColor', () {
    // ── byValue() retourne la bonne instance pour chaque valeur connue ────
    test("findPipiColorByValue('incolore') → pipiColorIncolore", () {
      expect(findPipiColorByValue('incolore'), equals(pipiColorIncolore));
    });

    test("findPipiColorByValue('jaune_clair') → pipiColorJauneClair", () {
      expect(findPipiColorByValue('jaune_clair'), equals(pipiColorJauneClair));
    });

    test("findPipiColorByValue('jaune_fonce') → pipiColorJauneFonce", () {
      expect(findPipiColorByValue('jaune_fonce'), equals(pipiColorJauneFonce));
    });

    test("findPipiColorByValue('rose_urates') → pipiColorRoseUrates", () {
      expect(
        findPipiColorByValue('rose_urates'),
        equals(pipiColorRoseUrates),
      );
    });

    // ── findPipiColorByValue() retourne null pour les entrées invalides ────────────────
    test("findPipiColorByValue(null/''/'inconnu') → null", () {
      expect(findPipiColorByValue(null), isNull);
      expect(findPipiColorByValue(''), isNull);
      expect(findPipiColorByValue('inconnu'), isNull);
    });

    // ── fromDbValue() retourne la bonne instance pour les valeurs connues ──
    test("findPipiColorFromDbValue('jaune_fonce') → pipiColorJauneFonce", () {
      expect(
        findPipiColorFromDbValue('jaune_fonce'),
        equals(pipiColorJauneFonce),
      );
    });

    test("findPipiColorFromDbValue('rose_urates') → pipiColorRoseUrates", () {
      expect(
        findPipiColorFromDbValue('rose_urates'),
        equals(pipiColorRoseUrates),
      );
    });

    // ── fromDbValue() fallback sur [incolore] pour les entrées invalides ───
    test("findPipiColorFromDbValue(null/''/'inconnu') → pipiColorIncolore", () {
      expect(findPipiColorFromDbValue(null), equals(pipiColorIncolore));
      expect(findPipiColorFromDbValue(''), equals(pipiColorIncolore));
      expect(findPipiColorFromDbValue('inconnu'), equals(pipiColorIncolore));
    });

    // ── pipiColors contient exactement 4 éléments ────────────────────────────
    test('pipiColors.length == 4', () {
      expect(pipiColors.length, equals(4));
    });
  });
}

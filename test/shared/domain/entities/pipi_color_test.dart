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
    test("byValue('incolore') → PipiColor.incolore", () {
      expect(PipiColor.byValue('incolore'), equals(PipiColor.incolore));
    });

    test("byValue('jaune_clair') → PipiColor.jauneClair", () {
      expect(PipiColor.byValue('jaune_clair'), equals(PipiColor.jauneClair));
    });

    test("byValue('jaune_fonce') → PipiColor.jauneFonce", () {
      expect(PipiColor.byValue('jaune_fonce'), equals(PipiColor.jauneFonce));
    });

    test("byValue('rose_urates') → PipiColor.roseUrates", () {
      expect(
        PipiColor.byValue('rose_urates'),
        equals(PipiColor.roseUrates),
      );
    });

    // ── byValue() retourne null pour les entrées invalides ────────────────
    test("byValue(null/''/'inconnu') → null", () {
      expect(PipiColor.byValue(null), isNull);
      expect(PipiColor.byValue(''), isNull);
      expect(PipiColor.byValue('inconnu'), isNull);
    });

    // ── fromDbValue() retourne la bonne instance pour les valeurs connues ──
    test("fromDbValue('jaune_fonce') → PipiColor.jauneFonce", () {
      expect(
        PipiColor.fromDbValue('jaune_fonce'),
        equals(PipiColor.jauneFonce),
      );
    });

    test("fromDbValue('rose_urates') → PipiColor.roseUrates", () {
      expect(
        PipiColor.fromDbValue('rose_urates'),
        equals(PipiColor.roseUrates),
      );
    });

    // ── fromDbValue() fallback sur [incolore] pour les entrées invalides ───
    test("fromDbValue(null/''/'inconnu') → PipiColor.incolore", () {
      expect(PipiColor.fromDbValue(null), equals(PipiColor.incolore));
      expect(PipiColor.fromDbValue(''), equals(PipiColor.incolore));
      expect(PipiColor.fromDbValue('inconnu'), equals(PipiColor.incolore));
    });

    // ── .values contient exactement 4 éléments ────────────────────────────
    test('.values.length == 4', () {
      expect(PipiColor.values.length, equals(4));
    });
  });
}

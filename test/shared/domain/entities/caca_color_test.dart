/// Testing of the CacaColor entity.
/// Couverture :
/// - `byValue()` returns the correct instance for each known database value (4).
/// - `byValue()` returns null for null, empty, and unknown values (1 combination).
/// - `fromDbValue()` returns the correct instance for known values (4).
/// - `fromDbValue()` falls back to `cacaColorJauneMoutarde` for null, empty, and unknown values (1 combination).
/// - The `.values` attribute contains exactly 4 elements (1).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('CacaColor', () {
    // ── `byValue()` returns the correct instance for each known value. ────
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

    // ── `findCacaColorByValue()` returns null for invalid inputs.
    test("findCacaColorByValue(null/''/'inconnu') → null", () {
      expect(findCacaColorByValue(null), isNull);
      expect(findCacaColorByValue(''), isNull);
      expect(findCacaColorByValue('inconnu'), isNull);
    });

    // ── `fromDbValue()` returns the correct instance for known values.
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

    // ── The `findCacaColorFromDbValue()` function defaults to "[cacaColorJauneMoutarde]" for invalid entries. ──
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

    // ── cacaColors contains exactly 4 elements. ────────────────────────────
    test('cacaColors.length == 4', () {
      expect(cacaColors.length, equals(4));
    });
  });
}

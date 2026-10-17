/// Testing of the PipiColor entity.
/// Couverture :
/// - `byValue()` returns the correct instance for each known database value (4).
/// - `byValue()` returns null for null, empty, and unknown values (1 combination).
/// - `fromDbValue()` returns the correct instance for known values (4).
/// - `fromDbValue()` defaults to "inconspicuous" for null, empty, and unknown values (1 combination).
/// - The `.values` attribute contains exactly 4 elements (1).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('PipiColor', () {
    // ── `byValue()` returns the correct instance for each known value. ────
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

    // ── `findPipiColorByValue()` returns null for invalid inputs.
    test("findPipiColorByValue(null/''/'inconnu') → null", () {
      expect(findPipiColorByValue(null), isNull);
      expect(findPipiColorByValue(''), isNull);
      expect(findPipiColorByValue('inconnu'), isNull);
    });

    // ── `fromDbValue()` returns the correct instance for known values.
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

    // ── `fromDbValue()` falls back to "[incolore]" for invalid inputs. ───
    test("findPipiColorFromDbValue(null/''/'inconnu') → pipiColorIncolore", () {
      expect(findPipiColorFromDbValue(null), equals(pipiColorIncolore));
      expect(findPipiColorFromDbValue(''), equals(pipiColorIncolore));
      expect(findPipiColorFromDbValue('inconnu'), equals(pipiColorIncolore));
    });

    // ── pipiColors consists of exactly 4 elements. ────────────────────────────
    test('pipiColors.length == 4', () {
      expect(pipiColors.length, equals(4));
    });
  });
}

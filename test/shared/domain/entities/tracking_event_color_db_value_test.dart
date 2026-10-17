// ignore_for_file: lines_longer_than_80_chars // Tests du getter colorDbValue de DiaperEvent

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';

void main() {
  group('DiaperEvent.colorDbValue', () {
    final baseTimestamp = DateTime.utc(2023, 10, 25);

    // ── pipi → returns `pipiColor.value` (or null if not selected) ───
    test('wasteType=pipi avec pipiColor sélectionnée → pipiColor.value', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        wasteType: WasteType.pipi,
        pipiColor:
        pipiColorJauneClair,
      );

      expect(event.colorDbValue, equals('jaune_clair'));
    });

    test('wasteType=pipi sans pipiColor → null', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        wasteType: WasteType.pipi,
      );

      expect(event.colorDbValue, isNull);
    });

    // ── caca → returns `cacaColor.value` (or `null` if not selected) ───
    test('wasteType=caca avec cacaColor sélectionnée → cacaColor.value', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        wasteType: WasteType.caca,
        cacaColor:
        cacaColorVertOlive,
      );

      expect(event.colorDbValue, equals('vert_olive'));
    });

    test('wasteType=caca sans cacaColor → null', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        wasteType: WasteType.caca,
      );

      expect(event.colorDbValue, isNull);
    });

    // ── lesDeux → pipe-delimited format or fallback to single-value.
    test('wasteType=lesDeux avec pipiColor et cacaColor → "pipi|caca"', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        wasteType: WasteType.lesDeux,
        pipiColor:
        pipiColorIncolore,
        cacaColor:
        cacaColorJauneMoutarde,
      );

      expect(event.colorDbValue, equals('incolore|jaune_moutarde'));
    });

    test('wasteType=lesDeux avec pipiColor seulement → pipiColor.value', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        wasteType: WasteType.lesDeux,
        pipiColor:
        pipiColorJauneFonce,
      );

      expect(event.colorDbValue, equals('jaune_fonce'));
    });

    test('wasteType=lesDeux avec cacaColor seulement → cacaColor.value', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        wasteType: WasteType.lesDeux,
        cacaColor:
        cacaColorMeconium,
      );

      expect(event.colorDbValue, equals('meconium'));
    });

    // ── wasteType is always null, regardless of the colors.
    test('wasteType=null (même avec des couleurs) → null', () {
      final event = DiaperEvent(
        timestamp: baseTimestamp,
        pipiColor:
        pipiColorRoseUrates,
        cacaColor: cacaColorJauneClair,
      );

      expect(event.colorDbValue, isNull);
    });
  });
}

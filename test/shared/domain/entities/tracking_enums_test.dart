// ignore_for_file: lines_longer_than_80_chars // Tests for tracking enums (FeedingSubtype, WasteType, HealthSubtype, CacaColor, PipiColor)

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('FeedingSubtype', () {
    test('has 2 values', () {
      expect(FeedingSubtype.values.length, equals(2));
    });

    test('natural name is correct', () {
      expect(FeedingSubtype.natural.name, equals('natural'));
    });

    test('artificial name is correct', () {
      expect(FeedingSubtype.artificial.name, equals('artificial'));
    });

    test('dbValue returns correct values', () {
      expect(FeedingSubtype.natural.dbValue, equals('natural'));
      expect(FeedingSubtype.artificial.dbValue, equals('artificial'));
    });

    test('fromDbValue returns correct enum for new values', () {
      expect(FeedingSubtype.fromDbValue('natural'), equals(FeedingSubtype.natural));
      expect(FeedingSubtype.fromDbValue('artificial'), equals(FeedingSubtype.artificial));
    });

    test('fromDbValue returns correct enum for legacy values', () {
      expect(FeedingSubtype.fromDbValue('sein'), equals(FeedingSubtype.natural));
      expect(FeedingSubtype.fromDbValue('bib'), equals(FeedingSubtype.artificial));
    });

    test('fromDbValue returns null for null input', () {
      expect(FeedingSubtype.fromDbValue(null), isNull);
    });

    test('fromDbValue returns null for empty string', () {
      expect(FeedingSubtype.fromDbValue(''), isNull);
    });

    test('fromDbValue returns null for unknown value', () {
      expect(FeedingSubtype.fromDbValue('unknown'), isNull);
    });
  });

  group('WasteType', () {
    test('has 3 values', () {
      expect(WasteType.values.length, equals(3));
    });

    test('dbValue returns correct values', () {
      expect(WasteType.pipi.dbValue, equals('pipi'));
      expect(WasteType.caca.dbValue, equals('caca'));
      expect(WasteType.lesDeux.dbValue, equals('les_deux'));
    });

    test('fromDbValue returns correct enum for valid values', () {
      expect(WasteType.fromDbValue('pipi'), equals(WasteType.pipi));
      expect(WasteType.fromDbValue('caca'), equals(WasteType.caca));
      expect(WasteType.fromDbValue('les_deux'), equals(WasteType.lesDeux));
      expect(WasteType.fromDbValue('lesdeux'), equals(WasteType.lesDeux));
    });

    test('fromDbValue returns null for null input', () {
      expect(WasteType.fromDbValue(null), isNull);
    });

    test('fromDbValue returns null for empty string', () {
      expect(WasteType.fromDbValue(''), isNull);
    });

    test('fromDbValue returns null for unknown value', () {
      expect(WasteType.fromDbValue('unknown'), isNull);
    });

    test('fromDbValue is case-insensitive', () {
      expect(WasteType.fromDbValue('PIPİ'), equals(WasteType.pipi));
      expect(WasteType.fromDbValue('CACA'), equals(WasteType.caca));
      expect(WasteType.fromDbValue('LES_DEUX'), equals(WasteType.lesDeux));
    });

    test('fromDbValueOrDefault returns default for null', () {
      expect(WasteType.fromDbValueOrDefault(null), equals(WasteType.caca));
    });

    test('fromDbValueOrDefault returns default for empty string', () {
      expect(WasteType.fromDbValueOrDefault(''), equals(WasteType.caca));
    });

    test('fromDbValueOrDefault returns default for unknown value', () {
      expect(WasteType.fromDbValueOrDefault('unknown'), equals(WasteType.caca));
    });

    test('fromDbValueOrDefault returns correct value for valid input', () {
      expect(WasteType.fromDbValueOrDefault('pipi'), equals(WasteType.pipi));
      expect(WasteType.fromDbValueOrDefault('caca'), equals(WasteType.caca));
      expect(WasteType.fromDbValueOrDefault('les_deux'), equals(WasteType.lesDeux));
    });
  });

  group('HealthSubtype', () {
    test('has correct number of values', () {
      expect(HealthSubtype.values.length, greaterThan(0));
    });

    test('byValue returns correct enum for valid values', () {
      expect(HealthSubtype.byValue('nettoyage_yeux'), equals(HealthSubtype.nettoyageYeux));
      expect(HealthSubtype.byValue('nettoyage_nez'), equals(HealthSubtype.nettoyageNez));
    });

    test('byValue returns null for unknown value', () {
      expect(HealthSubtype.byValue('unknown'), isNull);
    });
  });

  group('CacaColor', () {
    test('const instances have correct properties', () {
      expect(cacaColorMeconium.value, equals('meconium'));
      expect(cacaColorMeconium.label, equals('Mécônium'));

      expect(cacaColorVertOlive.value, equals('vert_olive'));
      expect(cacaColorVertOlive.label, equals('Vert olive'));

      expect(cacaColorJauneMoutarde.value, equals('jaune_moutarde'));
      expect(cacaColorJauneMoutarde.label, equals('Jaune moutarde'));

      expect(cacaColorJauneClair.value, equals('jaune_clair'));
      expect(cacaColorJauneClair.label, equals('Jaune clair'));
    });
  });

  group('PipiColor', () {
    test('const instances have correct properties', () {
      expect(pipiColorIncolore.value, equals('incolore'));
      expect(pipiColorIncolore.label, equals('Incolore'));

      expect(pipiColorJauneClair.value, equals('jaune_clair'));
      expect(pipiColorJauneClair.label, equals('Jaune clair'));

      expect(pipiColorJauneFonce.value, equals('jaune_fonce'));
      expect(pipiColorJauneFonce.label, equals('Jaune foncé'));

      expect(pipiColorRoseUrates.value, equals('rose_urates'));
      expect(pipiColorRoseUrates.label, equals('Rose/Orange (urates)'));
    });

    test('pipiColors list contains all 4 colors', () {
      expect(pipiColors.length, equals(4));
      expect(pipiColors, contains(pipiColorIncolore));
      expect(pipiColors, contains(pipiColorJauneClair));
      expect(pipiColors, contains(pipiColorJauneFonce));
      expect(pipiColors, contains(pipiColorRoseUrates));
    });

    test('findPipiColorByValue returns correct color', () {
      expect(findPipiColorByValue('incolore'), equals(pipiColorIncolore));
      expect(findPipiColorByValue('jaune_clair'), equals(pipiColorJauneClair));
      expect(findPipiColorByValue('jaune_fonce'), equals(pipiColorJauneFonce));
      expect(findPipiColorByValue('rose_urates'), equals(pipiColorRoseUrates));
    });

    test('findPipiColorByValue returns null for null/empty/unknown', () {
      expect(findPipiColorByValue(null), isNull);
      expect(findPipiColorByValue(''), isNull);
      expect(findPipiColorByValue('unknown'), isNull);
    });
  });
}

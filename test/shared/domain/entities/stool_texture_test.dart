/// Tests de StoolTexture et du getter textureDbValue de DiaperEvent.
/// Couverture :
/// - findStoolTextureByValue() : les 5 valeurs DB connues (5)
/// - findStoolTextureByValue() : null, vide, inconnu → null, sans fallback (1)
/// - stoolTextures : 5 valeurs, consistance croissante, valeurs ASCII (3)
/// - textureDbValue : caca / les_deux → valeur, pipi / type absent → null (5)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';

void main() {
  group('StoolTexture', () {
    // ── lookup des valeurs DB connues ─────────────────────────────────────
    test('findStoolTextureByValue trouve chaque valeur connue', () {
      expect(findStoolTextureByValue('aqueuse'), equals(stoolTextureAqueuse));
      expect(findStoolTextureByValue('grumeleuse'),
          equals(stoolTextureGrumeleuse));
      expect(findStoolTextureByValue('pateuse'), equals(stoolTexturePateuse));
      expect(findStoolTextureByValue('moulee'), equals(stoolTextureMoulee));
      expect(findStoolTextureByValue('dure'), equals(stoolTextureDure));
    });

    // ── pas de valeur par défaut inventée ─────────────────────────────────
    test('findStoolTextureByValue(null/""/inconnu) → null', () {
      expect(findStoolTextureByValue(null), isNull);
      expect(findStoolTextureByValue(''), isNull);
      expect(findStoolTextureByValue('cremeuse'), isNull);
    });

    // ── l'échelle ─────────────────────────────────────────────────────────────
    test('stoolTextures contient 5 valeurs', () {
      expect(stoolTextures, hasLength(5));
    });

    test('les valeurs comme les labels sont uniques', () {
      expect(stoolTextures.map((t) => t.value).toSet(), hasLength(5));
      expect(stoolTextures.map((t) => t.label).toSet(), hasLength(5));
      expect(stoolTextures.map((t) => t.labelKey).toSet(), hasLength(5));
    });

    test('les valeurs DB restent en ASCII (les accents sont dans le label)', () {
      // Un export JSON relu à la main doit rester éditable sans clavier
      // accentué, et une valeur normalisée NFD/NFC ne doit pas dépendre de
      // l'encodeur.
      for (final texture in stoolTextures) {
        expect(texture.value, matches(RegExp(r'^[a-z_]+$')));
      }
      expect(stoolTexturePateuse.value, equals('pateuse'));
      expect(stoolTexturePateuse.label, equals('Pâteuse'));
      expect(stoolTextureMoulee.value, equals('moulee'));
      expect(stoolTextureMoulee.label, equals('Moulée'));
    });
  });

  group('DiaperEvent.textureDbValue', () {
    final timestamp = DateTime.utc(2023, 10, 25);

    test('wasteType=caca avec texture → valeur DB', () {
      final event = DiaperEvent(
        timestamp: timestamp,
        wasteType: WasteType.caca,
        stoolTexture: stoolTexturePateuse,
      );

      expect(event.textureDbValue, equals('pateuse'));
    });

    test('wasteType=les_deux avec texture → valeur DB', () {
      final event = DiaperEvent(
        timestamp: timestamp,
        wasteType: WasteType.lesDeux,
        pipiColor: pipiColorJauneClair,
        cacaColor: cacaColorJauneMoutarde,
        stoolTexture: stoolTextureMoulee,
      );

      expect(event.textureDbValue, equals('moulee'));
    });

    // ── la consistance ne décrit qu'une selle ───────────────────────────────
    test('wasteType=pipi avec une texture encore remplie → null', () {
      final event = DiaperEvent(
        timestamp: timestamp,
        wasteType: WasteType.pipi,
        pipiColor: pipiColorJauneClair,
        stoolTexture: stoolTextureDure,
      );

      expect(event.textureDbValue, isNull);
    });

    test('wasteType absent (ligne héritée) avec texture → null', () {
      final event = DiaperEvent(
        timestamp: timestamp,
        stoolTexture: stoolTextureAqueuse,
      );

      expect(event.textureDbValue, isNull);
    });

    test('wasteType=caca sans texture → null', () {
      final event = DiaperEvent(
        timestamp: timestamp,
        wasteType: WasteType.caca,
      );

      expect(event.textureDbValue, isNull);
    });
  });
}

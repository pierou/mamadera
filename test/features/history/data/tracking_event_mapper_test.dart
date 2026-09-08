import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' as drift;
import 'package:mamadera/data/local/db_constants.dart' as db_const;
import 'package:mamadera/data/local/tracking_event_mapper.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';

/// Fake de chiffrement identité : le mapper n'utilise que decrypt().
class _IdentityEncryption extends EncryptionService {
  @override
  String encrypt(String plainText) => plainText;

  @override
  String? decrypt(String? cipherText) => cipherText;
}

/// Test de régression : les rows legacy `les_deux` avec une seule partie de
/// couleur ne doivent pas lever de TypeError dans le mapper (piège de
/// précédence `??` vs `as`) et doivent être résolues vers le bon type.
void main() {
  final encryption = _IdentityEncryption();

  group('mapToEntity — legacy les_deux à une seule couleur', () {
    test('couleur caca-only (meconium) → cacaColor résolu, pas d\'exception', () {
      final row = drift.TrackingEvent(
        id: 1,
        type: db_const.typeCaca,
        timestamp: DateTime(2023, 6, 15),
        wasteType: WasteType.lesDeux.dbValue,
        color: 'meconium',
        notes: null,
      );

      final event = mapToEntity(row, encryption);

      expect(event, isA<DiaperEvent>());
      final diaper = event as DiaperEvent;
      expect(diaper.wasteType, WasteType.lesDeux);
      expect(diaper.cacaColor, cacaColorMeconium);
      expect(diaper.pipiColor, isNull);
    });

    test('couleur pipi-only (rose_urates) → pipiColor résolu', () {
      final row = drift.TrackingEvent(
        id: 2,
        type: db_const.typeCaca,
        timestamp: DateTime(2023, 6, 15),
        wasteType: WasteType.lesDeux.dbValue,
        color: 'rose_urates',
        notes: null,
      );

      final event = mapToEntity(row, encryption);

      expect(event, isA<DiaperEvent>());
      final diaper = event as DiaperEvent;
      expect(diaper.pipiColor, pipiColorRoseUrates);
      expect(diaper.cacaColor, isNull);
    });
  });

  group('mapToEntity — consistance de la selle', () {
    test('une texture connue est lue sur l\'événement couche', () {
      final row = drift.TrackingEvent(
        id: 10,
        type: db_const.typeCaca,
        timestamp: DateTime(2026, 9, 1),
        wasteType: WasteType.caca.dbValue,
        color: 'vert_olive',
        texture: 'pateuse',
        notes: null,
      );

      final diaper = mapToEntity(row, encryption) as DiaperEvent;

      expect(diaper.stoolTexture, stoolTexturePateuse);
    });

    // Une valeur lue en base qui ne fait pas partie de l\'échelle (version
    // antérieure de l\'app, backup édité à la main) doit rester « aucune
    // texture » plutôt que d\'être convertie au hasard vers un cran voisin.
    test('texture inconnue → null, jamais une texture par défaut', () {
      final row = drift.TrackingEvent(
        id: 11,
        type: db_const.typeCaca,
        timestamp: DateTime(2026, 9, 1),
        wasteType: WasteType.caca.dbValue,
        texture: 'en_rations',
        notes: null,
      );

      final diaper = mapToEntity(row, encryption) as DiaperEvent;

      expect(diaper.stoolTexture, isNull);
    });

    // Les changes notées avant la v9 ont une colonne NULL : l\'écran ne doit
    // rien inventer à leur sujet.
    test('column texture absente (lignes héritées) → null', () {
      final row = drift.TrackingEvent(
        id: 12,
        type: db_const.typeCaca,
        timestamp: DateTime(2026, 8, 30),
        wasteType: WasteType.caca.dbValue,
        color: 'jaune_moutarde',
        notes: null,
      );

      final diaper = mapToEntity(row, encryption) as DiaperEvent;

      expect(diaper.stoolTexture, isNull);
      expect(diaper.cacaColor, cacaColorJauneMoutarde);
    });
  });
}

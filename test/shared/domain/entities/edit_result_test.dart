import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/widgets/edit_event_dialog.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('UpdateResult', () {
    final baseTimestamp = DateTime.utc(2023, 10, 25, 14, 30);

    // ── Construction et getters ────────────────────────────────
    test('construction complète → tous les getters retournent les valeurs attendues', () {
      final result = UpdateResult(
        timestamp: baseTimestamp,
        duration: 60,
        notes: 'nettoyage_yeux',
        wasteType: 'pipi',
        color: 'jaune_clair',
      );

      expect(result.timestamp, equals(baseTimestamp));
      expect(result.duration, equals(60.0));
      expect(result.notes, equals('nettoyage_yeux'));
      expect(result.wasteType, equals('pipi'));
      expect(result.color, equals('jaune_clair'));
    });

    test('construction vide → tous les champs optionnels sont null', () {
      const result = UpdateResult();

      expect(result.timestamp, isNull);
      expect(result.duration, isNull);
      expect(result.notes, isNull);
      expect(result.wasteType, isNull);
      expect(result.color, isNull);
    });

    test('construction partielle → seuls les champs fournis sont non-null', () {
      final result = UpdateResult(
        timestamp: baseTimestamp,
        color: 'vert_olive',
      );

      expect(result.timestamp, equals(baseTimestamp));
      expect(result.duration, isNull);
      expect(result.notes, isNull);
      expect(result.wasteType, isNull);
      expect(result.color, equals('vert_olive'));
    });

    // ── wasteTypeEnum parsing ──────────────────────────────────
    test('wasteType="pipi" → wasteTypeEnum == WasteType.pipi', () {
      const result = UpdateResult(wasteType: 'pipi');
      expect(result.wasteTypeEnum, equals(WasteType.pipi));
    });

    test('wasteType=null → wasteTypeEnum est null', () {
      const result = UpdateResult();
      expect(result.wasteTypeEnum, isNull);
    });

    // ── pipiColorEnum / cacaColorEnum parsing (format pipe) ────
    test('pipi avec color="jaune_clair" → pipiColorEnum == PipiColor.jauneClair', () {
      const result = UpdateResult(wasteType: 'pipi', color: 'jaune_clair');

      expect(result.pipiColorEnum, equals(PipiColor.jauneClair));
    });

    test('lesDeux avec color="incolore|vert_olive" → pipi et caca parsés correctement', () {
      const result = UpdateResult(wasteType: 'les_deux', color: 'incolore|vert_olive');

      expect(result.pipiColorEnum, equals(PipiColor.incolore));
      expect(result.cacaColorEnum, equals(CacaColor.vertOlive));
    });

    test('caca → pipiColorEnum retourne null (non pertinent)', () {
      const result = UpdateResult(wasteType: 'caca', color: 'jaune_moutarde');

      expect(result.pipiColorEnum, isNull);
    });

    test(
        'lesDeux avec une seule couleur exclusive pipi → pipi parsé, caca retourne null', () {
      // 'rose_urates' n'existe que dans PipiColor, pas dans CacaColor
      const result = UpdateResult(wasteType: 'les_deux', color: 'rose_urates');

      expect(result.pipiColorEnum, equals(PipiColor.roseUrates));
      // Caca ne connait pas 'rose_urates' → null (pas de fallback silencieux)
      expect(result.cacaColorEnum, isNull);
    });

    // ── colorDbValue reconstruction ────────────────────────────
    test('lesDeux avec pipi+caca → format pipe "incolore|jaune_moutarde"', () {
      const result = UpdateResult(
        wasteType: 'les_deux',
        color: 'incolore|jaune_moutarde',
      );

      expect(result.colorDbValue, equals('incolore|jaune_moutarde'));
    });

    test('pipi avec une couleur → retourne juste la valeur DB', () {
      const result = UpdateResult(wasteType: 'pipi', color: 'rose_urates');

      expect(result.colorDbValue, equals('rose_urates'));
    });
  });

  group('DeleteResult', () {
    test('DeleteResult est un EditResult (sealed class hierarchy)', () {
      const result = DeleteResult();
      expect(result, isA<EditResult>());
    });

    test('construction vide sans paramètres requis', () {
      // Vérifie que le constructeur constant fonctionne sans crash
      const result = DeleteResult();
      expect(result, isNotNull);
    });
  });
}

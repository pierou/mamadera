import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/widgets/edit_event_dialog.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('UpdateResult', () {
    final baseTimestamp = DateTime.utc(2023, 10, 25, 14, 30);

    // ── Construction et getters (champs typés directement) ─────
    test('construction complète → tous les champs retournent les valeurs attendues', () {
      final result = UpdateResult(
        timestamp: baseTimestamp,
        duration: 60,
        notes: 'nettoyage_yeux',
        wasteType: WasteType.pipi,
        pipiColor: PipiColor.jauneClair,
      );

      expect(result.timestamp, equals(baseTimestamp));
      expect(result.duration, equals(60.0));
      expect(result.notes, equals('nettoyage_yeux'));
      expect(result.wasteType, equals(WasteType.pipi));
      expect(result.pipiColor, equals(PipiColor.jauneClair));
    });

    test('construction vide → tous les champs optionnels sont null', () {
      const result = UpdateResult();

      expect(result.timestamp, isNull);
      expect(result.duration, isNull);
      expect(result.notes, isNull);
      expect(result.wasteType, isNull);
      expect(result.pipiColor, isNull);
      expect(result.cacaColor, isNull);
    });

    test('construction partielle → seuls les champs fournis sont non-null', () {
      final result = UpdateResult(
        timestamp: baseTimestamp,
        cacaColor: CacaColor.vertOlive,
      );

      expect(result.timestamp, equals(baseTimestamp));
      expect(result.duration, isNull);
      expect(result.notes, isNull);
      expect(result.wasteType, isNull);
      expect(result.pipiColor, isNull);
      expect(result.cacaColor, equals(CacaColor.vertOlive));
    });

    // ── wasteType est déjà un enum typé (pas de parsing) ───────
    test('wasteType=WasteType.pipi → champ retourne l\'enum directement', () {
      const result = UpdateResult(wasteType: WasteType.pipi);
      expect(result.wasteType, equals(WasteType.pipi));
    });

    test('wasteType=null → reste null', () {
      const result = UpdateResult();
      expect(result.wasteType, isNull);
    });

    // ── pipiColor / cacaColor sont déjà des enums typés ────────
    test('pipiColor=PipiColor.jauneClair → champ retourne l\'enum directement', () {
      const result = UpdateResult(pipiColor: PipiColor.jauneClair);

      expect(result.pipiColor, equals(PipiColor.jauneClair));
    });

    test('lesDeux avec pipiColor et cacaColor → les deux champs sont typés', () {
      const result = UpdateResult(
        wasteType: WasteType.lesDeux,
        pipiColor: PipiColor.incolore,
        cacaColor: CacaColor.vertOlive,
      );

      expect(result.wasteType, equals(WasteType.lesDeux));
      expect(result.pipiColor, equals(PipiColor.incolore));
      expect(result.cacaColor, equals(CacaColor.vertOlive));
    });

    test('caca avec cacaColor uniquement → pipiColor reste null', () {
      const result = UpdateResult(
        wasteType: WasteType.caca,
        cacaColor: CacaColor.jauneMoutarde,
      );

      expect(result.wasteType, equals(WasteType.caca));
      expect(result.pipiColor, isNull);
      expect(result.cacaColor, equals(CacaColor.jauneMoutarde));
    });

    test('lesDeux avec seule pipiColor → caca reste null', () {
      const result = UpdateResult(
        wasteType: WasteType.lesDeux,
        pipiColor: PipiColor.roseUrates,
      );

      expect(result.pipiColor, equals(PipiColor.roseUrates));
      expect(result.cacaColor, isNull);
    });

    // ── Vérification que les enums ont bien un .dbValue getter ──
    test('WasteType enum a un .dbValue getter', () {
      const result = UpdateResult(wasteType: WasteType.lesDeux);
      expect(result.wasteType!.dbValue, equals('les_deux'));
    });

    test('PipiColor enum a un .dbValue getter', () {
      const result = UpdateResult(pipiColor: PipiColor.jauneClair);
      expect(result.pipiColor!.value, equals('jaune_clair'));
    });

    test('CacaColor enum a un .dbValue getter', () {
      const result = UpdateResult(cacaColor: CacaColor.vertOlive);
      expect(result.cacaColor!.value, equals('vert_olive'));
    });
  });

  group('DeleteResult', () {
    test('DeleteResult est un EditResult (sealed class hierarchy)', () {
      const result = DeleteResult();
      expect(result, isA<EditResult>());
    });

    test('construction vide sans paramètres requis', () {
      const result = DeleteResult();
      expect(result, isNotNull);
    });
  });
}

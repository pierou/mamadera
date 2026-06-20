// ignore_for_file: lines_longer_than_80_chars // Tests des propriétés et du parsing de HistoryFilter

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('HistoryFilter', () {
    // ── .dbKey retourne le nom en minuscule (5) ────────────────
    group('.dbKey doit retourner le nom de l\'enum en minuscules', () {
      test('all → "all"', () {
        expect(HistoryFilter.all.dbKey, 'all');
      });

      test('miam → "miam"', () {
        expect(HistoryFilter.miam.dbKey, 'miam');
      });

      test('dodo → "dodo"', () {
        expect(HistoryFilter.dodo.dbKey, 'dodo');
      });

      test('caca → "caca"', () {
        expect(HistoryFilter.caca.dbKey, 'caca');
      });

      test('sante → "sante"', () {
        expect(HistoryFilter.sante.dbKey, 'sante');
      });
    });

    // ── .label pour chaque filtre (5) ──────────────────────────
    group('.label doit retourner le texte affiché correct', () {
      test('all → "Tous"', () {
        expect(HistoryFilter.all.label, 'Tous');
      });

      test('miam → "Miam"', () {
        expect(HistoryFilter.miam.label, 'Miam');
      });

      test('dodo → "Sommeil"', () {
        expect(HistoryFilter.dodo.label, 'Sommeil');
      });

      test('caca → "Caca"', () {
        expect(HistoryFilter.caca.label, 'Caca');
      });

      test('sante → "Santé"', () {
        expect(HistoryFilter.sante.label, 'Santé');
      });
    });

    // ── .trackingType null pour all, string pour autres (2) ────
    group('.trackingType doit retourner le type de suivi ou null', () {
      test('all retourne null car il ne filtre aucun type spécifique', () {
        expect(HistoryFilter.all.trackingType, isNull);
      });

      test('les autres filtres retournent leur nom en minuscules', () {
        expect(HistoryFilter.miam.trackingType, 'miam');
        expect(HistoryFilter.dodo.trackingType, 'dodo');
        expect(HistoryFilter.caca.trackingType, 'caca');
        expect(HistoryFilter.sante.trackingType, 'sante');
      });
    });

    // ── fromString() valide / inconnu / vide (3) ───────────────
    group('.fromString() doit convertir une chaîne en HistoryFilter', () {
      test('une entrée valide retourne l\'enum correspondant', () {
        expect(HistoryFilter.fromString('miam'), HistoryFilter.miam);
        expect(HistoryFilter.fromString('DODO'), HistoryFilter.dodo);
        expect(HistoryFilter.fromString('Caca'), HistoryFilter.caca);
        expect(HistoryFilter.fromString('SANTÉ'), HistoryFilter.all); // 'santé' ≠ 'sante', fallback
      });

      test('une entrée inconnue retourne all en fallback safe', () {
        expect(HistoryFilter.fromString('inconnu'), HistoryFilter.all);
      });

      test('une chaîne vide ou "all" retourne explicitement all', () {
        expect(HistoryFilter.fromString(''), HistoryFilter.all);
        expect(HistoryFilter.fromString('all'), HistoryFilter.all);
        expect(HistoryFilter.fromString('ALL'), HistoryFilter.all);
      });
    });
  });

  group('HealthSubtype.byValue()', () {
    // Chaque valeur DB connue retourne la bonne instance.
    test('"nettoyage_yeux" → nettoyageYeux', () {
      expect(
        HealthSubtype.byValue('nettoyage_yeux'),
        equals(HealthSubtype.nettoyageYeux),
      );
    });

    test('"nettoyage_nombril" → nettoyageNombril', () {
      expect(
        HealthSubtype.byValue('nettoyage_nombril'),
        equals(HealthSubtype.nettoyageNombril),
      );
    });

    test('"nettoyage_visage" → nettoyageVisage', () {
      expect(
        HealthSubtype.byValue('nettoyage_visage'),
        equals(HealthSubtype.nettoyageVisage),
      );
    });

    test('"nettoyage_nez" → nettoyageNez', () {
      expect(
        HealthSubtype.byValue('nettoyage_nez'),
        equals(HealthSubtype.nettoyageNez),
      );
    });

    test('"vitamine_d" → vitamineD', () {
      expect(
        HealthSubtype.byValue('vitamine_d'),
        equals(HealthSubtype.vitamineD),
      );
    });

    test('"vitamine_k" → vitamineK', () {
      expect(
        HealthSubtype.byValue('vitamine_k'),
        equals(HealthSubtype.vitamineK),
      );
    });
  });

  group('HealthSubtype.byValue() – valeur inconnue retourne null', () {
    test('"inconnu" → null', () {
      expect(HealthSubtype.byValue('inconnu'), isNull);
    });
  });

  group('HealthSubtype.values', () {
    // Vérifie que la liste contient bien les 6 sous-types attendus.
    test('.values.length == 6', () {
      expect(HealthSubtype.values.length, equals(6));
    });
  });
}


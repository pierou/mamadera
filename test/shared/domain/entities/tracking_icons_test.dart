import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_icons.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('TrackingTypeIcon extension', () {
    test('miam returns lunch_dining icon', () {
      expect(TrackingType.miam.icon, Icons.lunch_dining);
    });

    test('sante returns favorite icon', () {
      expect(TrackingType.sante.icon, Icons.favorite);
    });

    test('caca returns water_drop_outlined icon', () {
      expect(TrackingType.caca.icon, Icons.water_drop_outlined);
    });

    test('dodo returns nightlight icon', () {
      expect(TrackingType.dodo.icon, Icons.nightlight);
    });
  });

  group('FeedingSubtypeIcon extension', () {
    test('natural returns local_drink_outlined icon', () {
      expect(FeedingSubtype.natural.icon, Icons.local_drink_outlined);
    });

    test('artificial returns coffee_rounded icon', () {
      expect(FeedingSubtype.artificial.icon, Icons.coffee_rounded);
    });
  });

  group('WasteTypeIcon extension', () {
    test('pipi returns water_drop_outlined icon', () {
      expect(WasteType.pipi.icon, Icons.water_drop_outlined);
    });

    test('caca returns water_drop icon', () {
      expect(WasteType.caca.icon, Icons.water_drop);
    });

    test('lesDeux returns wb_sunny icon', () {
      expect(WasteType.lesDeux.icon, Icons.wb_sunny);
    });
  });

  group('HealthIcons.fromValue', () {
    test('nettoyage types return cleaning_services icon', () {
      expect(HealthIcons.fromValue('nettoyage_yeux'), Icons.cleaning_services);
      expect(HealthIcons.fromValue('nettoyage_nombril'), Icons.cleaning_services);
      expect(HealthIcons.fromValue('nettoyage_visage'), Icons.cleaning_services);
      expect(HealthIcons.fromValue('nettoyage_nez'), Icons.cleaning_services);
    });

    test('vitamine types return medication icon', () {
      expect(HealthIcons.fromValue('vitamine_d'), Icons.medication);
      expect(HealthIcons.fromValue('vitamine_k'), Icons.medication);
    });

    test('unknown value returns health_and_safety icon', () {
      expect(HealthIcons.fromValue('unknown_fallback'), Icons.health_and_safety);
    });
  });

  group('HealthIcons.from (HealthSubtype)', () {
    test('returns correct icon for each HealthSubtype constant', () {
      // Nettoyages → cleaning_services
      expect(HealthIcons.from(HealthSubtype.nettoyageYeux), Icons.cleaning_services);
      expect(HealthIcons.from(HealthSubtype.nettoyageNombril), Icons.cleaning_services);
      expect(HealthIcons.from(HealthSubtype.nettoyageVisage), Icons.cleaning_services);
      expect(HealthIcons.from(HealthSubtype.nettoyageNez), Icons.cleaning_services);

      // Vitamines → medication
      expect(HealthIcons.from(HealthSubtype.vitamineD), Icons.medication);
      expect(HealthIcons.from(HealthSubtype.vitamineK), Icons.medication);
    });
  });
}

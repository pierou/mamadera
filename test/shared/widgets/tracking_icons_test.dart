import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/widgets/tracking_icons.dart';
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

    test('solid returns rice_bowl icon', () {
      expect(FeedingSubtype.solid.icon, Icons.rice_bowl);
    });
  });

  group('WasteTypeIcon extension', () {
    test('pipi returns water_drop_outlined icon', () {
      expect(WasteType.pipi.icon, Icons.water_drop_outlined);
    });

    test('caca returns water_drop icon', () {
      expect(WasteType.caca.icon, Icons.water_drop);
    });

    test('lesDeux returns opacity icon (drop family, not the sun)', () {
      expect(WasteType.lesDeux.icon, Icons.opacity);
    });
  });

  group('HealthIcons.fromValue', () {
    test('nettoyage types return cleaning_services icon', () {
      expect(HealthIcons.fromValue('nettoyage_yeux'), Icons.cleaning_services);
      expect(
          HealthIcons.fromValue('nettoyage_nombril'), Icons.cleaning_services);
      expect(
          HealthIcons.fromValue('nettoyage_visage'), Icons.cleaning_services);
      expect(HealthIcons.fromValue('nettoyage_nez'), Icons.cleaning_services);
    });

    test('vitamine types return medication icon', () {
      expect(HealthIcons.fromValue('vitamine_d'), Icons.medication);
      expect(HealthIcons.fromValue('vitamine_k'), Icons.medication);
    });

    test('unknown value returns health_and_safety icon', () {
      expect(
          HealthIcons.fromValue('unknown_fallback'), Icons.health_and_safety);
    });
  });

  group('TrackingTypeListIcon and HistoryFilterIcon (the outlined pair)', () {
    test('a history row wears the outlined glyph of its type', () {
      expect(TrackingType.miam.listIcon, Icons.lunch_dining_outlined);
      expect(TrackingType.dodo.listIcon, Icons.nightlight_outlined);
      expect(TrackingType.sante.listIcon, Icons.favorite_border);
      expect(TrackingType.caca.listIcon, Icons.water_drop_outlined);
    });

    test('outlining a row does not restyle the home grid', () {
      // The two mappings exist because the filled glyphs are what the home buttons
      // ship with, and those buttons are inside the live store listings.
      expect(TrackingType.miam.icon, Icons.lunch_dining);
      expect(TrackingType.dodo.icon, Icons.nightlight);
      expect(TrackingType.sante.icon, Icons.favorite);
    });

    test('a filter pill wears its type glyph, outlined like the row', () {
      expect(HistoryFilter.miam.pillIcon, Icons.lunch_dining_outlined);
      expect(HistoryFilter.dodo.pillIcon, Icons.nightlight_outlined);
      expect(HistoryFilter.caca.pillIcon, Icons.water_drop_outlined);
      expect(HistoryFilter.sante.pillIcon, Icons.favorite_border);
    });

    test('a pill that is not one type wears no glyph', () {
      expect(HistoryFilter.all.pillIcon, isNull,
          reason: '« Tous » is every type, so it is none of them');
      expect(HistoryFilter.measurements.pillIcon, isNull,
          reason: 'B7: measurements are not a tracking type');
    });

    test('the pill glyph of a type matches the row glyph of that type', () {
      // Two surfaces, one identity: the pill for « Sommeil » and a sleep row must
      // not be two different pictures of the same thing.
      expect(HistoryFilter.miam.pillIcon, TrackingType.miam.listIcon);
      expect(HistoryFilter.dodo.pillIcon, TrackingType.dodo.listIcon);
      expect(HistoryFilter.caca.pillIcon, TrackingType.caca.listIcon);
      expect(HistoryFilter.sante.pillIcon, TrackingType.sante.listIcon);
    });
  });

  group('HealthIcons.from (HealthSubtype)', () {
    test('returns correct icon for each HealthSubtype constant', () {
      // Nettoyages → cleaning_services
      expect(HealthIcons.from(HealthSubtype.nettoyageYeux),
          Icons.cleaning_services);
      expect(HealthIcons.from(HealthSubtype.nettoyageNombril),
          Icons.cleaning_services);
      expect(HealthIcons.from(HealthSubtype.nettoyageVisage),
          Icons.cleaning_services);
      expect(HealthIcons.from(HealthSubtype.nettoyageNez),
          Icons.cleaning_services);

      // Vitamines → medication
      expect(HealthIcons.from(HealthSubtype.vitamineD), Icons.medication);
      expect(HealthIcons.from(HealthSubtype.vitamineK), Icons.medication);
    });
  });
}

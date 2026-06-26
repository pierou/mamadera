import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('TrackingEvent sealed hierarchy', () {
    final baseTimestamp = DateTime.utc(2023, 10, 25, 14, 30, 0);

    group('FeedingEvent construction', () {
      test('doit être instanciable avec les paramètres requis', () {
        final event = FeedingEvent(
          timestamp: baseTimestamp,
          subtype: FeedingSubtype.sein,
          duration: 30,
        );

        expect(event.trackingType, TrackingType.miam);
        expect(event.timestamp, baseTimestamp);
        expect(event.id, isNull);
        expect(event.subtype, FeedingSubtype.sein);
        expect(event.duration, 30.0);
        expect(event.notes, isNull);
      });

      test('doit accepter les paramètres optionnels', () {
        final event = FeedingEvent(
          timestamp: baseTimestamp,
          subtype: FeedingSubtype.bib,
          duration: 15,
          id: 1,
          notes: 'Biberon complet',
        );

        expect(event.id, 1);
        expect(event.notes, 'Biberon complet');
      });
    });

    group('SleepEvent construction', () {
      test('doit être instanciable avec les paramètres requis', () {
        final event = SleepEvent(
          timestamp: baseTimestamp,
          duration: 90,
        );

        expect(event.trackingType, TrackingType.dodo);
        expect(event.timestamp, baseTimestamp);
        expect(event.duration, 90.0);
      });

      test('doit accepter les paramètres optionnels', () {
        final event = SleepEvent(
          timestamp: baseTimestamp,
          duration: 60,
          id: 2,
          notes: 'Dodo dans le lit',
        );

        expect(event.id, 2);
        expect(event.notes, 'Dodo dans le lit');
      });
    });

    group('DiaperEvent construction', () {
      test('doit être instanciable avec wasteType et couleurs', () {
        final event = DiaperEvent(
          timestamp: baseTimestamp,
          wasteType: WasteType.pipi,
          pipiColor: PipiColor.jauneClair,
        );

        expect(event.trackingType, TrackingType.caca);
        expect(event.wasteType, WasteType.pipi);
        expect(event.pipiColor, PipiColor.jauneClair);
      });
    });

    group('HealthEvent construction', () {
      test('doit être instanciable avec subtype', () {
        final event = HealthEvent(
          timestamp: baseTimestamp,
          subtype: HealthSubtype.nettoyageYeux,
        );

        expect(event.trackingType, TrackingType.sante);
        expect(event.subtype, HealthSubtype.nettoyageYeux);
      });
    });

    group('Equality & hashCode', () {
      final baseEvent = FeedingEvent(
        timestamp: baseTimestamp,
        subtype: FeedingSubtype.sein,
        duration: 30,
        id: 2,
      );

      test('doit retourner vrai pour deux instances strictement égales', () {
        expect(baseEvent, equals(baseEvent));
      });

      test(
          'doit retourner vrai pour deux instances différentes mais aux valeurs identiques',
          () {
        final duplicate = FeedingEvent(
          timestamp: baseTimestamp,
          subtype: FeedingSubtype.sein,
          duration: 30,
          id: 2,
        );
        expect(baseEvent, equals(duplicate));
      });

      test('doit retourner faux si une valeur diffère', () {
        final differentEvent = SleepEvent(
          timestamp: baseTimestamp,
          duration: 30,
          id: 2,
        );
        expect(baseEvent, isNot(equals(differentEvent)));
      });

      test('doit retourner faux pour null', () {
        expect(baseEvent, isNot(equals(null)));
      });

      test('doit retourner faux pour un type différent', () {
        expect(baseEvent, isNot(equals('String')));
      });

      test('hashCode doit être identique pour des instances égales', () {
        final duplicate = FeedingEvent(
          timestamp: baseTimestamp,
          subtype: FeedingSubtype.sein,
          duration: 30,
          id: 2,
        );
        expect(baseEvent.hashCode, equals(duplicate.hashCode));
      });
    });

    group('toString', () {
      test('FeedingEvent doit retourner une représentation lisible de l\'objet', () {
        final event = FeedingEvent(
          timestamp: baseTimestamp,
          subtype: FeedingSubtype.sein,
          duration: 30,
          id: 5,
          notes: 'Info de debug',
        );

        final stringRepresentation = event.toString();

        expect(stringRepresentation, contains('FeedingEvent'));
        expect(stringRepresentation, contains('id: 5'));
        expect(stringRepresentation, contains('duration: 30.0'));
      });

      test('SleepEvent doit retourner une représentation lisible de l\'objet', () {
        final event = SleepEvent(
          timestamp: baseTimestamp,
          duration: 60,
          id: 10,
        );

        expect(event.toString(), contains('SleepEvent'));
      });

      test('DiaperEvent doit retourner une représentation lisible de l\'objet', () {
        final event = DiaperEvent(
          timestamp: baseTimestamp,
          wasteType: WasteType.caca,
          id: 15,
        );

        expect(event.toString(), contains('DiaperEvent'));
      });

      test('HealthEvent doit retourner une représentation lisible de l\'objet', () {
        final event = HealthEvent(
          timestamp: baseTimestamp,
          subtype: HealthSubtype.vitamineD,
          id: 20,
        );

        expect(event.toString(), contains('HealthEvent'));
      });
    });
  });
}

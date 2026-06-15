import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('TrackingEvent', () {
    final baseTimestamp = DateTime.utc(2023, 10, 25, 14, 30, 0);

    group('Construction', () {
      test('doit être instanciable avec les paramètres requis', () {
        final event = TrackingEvent(
          type: TrackingType.miam,
          timestamp: baseTimestamp,
        );

        expect(event.type, TrackingType.miam);
        expect(event.timestamp, baseTimestamp);
        expect(event.id, isNull);
        expect(event.duration, isNull);
        expect(event.notes, isNull);
      });

      test('doit accepter les paramètres optionnels', () {
        final event = TrackingEvent(
          type: TrackingType.dodo,
          timestamp: baseTimestamp,
          id: 1,
          duration: 1.5,
          notes: 'Focus sur les tests',
        );

        expect(event.type, TrackingType.dodo);
        expect(event.timestamp, baseTimestamp);
        expect(event.id, 1);
        expect(event.duration, 1.5);
        expect(event.notes, 'Focus sur les tests');
      });
    });

    group('Equality & hashCode', () {
      final baseEvent = TrackingEvent(
        type: TrackingType.caca,
        timestamp: baseTimestamp,
        id: 2,
        duration: 0.5,
        notes: 'Pause café',
      );

      test('doit retourner vrai pour deux instances strictement égales', () {
        expect(baseEvent, equals(baseEvent));
      });

      test(
          'doit retourner vrai pour deux instances différentes mais aux valeurs identiques',
          () {
        final duplicate = TrackingEvent(
          type: TrackingType.caca,
          timestamp: baseTimestamp,
          id: 2,
          duration: 0.5,
          notes: 'Pause café',
        );
        expect(baseEvent, equals(duplicate));
      });

      test('doit retourner faux si une valeur diffère', () {
        final differentEvent = TrackingEvent(
          type: TrackingType.sante,
          timestamp: baseTimestamp,
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
        final duplicate = TrackingEvent(
          type: TrackingType.caca,
          timestamp: baseTimestamp,
          id: 2,
          duration: 0.5,
          notes: 'Pause café',
        );
        expect(baseEvent.hashCode, equals(duplicate.hashCode));
      });
    });

    group('toString', () {
      test('doit retourner une représentation lisible de l\'objet', () {
        final event = TrackingEvent(
          type: TrackingType.miam,
          timestamp: baseTimestamp,
          id: 5,
          duration: 1,
          notes: 'Info de debug',
        );

        final stringRepresentation = event.toString();

        expect(stringRepresentation, contains('TrackingEvent'));
        expect(stringRepresentation, contains('id: 5'));
        expect(stringRepresentation, contains('type: ${event.type}'));
        expect(stringRepresentation, contains('duration: 1.0'));
      });
    });
  });
}

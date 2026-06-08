import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/entities/tracking_event.dart';

void main() {
  group('TrackingEvent', () {
    final baseTimestamp = DateTime.utc(2023, 10, 25, 14, 30, 0);

    group('Construction', () {
      test('doit être instanciable avec les paramètres requis', () {
        final event = TrackingEvent(
          type: 'meeting',
          timestamp: baseTimestamp,
        );

        expect(event.type, 'meeting');
        expect(event.timestamp, baseTimestamp);
        expect(event.id, isNull);
        expect(event.duration, isNull);
        expect(event.notes, isNull);
      });

      test('doit accepter les paramètres optionnels', () {
        final event = TrackingEvent(
          type: 'work',
          timestamp: baseTimestamp,
          id: 1,
          duration: 1.5,
          notes: 'Focus sur les tests',
        );

        expect(event.type, 'work');
        expect(event.timestamp, baseTimestamp);
        expect(event.id, 1);
        expect(event.duration, 1.5);
        expect(event.notes, 'Focus sur les tests');
      });
    });

    group('Equality & hashCode', () {
      final baseEvent = TrackingEvent(
        type: 'break',
        timestamp: baseTimestamp,
        id: 2,
        duration: 0.5,
        notes: 'Pause café',
      );

      test('doit retourner vrai pour deux instances strictement égales', () {
        expect(baseEvent, equals(baseEvent));
      });

      test('doit retourner vrai pour deux instances différentes mais aux valeurs identiques', () {
        final duplicate = TrackingEvent(
          type: 'break',
          timestamp: baseTimestamp,
          id: 2,
          duration: 0.5,
          notes: 'Pause café',
        );
        expect(baseEvent, equals(duplicate));
      });

      test('doit retourner faux si une valeur diffère', () {
        final differentEvent = TrackingEvent(
          type: 'study',
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
          type: 'break',
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
          type: 'test',
          timestamp: baseTimestamp,
          id: 5,
          duration: 1,
          notes: 'Info de debug',
        );
        
        final stringRepresentation = event.toString();
        
        expect(stringRepresentation, contains('TrackingEvent'));
        expect(stringRepresentation, contains('type: test'));
        expect(stringRepresentation, contains('id: 5'));
        expect(stringRepresentation, contains('duration: 1.0'));
      });
    });
  });
}
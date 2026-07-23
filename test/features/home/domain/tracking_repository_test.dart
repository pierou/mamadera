// ignore_for_file: lines_longer_than_80_chars // Tests de l'interface TrackingRepository (contrat pur, sans DB)

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Mock de [TrackingRepository] pour tester le contrat d'interface.
class MockTrackingRepository implements TrackingRepository {
  final List<TrackingEvent> _events = [];

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async {
    return _events.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type) async {
    return _events.where((e) => e.trackingType == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<int> insertEvent(TrackingEvent event) async {
    final id = _events.isEmpty ? 1 : _events.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    // Dans un vrai repo, l'ID serait assigné par la DB. Ici on simule.
    _events.add(event);
    return id;
  }

  @override
  Future<DateTime?> getLastEventByTypeAndSubtype(TrackingType type, {String? subtypeValue}) async {
    final filtered = _events.where((e) {
      if (e.trackingType != type) return false;
      if (subtypeValue == null) return true;
      // Vérifier le subtype selon le type d'événement en utilisant map()
      return e.map(
        (base) => false,
        feeding: (e) => e.subtype.name == subtypeValue,
        sleep: (e) => subtypeValue.isEmpty,
        diaper: (e) => subtypeValue.isEmpty,
        health: (e) => e.subtype.value == subtypeValue,
      );
    }).toList();

    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.first.timestamp;
  }
}

void main() {
  late MockTrackingRepository repository;

  setUp(() {
    repository = MockTrackingRepository();
  });

  group('TrackingRepository interface contract', () {
    group('getAllEventsOrdered', () {
      test('retourne une liste vide quand aucun événement n\'existe', () async {
        final result = await repository.getAllEventsOrdered();
        expect(result, isEmpty);
      });

      test('retourne tous les événements triés par timestamp décroissant', () async {
        final oldEvent = FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8, 0),
          subtype: FeedingSubtype.sein,
          duration: 20,
        );
        final newEvent = SleepEvent(
          timestamp: DateTime(2024, 1, 1, 14, 0),
          duration: 60,
        );

        await repository.insertEvent(oldEvent);
        await repository.insertEvent(newEvent);

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(2));
        expect(result.first, newEvent);
        expect(result.last, oldEvent);
      });

      test('trie les événements par timestamp décroissant', () async {
        final olderEvent = FeedingEvent(
          timestamp: DateTime(2024, 1, 1),
          subtype: FeedingSubtype.bib,
          duration: 15,
        );
        final newerEvent = FeedingEvent(
          timestamp: DateTime(2024, 1, 2),
          subtype: FeedingSubtype.sein,
          duration: 25,
        );

        await repository.insertEvent(olderEvent);
        await repository.insertEvent(newerEvent);

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(2));
        // L'événement avec le timestamp le plus récent doit être en premier
        expect(result.first, newerEvent);
        expect(result.last, olderEvent);
      });
    });

    group('getEventsByType', () {
      test('retourne les événements d\'un type spécifique', () async {
        final feeding = FeedingEvent(
          timestamp: DateTime(2024, 1, 1),
          subtype: FeedingSubtype.sein,
          duration: 30,
        );
        final sleep = SleepEvent(
          timestamp: DateTime(2024, 1, 1),
          duration: 90,
        );
        final feeding2 = FeedingEvent(
          timestamp: DateTime(2024, 1, 2),
          subtype: FeedingSubtype.bib,
          duration: 20,
        );

        await repository.insertEvent(feeding);
        await repository.insertEvent(sleep);
        await repository.insertEvent(feeding2);

        final miams = await repository.getEventsByType(TrackingType.miam);
        expect(miams, hasLength(2));
        expect(miams.every((e) => e is FeedingEvent), isTrue);

        final dodos = await repository.getEventsByType(TrackingType.dodo);
        expect(dodos, hasLength(1));
        expect(dodos.first, sleep);
      });

      test('retourne une liste vide pour un type sans événements', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1),
          subtype: FeedingSubtype.sein,
          duration: 30,
        ));

        final santes = await repository.getEventsByType(TrackingType.sante);
        expect(santes, isEmpty);
      });

      test('filtre correctement tous les types', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1),
          subtype: FeedingSubtype.sein,
          duration: 30,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime(2024, 1, 1),
          duration: 60,
        ));
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime(2024, 1, 1),
          wasteType: WasteType.pipi,
        ));
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime(2024, 1, 1),
          subtype: HealthSubtype.vitamineD,
        ));

        expect((await repository.getEventsByType(TrackingType.miam)), hasLength(1));
        expect((await repository.getEventsByType(TrackingType.dodo)), hasLength(1));
        expect((await repository.getEventsByType(TrackingType.caca)), hasLength(1));
        expect((await repository.getEventsByType(TrackingType.sante)), hasLength(1));
      });
    });

    group('insertEvent', () {
      test('insère un FeedingEvent et retourne un ID', () async {
        final event = FeedingEvent(
          timestamp: DateTime(2024, 1, 1),
          subtype: FeedingSubtype.sein,
          duration: 30,
        );
        final id = await repository.insertEvent(event);

        expect(id, isA<int>());
        expect(id, greaterThan(0));
      });

      test('insère un SleepEvent', () async {
        final event = SleepEvent(
          timestamp: DateTime(2024, 1, 1),
          duration: 120,
        );
        final id = await repository.insertEvent(event);

        expect(id, isA<int>());
        expect((await repository.getAllEventsOrdered()), hasLength(1));
      });

      test('insère un DiaperEvent', () async {
        final event = DiaperEvent(
          timestamp: DateTime(2024, 1, 1),
          wasteType: WasteType.caca,
          cacaColor: cacaColorMeconium,
        );
        final id = await repository.insertEvent(event);

        expect(id, isA<int>());
      });

      test('insère un HealthEvent', () async {
        final event = HealthEvent(
          timestamp: DateTime(2024, 1, 1),
          subtype: HealthSubtype.vitamineK,
        );
        final id = await repository.insertEvent(event);

        expect(id, isA<int>());
      });

      test('accumule plusieurs événements', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.sein,
          duration: 20,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
        ));
        await repository.insertEvent(DiaperEvent(
          timestamp: DateTime(2024, 1, 1, 12),
          wasteType: WasteType.pipi,
        ));

        expect((await repository.getAllEventsOrdered()), hasLength(3));
      });
    });

    group('getLastEventByTypeAndSubtype', () {
      test('retourne null quand aucun événement ne correspond', () async {
        final result = await repository.getLastEventByTypeAndSubtype(TrackingType.sante);
        expect(result, isNull);
      });

      test('retourne le timestamp du dernier événement d\'un type', () async {
        final old = FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.sein,
          duration: 20,
        );
        final new_ = FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          subtype: FeedingSubtype.sein,
          duration: 25,
        );

        await repository.insertEvent(old);
        await repository.insertEvent(new_);

        final result = await repository.getLastEventByTypeAndSubtype(TrackingType.miam);
        expect(result, isNotNull);
        expect(result, new_.timestamp);
      });

      test('filtre par subtype pour FeedingEvent', () async {
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.sein,
          duration: 20,
        ));
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          subtype: FeedingSubtype.bib,
          duration: 30,
        ));

        final seinLast = await repository.getLastEventByTypeAndSubtype(
          TrackingType.miam,
          subtypeValue: 'sein',
        );
        expect(seinLast, isNotNull);
        expect(seinLast, DateTime(2024, 1, 1, 8));

        final bibLast = await repository.getLastEventByTypeAndSubtype(
          TrackingType.miam,
          subtypeValue: 'bib',
        );
        expect(bibLast, isNotNull);
        expect(bibLast, DateTime(2024, 1, 1, 14));
      });

      test('filtre par subtype pour HealthEvent', () async {
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: HealthSubtype.vitamineD,
        ));
        await repository.insertEvent(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          subtype: HealthSubtype.vitamineK,
        ));

        final vitDLast = await repository.getLastEventByTypeAndSubtype(
          TrackingType.sante,
          subtypeValue: 'vitamine_d',
        );
        expect(vitDLast, isNotNull);
        expect(vitDLast, DateTime(2024, 1, 1, 8));
      });

      test('retourne le plus récent parmi plusieurs événements du même type', () async {
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 6),
          duration: 60,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 12),
          duration: 90,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 20),
          duration: 120,
        ));

        final result = await repository.getLastEventByTypeAndSubtype(TrackingType.dodo);
        expect(result, DateTime(2024, 1, 1, 20));
      });
    });

    group('contrat complet', () {
      test('cycle complet: insert → filter → getLast → read all', () async {
        // Insert multiple events
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.sein,
          duration: 30,
        ));
        await repository.insertEvent(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 90,
        ));
        await repository.insertEvent(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          subtype: FeedingSubtype.bib,
          duration: 20,
        ));

        // Get all ordered
        final all = await repository.getAllEventsOrdered();
        expect(all, hasLength(3));
        expect(all.first.trackingType, TrackingType.miam); // bib at 14h

        // Get by type
        final miams = await repository.getEventsByType(TrackingType.miam);
        expect(miams, hasLength(2));

        // Get last by type
        final lastMiam = await repository.getLastEventByTypeAndSubtype(TrackingType.miam);
        expect(lastMiam, DateTime(2024, 1, 1, 14));

        // Verify still all present
        expect((await repository.getAllEventsOrdered()), hasLength(3));
      });
    });
  });
}

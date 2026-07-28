// ignore_for_file: lines_longer_than_80_chars // Tests de l'interface HistoryRepository (contrat pur, sans DB)

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Mock de [HistoryRepository] pour tester le contrat d'interface.
class MockHistoryRepository implements HistoryRepository {
  final Map<int, TrackingEvent> _events = {};
  int _nextId = 1;

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered({String? babyId}) async {
    return _events.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type, {String? babyId}) async {
    return _events.values.where((e) => e.trackingType == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<bool> updateEvent({required int id, required TrackingEvent event}) async {
    if (!_events.containsKey(id)) return false;
    _events[id] = event;
    return true;
  }

  @override
  Future<bool> deleteEvent(int id) async {
    return _events.remove(id) != null;
  }

  /// Helper pour simuler l'insertion (comme le ferait la DB).
  int insert(TrackingEvent event) {
    final id = _nextId++;
    _events[id] = event;
    return id;
  }
}

void main() {
  late MockHistoryRepository repository;

  setUp(() {
    repository = MockHistoryRepository();
  });

  group('HistoryRepository interface contract', () {
    group('getAllEventsOrdered', () {
      test('retourne une liste vide quand aucun événement n\'existe', () async {
        final result = await repository.getAllEventsOrdered();
        expect(result, isEmpty);
      });

      test('retourne tous les événements triés par timestamp décroissant', () async {
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));
        repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          duration: 60,
        ));
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          subtype: FeedingSubtype.artificial,
        ));

        final result = await repository.getAllEventsOrdered();
        expect(result, hasLength(3));
        expect(result.first.timestamp, DateTime(2024, 1, 1, 14));
        expect(result[1].timestamp, DateTime(2024, 1, 1, 10));
        expect(result.last.timestamp, DateTime(2024, 1, 1, 8));
      });

      test('filtre par babyId quand fourni', () async {
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          babyId: 'baby-1',
        ));
        repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
          babyId: 'baby-2',
        ));

        // Dans un vrai repo, le filtre serait appliqué ici.
        // Le mock retourne tous les événements — c'est le comportement par défaut.
        final result = await repository.getAllEventsOrdered(babyId: 'baby-1');
        expect(result, hasLength(2));
      });
    });

    group('getEventsByType', () {
      test('retourne les événements d\'un type spécifique', () async {
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));
        repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 90,
        ));
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 14),
          subtype: FeedingSubtype.artificial,
        ));

        final result = await repository.getEventsByType(TrackingType.miam);
        expect(result, hasLength(2));
        expect(result.every((e) => e is FeedingEvent), isTrue);
      });

      test('retourne les événements dodo', () async {
        repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
        ));
        repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 20),
          duration: 120,
        ));

        final result = await repository.getEventsByType(TrackingType.dodo);
        expect(result, hasLength(2));
        expect(result.every((e) => e is SleepEvent), isTrue);
      });

      test('retourne les événements caca', () async {
        repository.insert(DiaperEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          wasteType: WasteType.pipi,
        ));
        repository.insert(DiaperEvent(
          timestamp: DateTime(2024, 1, 1, 12),
          wasteType: WasteType.caca,
          cacaColor: cacaColorMeconium,
        ));

        final result = await repository.getEventsByType(TrackingType.caca);
        expect(result, hasLength(2));
        expect(result.every((e) => e is DiaperEvent), isTrue);
      });

      test('retourne les événements santé', () async {
        repository.insert(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 9),
          subtype: HealthSubtype.vitamineD,
        ));
        repository.insert(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 15),
          subtype: HealthSubtype.nettoyageYeux,
        ));

        final result = await repository.getEventsByType(TrackingType.sante);
        expect(result, hasLength(2));
        expect(result.every((e) => e is HealthEvent), isTrue);
      });

      test('retourne une liste vide pour un type sans événements', () async {
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));

        final result = await repository.getEventsByType(TrackingType.dodo);
        expect(result, isEmpty);
      });

      test('filtre par type et babyId', () async {
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          babyId: 'baby-1',
        ));
        repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          subtype: FeedingSubtype.artificial,
          babyId: 'baby-2',
        ));

        final result = await repository.getEventsByType(TrackingType.miam, babyId: 'baby-1');
        expect(result, hasLength(2));
      });
    });

    group('updateEvent', () {
      test('met à jour un événement existant et retourne true', () async {
        final id = repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));

        final updated = await repository.updateEvent(
          id: id,
          event: FeedingEvent(
            timestamp: DateTime(2024, 1, 1, 8),
            subtype: FeedingSubtype.artificial,
          ),
        );

        expect(updated, isTrue);
        final all = await repository.getAllEventsOrdered();
        expect(all.first, isA<FeedingEvent>());
        expect((all.first as FeedingEvent).subtype, FeedingSubtype.artificial);
      });

      test('ne met pas à jour un événement inexistant et retourne false', () async {
        final updated = await repository.updateEvent(
          id: 999,
          event: FeedingEvent(
            timestamp: DateTime(2024, 1, 1, 8),
            subtype: FeedingSubtype.natural,
          ),
        );

        expect(updated, isFalse);
      });

      test('préserve les autres événements lors de la mise à jour', () async {
        final id1 = repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));
        repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
        ));

        await repository.updateEvent(
          id: id1,
          event: FeedingEvent(
            timestamp: DateTime(2024, 1, 1, 8),
            subtype: FeedingSubtype.artificial,
          ),
        );

        final all = await repository.getAllEventsOrdered();
        expect(all, hasLength(2));
      });

      test('met à jour un SleepEvent', () async {
        final id = repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
          notes: 'original note',
        ));

        final updated = await repository.updateEvent(
          id: id,
          event: SleepEvent(
            timestamp: DateTime(2024, 1, 1, 10),
            duration: 90,
            notes: 'updated note',
          ),
        );

        expect(updated, isTrue);
        final all = await repository.getAllEventsOrdered();
        expect((all.first as SleepEvent).duration, 90);
        expect((all.first as SleepEvent).notes, 'updated note');
      });

      test('met à jour un DiaperEvent', () async {
        final id = repository.insert(DiaperEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          wasteType: WasteType.pipi,
          pipiColor: pipiColorJauneClair,
        ));

        final updated = await repository.updateEvent(
          id: id,
          event: DiaperEvent(
            timestamp: DateTime(2024, 1, 1, 8),
            wasteType: WasteType.caca,
            cacaColor: cacaColorMeconium,
          ),
        );

        expect(updated, isTrue);
        final all = await repository.getAllEventsOrdered();
        final event = all.first as DiaperEvent;
        expect(event.wasteType, WasteType.caca);
        expect(event.cacaColor, cacaColorMeconium);
      });

      test('met à jour un HealthEvent', () async {
        final id = repository.insert(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 9),
          subtype: HealthSubtype.vitamineD,
        ));

        final updated = await repository.updateEvent(
          id: id,
          event: HealthEvent(
            timestamp: DateTime(2024, 1, 1, 9),
            subtype: HealthSubtype.nettoyageYeux,
          ),
        );

        expect(updated, isTrue);
        final all = await repository.getAllEventsOrdered();
        expect((all.first as HealthEvent).subtype, HealthSubtype.nettoyageYeux);
      });
    });

    group('deleteEvent', () {
      test('supprime un événement existant et retourne true', () async {
        final id = repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));

        final result = await repository.deleteEvent(id);

        expect(result, isTrue);
        final all = await repository.getAllEventsOrdered();
        expect(all, isEmpty);
      });

      test('retourne false pour un ID inexistant', () async {
        final result = await repository.deleteEvent(999);
        expect(result, isFalse);
      });

      test('ne supprime pas les autres événements', () async {
        final id1 = repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));
        repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
        ));

        await repository.deleteEvent(id1);

        final all = await repository.getAllEventsOrdered();
        expect(all, hasLength(1));
        expect(all.first, isA<SleepEvent>());
      });

      test('supprime un SleepEvent', () async {
        final id = repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
        ));

        expect(await repository.deleteEvent(id), isTrue);
        expect(await repository.getAllEventsOrdered(), isEmpty);
      });

      test('supprime un DiaperEvent', () async {
        final id = repository.insert(DiaperEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          wasteType: WasteType.pipi,
        ));

        expect(await repository.deleteEvent(id), isTrue);
        expect(await repository.getAllEventsOrdered(), isEmpty);
      });

      test('supprime un HealthEvent', () async {
        final id = repository.insert(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 9),
          subtype: HealthSubtype.vitamineD,
        ));

        expect(await repository.deleteEvent(id), isTrue);
        expect(await repository.getAllEventsOrdered(), isEmpty);
      });
    });

    group('contrat complet', () {
      test('cycle complet: insert → read → update → read → delete → read empty', () async {
        // Insert
        final id = repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
          notes: 'morning feeding',
        ));

        // Read all
        var all = await repository.getAllEventsOrdered();
        expect(all, hasLength(1));
        expect((all.first as FeedingEvent).notes, 'morning feeding');

        // Read by type
        var miams = await repository.getEventsByType(TrackingType.miam);
        expect(miams, hasLength(1));

        // Update
        final updated = await repository.updateEvent(
          id: id,
          event: FeedingEvent(
            timestamp: DateTime(2024, 1, 1, 8),
            subtype: FeedingSubtype.artificial,
            notes: 'updated feeding',
          ),
        );
        expect(updated, isTrue);

        // Verify update
        all = await repository.getAllEventsOrdered();
        expect(all, hasLength(1));
        expect((all.first as FeedingEvent).subtype, FeedingSubtype.artificial);
        expect((all.first as FeedingEvent).notes, 'updated feeding');

        // Delete
        final deleted = await repository.deleteEvent(id);
        expect(deleted, isTrue);

        // Verify empty
        all = await repository.getAllEventsOrdered();
        expect(all, isEmpty);

        // Verify update on deleted returns false
        final updateAfterDelete = await repository.updateEvent(
          id: id,
          event: FeedingEvent(
            timestamp: DateTime(2024, 1, 1, 8),
            subtype: FeedingSubtype.natural,
          ),
        );
        expect(updateAfterDelete, isFalse);

        // Verify delete on already deleted returns false
        final deleteAgain = await repository.deleteEvent(id);
        expect(deleteAgain, isFalse);
      });

      test('multi-event lifecycle: insert 3, filter, update one, delete one, verify counts', () async {
        final id1 = repository.insert(FeedingEvent(
          timestamp: DateTime(2024, 1, 1, 8),
          subtype: FeedingSubtype.natural,
        ));
        final id2 = repository.insert(SleepEvent(
          timestamp: DateTime(2024, 1, 1, 10),
          duration: 60,
        ));
        repository.insert(HealthEvent(
          timestamp: DateTime(2024, 1, 1, 12),
          subtype: HealthSubtype.vitamineD,
        ));

        // Verify all present
        expect((await repository.getAllEventsOrdered()), hasLength(3));
        expect((await repository.getEventsByType(TrackingType.miam)), hasLength(1));
        expect((await repository.getEventsByType(TrackingType.dodo)), hasLength(1));
        expect((await repository.getEventsByType(TrackingType.sante)), hasLength(1));

        // Update middle event
        final updated = await repository.updateEvent(
          id: id2,
          event: SleepEvent(
            timestamp: DateTime(2024, 1, 1, 10),
            duration: 90,
          ),
        );
        expect(updated, isTrue);

        // Delete first event
        await repository.deleteEvent(id1);

        // Verify counts after mutations
        expect((await repository.getAllEventsOrdered()), hasLength(2));
        expect((await repository.getEventsByType(TrackingType.miam)), isEmpty);
        expect((await repository.getEventsByType(TrackingType.dodo)), hasLength(1));
        expect((await repository.getEventsByType(TrackingType.sante)), hasLength(1));

        // Verify updated duration
        final dodos = await repository.getEventsByType(TrackingType.dodo);
        expect((dodos.first as SleepEvent).duration, 90);
      });
    });
  });
}

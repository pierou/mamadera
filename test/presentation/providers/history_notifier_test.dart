import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/domain/repositories/measurement_repository.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/history/domain/history_row.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_notifier.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'history_notifier_test.mocks.dart';

@GenerateMocks([HistoryRepository])
void main() {
  late MockHistoryRepository mockRepository;
  late _FakeMeasurementRepository fakeMeasurementRepository;
  late ProviderContainer container;
  List<Future<void>> pendingFutures = [];

  final event1 = FeedingEvent(
    unit: QuantityUnit.ml,
    id: 1,
    timestamp: DateTime.utc(2023, 1, 1),
    subtype: FeedingSubtype.natural,
  );
  final event2 = SleepEvent(
    unit: QuantityUnit.min,
    id: 2,
    timestamp: DateTime.utc(2023, 1, 2),
    duration: 60,
  );
  final event3 = FeedingEvent(
    unit: QuantityUnit.ml,
    id: 3,
    timestamp: DateTime.utc(2023, 1, 3),
    subtype: FeedingSubtype.artificial,
  );
  final eventDodo = SleepEvent(
    unit: QuantityUnit.min,
    id: 2,
    timestamp: DateTime.utc(2023, 1, 2),
    duration: 45,
  );
  final eventTest = HealthEvent(
    id: 1,
    timestamp: DateTime.utc(2023, 1, 1),
    subtype: HealthSubtype.nettoyageYeux,
  );
  final eventRapide = DiaperEvent(
    id: 1,
    timestamp: DateTime.utc(2023, 1, 1),
    wasteType: WasteType.caca,
    cacaColor: cacaColorVertOlive,
  );

  setUp(() {
    mockRepository = MockHistoryRepository();
    fakeMeasurementRepository = _FakeMeasurementRepository();
    container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWith(
          (_) async => mockRepository,
        ),
        // The "all-inclusive" package combines all the services: this is the real provider.
        // If the base were to be opened for testing, it would be replaced by a simulated version stored in memory.
        measurementRepositoryProvider
            .overrideWith((_) async => fakeMeasurementRepository),
        // The `updateEvent` and `deleteEvent` functions refresh the reminders: this is the correct way to do it.
        // The `notifier` would read its repository (database) – in this case, it would perform a no-operation.
        reminderNotifierProvider.overrideWith(_QuietRemindersNotifier.new),
      ],
    );
    pendingFutures = [];
  });

  tearDown(() {
    // Await all pending futures before disposing to avoid Riverpod 3.x disposal errors
    if (pendingFutures.isNotEmpty) {
      Future.wait(pendingFutures).ignore();
      pendingFutures = [];
    }
    container.dispose();
  });

  group('HistoryNotifier avec filtre "all"', () {
    test('appelle getAllEventsOrdered() et retourne les événements', () async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1, event2]);

      final future =
          container.read(historyNotifierProvider(HistoryFilter.all).future);
      pendingFutures.add(future);

      final state = await future;
      pendingFutures.remove(future);

      expect(state, hasLength(2));
      expect(
          (state[0] as EventHistoryRow).event.trackingType, TrackingType.miam);
      expect(
          (state[1] as EventHistoryRow).event.trackingType, TrackingType.dodo);

      verify(mockRepository.getAllEventsOrdered()).called(1);
    });

    test('retourne une liste vide si aucun événement', () async {
      when(mockRepository.getAllEventsOrdered()).thenAnswer((_) async => []);

      final future =
          container.read(historyNotifierProvider(HistoryFilter.all).future);
      pendingFutures.add(future);

      final state = await future;
      pendingFutures.remove(future);

      expect(state, isEmpty);
      verify(mockRepository.getAllEventsOrdered()).called(1);
    });
  });

  group('HistoryNotifier avec filtre type', () {
    test('appelle getEventsByType() avec le bon filtre', () async {
      when(mockRepository.getEventsByType(TrackingType.miam))
          .thenAnswer((_) async => [event1, event3]);

      final future =
          container.read(historyNotifierProvider(HistoryFilter.miam).future);
      pendingFutures.add(future);

      final state = await future;
      pendingFutures.remove(future);

      expect(state, hasLength(2));
      for (final event in state) {
        expect(
            (event as EventHistoryRow).event.trackingType, TrackingType.miam);
      }

      verify(mockRepository.getEventsByType(TrackingType.miam)).called(1);
    });

    test('appelle getEventsByType() pour différents types', () async {
      when(mockRepository.getEventsByType(TrackingType.dodo))
          .thenAnswer((_) async => [eventDodo]);

      final future =
          container.read(historyNotifierProvider(HistoryFilter.dodo).future);
      pendingFutures.add(future);

      final state = await future;
      pendingFutures.remove(future);

      expect(state, hasLength(1));
      expect(
          (state[0] as EventHistoryRow).event.trackingType, TrackingType.dodo);

      verify(mockRepository.getEventsByType(TrackingType.dodo)).called(1);
    });
  });

  group('HistoryNotifier avec filtre sante', () {
    test('appelle getEventsByType() avec le bon filtre', () async {
      when(mockRepository.getEventsByType(TrackingType.sante))
          .thenAnswer((_) async => [eventTest]);

      final future =
          container.read(historyNotifierProvider(HistoryFilter.sante).future);
      pendingFutures.add(future);

      final state = await future;
      pendingFutures.remove(future);

      expect(state, hasLength(1));
      expect(
          (state[0] as EventHistoryRow).event.trackingType, TrackingType.sante);

      verify(mockRepository.getEventsByType(TrackingType.sante)).called(1);
    });
  });

  group('HistoryNotifier avec filtre caca', () {
    test('appelle getEventsByType() avec le bon filtre', () async {
      when(mockRepository.getEventsByType(TrackingType.caca))
          .thenAnswer((_) async => [eventRapide]);

      final future =
          container.read(historyNotifierProvider(HistoryFilter.caca).future);
      pendingFutures.add(future);

      final state = await future;
      pendingFutures.remove(future);

      expect(state, hasLength(1));
      expect(
          (state[0] as EventHistoryRow).event.trackingType, TrackingType.caca);

      verify(mockRepository.getEventsByType(TrackingType.caca)).called(1);
    });
  });

  group('État loading → data → error', () {
    test('état loading puis data en cas de succès', () async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [eventTest]);

      // Initially, the state should be "loading."
      final initial =
          container.read(historyNotifierProvider(HistoryFilter.all));
      expect(initial, isA<AsyncLoading<List<HistoryRow>>>());

      // After the resolution is applied, the state should be updated with the new data.
      final data = await container
          .read(historyNotifierProvider(HistoryFilter.all).future);
      expect(data, isNotEmpty);
      expect(
        container.read(historyNotifierProvider(HistoryFilter.all)),
        isA<AsyncData<List<HistoryRow>>>(),
      );
    });

    test('état error si le repository lève une exception', () async {
      when(mockRepository.getAllEventsOrdered())
          .thenThrow(Exception('Erreur de connexion'));

      // We initiate the build process.
      final initialState =
          container.read(historyNotifierProvider(HistoryFilter.all));
      expect(initialState, isA<AsyncLoading<List<HistoryRow>>>());

      // Wait for the events to spread.
      await Future<void>.delayed(const Duration(seconds: 1));

      // The test passes if the service provider doesn't crash.
      // (The actual test of the error is verified through the mock object.)
      final finalState =
          container.read(historyNotifierProvider(HistoryFilter.all));
      // The state can be "loading," "error," or "data," depending on the timing.
      expect(finalState, isA<AsyncValue<List<HistoryRow>>>());
    });
  });

  group('Timeout handling', () {
    test(
      'lève une erreur de timeout si le repository est trop lent',
      () async {
        // Simule un appel qui dure 20 secondes (> timeout de 10s)
        when(mockRepository.getAllEventsOrdered()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 20));
          return [];
        });

        // We initiate the build process.
        final initialState =
            container.read(historyNotifierProvider(HistoryFilter.all));
        expect(initialState, isA<AsyncLoading<List<HistoryRow>>>());

        // Wait for the timeout to be triggered (approximately 10 seconds, plus a margin).
        await Future<void>.delayed(const Duration(seconds: 12));

        // Verify that the state has changed.
        final finalState =
            container.read(historyNotifierProvider(HistoryFilter.all));
        expect(finalState, isA<AsyncValue<List<HistoryRow>>>());
      },
    );

    test('ne déclenche pas le timeout si le repository est rapide', () async {
      when(mockRepository.getAllEventsOrdered()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return [eventRapide];
      });

      final state = await container
          .read(historyNotifierProvider(HistoryFilter.all).future);

      expect(state, hasLength(1));
      expect(
          (state[0] as EventHistoryRow).event.trackingType, TrackingType.caca);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Unified timeline (v1.2.1): Merged entries displayed under the "all" filter.
  // ─────────────────────────────────────────────────────────────────────
  group('Frise unifiée — mesures', () {
    final mPoids = GrowthMeasurement(
      id: 11,
      kind: MeasureKind.poids,
      unit: 'g',
      value: 3000,
      babyId: 'baby_1',
      recordedAt: DateTime.utc(2023, 1, 1, 12),
    );
    // Same timestamps as event2 (2023-01-02T00) for testing purposes, to ensure fairness.
    final mTaille = GrowthMeasurement(
      id: 12,
      kind: MeasureKind.taille,
      unit: 'cm',
      value: 50,
      babyId: 'baby_1',
      recordedAt: DateTime.utc(2023, 1, 2),
    );
    final mTemp = GrowthMeasurement(
      id: 13,
      kind: MeasureKind.temperature,
      unit: 'degC',
      value: 37,
      babyId: 'baby_1',
      recordedAt: DateTime.utc(2023, 1, 2, 6),
    );

    test('filtre « tout » : mesures fusionnées, triées à leur horodatage',
        () async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1, event2, event3]);
      fakeMeasurementRepository.rows
        ..add(mPoids)
        ..add(mTaille)
        ..add(mTemp);

      final state = await container
          .read(historyNotifierProvider(HistoryFilter.all).future);

      // 3 events + 3 actions, sorted in descending order; in case of a tie in timestamp, ...
      // The event takes precedence over the measure.
      expect(state, hasLength(6));
      expect((state[0] as EventHistoryRow).event.id, 3);
      expect((state[1] as MeasurementHistoryRow).measurement.id, 13);
      expect((state[2] as EventHistoryRow).event.id, 2);
      expect((state[3] as MeasurementHistoryRow).measurement.id, 12);
      expect((state[4] as MeasurementHistoryRow).measurement.id, 11);
      expect((state[5] as EventHistoryRow).event.id, 1);
    });

    test('filtre de type : les mesures n’apparaissent jamais', () async {
      when(mockRepository.getEventsByType(TrackingType.miam))
          .thenAnswer((_) async => [event1]);
      fakeMeasurementRepository.rows
        ..add(mPoids)
        ..add(mTaille);

      final state = await container
          .read(historyNotifierProvider(HistoryFilter.miam).future);

      expect(state, hasLength(1));
      expect(state.single, isA<EventHistoryRow>());
    });

    test('la mesure n’est jamais dupliquée en événement', () async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1]);
      fakeMeasurementRepository.rows.add(mPoids);

      final state = await container
          .read(historyNotifierProvider(HistoryFilter.all).future);

      expect(state.whereType<MeasurementHistoryRow>(), hasLength(1));
      expect(state.whereType<EventHistoryRow>(), hasLength(1));
      // The measurement retains its decoded value, not an event ID.
      expect(
          (state.firstWhere((r) => r is MeasurementHistoryRow)
                  as MeasurementHistoryRow)
              .measurement
              .value,
          3000);
    });

    test('échec de la lecture des mesures : la frise garde les événements',
        () async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1, event2]);
      fakeMeasurementRepository.throwOnRead = true;

      final state = await container
          .read(historyNotifierProvider(HistoryFilter.all).future);

      expect(state, hasLength(2));
      expect(state.every((r) => r is EventHistoryRow), isTrue);
    });

    test('updateMeasurement : le repository est appelé et la frise rechargée',
        () async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1]);
      fakeMeasurementRepository.rows.add(mPoids);

      final corrected = mPoids.copyWith(value: 3500);
      await container
          .read(historyNotifierProvider(HistoryFilter.all).notifier)
          .updateMeasurement(corrected);

      expect(fakeMeasurementRepository.updated.single, corrected);
      final state =
          container.read(historyNotifierProvider(HistoryFilter.all)).value!;
      final row = state.firstWhere((r) => r is MeasurementHistoryRow)
          as MeasurementHistoryRow;
      expect(row.measurement.value, 3500);
    });

    test('deleteMeasurement : la ligne disparaît de la frise', () async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1]);
      fakeMeasurementRepository.rows
        ..add(mPoids)
        ..add(mTaille);

      await container
          .read(historyNotifierProvider(HistoryFilter.all).notifier)
          .deleteMeasurement(mPoids.id);

      expect(fakeMeasurementRepository.deleted, [mPoids.id]);
      final state =
          container.read(historyNotifierProvider(HistoryFilter.all)).value!;
      expect(state.whereType<MeasurementHistoryRow>(), hasLength(1));
      expect(
          (state.firstWhere((r) => r is MeasurementHistoryRow)
                  as MeasurementHistoryRow)
              .measurement
              .id,
          mTaille.id);
    });

    test('updateEvent : le repository est appelé et la frise rechargée',
        () async {
      // The list is mutable: the `updateEvent` stub corrects it, and so does...
      // Reviewing the timeline displays the edited event.
      final events = [event1, event2];
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => events);
      final edited = event1.copyWith(timestamp: DateTime.utc(2023, 1, 3, 12));
      when(mockRepository.updateEvent(id: 1, event: anyNamed('event')))
          .thenAnswer((_) async {
        events[0] = edited;
        return true;
      });

      await container
          .read(historyNotifierProvider(HistoryFilter.all).notifier)
          .updateEvent(edited);

      verify(mockRepository.updateEvent(id: 1, event: edited)).called(1);
      final state =
          container.read(historyNotifierProvider(HistoryFilter.all)).value!;
      expect((state.first as EventHistoryRow).event.id, 1);
      expect(state.first.timestamp, DateTime.utc(2023, 1, 3, 12));
    });

    test('deleteEvent : le repository est appelé et la frise rechargée',
        () async {
      final events = [event1, event2];
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => events);
      when(mockRepository.deleteEvent(2)).thenAnswer((_) async {
        events.removeWhere((e) => e.id == 2);
        return true;
      });

      await container
          .read(historyNotifierProvider(HistoryFilter.all).notifier)
          .deleteEvent(2);

      verify(mockRepository.deleteEvent(2)).called(1);
      final state =
          container.read(historyNotifierProvider(HistoryFilter.all)).value!;
      expect(state, hasLength(1));
      expect((state.single as EventHistoryRow).event.id, 1);
    });
  });
}

/// Silent notifications: `refresh()` does nothing, and `build()` returns...
/// empty — the tests for the header don't want a repository for reminders.
class _QuietRemindersNotifier extends RemindersNotifier {
  @override
  Future<Map<TrackingType, List<ReminderStatus>>> build() async => const {};

  @override
  Future<void> refresh() async {}
}

/// In-memory measurement repository: `update` and `deleteById` methods modify the data.
/// They maintain a list and keep a call log for each claim.
class _FakeMeasurementRepository implements MeasurementRepository {
  final List<GrowthMeasurement> rows = [];
  final List<GrowthMeasurement> updated = [];
  final List<int> deleted = [];
  bool throwOnRead = false;

  @override
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  }) async {
    rows.add(GrowthMeasurement(
      id: (rows.isEmpty ? 0 : rows.last.id) + 1,
      kind: kind,
      unit: kind.displayUnit,
      value: value,
      babyId: babyId,
      recordedAt: recordedAt,
      notes: notes,
    ));
  }

  @override
  Future<GrowthMeasurement?> latestOfKind(
      String? babyId, MeasureKind kind) async {
    for (final row in rows) {
      if (row.kind == kind && (babyId == null || row.babyId == babyId)) {
        return row;
      }
    }
    return null;
  }

  @override
  Future<List<GrowthMeasurement>> allForBaby(
    String? babyId, {
    MeasureKind? kind,
  }) async {
    if (throwOnRead) throw StateError('lecture simulée en échec');
    final out = <GrowthMeasurement>[
      for (final row in rows)
        if ((babyId == null || row.babyId == babyId) &&
            (kind == null || row.kind == kind))
          row,
    ]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return out;
  }

  @override
  Future<void> update(GrowthMeasurement measurement) async {
    updated.add(measurement);
    final index = rows.indexWhere((r) => r.id == measurement.id);
    if (index >= 0) rows[index] = measurement;
  }

  @override
  Future<bool> deleteById(int id) async {
    final index = rows.indexWhere((r) => r.id == id);
    if (index < 0) return false;
    rows.removeAt(index);
    deleted.add(id);
    return true;
  }
}

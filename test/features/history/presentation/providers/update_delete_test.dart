import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/domain/history_row.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
// @GenerateNiceMocks allows unstubbed calls to return default values.
// Instead of raising a `MissingStubError`, this is useful because `updateEvent()` passes all named parameters.
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_delete_test.mocks.dart';

@GenerateNiceMocks([MockSpec<HistoryRepository>()])
void main() {
  late MockHistoryRepository mockRepository;
  late ProviderContainer container;
  List<Future<void>> pendingFutures = [];

  // Synthetic fixtures: simple round IDs, basic timestamps – using typed subtypes.
  final event1 = FeedingEvent(
    unit: QuantityUnit.ml,
    id: 10,
    timestamp: DateTime.utc(2024, 1, 1),
    subtype: FeedingSubtype.natural,
  );
  final event2 = SleepEvent(
    unit: QuantityUnit.min,
    id: 20,
    timestamp: DateTime.utc(2024, 1, 2),
    duration: 60,
  );

  setUp(() {
    mockRepository = MockHistoryRepository();
    container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWith((_) async => mockRepository),
      ],
    );
    pendingFutures = [];

    // Use addTearDown to properly await async work before disposing
    // This runs AFTER the test completes but BEFORE any tearDown
    addTearDown(() async {
      if (pendingFutures.isNotEmpty) {
        await Future.wait(pendingFutures);
        pendingFutures = [];
      }
      container.dispose();
    });
  });

  group('updateEvent()', () {
    test('succès → transition loading→data (filtre all)', () async {
      when(mockRepository.updateEvent(
              id: anyNamed('id'), event: anyNamed('event')))
          .thenAnswer((_) async => true);
      final updated = FeedingEvent(
        unit: QuantityUnit.ml,
        id: 10,
        timestamp: DateTime.utc(2024, 6, 1),         // Timestamp modified.
        subtype: FeedingSubtype.natural,
      );

      var callCount = 0;
      when(mockRepository.getAllEventsOrdered()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [event1]; // Initial build
        return [updated]; // Post-update refresh
      });

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.all).notifier,
      );
      await notifier.future; // Build initial stable

      // Initiate the update without waiting → change the state to "AsyncLoading."
      final updateFuture = notifier.updateEvent(updated);
      pendingFutures.add(updateFuture);

      // Immediately after the request: loading state (the first `state = const AsyncLoading()` is synchronous).
      expect(
        container.read(historyNotifierProvider(HistoryFilter.all)),
        isA<AsyncLoading<List<HistoryRow>>>(),
      );

      await updateFuture;       // Wait for the operation to finish.
      pendingFutures.remove(updateFuture);

      // Post-waiting state: data state with a refreshed list containing the modified event.
      final state = container.read(historyNotifierProvider(HistoryFilter.all));
      expect(state, isA<AsyncData<List<HistoryRow>>>());
      expect((state as AsyncData).value, hasLength(1));
      expect(state.value![0].timestamp, updated.timestamp);
    });

    test('succès → transition loading→data (filtre type miam)', () async {
      when(mockRepository.updateEvent(
              id: anyNamed('id'), event: anyNamed('event')))
          .thenAnswer((_) async => true);
      final updated = FeedingEvent(
        unit: QuantityUnit.ml,
        id: 10,
        timestamp: DateTime.utc(2024, 3, 1),
        subtype: FeedingSubtype.natural,
        notes: 'note ajoutée',
      );

      var callCount = 0;
      when(mockRepository.getEventsByType(TrackingType.miam))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [event1];         // Initial filtered build, yum!
        return [updated];         // Filtered refresh after update.
      });

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.miam).notifier,
      );
      await notifier.future;

      final updateFuture = notifier.updateEvent(updated);
      pendingFutures.add(updateFuture);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.miam)),
        isA<AsyncLoading<List<HistoryRow>>>(),
      );

      await updateFuture;       // Wait for the operation to finish.
      pendingFutures.remove(updateFuture);

      // The "refresh post-update" feature used the `getEventsByType` function, respecting the specified filter.
      verify(mockRepository.getEventsByType(TrackingType.miam))
          .called(greaterThan(1));
    });

    test('erreur repo → AsyncError avec message préservé', () async {
      // The notifier passes the complete event data to the `updateEvent` function.
      when(mockRepository.updateEvent(
              id: anyNamed('id'), event: anyNamed('event')))
          .thenThrow(Exception('Erreur réseau'));

      final santeEvent = HealthEvent(
        id: 50,
        timestamp: DateTime.utc(2024, 1, 1),
        subtype: HealthSubtype.nettoyageYeux,
        notes: 'vaccin',
      );

      // Build an initial, stable version before any update errors occur.
      when(mockRepository.getEventsByType(TrackingType.sante))
          .thenAnswer((_) async => [santeEvent]);
      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.sante).notifier,
      );
      await notifier.future;

      // Initiate the update process, knowing it will fail → capture the screen to observe the transitions.
      final updateFuture = notifier.updateEvent(santeEvent);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.sante)),
        isA<AsyncLoading<List<HistoryRow>>>(),
      );

      await updateFuture; // AsyncValue.guard capture l'exception → AsyncError

      final state =
          container.read(historyNotifierProvider(HistoryFilter.sante));
      expect(state, isA<AsyncError<List<HistoryRow>>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Erreur réseau'),
      );
    });
  });

  group('deleteEvent()', () {
    test('succès → transition loading→data (filtre all)', () async {
      when(mockRepository.deleteEvent(any)).thenAnswer((_) async => true);

      var callCount = 0;
      when(mockRepository.getAllEventsOrdered()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [event1, event2]; // Initial build : 2 events
        return [
          event1
        ];         // Post-deletion refresh: only the event that was not deleted remains.
      });

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.all).notifier,
      );
      await notifier.future;

      // Initiate the deletion without delay → set the synchronous state to AsyncLoading.
      final deleteFuture = notifier.deleteEvent(event2.id!);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.all)),
        isA<AsyncLoading<List<HistoryRow>>>(),
      );

      await deleteFuture;       // Wait for the operation to finish.

      final state = container.read(historyNotifierProvider(HistoryFilter.all));
      expect(state, isA<AsyncData<List<HistoryRow>>>());
      // The event that was removed is no longer in the updated list.
      expect((state as AsyncData).value, hasLength(1));
      expect((state.value!.first as EventHistoryRow).event.id, event1.id);

      verify(mockRepository.deleteEvent(event2.id!)).called(1);
    });

    test('succès → transition loading→data (filtre type dodo)', () async {
      when(mockRepository.deleteEvent(any)).thenAnswer((_) async => true);
      final remaining = SleepEvent(
        unit: QuantityUnit.min,
        id: 30,
        timestamp: DateTime.utc(2024, 1, 3),
        duration: 45,
      );

      var callCount = 0;
      when(mockRepository.getEventsByType(TrackingType.dodo))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [event2, remaining]; // Initial : 2 dodos
        return [remaining]; // Post-delete : seul l'autre dodo reste
      });

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.dodo).notifier,
      );
      await notifier.future;

      // Initiate the deletion without delay → set the synchronous state to AsyncLoading.
      final deleteFuture = notifier.deleteEvent(event2.id!);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.dodo)),
        isA<AsyncLoading<List<HistoryRow>>>(),
      );

      await deleteFuture;       // Wait for the operation to finish.

      final state = container.read(historyNotifierProvider(HistoryFilter.dodo));
      expect(state, isA<AsyncData<List<HistoryRow>>>());
      // The post-deletion refresh successfully used the "dodo" filter (getEventsByType).
      verify(mockRepository.getEventsByType(TrackingType.dodo))
          .called(greaterThan(1));
    });

    test('erreur repo → AsyncError avec message préservé', () async {
      when(mockRepository.deleteEvent(any)).thenThrow(Exception('DB locked'));

      // Build a stable initial version before any potential deletion errors.
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1]);

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.all).notifier,
      );
      await notifier.future;

      // Initiate the deletion process, which will fail → capture the subsequent events to observe the transitions.
      final deleteFuture = notifier.deleteEvent(event1.id!);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.all)),
        isA<AsyncLoading<List<HistoryRow>>>(),
      );

      await deleteFuture; // AsyncValue.guard capture l'exception → AsyncError

      final state = container.read(historyNotifierProvider(HistoryFilter.all));
      expect(state, isA<AsyncError<List<HistoryRow>>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('DB locked'),
      );

      verify(mockRepository.deleteEvent(event1.id!)).called(1);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
// @GenerateNiceMocks permet aux appels non-stubbés de retourner des valeurs par défaut
// au lieu de lever MissingStubError — utile car updateEvent() passe tous les params nommés.
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_delete_test.mocks.dart';

@GenerateNiceMocks([MockSpec<HistoryRepository>()])
void main() {
  late MockHistoryRepository mockRepository;
  late ProviderContainer container;
  List<Future<void>> pendingFutures = [];

  // Fixtures synthétiques : id ronds, timestamps simples — using typed subtypes
  final event1 = FeedingEvent(
    id: 10,
    timestamp: DateTime.utc(2024, 1, 1),
    subtype: FeedingSubtype.sein,
    duration: 15,
  );
  final event2 = SleepEvent(
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
      when(mockRepository.updateEvent(id: anyNamed('id'), event: anyNamed('event')))
          .thenAnswer((_) async => true);
      final updated = FeedingEvent(
        id: 10,
        timestamp: DateTime.utc(2024, 6, 1), // Timestamp modifié
        subtype: FeedingSubtype.sein,
        duration: 30, // Durée augmentée
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

      // Lancer l'update sans attendre → state synchrone set à AsyncLoading
      final updateFuture = notifier.updateEvent(updated);
      pendingFutures.add(updateFuture);

      // Immédiatement après appel : état loading (le premier `state = const AsyncLoading()` est synchrone)
      expect(
        container.read(historyNotifierProvider(HistoryFilter.all)),
        isA<AsyncLoading<List<TrackingEvent>>>(),
      );

      await updateFuture; // Attendre la fin de l'opération
      pendingFutures.remove(updateFuture);

      // Post-attente : état data avec liste refreshée contenant l'événement modifié
      final state = container.read(historyNotifierProvider(HistoryFilter.all));
      expect(state, isA<AsyncData<List<TrackingEvent>>>());
      expect((state as AsyncData).value, hasLength(1));
      expect(state.value![0].timestamp, updated.timestamp);
    });

    test('succès → transition loading→data (filtre type miam)', () async {
      when(mockRepository.updateEvent(id: anyNamed('id'), event: anyNamed('event')))
          .thenAnswer((_) async => true);
      final updated = FeedingEvent(
        id: 10,
        timestamp: DateTime.utc(2024, 3, 1),
        subtype: FeedingSubtype.sein,
        duration: 25,
        notes: 'note ajoutée',
      );

      var callCount = 0;
      when(mockRepository.getEventsByType(TrackingType.miam)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [event1]; // Initial build filtré miam
        return [updated]; // Post-update refresh filtré
      });

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.miam).notifier,
      );
      await notifier.future;

      final updateFuture = notifier.updateEvent(updated);
      pendingFutures.add(updateFuture);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.miam)),
        isA<AsyncLoading<List<TrackingEvent>>>(),
      );

      await updateFuture; // Attendre la fin de l'opération
      pendingFutures.remove(updateFuture);

      // Refresh post-update a utilisé getEventsByType (filtre respecté)
      verify(mockRepository.getEventsByType(TrackingType.miam)).called(greaterThan(1));
    });

    test('erreur repo → AsyncError avec message préservé', () async {
      // Le notifier passe event complet à updateEvent.
      when(mockRepository.updateEvent(id: anyNamed('id'), event: anyNamed('event')))
          .thenThrow(Exception('Erreur réseau'));

      final santeEvent = HealthEvent(
        id: 50,
        timestamp: DateTime.utc(2024, 1, 1),
        subtype: HealthSubtype.nettoyageYeux,
        notes: 'vaccin',
      );

      // Build initial stable avant erreur de mise à jour
      when(mockRepository.getEventsByType(TrackingType.sante))
          .thenAnswer((_) async => [santeEvent]);
      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.sante).notifier,
      );
      await notifier.future;

      // Lancer l'update qui va échouer → capture la future pour observer transitions
      final updateFuture = notifier.updateEvent(santeEvent);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.sante)),
        isA<AsyncLoading<List<TrackingEvent>>>(),
      );

      await updateFuture; // AsyncValue.guard capture l'exception → AsyncError

      final state = container.read(historyNotifierProvider(HistoryFilter.sante));
      expect(state, isA<AsyncError<List<TrackingEvent>>>());
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
        return [event1]; // Post-delete refresh : seul l'évent non supprimé reste
      });

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.all).notifier,
      );
      await notifier.future;

      // Lancer la suppression sans attendre → state synchrone set à AsyncLoading
      final deleteFuture = notifier.deleteEvent(event2.id!);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.all)),
        isA<AsyncLoading<List<TrackingEvent>>>(),
      );

      await deleteFuture; // Attendre la fin de l'opération

      final state = container.read(historyNotifierProvider(HistoryFilter.all));
      expect(state, isA<AsyncData<List<TrackingEvent>>>());
      // L'événement supprimé n'est plus dans la liste refreshée
      expect((state as AsyncData).value, hasLength(1));
      expect(state.value!.first.id, event1.id);

      verify(mockRepository.deleteEvent(event2.id!)).called(1);
    });

    test('succès → transition loading→data (filtre type dodo)', () async {
      when(mockRepository.deleteEvent(any)).thenAnswer((_) async => true);
      final remaining = SleepEvent(
        id: 30,
        timestamp: DateTime.utc(2024, 1, 3),
        duration: 45,
      );

      var callCount = 0;
      when(mockRepository.getEventsByType(TrackingType.dodo)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [event2, remaining]; // Initial : 2 dodos
        return [remaining]; // Post-delete : seul l'autre dodo reste
      });

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.dodo).notifier,
      );
      await notifier.future;

      // Lancer la suppression sans attendre → state synchrone set à AsyncLoading
      final deleteFuture = notifier.deleteEvent(event2.id!);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.dodo)),
        isA<AsyncLoading<List<TrackingEvent>>>(),
      );

      await deleteFuture; // Attendre la fin de l'opération

      final state = container.read(historyNotifierProvider(HistoryFilter.dodo));
      expect(state, isA<AsyncData<List<TrackingEvent>>>());
      // Le refresh post-delete a bien utilisé le filtre dodo (getEventsByType)
      verify(mockRepository.getEventsByType(TrackingType.dodo)).called(greaterThan(1));
    });

    test('erreur repo → AsyncError avec message préservé', () async {
      when(mockRepository.deleteEvent(any))
          .thenThrow(Exception('DB locked'));

      // Build initial stable avant erreur de suppression
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => [event1]);

      final notifier = container.read(
        historyNotifierProvider(HistoryFilter.all).notifier,
      );
      await notifier.future;

      // Lancer la suppression qui va échouer → capture future pour observer transitions
      final deleteFuture = notifier.deleteEvent(event1.id!);

      expect(
        container.read(historyNotifierProvider(HistoryFilter.all)),
        isA<AsyncLoading<List<TrackingEvent>>>(),
      );

      await deleteFuture; // AsyncValue.guard capture l'exception → AsyncError

      final state = container.read(historyNotifierProvider(HistoryFilter.all));
      expect(state, isA<AsyncError<List<TrackingEvent>>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('DB locked'),
      );

      verify(mockRepository.deleteEvent(event1.id!)).called(1);
    });
  });
}

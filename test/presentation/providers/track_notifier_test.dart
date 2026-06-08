import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/home/presentation/providers/track_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'track_notifier_test.mocks.dart';

@GenerateMocks([TrackingRepository])
void main() {
  late MockTrackingRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockTrackingRepository();
    container = ProviderContainer(
      overrides: [
        trackingRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TrackNotifier.track()', () {
    test('appelle le repository avec les bons paramètres', () async {
      when(mockRepository.insertEvent(
        type: 'miam',
        timestamp: anyNamed('timestamp'),
        duration: 10,
        notes: 'notes de test',
      )).thenAnswer((_) async => 1);

      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: 'miam',
        duration: 10,
        notes: 'notes de test',
      );

      verify(
        mockRepository.insertEvent(
          type: 'miam',
          timestamp: anyNamed('timestamp'),
          duration: 10,
          notes: 'notes de test',
        ),
      ).called(1);
    });

    test('transition état loading → data en cas de succès', () async {
      when(mockRepository.insertEvent(
        type: 'dodo',
        timestamp: anyNamed('timestamp'),
        duration: anyNamed('duration'),
        notes: anyNamed('notes'),
      )).thenAnswer((_) async => 2);

      final notifier = container.read(trackNotifierProvider.notifier);

      // Lancer track() et attendre sa fin
      await notifier.track(type: 'dodo');

      // Donner à Riverpod le temps de notifier les listeners
      await Future<void>.delayed(Duration.zero);

      // Après succès, l'état est AsyncData
      final result = container.read(trackNotifierProvider);
      expect(result, isA<AsyncData<void>>());
    });

    test('transition état loading → error en cas d\'échec', () async {
      when(mockRepository.insertEvent(
        type: 'caca',
        timestamp: anyNamed('timestamp'),
        duration: null,
        notes: null,
      )).thenThrow(Exception('Erreur de base de données'));

      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(type: 'caca');

      final state = container.read(trackNotifierProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError<void>).error,
        isA<Exception>(),
      );
    });

    test('track() sans paramètres optionnels fonctionne', () async {
      when(mockRepository.insertEvent(
        type: 'sein',
        timestamp: anyNamed('timestamp'),
        duration: null,
        notes: null,
      )).thenAnswer((_) async => 3);

      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(type: 'sein');

      verify(
        mockRepository.insertEvent(
          type: 'sein',
          timestamp: anyNamed('timestamp'),
          duration: null,
          notes: null,
        ),
      ).called(1);

      expect(
        container.read(trackNotifierProvider),
        isA<AsyncData<void>>(),
      );
    });
  });
}

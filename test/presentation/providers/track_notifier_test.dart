import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/home/presentation/providers/track_notifier.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'track_notifier_test.mocks.dart';

@GenerateMocks([TrackingRepository])
void main() {
  late MockTrackingRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockTrackingRepository();
    // Stub par défaut : insertEvent retourne toujours un ID valide.
    when(
      mockRepository.insertEvent(
        type: anyNamed('type'),
        timestamp: anyNamed('timestamp'),
        duration: anyNamed('duration'),
        notes: anyNamed('notes'),
        wasteType: anyNamed('wasteType'),
        pipiColor: anyNamed('pipiColor'),
        cacaColor: anyNamed('cacaColor'),
        ),
    ).thenAnswer((_) async => 1);

    container = ProviderContainer(
      overrides: [
        trackingRepositoryProvider.overrideWithValue(AsyncData(mockRepository)),
      ],
      );
    });

  tearDown(() {
    container.dispose();
  });

  group('TrackNotifier.track()', () {
    test('appelle le repository avec les bons paramètres', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: TrackingType.miam,
        duration: 10,
        notes: 'notes de test',
      );

      verify(
        mockRepository.insertEvent(
          type: TrackingType.miam,
          timestamp: anyNamed('timestamp'),
          duration: 10,
          notes: 'notes de test',
          wasteType: null as WasteType?,
          pipiColor: null as PipiColor?,
          cacaColor: null as CacaColor?,
        ),
      ).called(1);
    });

    test('transition état loading → data en cas de succès', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(type: TrackingType.dodo);

      // Après succès, l'état est AsyncData.
      final result = container.read(trackNotifierProvider);
      expect(result, isA<AsyncData<void>>());
    });

    test('transition état loading → error en cas d\'échec', () async {
      when(
        mockRepository.insertEvent(
          type: TrackingType.caca,
          timestamp: anyNamed('timestamp'),
          duration: anyNamed('duration'),
          notes: anyNamed('notes'),
          wasteType: anyNamed('wasteType'),
          pipiColor: anyNamed('pipiColor'),
          cacaColor: anyNamed('cacaColor'),
        ),
      ).thenThrow(Exception('Erreur de base de données'));

      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(type: TrackingType.caca);

      final state = container.read(trackNotifierProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error,
        isA<Exception>(),
      );
    });

    test('track() sans paramètres optionnels fonctionne', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(type: TrackingType.miam);

      verify(
        mockRepository.insertEvent(
          type: TrackingType.miam,
          timestamp: anyNamed('timestamp'),
          duration: null as double?,
          notes: null as String?,
          wasteType: null as WasteType?,
          pipiColor: null as PipiColor?,
          cacaColor: null as CacaColor?,
        ),
      ).called(1);

      expect(container.read(trackNotifierProvider), isA<AsyncData<void>>());
    });

    test('track() avec paramètres de selle (wasteType, couleurs)', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: TrackingType.caca,
        wasteType: WasteType.pipi,
        pipiColor: PipiColor.jauneClair,
        cacaColor: CacaColor.meconium,
      );

      verify(
        mockRepository.insertEvent(
          type: TrackingType.caca,
          timestamp: anyNamed('timestamp'),
          duration: null as double?,
          notes: null as String?,
          wasteType: WasteType.pipi,
          pipiColor: PipiColor.jauneClair,
          cacaColor: CacaColor.meconium,
        ),
      ).called(1);

      expect(container.read(trackNotifierProvider), isA<AsyncData<void>>());
    });
  });
}


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/home/presentation/providers/track_notifier.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
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
    // Stub par défaut : insertEvent(event) retourne toujours un ID valide.
    when(mockRepository.insertEvent(any)).thenAnswer((_) async => 1);

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
    test('appelle le repository avec un FeedingEvent pour type=miam', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: TrackingType.miam,
        duration: 10,
        notes: 'notes de test',
      );

      // Capturer l'événement passé à insertEvent pour vérifier le contenu.
      final captured = verify(mockRepository.insertEvent(captureAny)).captured;
      expect(captured, hasLength(1));
      final event = captured.first as TrackingEvent;
      expect(event, isA<FeedingEvent>());
      expect((event as FeedingEvent).subtype, equals(FeedingSubtype.natural));
      expect(event.duration, equals(10.0));
      expect(event.notes, equals('notes de test'));
    });

    test('transition état loading → data en cas de succès', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(type: TrackingType.dodo);

      // Après succès, l'état est AsyncData.
      final result = container.read(trackNotifierProvider);
      expect(result, isA<AsyncData<void>>());
    });

    test('transition état loading → error en cas d\'échec', () async {
      when(mockRepository.insertEvent(any)).thenThrow(Exception('Erreur de base de données'));

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

      final captured = verify(mockRepository.insertEvent(captureAny)).captured;
      expect(captured, hasLength(1));
      final event = captured.first as TrackingEvent;
      expect(event, isA<FeedingEvent>());
      // Valeurs par défaut : natural, duration 0.0, notes null
      expect((event as FeedingEvent).subtype, equals(FeedingSubtype.natural));

      expect(container.read(trackNotifierProvider), isA<AsyncData<void>>());
    });

    test('track() avec paramètres de selle (wasteType, couleurs)', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: TrackingType.caca,
        wasteType: WasteType.pipi,
        pipiColor:
        pipiColorJauneClair,
        cacaColor:
        cacaColorMeconium,
      );

      final captured = verify(mockRepository.insertEvent(captureAny)).captured;
      expect(captured, hasLength(1));
      final event = captured.first as TrackingEvent;
      expect(event, isA<DiaperEvent>());
      expect((event as DiaperEvent).wasteType, equals(WasteType.pipi));
      expect(event.pipiColor, equals(pipiColorJauneClair));
      expect(event.cacaColor, equals(cacaColorMeconium));

      expect(container.read(trackNotifierProvider), isA<AsyncData<void>>());
    });

    test('track() avec SleepEvent pour type=dodo', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: TrackingType.dodo,
        duration: 90,
        notes: 'bonne sieste',
      );

      final captured = verify(mockRepository.insertEvent(captureAny)).captured;
      expect(captured, hasLength(1));
      final event = captured.first as TrackingEvent;
      expect(event, isA<SleepEvent>());
      expect((event as SleepEvent).duration, equals(90.0));
      expect(event.notes, equals('bonne sieste'));
    });

    test('track() avec HealthEvent pour type=sante', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: TrackingType.sante,
        healthSubtype: HealthSubtype.vitamineD,
        notes: 'dose quotidienne',
      );

      final captured = verify(mockRepository.insertEvent(captureAny)).captured;
      expect(captured, hasLength(1));
      final event = captured.first as TrackingEvent;
      expect(event, isA<HealthEvent>());
      expect((event as HealthEvent).subtype, equals(HealthSubtype.vitamineD));
      expect(event.notes, equals('dose quotidienne'));
    });

    test('insertEvent est appelé exactement une fois par track()', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(type: TrackingType.miam);

      verify(mockRepository.insertEvent(any)).called(1);
    });
  });
}


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
        quantity: 10,
        notes: 'notes de test',
      );

      // Capturer l'événement passé à insertEvent pour vérifier le contenu.
      final captured = verify(mockRepository.insertEvent(captureAny)).captured;
      expect(captured, hasLength(1));
      final event = captured.first as TrackingEvent;
      expect(event, isA<FeedingEvent>());
      expect((event as FeedingEvent).subtype, equals(FeedingSubtype.natural));
      expect(event.quantity, equals(10.0));
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

    test('track() avec consistance de la selle', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      await notifier.track(
        type: TrackingType.caca,
        wasteType: WasteType.caca,
        cacaColor: cacaColorJauneMoutarde,
        stoolTexture: stoolTextureMoulee,
      );

      final captured = verify(mockRepository.insertEvent(captureAny)).captured;
      final event = captured.first as DiaperEvent;
      expect(event.stoolTexture, equals(stoolTextureMoulee));
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

  group('TrackNotifier.track() — date de l’événement', () {
    // Le parent choisit le moment de l’événement ; le notifier doit le
    // transmettre tel quel, et tomber sur maintenant lorsqu’il est omis.
    test('un timestamp fourni est utilisé tel quel pour chaque type', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      final chosen = DateTime(2026, 2, 3, 14, 25);

      for (final type in TrackingType.values) {
        reset(mockRepository);
        when(mockRepository.insertEvent(any)).thenAnswer((_) async => 1);

        await notifier.track(type: type, timestamp: chosen);

        final event = verify(mockRepository.insertEvent(captureAny)).captured.single
            as TrackingEvent;
        expect(event.timestamp, equals(chosen),
            reason: 'timestamp ignoré pour ${type.name}');
      }
    });

    test('un timestamp omis reste daté du moment de la saisie', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      final before = DateTime.now();

      await notifier.track(type: TrackingType.dodo, duration: 30);

      final event = verify(mockRepository.insertEvent(captureAny)).captured.single
          as TrackingEvent;
      expect(event.timestamp.isBefore(before), isFalse);
      expect(event.timestamp.isAfter(DateTime.now()), isFalse);
    });

    test('un timestamp dans le passé est conservé (saisie a posteriori)', () async {
      final notifier = container.read(trackNotifierProvider.notifier);
      final sieste = DateTime.now().subtract(const Duration(hours: 2));

      await notifier.track(
        type: TrackingType.dodo,
        duration: 45,
        quantity: 45,
        timestamp: sieste,
      );

      final event = verify(mockRepository.insertEvent(captureAny)).captured.single
          as SleepEvent;
      expect(event.timestamp, equals(sieste));
      expect(event.duration, equals(45.0));
    });
  });
}


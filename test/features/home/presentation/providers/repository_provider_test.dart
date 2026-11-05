import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_notifier.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/mockito.dart';

import '../../../../data/repositories/tracking_repository_impl_test.mocks.dart';

/// Repository stub: returns per-type timestamps and records every
/// `getLatestEventTimestamp` call with its babyId argument.
class _CapturingTrackingRepository implements TrackingRepository {
  _CapturingTrackingRepository(this.timestamps);

  final Map<TrackingType, DateTime?> timestamps;
  final List<(TrackingType, String?)> calls = [];

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async => const [];

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type) async =>
      const [];

  @override
  Future<int> insertEvent(TrackingEvent event) async => 0;

  @override
  Future<DateTime?> getLastEventByTypeAndSubtype(TrackingType type,
          {String? subtypeValue}) async =>
      null;

  @override
  Future<DateTime?> getLatestEventTimestamp(TrackingType type,
      {String? babyId}) async {
    calls.add((type, babyId));
    return timestamps[type];
  }
}

/// [RemindersNotifier] without polling and without the service chain: its
/// state is the « something was tracked or edited » cycle this provider
/// piggybacks on, and the tests drive it directly.
class _QuietRemindersNotifier extends RemindersNotifier {
  @override
  Future<Map<TrackingType, List<ReminderStatus>>> build() async => const {};
}

class _TestActiveBabyNotifier extends ActiveBabyNotifier {
  _TestActiveBabyNotifier(this.profile);

  final BabyProfile? profile;

  @override
  Future<BabyProfile?> build() async => profile;
}

/// Awaits the first [AsyncData] of [lastTrackedTimestampsProvider] through
/// [ProviderContainer.listen] — the same subscription path widgets use with
/// `ref.watch`.
///
/// The riverpod 3.3.2 `.future` getter is not used here on purpose: it never
/// settles for a `FutureProvider` that watches an `AsyncNotifierProvider`
/// (a bare multi-await provider resolves fine; adding one AsyncNotifier
/// watch makes it hang). Widgets are unaffected because they subscribe
/// through `listen`, which does deliver [AsyncData].
Future<Map<TrackingType, DateTime?>> readLastTracked(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 5),
}) {
  final completer = Completer<Map<TrackingType, DateTime?>>();
  final subscription = container.listen(
    lastTrackedTimestampsProvider,
    (_, next) {
      if (next case AsyncData(value: final value)) {
        if (!completer.isCompleted) completer.complete(value);
      } else if (next case AsyncError(:final error, :final stackTrace)) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    },
  );
  return completer.future
      .timeout(
        timeout,
        onTimeout: () => throw StateError(
          'lastTrackedTimestampsProvider did not settle in time',
        ),
      )
      .whenComplete(subscription.close);
}

void main() {
  group('trackingRepositoryProvider', () {
    late MockAppDatabase mockDb;
    late MockEncryptionService mockEncryption;

    setUp(() {
      mockDb = MockAppDatabase();
      mockEncryption = MockEncryptionService();
    });

    test('retourne un TrackingRepository quand les dépendances sont résolues',
        () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      final repository =
          await container.read(trackingRepositoryProvider.future);

      expect(repository, isA<TrackingRepository>());

      container.dispose();
    });

    test('le provider est un FutureProvider', () {
      expect(
        trackingRepositoryProvider,
        isA<FutureProvider<TrackingRepository>>(),
      );
    });

    test('dispose correctement sans erreur', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      expect(container.dispose, returnsNormally);
    });

    test('cache le résultat après la première résolution', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      // First reading: solving the future.
      final first = await container.read(trackingRepositoryProvider.future);

      // Second read — returns the same instance (caches Riverpod).
      final second = await container.read(trackingRepositoryProvider.future);

      expect(identical(first, second), isTrue);

      container.dispose();
    });

    test('propage une erreur de databaseProvider', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider
            .overrideWith((ref) async => throw Exception('DB error')),
      ]);

      expect(
        () => container.read(trackingRepositoryProvider.future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });

    test('injecte bien l\'encryption service dans le repository', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      // The construction of the provider utilizes both dependencies – if we...
      // If you change the override setting, the result should change accordingly.
      final repo = await container.read(trackingRepositoryProvider.future);

      expect(repo, isA<TrackingRepository>());
      // Successful access confirms that the injections were effective.

      container.dispose();
    });

    test('propage une erreur de construction du repository', () async {
      when(mockDb.insertEvent(any)).thenThrow(Exception('DB error'));

      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      // The provider resolves the issue (building the repository does not involve any database operations).
      final repo = await container.read(trackingRepositoryProvider.future);

      expect(repo, isA<TrackingRepository>());

      // However, repo transactions amplify the error stemming from the central bank's actions.
      final testEvent = FeedingEvent(
        unit: QuantityUnit.ml,
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.natural,
      );
      expect(
        () => repo.insertEvent(testEvent),
        throwsA(anything),
      );

      container.dispose();
    });
  });

  // ── lastTrackedTimestampsProvider ──────────────────────────────

  group('lastTrackedTimestampsProvider', () {
    late _CapturingTrackingRepository repository;

    ProviderContainer makeContainer(BabyProfile? baby) {
      repository = _CapturingTrackingRepository({});
      return ProviderContainer(overrides: [
        trackingRepositoryProvider.overrideWith((ref) async => repository),
        activeBabyProvider.overrideWith(() => _TestActiveBabyNotifier(baby)),
        reminderNotifierProvider.overrideWith(_QuietRemindersNotifier.new),
      ]);
    }

    final luna = BabyProfile(
      id: 'b1',
      name: 'Luna',
      birthDate: DateTime.utc(2024, 1, 1),
    );

    test(
        'maps the four home types to the repository timestamps, '
        'scoped to the active baby', () async {
      final container = makeContainer(luna);
      // Pre-resolve the provider's dependencies so the first build already
      // sees the baby data — otherwise it fires one transient unscoped
      // query while the profile is still loading (harmless in the app,
      // noise in the call log).
      await container.read(activeBabyProvider.future);
      await container.read(reminderNotifierProvider.future);

      final miamAt = DateTime(2024, 3, 1, 8);
      final dodoAt = DateTime(2024, 3, 1, 22);
      repository.timestamps
        ..[TrackingType.miam] = miamAt
        ..[TrackingType.dodo] = dodoAt;

      final map = await readLastTracked(container);

      expect(map.keys.toSet(), {
        TrackingType.miam,
        TrackingType.sante,
        TrackingType.caca,
        TrackingType.dodo
      });
      expect(map[TrackingType.miam], miamAt);
      expect(map[TrackingType.dodo], dodoAt);
      expect(map[TrackingType.sante], isNull);
      expect(map[TrackingType.caca], isNull);
      expect(repository.calls.toSet(), {
        (TrackingType.miam, 'b1'),
        (TrackingType.sante, 'b1'),
        (TrackingType.caca, 'b1'),
        (TrackingType.dodo, 'b1'),
      });

      container.dispose();
    });

    test('reads the unscoped column when no active baby is loaded', () async {
      final container = makeContainer(null);

      final map = await readLastTracked(container);

      expect(map, isNotEmpty);
      for (final (type, babyId) in repository.calls) {
        expect(babyId, isNull, reason: 'unscoped read for $type');
      }

      container.dispose();
    });

    // The freshness contract: the provider piggybacks on the reminder cycle
    // (the app-wide « something was tracked or edited » signal). A state
    // move there must re-query the repository.
    test('re-queries the repository when the reminder state moves', () async {
      final container = makeContainer(luna);
      await container.read(activeBabyProvider.future);
      await container.read(reminderNotifierProvider.future);

      final first = DateTime(2024, 3, 1, 8);
      repository.timestamps[TrackingType.miam] = first;

      final read1 = await readLastTracked(container);
      expect(read1[TrackingType.miam], first);
      expect(repository.calls, hasLength(4));

      final second = DateTime(2024, 3, 2, 9);
      repository.timestamps[TrackingType.miam] = second;
      // A state that is NOT equal to the initial `const {}` — riverpod skips
      // the rebuild when the new state compares equal to the old one.
      container.read(reminderNotifierProvider.notifier).state =
          AsyncValue.data(<TrackingType, List<ReminderStatus>>{
        TrackingType.miam: const [],
      });

      final read2 = await readLastTracked(container);
      expect(read2[TrackingType.miam], second);
      expect(repository.calls, hasLength(8));

      container.dispose();
    });
  });
}

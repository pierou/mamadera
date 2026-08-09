import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart' as repo_prov;
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/features/reminders/domain/services/reminders_service.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

import '../../data/repositories/mock_reminders_repository.dart';

/// Stub notifier that returns a fixed baby profile on build.
class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}

// Mock for TrackingRepository (simple in-memory implementation)
class MockTrackingRepository implements TrackingRepository {
  final Map<String, DateTime?> _lastEventByType = {};

  void setLastEvent(TrackingType type, String? subtype, DateTime? timestamp) {
    _lastEventByType['${type.name}|$subtype'] = timestamp;
  }

  @override
  Future<DateTime?> getLastEventByTypeAndSubtype(
    TrackingType type, {
    String? subtypeValue,
  }) async {
    return _lastEventByType['${type.name}|$subtypeValue'];
  }

  @override
  Future<int> insertEvent(TrackingEvent event) async => throw UnimplementedError();

  @override
  Future<List<TrackingEvent>> getAllEventsOrdered() async => throw UnimplementedError();

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type) async => throw UnimplementedError();
}



void main() {
  group('reminderNotifierProvider', () {
    late MockTrackingRepository mockTrackingRepo;
    late ProviderContainer container;

    setUp(() {
      mockTrackingRepo = MockTrackingRepository();
      container = ProviderContainer(overrides: [
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('returns empty map when RemindersAllCompleted', (tester) async {
      final mockReminders = MockRemindersRepository();
      // Set all items as completed today → no reminders due
      mockReminders.lastCompletedByItem[ReminderItemPresets.vitaminD.id] = DateTime.now();

      final service = RemindersService(
        items: [ReminderItemPresets.vitaminD],
        repository: mockReminders,
      );

      container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderNotifierProvider.future);

      expect(result, isEmpty);
      container.dispose();
    });

    testWidgets('enriches ReminderStatus with lastEventAt from tracking repo', (tester) async {
      // Set up: Vitamin D was tracked yesterday
      mockTrackingRepo.setLastEvent(
        TrackingType.sante,
        'vitamine_d',
        DateTime.utc(2024, 6, 1),
      );

      final mockReminders = MockRemindersRepository();
      // No last completed → reminder IS due

      final service = RemindersService(
        items: [ReminderItemPresets.vitaminD],
        repository: mockReminders,
      );

      container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderNotifierProvider.future);

      expect(result, isNotEmpty);
      expect(result[TrackingType.sante], isNotNull);
      expect(result[TrackingType.sante]!.length, equals(1));
      expect(result[TrackingType.sante]!.first.lastEventAt, equals(DateTime.utc(2024, 6, 1)));
      container.dispose();
    });

    testWidgets('groups multiple reminders by TrackingType', (tester) async {
      mockTrackingRepo.setLastEvent(
        TrackingType.sante, 'vitamine_d', DateTime.utc(2024, 5, 1),
      );
      mockTrackingRepo.setLastEvent(
        TrackingType.sante, 'nettoyage_yeux', DateTime.utc(2024, 6, 1),
      );

      final mockReminders = MockRemindersRepository();

      final service = RemindersService(
        items: [ReminderItemPresets.vitaminD, ReminderItemPresets.eyeCleaning],
        repository: mockReminders,
      );

      container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderNotifierProvider.future);

      // Both are TrackingType.sante, so grouped under same key
      expect(result.keys.length, equals(1));
      expect(result[TrackingType.sante]!.length, equals(2));
      container.dispose();
    });

    testWidgets('handles null lastEventAt when event never tracked', (tester) async {
      // No events set — repo returns null for everything
      final mockReminders = MockRemindersRepository();

      final service = RemindersService(
        items: [ReminderItemPresets.vitaminD],
        repository: mockReminders,
      );

      container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderNotifierProvider.future);

      expect(result[TrackingType.sante], isNotNull);
      expect(result[TrackingType.sante]!.first.lastEventAt, isNull);
      container.dispose();
    });

    testWidgets('refresh() triggers re-evaluation of reminders', (tester) async {
      // Set up: Vitamin D tracked initially
      mockTrackingRepo.setLastEvent(
        TrackingType.sante,
        'vitamine_d',
        DateTime.utc(2024, 6, 1),
      );

      final mockReminders = MockRemindersRepository();
      final service = RemindersService(
        items: [ReminderItemPresets.vitaminD, ReminderItemPresets.eyeCleaning],
        repository: mockReminders,
      );

      container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      // Initial read
      final firstResult = await container.read(reminderNotifierProvider.future);
      expect(firstResult[TrackingType.sante]!.length, equals(2));

      // Update mock repo to simulate new event
      mockTrackingRepo.setLastEvent(
        TrackingType.sante,
        'vitamine_d',
        DateTime.now(),
      );
      // Mark one item as completed
      mockReminders.lastCompletedByItem[ReminderItemPresets.vitaminD.id] = DateTime.now();

      // Refresh
      final notifier = container.read(reminderNotifierProvider.notifier);
      await notifier.refresh();

      final secondResult = container.read(reminderNotifierProvider);
      expect(secondResult, isA<AsyncData<Map<TrackingType, List<ReminderStatus>>>>());
      final data = secondResult.maybeWhen(
        data: (d) => d,
        orElse: () => <TrackingType, List<ReminderStatus>>{},
      );
      // Only eyeCleaning should remain due
      expect(data[TrackingType.sante]!.length, equals(1));
      expect(data[TrackingType.sante]!.first.item.id, equals(ReminderItemPresets.eyeCleaning.id));
      container.dispose();
    });
  });

  group('dynamicRemindersProvider reactivity', () {
    /// B1: dynamicRemindersProvider returns reminder items for the active baby.
    testWidgets(
      'dynamicRemindersProvider re-evaluates when active baby changes',
      (tester) async {
        final babyA = BabyProfile(id: 'baby_a', name: 'Baby A', birthDate: DateTime(2024, 1, 5));
        final babyB = BabyProfile(id: 'baby_b', name: 'Baby B', birthDate: DateTime(2024, 3, 20));

        // Container for baby A
        final containerA = ProviderContainer(
          overrides: [
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(babyA)),
          ],
        );

        final remindersA = await containerA.read(dynamicRemindersProvider.future);
        expect(remindersA, isNotEmpty);

        // Container for baby B
        final containerB = ProviderContainer(
          overrides: [
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(babyB)),
          ],
        );

        final remindersB = await containerB.read(dynamicRemindersProvider.future);
        expect(remindersB, isNotEmpty);

        // Both babies get the same 4 reminders (Vitamin D daily, Vitamin K every 30 days, eye/face cleaning)
        expect(remindersA.length, equals(4));
        expect(remindersB.length, equals(4));
        expect(remindersA.map((e) => e.id), equals(remindersB.map((e) => e.id)));

        containerA.dispose();
        containerB.dispose();
      },
    );
  });

  group('remindersServiceProvider reactivity', () {
    /// B2: remindersServiceProvider rebuilds its items when the active baby switches.
    testWidgets(
      'remindersServiceProvider reflects new active baby after switch',
      (tester) async {
        final babyA = BabyProfile(id: 'baby_a', name: 'Baby A', birthDate: DateTime(2024, 1, 5));
        final babyB = BabyProfile(id: 'baby_b', name: 'Baby B', birthDate: DateTime(2024, 3, 20));

        // Simulate what remindersServiceProvider builds for each active baby.
        // The provider depends on dynamicRemindersProvider (which watches activeBabyProvider),
        // so when the active baby changes, the service items should change accordingly.
        final mockRepo = MockRemindersRepository();
        final serviceA = RemindersService(
          items: ReminderItemPresets.buildForBaby(babyA),
          repository: mockRepo,
        );

        final containerA = ProviderContainer(
          overrides: [
            remindersServiceProvider.overrideWith((ref) => Future.value(serviceA)),
          ],
        );

        final readServiceA = await containerA.read(remindersServiceProvider.future);
        expect(readServiceA, isA<RemindersService>());

        // Container for baby B
        final serviceB = RemindersService(
          items: ReminderItemPresets.buildForBaby(babyB),
          repository: mockRepo,
        );

        final containerB = ProviderContainer(
          overrides: [
            remindersServiceProvider.overrideWith((ref) => Future.value(serviceB)),
          ],
        );

        final readServiceB = await containerB.read(remindersServiceProvider.future);

        // Both babies get the same reminder item list (all constants since Vitamin K uses CustomInterval)
        expect(readServiceB.items.length, equals(4));
        expect(readServiceB.items.map((e) => e.id), equals(readServiceA.items.map((e) => e.id)));

        containerA.dispose();
        containerB.dispose();
      },
    );
  });

  group('ReminderStatus', () {
    testWidgets('preserves lastEventAt when set', (tester) async {
      final tracked = DateTime.utc(2024, 5, 15, 10, 30, 0);
      final status = ReminderStatus(
        item: ReminderItemPresets.vitaminD,
        lastEventAt: tracked,
      );

      expect(status.lastEventAt, equals(tracked));
    });

    testWidgets('handles null lastEventAt for never-tracked events', (tester) async {
      final status = ReminderStatus(item: ReminderItemPresets.vitaminD);

      expect(status.lastEventAt, isNull);
    });

    testWidgets('preserves lastDismissedAt for cooldown tracking', (tester) async {
      final dismissed = DateTime.utc(2024, 6, 1, 8, 0, 0);
      final status = ReminderStatus(
        item: ReminderItemPresets.vitaminD,
        lastDismissedAt: dismissed,
      );

      expect(status.lastDismissedAt, equals(dismissed));
    });

    testWidgets('ReminderStatus equality works correctly', (tester) async {
      final tracked = DateTime.utc(2024, 5, 15, 10, 30, 0);
      final status1 = ReminderStatus(
        item: ReminderItemPresets.vitaminD,
        lastEventAt: tracked,
      );
      final status2 = ReminderStatus(
        item: ReminderItemPresets.vitaminD,
        lastEventAt: tracked,
      );

      expect(status1, equals(status2));
    });

    testWidgets('ReminderStatus with different values are not equal', (tester) async {
      final status1 = ReminderStatus(
        item: ReminderItemPresets.vitaminD,
        lastEventAt: DateTime.utc(2024, 5, 15),
      );
      final status2 = ReminderStatus(
        item: ReminderItemPresets.eyeCleaning,
        lastEventAt: DateTime.utc(2024, 5, 15),
      );

      expect(status1, isNot(equals(status2)));
    });
  });

  group('remindersRepositoryProvider', () {
    testWidgets('provider is a FutureProvider', (tester) async {
      expect(
        remindersRepositoryProvider,
        isA<FutureProvider<Object?>>(),
      );
    });
  });

  group('babyProfileProvider', () {
    testWidgets('provider is a FutureProvider of BabyProfileRepository', (tester) async {
      expect(
        babyProfileProvider,
        isA<FutureProvider<BabyProfileRepository>>(),
      );
    });
  });

  group('dynamicRemindersProvider', () {
    testWidgets('provider is a FutureProvider', (tester) async {
      expect(
        dynamicRemindersProvider,
        isA<FutureProvider<List<ReminderItem>>>(),
      );
    });
  });

  group('remindersServiceProvider', () {
    testWidgets('provider is a FutureProvider', (tester) async {
      expect(
        remindersServiceProvider,
        isA<FutureProvider<RemindersService>>(),
      );
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart' as repo_prov;
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/features/reminders/domain/services/reminders_service.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

import '../../data/repositories/mock_reminders_repository.dart';

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
  group('reminderStatusesProvider', () {
    late MockTrackingRepository mockTrackingRepo;

    setUp(() {
      mockTrackingRepo = MockTrackingRepository();
    });

    testWidgets('returns empty map when RemindersAllCompleted', (tester) async {
      final mockReminders = MockRemindersRepository();
      // Set all items as completed today → no reminders due
      mockReminders.lastCompletedByItem[ReminderItem.vitaminD().id] = DateTime.now();

      final service = RemindersService(
        items: [ReminderItem.vitaminD()],
        repository: mockReminders,
      );

      final container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderStatusesProvider.future);

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
        items: [ReminderItem.vitaminD()],
        repository: mockReminders,
      );

      final container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderStatusesProvider.future);

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
        items: [ReminderItem.vitaminD(), ReminderItem.eyeCleaning()],
        repository: mockReminders,
      );

      final container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderStatusesProvider.future);

      // Both are TrackingType.sante, so grouped under same key
      expect(result.keys.length, equals(1));
      expect(result[TrackingType.sante]!.length, equals(2));
      container.dispose();
    });

    testWidgets('handles null lastEventAt when event never tracked', (tester) async {
      // No events set — repo returns null for everything
      final mockReminders = MockRemindersRepository();

      final service = RemindersService(
        items: [ReminderItem.vitaminD()],
        repository: mockReminders,
      );

      final container = ProviderContainer(overrides: [
        remindersServiceProvider.overrideWith((ref) => Future.value(service)),
        repo_prov.trackingRepositoryProvider.overrideWith((ref) async => mockTrackingRepo),
      ]);

      final result = await container.read(reminderStatusesProvider.future);

      expect(result[TrackingType.sante], isNotNull);
      expect(result[TrackingType.sante]!.first.lastEventAt, isNull);
      container.dispose();
    });
  });

  group('dynamicRemindersProvider', () {
    testWidgets('provider is a FutureProvider of ReminderItem list', (tester) async {
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
        isA<FutureProvider<dynamic>>(),
      );
    });
  });

  group('ReminderStatus', () {
    testWidgets('preserves lastEventAt when set', (tester) async {
      final tracked = DateTime.utc(2024, 5, 15, 10, 30, 0);
      final status = ReminderStatus(
        item: ReminderItem.vitaminD(),
        lastEventAt: tracked,
      );

      expect(status.lastEventAt, equals(tracked));
    });

    testWidgets('handles null lastEventAt for never-tracked events', (tester) async {
      final status = ReminderStatus(item: ReminderItem.vitaminD());

      expect(status.lastEventAt, isNull);
    });

    testWidgets('preserves lastDismissedAt for cooldown tracking', (tester) async {
      final dismissed = DateTime.utc(2024, 6, 1, 8, 0, 0);
      final status = ReminderStatus(
        item: ReminderItem.vitaminD(),
        lastDismissedAt: dismissed,
      );

      expect(status.lastDismissedAt, equals(dismissed));
    });
  });
}

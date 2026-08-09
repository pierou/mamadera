import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/features/reminders/domain/services/reminders_service.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

import '../data/repositories/mock_reminders_repository.dart';

void main() {
  late MockRemindersRepository mockRepo;
  late RemindersService service;

  final vitaminDItem = ReminderItem(
    id: 'vitamin_d',
    labelKey: 'reminders_vitamin_d_label',
    frequency: const Daily(),
    trackingType: TrackingType.sante,
    subtypeValue: 'healthSubtypeVitaminD',
  );

  group('RemindersService.checkDue()', () {
    setUp(() {
      mockRepo = MockRemindersRepository();
    });

    test('returns RemindersAllCompleted when no reminders are due', () async {
      // Completed today — not overdue.
      mockRepo.lastCompletedByItem['vitamin_d'] = DateTime.now();
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();
      expect(result, isA<RemindersAllCompleted>());
    });

    test('returns RemindersDue when a reminder has no last completed date', () async {
      // Never completed.
      mockRepo.lastCompletedByItem['vitamin_d'] = null;
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();
      expect(result, isA<RemindersDue>());
      if (result is RemindersDue) {
        expect(result.items.length, 1);
        expect(result.items.first.item.id, 'vitamin_d');
      }
    });

    test('returns RemindersDue when last completed was yesterday', () async {
      mockRepo.lastCompletedByItem['vitamin_d'] = DateTime.now().subtract(const Duration(days: 1));
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();
      expect(result, isA<RemindersDue>());
    });

    test('skips reminder within cooldown period', () async {
      // Reminder is due (last completed yesterday) but was dismissed recently.
      mockRepo.lastCompletedByItem['vitamin_d'] = DateTime.now().subtract(const Duration(days: 1));
      mockRepo.dismissalTimeById['vitamin_d'] = DateTime.now();
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();
      expect(result, isA<RemindersAllCompleted>());
    });

    test('includes reminder after cooldown period expires', () async {
      // Reminder is due (last completed yesterday) and dismissed 5 hours ago (> 4h cooldown).
      mockRepo.lastCompletedByItem['vitamin_d'] = DateTime.now().subtract(const Duration(days: 1));
      mockRepo.dismissalTimeById['vitamin_d'] = DateTime.now().subtract(const Duration(hours: 5));
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();
      expect(result, isA<RemindersDue>());
    });
  });

  group('RemindersService.dismiss()', () {
    setUp(() {
      mockRepo = MockRemindersRepository();
    });

    test('saves dismissal time for item', () async {
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      expect(mockRepo.dismissalTimeById['vitamin_d'], isNull);

      await service.dismiss('vitamin_d');

      expect(mockRepo.dismissalTimeById['vitamin_d'], isNotNull);
    });
  });
}

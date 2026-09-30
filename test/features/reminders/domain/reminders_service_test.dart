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

    test('passes the active baby id down to the completion lookup', () async {
      // Guards against the cross-baby leak: completing a routine for baby A must be
      // looked up under baby A only, so it cannot silence baby B's reminder.
      mockRepo.lastCompletedByItem['vitamin_d'] = DateTime.now();
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      await service.checkDue(babyId: 'baby_a');
      expect(mockRepo.lastCompletedBabyId, equals('baby_a'));

      // No profile yet → unscoped lookup (backward compatible v1 behaviour).
      await service.checkDue();
      expect(mockRepo.lastCompletedBabyId, isNull);
    });
  });
}

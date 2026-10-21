import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/db_constants.dart';
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

    test('returns RemindersDue when a reminder has no last completed date',
        () async {
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
      mockRepo.lastCompletedByItem['vitamin_d'] =
          DateTime.now().subtract(const Duration(days: 1));
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

  group('complétion manuelle (completionSource)', () {
    // Detached from a care setting: no subtype value is specified, and it is only set by a single tap.
    final pedicureItem = ReminderItem(
      id: 'pedicure',
      labelKey: 'reminderPedicure',
      frequency: const Daily(),
      trackingType: TrackingType.sante,
      completionSource: completionManual,
    );

    setUp(() {
      mockRepo = MockRemindersRepository();
    });

    test('un rappel détaché est dû sans aucun événement', () async {
      // Neither an event nor a completed task: the alarm still goes off.
      service = RemindersService(items: [pedicureItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
    });

    test(
        'un événement du bon type ne règle pas un rappel manuel (invariant D2)',
        () async {
      service = RemindersService(items: [pedicureItem], repository: mockRepo);

      // The service should not even query the events; it should simply receive a "health" status.
      // What was recorded today should not silence him.
      mockRepo.lastCompletedByItem['pedicure'] = DateTime.now();
      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
      expect(mockRepo.completedLookupCount, 0);
    });

    test("recordCompletion règle le rappel manuel jusqu'au jour suivant",
        () async {
      service = RemindersService(items: [pedicureItem], repository: mockRepo);
      final at = DateTime.now();

      await mockRepo.recordCompletion('pedicure', at: at);
      final settled = await service.checkDue();
      expect(settled, isA<RemindersAllCompleted>());

      // The following day, it becomes due again.
      mockRepo.manualCompletedByItem['pedicure'] =
          at.subtract(const Duration(days: 1));
      final dueAgain = await service.checkDue();
      expect(dueAgain, isA<RemindersDue>());
    });

    test(
        'une complétion manuelle ne règle jamais un rappel piloté par événements',
        () async {
      // The converse of implication: the manual is only read.
      // for the `manual` items.
      mockRepo.manualCompletedByItem['vitamin_d'] = DateTime.now();
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
      expect(mockRepo.lastManualCompletedBabyId, isNull);
    });

    test('le portage actif est transmis aux lectures manuelles et aux ignorés',
        () async {
      service = RemindersService(items: [pedicureItem], repository: mockRepo);

      await service.checkDue(babyId: 'baby_a');

      expect(mockRepo.lastManualCompletedBabyId, equals('baby_a'));
      expect(mockRepo.lastDismissalBabyId, equals('baby_a'));
    });
  });

  group("fenêtre d'ignorer (dismissalWindow)", () {
    setUp(() {
      mockRepo = MockRemindersRepository();
    });

    test('la fenêtre par défaut est de 24 h', () {
      final svc = RemindersService(items: const [], repository: mockRepo);
      expect(svc.dismissalWindow, const Duration(hours: 24));
    });

    test("un rappel ignoré moins de 24 h plus tôt n'est pas dû", () async {
      // Ignored one hour ago: it was removed from the list of tasks that needed to be completed.
      mockRepo.dismissedById['vitamin_d'] =
          DateTime.now().subtract(const Duration(hours: 1));
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersAllCompleted>());
    });

    test('un rappel ignoré il y a 25 h redevient dû', () async {
      // The window is a grace period, not a cancellation: after 24 hours, the...
      // The reminder reappears automatically.
      mockRepo.dismissedById['vitamin_d'] =
          DateTime.now().subtract(const Duration(hours: 25));
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
    });

    test('la fenêtre est injectable', () async {
      // Ignored 3 hours ago: The 2-hour window has passed, and a reminder is due.
      mockRepo.dismissedById['vitamin_d'] =
          DateTime.now().subtract(const Duration(hours: 3));
      service = RemindersService(
        items: [vitaminDItem],
        repository: mockRepo,
        dismissalWindow: const Duration(hours: 2),
      );

      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
    });
  });
}

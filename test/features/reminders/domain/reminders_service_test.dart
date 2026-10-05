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

  group('complétion manuelle (completionSource)', () {
    // Détaché d'un soin : pas de subtypeValue, réglé seulement par un tap.
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
      // Ni événement, ni complétion : le rappel sonne quand même.
      service = RemindersService(items: [pedicureItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
    });

    test('un événement du bon type ne règle pas un rappel manuel (invariant D2)', () async {
      service = RemindersService(items: [pedicureItem], repository: mockRepo);

      // Le service ne doit même pas interroger les événements : un `sante`
      // enregistré aujourd'hui ne doit pas le faire taire.
      mockRepo.lastCompletedByItem['pedicure'] = DateTime.now();
      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
      expect(mockRepo.completedLookupCount, 0);
    });

    test("recordCompletion règle le rappel manuel jusqu'au jour suivant", () async {
      service = RemindersService(items: [pedicureItem], repository: mockRepo);
      final at = DateTime.now();

      await mockRepo.recordCompletion('pedicure', at: at);
      final settled = await service.checkDue();
      expect(settled, isA<RemindersAllCompleted>());

      // Le lendemain, il redevient dû.
      mockRepo.manualCompletedByItem['pedicure'] = at.subtract(const Duration(days: 1));
      final dueAgain = await service.checkDue();
      expect(dueAgain, isA<RemindersDue>());
    });

    test('une complétion manuelle ne règle jamais un rappel piloté par événements', () async {
      // Le sens inverse de l'implication : le journal manuel est lu seulement
      // pour les items `manual`.
      mockRepo.manualCompletedByItem['vitamin_d'] = DateTime.now();
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
      expect(mockRepo.lastManualCompletedBabyId, isNull);
    });

    test('le portage actif est transmis aux lectures manuelles et aux ignorés', () async {
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
      // Ignoré il y a une heure : il sort de la liste des dus sans être fait.
      mockRepo.dismissedById['vitamin_d'] =
          DateTime.now().subtract(const Duration(hours: 1));
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersAllCompleted>());
    });

    test('un rappel ignoré il y a 25 h redevient dû', () async {
      // La fenêtre est un délai, pas une suppression : au bout de 24 h le
      // rappel reparaît tout seul.
      mockRepo.dismissedById['vitamin_d'] =
          DateTime.now().subtract(const Duration(hours: 25));
      service = RemindersService(items: [vitaminDItem], repository: mockRepo);

      final result = await service.checkDue();

      expect(result, isA<RemindersDue>());
    });

    test('la fenêtre est injectable', () async {
      // Ignoré il y a 3 h : la fenêtre de 2 h est passée, le rappel est dû.
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

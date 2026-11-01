import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

import '../../data/repositories/mock_reminders_repository.dart';

/// The baby monitor can be switched to test mode: without a base, the status can be controlled manually.
/// The main function and the notification system are linked through a `ref.watch` reference.
class _SwitchableBabyNotifier extends ActiveBabyNotifier {
  _SwitchableBabyNotifier(this.profile);

  BabyProfile? profile;

  void switchTo(BabyProfile? profile) {
    this.profile = profile;
    state = AsyncValue.data(profile);
  }

  @override
  Future<BabyProfile?> build() async => profile;
}

void main() {
  final babyA = BabyProfile(
    id: 'a',
    name: 'Anna',
    birthDate: DateTime(2024, 1, 15),
  );
  final babyB = BabyProfile(
    id: 'b',
    name: 'Boris',
    birthDate: DateTime(2024, 5, 2),
  );

  /// Detached reminder (D2): Thermometer, daily, set by tapping "Done."
  CustomReminder thermometer() => CustomReminder(
        id: 1,
        label: 'Thermomètre',
        frequency: const ReminderFrequency.daily(),
        subtypeValue: null,
        completionSource: completionManual,
      );

  /// Container for notifier tests: the repository is the only entry point.
  /// The "Real Service" channel (includes active baby settings + custom reminders).
  /// (the deposit) automatically adjusts itself, just like in the calibration tests.
  ProviderContainer buildContainer(
    MockRemindersRepository repo,
    _SwitchableBabyNotifier baby,
  ) {
    final container = ProviderContainer(
      overrides: [
        remindersRepositoryProvider.overrideWith((ref) async => repo),
        activeBabyProvider.overrideWith(() => baby),
      ],
    );
    addTearDown(container.dispose);
    // The notifier, within the `ref.watch` context, expects an `autoDispose` service: the auditor.
    // Please be advised that the following message will remain visible while you are reading.
    // like the app constantly does (e.g., notifications, welcome messages).
    container.listen(reminderNotifierProvider, (_, __) {});
    return container;
  }

  Future<void> settle(ProviderContainer container) =>
      container.read(reminderNotifierProvider.future);

  List<String> ids(ProviderContainer container) {
    final byType = container.read(reminderNotifierProvider).value!;
    return byType.values
        .expand((statuses) => statuses)
        .map((status) => status.item.id)
        .toList();
  }

  group('markDone (D1/D2)', () {
    test(
        'un détaché : le journal manuel est scopé au bébé actif, la ligne part',
        () async {
      final repo = ScopedDismissalRemindersRepository();
      // The deposit is applied before the container: this is how the provider chain works.
      // Read it on the first listen, not after.
      repo.customRemindersById[1] = thermometer();
      final baby = _SwitchableBabyNotifier(babyA);
      final container = buildContainer(repo, baby);
      await settle(container);
      expect(ids(container), contains('custom_1'));

      final item = repo.customRemindersById[1]!;
      final status = container
          .read(reminderNotifierProvider)
          .value!
          .values
          .expand((s) => s)
          .firstWhere((s) => s.item.id == 'custom_1');
      await container
          .read(reminderNotifierProvider.notifier)
          .markDone(status.item);
      await settle(container);

      expect(ids(container), isNot(contains('custom_1')));
      expect(repo.recordCompletionCallCount, 1);
      expect(repo.lastRecordCompletionBabyId, babyA.id);
      expect(repo.manualCompletedByItem['custom_1'], isNotNull);
      // The newspaper has already processed the payment for today's subscription; no further payment is due.
      // As long as the day doesn't change (daily frequency).
      expect(
        item.frequency
            .isDue(DateTime.now(), repo.manualCompletedByItem['custom_1']),
        isFalse,
      );
    });

    test('un lié à un soin : pas de journal manuel, le soin le règle (D2)',
        () async {
      final repo = ScopedDismissalRemindersRepository();
      final baby = _SwitchableBabyNotifier(babyA);
      final container = buildContainer(repo, baby);
      await settle(container);
      expect(ids(container), contains('vitamine_d'));

      final status = container
          .read(reminderNotifierProvider)
          .value!
          .values
          .expand((s) => s)
          .firstWhere((s) => s.item.id == 'vitamine_d');
      await container
          .read(reminderNotifierProvider.notifier)
          .markDone(status.item);
      await settle(container);

      // No entries found in `reminder_completions`: a care reminder was not...
      // The rule is that care, as an event, reveals the truth; otherwise, "fact" would be misleading.
      expect(repo.recordCompletionCallCount, 0);
      expect(repo.lastRecordCompletionBabyId, isNull);
      // And without any specific event, the amount remains outstanding.
      expect(ids(container), contains('vitamine_d'));
    });
  });

  group('snooze (D3)', () {
    test("l'ignorer supprime la ligne pour le bébé actif, pas pour les autres",
        () async {
      final repo = ScopedDismissalRemindersRepository();
      final baby = _SwitchableBabyNotifier(babyA);
      final container = buildContainer(repo, baby);
      await settle(container);
      expect(ids(container), contains('vitamine_d'));

      final status = container
          .read(reminderNotifierProvider)
          .value!
          .values
          .expand((s) => s)
          .firstWhere((s) => s.item.id == 'vitamine_d');
      await container
          .read(reminderNotifierProvider.notifier)
          .snooze(status.item);
      await settle(container);

      expect(repo.dismissCallCount, 1);
      expect(repo.lastDismissBabyId, babyA.id);
      expect(ids(container), isNot(contains('vitamine_d')));

      // Same repository, different baby: deletion is not an option for him.
      baby.switchTo(babyB);
      await settle(container);
      expect(ids(container), contains('vitamine_d'));
    });

    test('supprimé 24 h : encore éteint à +1 h, de nouveau dû à +25 h',
        () async {
      final repo = ScopedDismissalRemindersRepository();
      final baby = _SwitchableBabyNotifier(babyA);
      final container = buildContainer(repo, baby);
      await settle(container);

      final status = container
          .read(reminderNotifierProvider)
          .value!
          .values
          .expand((s) => s)
          .firstWhere((s) => s.item.id == 'vitamine_d');
      await container
          .read(reminderNotifierProvider.notifier)
          .snooze(status.item);
      await settle(container);
      expect(ids(container), isNot(contains('vitamine_d')));

      // +1 hour: Well within the 24-hour window.
      repo.seedDismissal(
        'vitamine_d',
        babyId: babyA.id,
        at: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await container.read(reminderNotifierProvider.notifier).refresh();
      await settle(container);
      expect(ids(container), isNot(contains('vitamine_d')));

      // +25 hours: The timeout period has been exceeded, and the notification is automatically reappearing.
      repo.seedDismissal(
        'vitamine_d',
        babyId: babyA.id,
        at: DateTime.now().subtract(const Duration(hours: 25)),
      );
      await container.read(reminderNotifierProvider.notifier).refresh();
      await settle(container);
      expect(ids(container), contains('vitamine_d'));
    });
  });

  group('dernière complétion', () {
    test('un détaché lit « dernière fois » depuis le journal manuel', () async {
      final repo = ScopedDismissalRemindersRepository();
      // The deposit is applied before the container: this is how the provider chain works.
      // Read it on the first listen, not after.
      final at = DateTime(2026, 8, 1, 9);
      repo.customRemindersById[1] = thermometer();
      repo.manualCompletedByItem['custom_1'] = at;
      final baby = _SwitchableBabyNotifier(babyA);
      final container = buildContainer(repo, baby);
      await settle(container);

      final status = container
          .read(reminderNotifierProvider)
          .value!
          .values
          .expand((s) => s)
          .firstWhere((s) => s.item.id == 'custom_1');
      // Daily, set up two months ago: still outstanding, but the service is active.
      // Manual log timestamping – not "never done before."
      expect(status.lastEventAt, at);
    });
  });
}

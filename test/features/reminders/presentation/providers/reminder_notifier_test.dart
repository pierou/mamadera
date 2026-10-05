import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

import '../../data/repositories/mock_reminders_repository.dart';

/// Notifier de bébé commutable en test : sans base, l'état se pilote à la
/// main et le notifier de rappels le suit par son `ref.watch`.
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

  /// Rappel détaché (D2) : thermomètre, quotidien, réglé par le tap « Fait ».
  CustomReminder thermometer() => CustomReminder(
        id: 1,
        label: 'Thermomètre',
        frequency: const ReminderFrequency.daily(),
        subtypeValue: null,
        completionSource: completionManual,
      );

  /// Conteneur des tests de notifier : le dépôt est le seul point d'entrée —
  /// la chaîne service réelle (préréglages du bébé actif + rappels custom du
  /// dépôt) se cale toute seule dessus, comme dans les tests de réglages.
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
    // Le notifier attend, en `ref.watch`, un service `autoDispose` : l'auditeur
    // ci-dessous tient le notifier vivant pendant que la lecture s'établit,
    // comme l'app fait en permanence (pastille, accueil).
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
    test('un détaché : le journal manuel est scopé au bébé actif, la ligne part',
        () async {
      final repo = ScopedDismissalRemindersRepository();
      // Le dépôt est semé avant le container : la chaîne de providers le
      // lit à la première écoute, pas après.
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
      await container.read(reminderNotifierProvider.notifier).markDone(status.item);
      await settle(container);

      expect(ids(container), isNot(contains('custom_1')));
      expect(repo.recordCompletionCallCount, 1);
      expect(repo.lastRecordCompletionBabyId, babyA.id);
      expect(repo.manualCompletedByItem['custom_1'], isNotNull);
      // Le journal a réglé le rappel pour aujourd'hui : plus dû à nouveau
      // tant que le jour ne change pas (fréquence quotidienne).
      expect(
        item.frequency.isDue(DateTime.now(), repo.manualCompletedByItem['custom_1']),
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
      await container.read(reminderNotifierProvider.notifier).markDone(status.item);
      await settle(container);

      // Aucun écrit dans `reminder_completions` : un rappel de soin ne se
      // règle que par l'événement du soin — sinon « fait » mentirait.
      expect(repo.recordCompletionCallCount, 0);
      expect(repo.lastRecordCompletionBabyId, isNull);
      // Et sans événement, il reste dû.
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
      await container.read(reminderNotifierProvider.notifier).snooze(status.item);
      await settle(container);

      expect(repo.dismissCallCount, 1);
      expect(repo.lastDismissBabyId, babyA.id);
      expect(ids(container), isNot(contains('vitamine_d')));

      // Même dépôt, autre bébé : la suppression n'existe pas pour lui.
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
      await container.read(reminderNotifierProvider.notifier).snooze(status.item);
      await settle(container);
      expect(ids(container), isNot(contains('vitamine_d')));

      // +1 h : bien à l'intérieur de la fenêtre de 24 h.
      repo.seedDismissal(
        'vitamine_d',
        babyId: babyA.id,
        at: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await container.read(reminderNotifierProvider.notifier).refresh();
      await settle(container);
      expect(ids(container), isNot(contains('vitamine_d')));

      // +25 h : la fenêtre est dépassée, le rappel revient tout seul.
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
      // Le dépôt est semé avant le container : la chaîne de providers le
      // lit à la première écoute, pas après.
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
      // Quotidien, réglé il y a deux mois : toujours dû, mais la ligne porte
      // l'horodatage du journal manuel — pas « jamais fait ».
      expect(status.lastEventAt, at);
    });
  });
}

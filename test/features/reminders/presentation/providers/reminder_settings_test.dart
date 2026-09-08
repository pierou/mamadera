import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

import '../../data/repositories/mock_reminders_repository.dart';

/// Stub notifier that returns a fixed baby profile on build.
class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}

final _baby = BabyProfile(
  id: 'baby-1',
  name: 'Léa',
  birthDate: DateTime(2026, 1, 15),
);

void main() {
  late MockRemindersRepository mockReminders;
  late ProviderContainer container;

  ProviderContainer buildContainer() => ProviderContainer(
        overrides: [
          remindersRepositoryProvider.overrideWith((ref) async => mockReminders),
          activeBabyProvider.overrideWith(() => _ActiveBabyStub(_baby)),
        ],
      );

  /// L'accueil écoute `reminderNotifierProvider` en permanence ; un test qui s'en
  /// passe ne reçoit jamais de réponse : le notifieur attend, en `ref.read`, un
  /// service `autoDispose` que rien ne maintient vivant pendant son chargement.
  /// Les tests de pastilles branchent donc l'auditeur que l'app tient déjà.
  void watchPills(ProviderContainer c) =>
      c.listen(reminderNotifierProvider, (_, __) {});

  setUp(() {
    mockReminders = MockRemindersRepository();
    container = buildContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('reminderSettingsProvider', () {
    test('starts empty on a fresh install: nothing has been switched off', () async {
      expect(await container.read(reminderSettingsProvider.future), isEmpty);
    });

    test('loads the overrides already stored in the database', () async {
      mockReminders.enabledById[ReminderItemPresets.vitaminK.id] = false;

      expect(
        await container.read(reminderSettingsProvider.future),
        {ReminderItemPresets.vitaminK.id: false},
      );
    });
  });

  group('enabledRemindersProvider', () {
    test('keeps every preset when the parent never opted out', () async {
      final items = await container.read(enabledRemindersProvider.future);

      expect(items.map((item) => item.id), ReminderItemPresets.buildForBaby(_baby).map((item) => item.id));
    });

    test('drops the reminders that were switched off, keeps the others', () async {
      mockReminders.enabledById[ReminderItemPresets.vitaminD.id] = false;

      final items = await container.read(enabledRemindersProvider.future);

      expect(items.map((item) => item.id), isNot(contains(ReminderItemPresets.vitaminD.id)));
      expect(items.map((item) => item.id), contains(ReminderItemPresets.vitaminK.id));
    });

    test('a stored enabled: true keeps the reminder', () async {
      mockReminders.enabledById[ReminderItemPresets.vitaminD.id] = true;

      final items = await container.read(enabledRemindersProvider.future);

      expect(items.map((item) => item.id), contains(ReminderItemPresets.vitaminD.id));
    });

    test('an unknown item id in the settings table changes nothing', () async {
      // Une ligne orpheline (rappel supprimé d'une version à l'autre, restauration
      // d'une sauvegarde plus ancienne) ne doit pas faire disparaître les autres.
      mockReminders.enabledById['old_reminder'] = false;

      final items = await container.read(enabledRemindersProvider.future);

      expect(items, hasLength(4));
    });

    test('disabling every reminder leaves nothing to ring', () async {
      for (final item in ReminderItemPresets.buildForBaby(_baby)) {
        mockReminders.enabledById[item.id] = false;
      }

      expect(await container.read(enabledRemindersProvider.future), isEmpty);
    });
  });

  group('ReminderSettingsNotifier.setEnabled', () {
    test('writes through to the repository and updates state at once', () async {
      await container.read(reminderSettingsProvider.future);
      final notifier = container.read(reminderSettingsProvider.notifier);

      await notifier.setEnabled(
        ReminderItemPresets.vitaminD.id,
        enabled: false,
      );

      expect(mockReminders.enabledById[ReminderItemPresets.vitaminD.id], isFalse);
      expect(mockReminders.setEnabledCallCount, 1);
      // Pas de rechargement : le switch ne doit pas revenir en arrière une frame.
      expect(
        container.read(reminderSettingsProvider).value,
        {ReminderItemPresets.vitaminD.id: false},
      );
    });

    test('re-enabling a reminder is stored explicitly, not deleted', () async {
      mockReminders.enabledById[ReminderItemPresets.vitaminD.id] = false;
      await container.read(reminderSettingsProvider.future);

      await container
          .read(reminderSettingsProvider.notifier)
          .setEnabled(ReminderItemPresets.vitaminD.id, enabled: true);

      expect(mockReminders.enabledById[ReminderItemPresets.vitaminD.id], isTrue);
    });
  });

  group('home pills follow the settings', () {
    test('a disabled reminder stops showing on the home screen', () async {
      watchPills(container);
      final first = await container.read(reminderNotifierProvider.future);
      expect(first[TrackingType.sante]?.map((status) => status.item.id),
          contains(ReminderItemPresets.eyeCleaning.id));

      await container
          .read(reminderSettingsProvider.notifier)
          .setEnabled(ReminderItemPresets.eyeCleaning.id, enabled: false);

      final after = await container.read(reminderNotifierProvider.future);

      expect(after[TrackingType.sante]?.map((status) => status.item.id),
          isNot(contains(ReminderItemPresets.eyeCleaning.id)));
      expect(after[TrackingType.sante]?.map((status) => status.item.id),
          contains(ReminderItemPresets.vitaminD.id));
    });

    test('a disabled reminder is no longer queried at all', () async {
      mockReminders.enabledById[ReminderItemPresets.vitaminK.id] = false;
      watchPills(container);

      await container.read(reminderNotifierProvider.future);

      expect(mockReminders.lookedUpItemIds, isNot(contains(ReminderItemPresets.vitaminK.id)));
      expect(mockReminders.lookedUpItemIds, contains(ReminderItemPresets.vitaminD.id));
    });

    test('switching everything off clears the home screen', () async {
      for (final item in ReminderItemPresets.buildForBaby(_baby)) {
        mockReminders.enabledById[item.id] = false;
      }
      watchPills(container);

      expect(await container.read(reminderNotifierProvider.future), isEmpty);
    });
  });
}

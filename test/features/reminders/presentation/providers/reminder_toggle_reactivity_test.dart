import 'dart:async';

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

/// Item 5 regression (v1.1.1): After toggling a setting in the "Settings" section, the home screen should...
/// receive the new state without waiting for the five-minute survey — whatever.
/// either the moment when the settings chain -> reminders enabled -> service is activated,
/// in relation to the invalidation.
///
/// The previous mechanism relied on `ref.invalidate(reminderNotifierProvider)`.
/// In the `setEnabled` method: if the notifier was reconstructing and reading the service beforehand.
/// Even though the upstream team had resolved the issue, the service was still built on the old infrastructure.
/// list, and the marker would remain (until the next update — or forever, if the...
/// Tick had been killed by the reconstruction: second test of this file.
///
/// Like the rest of the suite, these tests are run using `test()` (a proper loop).
/// (of events): Under `testWidgets`, `FakeAsync` does not advance the...
/// A chain of providers in Riverpod.
void main() {
  late MockRemindersRepository mockReminders;
  late Future<List<ReminderItem>> dynamicGate;

  /// Create a container using the deposit mock, with [dynamicGate] on the list.
  /// dynamic, and—if provided—a short-interval reminder notifier.
  ProviderContainer buildContainer({Duration? pollInterval}) =>
      ProviderContainer(
        overrides: [
          remindersRepositoryProvider.overrideWith((ref) async => mockReminders),
          activeBabyProvider.overrideWith(() => _ActiveBabyStub(_baby)),
          // Each reevaluation reviews [dynamicGate], which can be kept running.
          // waiting for the simulation to reach a point where a chain is still in flight at the moment the switch is activated.
          dynamicRemindersProvider.overrideWith((ref) => dynamicGate),
          if (pollInterval != null)
            reminderNotifierProvider
                .overrideWith(() => RemindersNotifier(pollInterval: pollInterval)),
        ],
      );

  /// The reception system is constantly listening for the signal: without this receiver, the...
  /// Temporary reading of the autoDispose service within the `_checkDue` function does not...
  /// never resolves (see [reminder_settings_test.dart]).
  void watchPills(ProviderContainer c) =>
      c.listen(reminderNotifierProvider, (_, __) {});

  /// Let the stream of providers empty into the main event loop.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 200));

  setUp(() {
    mockReminders = MockRemindersRepository();
    dynamicGate = Future.value([
      ReminderItemPresets.vitaminD,
      ReminderItemPresets.eyeCleaning
    ]);
  });

  test('un rappel éteint disparaît de l’accueil quand la chaîne se cale après le toggle',
      () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    watchPills(container);

    final initial = await container.read(reminderNotifierProvider.future);
    expect(
      initial[TrackingType.sante]?.map((s) => s.item.id).toSet(),
      {ReminderItemPresets.vitaminD.id, ReminderItemPresets.eyeCleaning.id},
    );

    // The timing will be "later" than the action: keep the list.
    // dynamique en attente pendant que le parent bascule le switch.
    final hold = Completer<List<ReminderItem>>();
    dynamicGate = hold.future;

    await container
        .read(reminderSettingsProvider.notifier)
        .setEnabled(ReminderItemPresets.eyeCleaning.id, enabled: false);

    // Let the chain finish: the dynamic list doesn't change, it's the only thing that does.
    // l’extinction est nouvelle.
    hold.complete([
      ReminderItemPresets.vitaminD,
      ReminderItemPresets.eyeCleaning
    ]);
    await settle();

    final after = container.read(reminderNotifierProvider).value;
    expect(after?[TrackingType.sante]?.map((s) => s.item.id),
        isNot(contains(ReminderItemPresets.eyeCleaning.id)),
        reason:
            'la pastille du rappel éteint doit partir sans attendre le tick');
    expect(
        after?[TrackingType.sante]?.map((s) => s.item.id),
        contains(ReminderItemPresets.vitaminD.id));
  });

  test('le sondage périodique survit à une reconstruction par invalidation',
      () async {
    final container = buildContainer(pollInterval: const Duration(milliseconds: 200));
    addTearDown(container.dispose);
    watchPills(container);

    await container.read(reminderNotifierProvider.future);
    final lookupsBefore = mockReminders.completedLookupCount;

    // Here's what `setEnabled` used to do: it would invalidate the notifier.
    // which restarts the `build()` function—and therefore, the timer's lifecycle.
    container.invalidate(reminderNotifierProvider);
    await container.read(reminderNotifierProvider.future);
    await settle();
    final lookupsAfterRebuild = mockReminders.completedLookupCount;
    expect(lookupsAfterRebuild, greaterThan(lookupsBefore),
        reason: 'la reconstruction a dû relire les complétions');

    // Two seconds later, the counter should have changed again:
    // If he had been killed by the cycle of life and reconstruction, he would be...
    // remained frozen.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(mockReminders.completedLookupCount, greaterThan(lookupsAfterRebuild),
        reason:
            'le sondage périodique a survécu à la reconstruction par invalidation');
  });
}

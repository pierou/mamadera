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

/// Régression item 5 (v1.1.1) : après un toggle dans Réglages, l'accueil doit
/// recevoir le nouvel état sans attendre le sondage de cinq minutes — quel que
/// soit le moment où la chaîne réglages → rappels activés → service se cale,
/// par rapport à l'invalidation.
///
/// L'ancien mécanisme appuyait sur `ref.invalidate(reminderNotifierProvider)`
/// dans `setEnabled` : si la reconstruction du notifieur lisait le service avant
/// que la chaîne en amont ait résolu, le service était construit sur l'ancienne
/// liste et la pastille survivait (jusqu'au prochain tick — ou à jamais, si le
/// tick avait été tué par la reconstruction : deuxième test de ce fichier).
///
/// Comme le reste de la suite, ces tests tournent sous `test()` (vraie boucle
/// d'événements) : sous `testWidgets`, le FakeAsync ne fait pas progresser la
/// chaîne de providers riverpod.
void main() {
  late MockRemindersRepository mockReminders;
  late Future<List<ReminderItem>> dynamicGate;

  /// Fabrique un conteneur avec le mock de dépôt, [dynamicGate] sur la liste
  /// dynamique, et — si fourni — un notifieur de rappels à intervalle court.
  ProviderContainer buildContainer({Duration? pollInterval}) =>
      ProviderContainer(
        overrides: [
          remindersRepositoryProvider.overrideWith((ref) async => mockReminders),
          activeBabyProvider.overrideWith(() => _ActiveBabyStub(_baby)),
          // Chaque réévaluation relit [dynamicGate], qu'on peut tenir en
          // attente pour simuler une chaîne encore en vol au moment du toggle.
          dynamicRemindersProvider.overrideWith((ref) => dynamicGate),
          if (pollInterval != null)
            reminderNotifierProvider
                .overrideWith(() => RemindersNotifier(pollInterval: pollInterval)),
        ],
      );

  /// L'accueil écoute le notifieur en permanence : sans cet écouteur, la
  /// lecture transitoire du service autoDispose dans `_checkDue` ne se
  /// résout jamais (voir [reminder_settings_test.dart]).
  void watchPills(ProviderContainer c) =>
      c.listen(reminderNotifierProvider, (_, __) {});

  /// Laisse la cascade de providers se vider sur la vraie boucle d'événements.
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

    // La chaîne va se caler « plus tard » que le geste : tenir la liste
    // dynamique en attente pendant que le parent bascule le switch.
    final hold = Completer<List<ReminderItem>>();
    dynamicGate = hold.future;

    await container
        .read(reminderSettingsProvider.notifier)
        .setEnabled(ReminderItemPresets.eyeCleaning.id, enabled: false);

    // Laisse la chaîne terminer : la liste dynamique ne change pas, seule
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

    // Ce que `setEnabled` faisait à l'ancienne : invalider le notifieur, ce
    // qui relance `build()` — et donc le cycle de vie du timer.
    container.invalidate(reminderNotifierProvider);
    await container.read(reminderNotifierProvider.future);
    await settle();
    final lookupsAfterRebuild = mockReminders.completedLookupCount;
    expect(lookupsAfterRebuild, greaterThan(lookupsBefore),
        reason: 'la reconstruction a dû relire les complétions');

    // Deux ticks plus tard, le compteur doit avoir bougé de nouveau :
    // s'il avait été tué par le cycle de vie de la reconstruction, il serait
    // resté figé.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(mockReminders.completedLookupCount, greaterThan(lookupsAfterRebuild),
        reason:
            'le sondage périodique a survécu à la reconstruction par invalidation');
  });
}

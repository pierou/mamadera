import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/l10n/app_localizations.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/home/presentation/screens/home_screen.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

import '../../../reminders/data/repositories/mock_reminders_repository.dart';
import '../../../reminders/presentation/providers/no_poll_reminders_notifier.dart';

/// Welcome harness for the baby's name, active mode: same overrides.
/// that the main harness (memory recall storage, notify without...).
/// timer, empty measurements, existing profile) plus a baby monitor.
/// This can be used to verify that the header is active and not captured.
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

  /// The all-in-one pump provides complete breast milk expression and sends a notification to your phone when it's time to feed the baby.
  /// Profile change during the test.
  Future<_SwitchableBabyNotifier> pumpHome(
    WidgetTester tester, {
    required BabyProfile? baby,
  }) async {
    final babyNotifier = _SwitchableBabyNotifier(baby);
    tester.view.physicalSize = const Size(600, 900);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The growth row should not expose the actual base during testing.
          measurementNotifierProvider
              .overrideWith(() => _NoMeasurementsNotifier()),
          activeBabyProvider.overrideWith(() => babyNotifier),
          anyBabyExistsProvider.overrideWith(() => _BabyExistsNotifier()),
          // The recall section fills up without a base: it's a memory-based system.
          // Notify without polling timer (same recipe as the harness).
          // principal).
          remindersRepositoryProvider
              .overrideWith((ref) async => MockRemindersRepository()),
          reminderNotifierProvider.overrideWith(NoPollRemindersNotifier.new),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.theme,
          home: Scaffold(body: const HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return babyNotifier;
  }

  group('Prénom du bébé actif sur l’accueil', () {
    testWidgets('shows the active baby name on home', (tester) async {
      await pumpHome(tester, baby: babyA);

      // The header displays the first name, clearly visible, above the grid.
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('the name is carried by the AppBar title, not the body',
        (tester) async {
      await pumpHome(tester, baby: babyA);

      // The first name is displayed in the title bar of the app (within the safe area).
      // (Scaffolding): Placed at the top of the screen, it extended beneath the...
      // system status bar on Android.
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
      expect((appBar.title! as Text).data, 'Anna');
    });

    testWidgets('no active baby means no AppBar on home', (tester) async {
      await pumpHome(tester, baby: null);

      // No active baby: no app bar, and the content remains.
      // under the status bar, using its own Safe Area.
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('switching the active baby updates the name shown',
        (tester) async {
      final babyNotifier = await pumpHome(tester, baby: babyA);
      expect(find.text('Anna'), findsOneWidget);

      // The parent switches to the other baby: the header and title of the reminders.
      // - A given name captured at the initial construction would remain.
      // regarding "Anna" and would cause the test to fail.
      babyNotifier.switchTo(babyB);
      await tester.pumpAndSettle();

      expect(find.text('Anna'), findsNothing);
      expect(find.text('Boris'), findsOneWidget);
    });

    testWidgets('no active baby renders no name and no null text',
        (tester) async {
      await pumpHome(tester, baby: null);

      // No "null" values, no fake identities: the initial launch.
      // It manages the creation of the profile.
      expect(find.text('null'), findsNothing);

      // The notification titles use a neutral form, without any first names.
      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));
      expect(find.text(l10n.reminderListTitle), findsOneWidget);
    });

    testWidgets('reminders header contains the name via the l10n placeholder',
        (tester) async {
      await pumpHome(tester, baby: babyA);

      // The statement refers to the message conveyed by the channel, not to a specific individual.
      // French text copied here.
      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));
      expect(find.text(l10n.reminderListTitleFor('Anna')), findsOneWidget);
      // And the neutral form no longer exists as soon as a first name is used.
      expect(find.text(l10n.reminderListTitle), findsNothing);
    });

    testWidgets('a 30 character baby name does not overflow', (tester) async {
      const longName = 'Aaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final baby = BabyProfile(
        id: 'long',
        name: longName,
        birthDate: DateTime(2024, 3, 10),
      );
      await pumpHome(tester, baby: baby);

      // The header is truncated (indicated by an ellipsis): no overflow errors reported.
      expect(tester.takeException(), isNull);
      expect(find.text(longName), findsOneWidget);
    });
  });
}

/// Switchable baby monitor: changing the profile publishes the status.
/// directly, like a successful [ActiveBabyNotifier.switchProfile] function.
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

/// A profile already exists: the onboarding process does not open, and the welcome screen is hidden.
class _BabyExistsNotifier extends AnyBabyExistsNotifier {
  _BabyExistsNotifier();

  @override
  Future<bool> build() async => true;
}

/// Empty fields: The growth row displays dashes without a base value.
class _NoMeasurementsNotifier extends MeasurementNotifier {
  _NoMeasurementsNotifier();

  @override
  Future<List<GrowthMeasurement>> build() async => const [];
}

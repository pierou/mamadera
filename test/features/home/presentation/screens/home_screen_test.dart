import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/l10n/app_localizations.dart';

import 'package:mamadera/core/theme.dart';
import 'package:mamadera/core/config/app_config.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/domain/repositories/measurement_repository.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/providers/theme_provider.dart';
import 'package:mamadera/core/router.dart';
import 'package:mamadera/core/services/app_preferences_service.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/core/services/theme_service.dart';
import 'package:mamadera/core/widgets/event_date_time_field.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/growth/presentation/widgets/measurement_button.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/features/history/presentation/screens/history_screen.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/home/presentation/screens/home_screen.dart';
import 'package:mamadera/features/home/presentation/widgets/onboarding_dialog.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
import 'package:mamadera/features/menu/presentation/screens/menu_screen.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/features/reminders/presentation/widgets/reminder_row.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../reminders/data/repositories/mock_reminders_repository.dart';
import '../../../reminders/presentation/providers/no_poll_reminders_notifier.dart';
import 'home_screen_test.mocks.dart';

/// Helper: Find a TrackButton by its label.
Finder findTrackButton(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TrackButton && widget.label == label,
  );
}

@GenerateNiceMocks([MockSpec<TrackingRepository>()])
void main() {
  late MockTrackingRepository mockRepo;

  setUp(() {
    mockRepo = MockTrackingRepository();
    TestActiveBabyNotifier.activeProfile = BabyProfile(
      id: 'test-baby-1',
      name: 'Test Baby',
      birthDate: DateTime.utc(2024, 1, 1),
      isActive: true,
    );
    TestAnyBabyExistsNotifier.anyExists = true;
  });

  tearDown(() {
    TestActiveBabyNotifier.activeProfile = null;
    TestAnyBabyExistsNotifier.anyExists = false;
  });

  /// Helper: Use the HomeScreen component with a mocked repository and an active user to bypass the onboarding process.
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          measurementRepositoryProvider
              .overrideWith((ref) async => _FakeMeasurementRepository()),
          trackingRepositoryProvider.overrideWith((ref) async => mockRepo),
          // The growth row should not expose the actual base during testing.
          measurementNotifierProvider
              .overrideWith(() => TestMeasurementNotifier(const [])),
          // Override with a test notifier that resolves synchronously via Future.microtask.
          activeBabyProvider.overrideWith(TestActiveBabyNotifier.new),
          anyBabyExistsProvider.overrideWith(TestAnyBabyExistsNotifier.new),
          // The recall section (D1) assesses the notification; the version of...
          // test ne laisse pas le timer de sondage de cinq minutes en attente.
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
  }

  // ──────────────────────────────────────────────
  // Displaying the Track Buttons.
  // ──────────────────────────────────────────────
  // ──────────────────────────────────────────────
  // Boutons de mesure (croissance, item 1 de v1.2.0)
  // ──────────────────────────────────────────────
  group('Boutons de mesure (croissance)', () {
    testWidgets('les 3 boutons de mesure s affichent sans toucher la grille',
        (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.byType(TrackButton), findsNWidgets(4));
      expect(find.byType(MeasurementButton), findsNWidgets(3));
      expect(find.text('Poids'), findsOneWidget);
      expect(find.text('Taille'), findsOneWidget);
      expect(find.text('Température'), findsOneWidget);
    });

    testWidgets('sans mesure, chaque bouton affiche un tiret', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('—'), findsNWidgets(3));
    });
  });

  group('Affichage des 4 TrackButtons', () {
    testWidgets('Nourriture, Sante, Couche, Dodo sont affiches',
        (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('Nourriture'), findsOneWidget);
      expect(find.text('Sant\u00e9'), findsOneWidget);
      expect(find.text('Couche'), findsOneWidget);
      expect(find.text('Dodo'), findsOneWidget);
    });

    testWidgets('chaque TrackButton a la couleur AppTheme attendue',
        (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // TrackButtons now use outlined cards with accent-colored borders and text
      final trackButtons =
          tester.widgetList<TrackButton>(find.byType(TrackButton)).toList();
      expect(trackButtons.length, 4);

      final colors = trackButtons.map((b) => b.color).toSet();
      expect(colors.contains(AppTheme.miam), isTrue, reason: 'Nourriture');
      expect(colors.contains(AppTheme.sante), isTrue, reason: 'Sant\u00e9');
      expect(colors.contains(AppTheme.caca), isTrue, reason: 'Couche');
      expect(colors.contains(AppTheme.dodo), isTrue, reason: 'Dodo');
    });

    testWidgets('no BottomNavigationBar in HomeScreen (provided by AppShell)',
        (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // HomeScreen no longer renders a Scaffold or BottomNavigationBar.
      // Those are provided by AppShell via go_router ShellRoute.
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });

  // ──────────────────────────────────────────────
  // Reminders are available under the (D1, M6) buttons.
  // ──────────────────────────────────────────────
  group('Rappels dus sous les boutons (D1)', () {
    /// The same harness as [pumpHome], but with a reminder storage compartment.
    /// Memory: The actual device produces the 4 pre-programmed settings for babies.
    /// The system is active, the list below the buttons is stable, and all 4 lines are readable.
    Future<void> pumpHomeWithDueReminders(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 900);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            trackingRepositoryProvider.overrideWith((ref) async => mockRepo),
            measurementNotifierProvider
                .overrideWith(() => TestMeasurementNotifier(const [])),
            activeBabyProvider.overrideWith(TestActiveBabyNotifier.new),
            anyBabyExistsProvider.overrideWith(TestAnyBabyExistsNotifier.new),
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
    }

    testWidgets(
        'les 4 rappels dus sont lisibles, grille et boutons de '
        'croissance inchangés', (tester) async {
      await pumpHomeWithDueReminders(tester);

      // The four track buttons and the three growth buttons are still present.
      expect(find.byType(TrackButton), findsNWidgets(4));
      expect(find.byType(MeasurementButton), findsNWidgets(3));

      // The four outstanding recall notices are listed individually, not aggregated into a single "+2" entry.
      // The title includes the baby's first name (version 1.2, with localization support).
      // (placeholder): The previous, more precise feature: "Reminders to do."
      // It described the state without a name, replacing it with the name of the channel.
      expect(find.text('Rappels de Test Baby à faire'), findsOneWidget);
      expect(find.byType(ReminderRow), findsNWidgets(4));
      expect(find.text('Vitamine D'), findsOneWidget);
      expect(find.text('Vitamine K'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
      expect(find.text('Nettoyage du visage'), findsOneWidget);
    });

    testWidgets('la grille reste utilisable : Nourriture ouvre sa feuille',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);
      // Three sub-types of pins: the pin extends beyond the harness, with dimensions of 200x300.
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpHomeWithDueReminders(tester);

      await tester.tap(findTrackButton('Nourriture'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets(
        'les boutons de croissance restent utilisables : Poids '
        'ouvre sa feuille', (tester) async {
      await pumpHomeWithDueReminders(tester);

      // The measuring sheet is taller than the 600x900 screen of the harness.
      // We're looking at a screen that's the size of a sheet of paper, just like the harness.
      // onboarding ci-dessous.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 3200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();

      final poids = find.text('Poids');
      expect(poids, findsOneWidget);
      await tester.tap(poids);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Navigation via bottom nav
  //
  // "Take Control" (M6): These tests were designed to test HomeScreen in isolation, without involving other components.
  // router - the navigation bar was missing, and the tap could not...
  // that would explode, hence the old ski jumps. Now, they're pumping in the real [substance/fuel/etc.].
  // app router, with deterministic providers (same recipe as...).
  // test/core/router_test.dart): the history stack, the locale, and the...
  // The themes are replaced because the channels they are expecting (the database) are not available.
  // The packages 'data' and 'path_provider' never work in this environment.
  // they would test and leave the screens spinning indefinitely.
  // ──────────────────────────────────────────────
  group('Navigation via bottom nav', () {
    /// Pompe is the core router within the app, handling navigation from the splash screen to the home screen, and managing different providers.
    /// deterministic (preferences accepted, babies remembered, measurements).
    /// (empty states, reminders due to stable conditions, resolved profiles in the absence of input).
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            appPreferencesProvider.overrideWith(_AcceptedPrefsNotifier.new),
            trackingRepositoryProvider.overrideWith((ref) async => mockRepo),
            measurementNotifierProvider
                .overrideWith(() => TestMeasurementNotifier(const [])),
            activeBabyProvider.overrideWith(TestActiveBabyNotifier.new),
            anyBabyExistsProvider.overrideWith(TestAnyBabyExistsNotifier.new),
            babyProfileListProvider
                .overrideWith((ref) async => const <BabyProfile>[]),
            remindersRepositoryProvider
                .overrideWith((ref) async => MockRemindersRepository()),
            reminderNotifierProvider.overrideWith(NoPollRemindersNotifier.new),
            historyRepositoryProvider
                .overrideWith((ref) async => _EmptyHistoryRepository()),
            localeProvider.overrideWith(_LocalePrefsNotifier.new),
            themeProvider.overrideWith(_ThemePrefsNotifier.new),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.theme,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
    }

    testWidgets('tap Historique -> affiche HistoryScreen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('history-tab')));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('tap Menu -> affiche MenuScreen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('menu-tab')));
      await tester.pumpAndSettle();

      expect(find.byType(MenuScreen), findsOneWidget);
    });

    testWidgets('tap Accueil -> retour a la grille', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('history-tab')));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-tab')));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsNothing);
      expect(find.byType(TrackButton), findsNWidgets(4));
    });
  });

  // ──────────────────────────────────────────────
  // Interactions TrackButtons -> dialogs ouverts
  // ──────────────────────────────────────────────
  group('Interactions Nourriture/Sante/Couche/Dodo', () {
    testWidgets('tap Nourriture -> ouvre FeedingTrackingDialog',
        (tester) async {
      // Three sub-types of pins: the pin extends beyond the harness, with dimensions of 200x300.
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpHome(tester);
      await tester.pumpAndSettle();

      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      final miamBtn = find.text('Nourriture');
      expect(miamBtn, findsOneWidget);

      await tester.tap(miamBtn);
      await tester.pumpAndSettle();

      // A bottom sheet needs to be opened (the food tracking dialog).
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('tap Sante -> ouverture HealthSubtypeDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final santeBtn = find.text('Sant\u00e9');
      expect(santeBtn, findsOneWidget);

      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Dialog doit contenir "Type de soin".
      expect(find.text('Type de soin'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
    });

    testWidgets('tap Couche -> ouverture WasteDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final cacaBtn = findTrackButton('Couche');
      expect(cacaBtn, findsOneWidget);

      await tester.tap(cacaBtn);
      await tester.pumpAndSettle();

      // FilterChips avec emojis.
      expect(find.text('🟡 Pipi'), findsOneWidget);
    });

    testWidgets('tap Dodo -> ouverture DurationPickerDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      expect(dodoBtn, findsOneWidget);

      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Titre du DurationPickerDialog.
      expect(find.text('Dur\u00e9e du sommeil'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Confirmation des dialogues -> insertEvent appele
  // ──────────────────────────────────────────────
  group('Confirmation des dialogues', () {
    testWidgets('Dodo: Confirmer envoie SleepEvent via insertEvent',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Default duration: 30 minutes.
      expect(find.text('30 min'), findsOneWidget);

      // Confirmer.
      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The `insertEvent` function was called with a `SleepEvent`.
      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<SleepEvent>());
    });

    testWidgets('Dodo: Annuler ne declenche aucun evenement', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Tap outside the bottom sheet to close it.
      await tester.tapAt(const Offset(400, 50));
      await tester.pumpAndSettle();

      verifyNever(mockRepo.insertEvent(any));
    });

    testWidgets('Sante: Confirmer sans selection -> SnackBar d\'erreur',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final santeBtn = find.text('Sant\u00e9');
      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Tap Confirmer sans selection.
      final confirmButton = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // SnackBar d'erreur.
      expect(find.textContaining('électionner'), findsOneWidget);
    });

    testWidgets('Sante: Selection + Confirmer -> HealthEvent via insertEvent',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final santeBtn = find.text('Sant\u00e9');
      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Selectionner "Nettoyage des yeux".
      final nettoyageYeux = find.text('Nettoyage des yeux');
      expect(nettoyageYeux, findsOneWidget);
      await tester.ensureVisible(nettoyageYeux);
      await tester.tap(nettoyageYeux, warnIfMissed: false);
      await tester.pumpAndSettle();

      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<HealthEvent>());
    });

    testWidgets('Couche: Confirmer -> DiaperEvent via insertEvent',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final cacaBtn = findTrackButton('Couche');
      await tester.tap(cacaBtn);
      await tester.pumpAndSettle();

      expect(find.text('🟡 Pipi'), findsOneWidget);
      expect(find.text('🟤 Caca'), findsOneWidget);

      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<DiaperEvent>());
    });
  });

  // ──────────────────────────────────────────────
  // Event date at creation.
  // ──────────────────────────────────────────────
  group('Date de saisie', () {
    Future<void> openSheetAndConfirm(
        WidgetTester tester, String buttonLabel) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(findTrackButton(buttonLabel));
      await tester.pumpAndSettle();

      // Every input form displays the date/time field.
      expect(find.byType(EventDateTimeField), findsOneWidget,
          reason: 'le dialogue $buttonLabel doit laisser choisir la date');

      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('Nourriture : la date par défaut est le moment de la saisie',
        (tester) async {
      // Three subtypes of pins: the power supply pin protrudes from...
      // The default size for the "harnais" sheet is 200x300 (like the other high-resolution sheets).
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);

      final before = DateTime.now();
      await openSheetAndConfirm(tester, 'Nourriture');

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single
          as TrackingEvent;
      expect(
          event.timestamp.isBefore(before.subtract(const Duration(minutes: 1))),
          isFalse);
      expect(event.timestamp.isAfter(DateTime.now()), isFalse);
    });

    testWidgets('Dodo : la date par défaut recule de la durée saisie',
        (tester) async {
      await openSheetAndConfirm(tester, 'Dodo');

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single
          as SleepEvent;
      // Default slider duration: 30 minutes → A nap started at 8:30 PM will be...
      // Recorded at 8:30 PM, not on time.
      final expected = DateTime.now().subtract(const Duration(minutes: 30));
      expect(event.timestamp.difference(expected).inSeconds.abs(), lessThan(65),
          reason: 'timestamp=${event.timestamp}, attendu≈$expected');
    });

    testWidgets('Couche : la date par défaut est le moment de la saisie',
        (tester) async {
      final before = DateTime.now();
      await openSheetAndConfirm(tester, 'Couche');

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single
          as TrackingEvent;
      expect(
          event.timestamp.isBefore(before.subtract(const Duration(minutes: 1))),
          isFalse);
      expect(event.timestamp.isAfter(DateTime.now()), isFalse);
    });

    testWidgets('Santé : la date par défaut est le moment de la saisie',
        (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(findTrackButton('Santé'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDateTimeField), findsOneWidget);

      // A selection is mandatory: choose a subtype and then confirm.
      final subtype = find.text('Nettoyage des yeux');
      await tester.ensureVisible(subtype);
      await tester.tap(subtype, warnIfMissed: false);
      await tester.pumpAndSettle();
      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single
          as TrackingEvent;
      expect(
          event.timestamp
              .isAfter(DateTime.now().add(const Duration(minutes: 1))),
          isFalse);
    });
  });

  // ──────────────────────────────────────────────
  // Consistance des selles
  // ──────────────────────────────────────────────
  group('Consistance du caca', () {
    testWidgets('une texture choisie est enregistrée sur l\'événement',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(findTrackButton('Couche'));
      await tester.pumpAndSettle();

      final chip = find.widgetWithText(FilterChip, 'Pâteuse');
      await tester.ensureVisible(chip);
      await tester.tap(chip, warnIfMissed: false);
      await tester.pumpAndSettle();

      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single
          as DiaperEvent;
      expect(event.stoolTexture, equals(stoolTexturePateuse));
    });

    // Regression: consistency is optional. A parent who doesn't understand...
    // Nothing should have its history filled with a single, predetermined step.
    testWidgets('aucune texture saisie → événement sans texture',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(findTrackButton('Couche'));
      await tester.pumpAndSettle();

      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single
          as DiaperEvent;
      expect(event.stoolTexture, equals(null));
    });
  });

  // ──────────────────────────────────────────────
  // Onboarding dialog shown only when no profiles exist
  // ──────────────────────────────────────────────
  group('Onboarding dialog', () {
    testWidgets('onboarding NOT shown when baby profiles exist',
        (tester) async {
      TestAnyBabyExistsNotifier.anyExists = true;
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Onboarding widget should not be present.
      expect(find.byType(OnboardingDialog), findsNothing);
    });

    // Note: The positive case remained uncovered — `showModalBottomSheet`.
    // It exceeded the 600x900 dimensions of the harness, and the overflow caused the test to fail.
    // a reason unrelated to what he was verifying. He is discussed further below in a...
    // Screen at the height of the sheet.
  });

  // ─────────────────────────────────────────────────────────────────────────
  // The database was cleared and then re-imported, so it's populated again, but the spreadsheet...
  // The onboarding process was already underway. It should not continue after this point, and should not...
  // It is especially important not to respond to this with a second profile.
  // ─────────────────────────────────────────────────────────────────────────
  group('Onboarding sheet over a restored database', () {
    Future<void> pumpHomeTall(WidgetTester tester) async {
      // The previous instance belongs to a destroyed notifier: keep it.
      // A living person would cause a notice to be published in a defunct publication.
      TestAnyBabyExistsNotifier.instance = null;
      // The sheet is taller than the harness screen; it measures 900 pixels in height.
      // It overflows, and the test fails due to a layout issue, not a behavioral one.
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            trackingRepositoryProvider.overrideWith((ref) async => mockRepo),
            measurementNotifierProvider
                .overrideWith(() => TestMeasurementNotifier(const [])),
            activeBabyProvider.overrideWith(TestActiveBabyNotifier.new),
            anyBabyExistsProvider.overrideWith(TestAnyBabyExistsNotifier.new),
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
    }

    testWidgets('shown when no profile exists', (tester) async {
      TestAnyBabyExistsNotifier.anyExists = false;
      await pumpHomeTall(tester);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDialog), findsOneWidget);
    });

    testWidgets('closed as soon as a profile exists while it is open',
        (tester) async {
      TestAnyBabyExistsNotifier.anyExists = false;
      await pumpHomeTall(tester);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingDialog), findsOneWidget);

      // The restoration process is completed while the document is on display.
      TestAnyBabyExistsNotifier.restored();
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDialog), findsNothing);
    });
  });
}

/// Test notification for growth: fixed list, independent of the database.
class TestMeasurementNotifier extends MeasurementNotifier {
  TestMeasurementNotifier(this.measurements);

  final List<GrowthMeasurement> measurements;

  @override
  Future<List<GrowthMeasurement>> build() async => measurements;
}

/// Test notifier that resolves the active baby profile synchronously.
/// Sets state directly in build() so .value is available immediately during initState.
class TestActiveBabyNotifier extends ActiveBabyNotifier {
  static BabyProfile? activeProfile;

  @override
  Future<BabyProfile?> build() {
    // Set state synchronously so ref.read(activeBabyProvider).value returns the profile immediately
    state = AsyncValue.data(activeProfile);
    return Future.value(activeProfile);
  }
}

/// Test notifier that resolves whether any baby exists synchronously.
class TestAnyBabyExistsNotifier extends AnyBabyExistsNotifier {
  static bool anyExists = false;

  /// Displays a profile even when the onboarding screen is already open.
  /// — what is produced by a restoration process that culminates at that point.
  static void restored() {
    anyExists = true;
    instance?._publishRestored();
  }

  static TestAnyBabyExistsNotifier? instance;

  void _publishRestored() => state = const AsyncValue<bool>.data(true);

  @override
  Future<bool> build() {
    instance = this;
    state = AsyncValue.data(anyExists);
    return Future.value(anyExists);
  }
}

/// Accepted preferences for testing the actual router: provide the real notification.
/// it would open the device's shutter, which was missing during the test – and that's what...
/// It was blocking the old version of these tests related to the splash page redirection.
class _AcceptedPrefsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async => const AppPreferences(
        appVersion: AppConfig.version,
        termsAccepted: true,
        patchNotesOptOut: true,
      );
}

/// Deterministic locale: the actual notification is waiting for the `path_provider` channel.
/// which never responds in the test environment, and the MenuScreen would remain.
/// en spinner.
class _LocalePrefsNotifier extends LocaleNotifier {
  @override
  Future<LocalePreference> build() async =>
      const LocalePreference(languageCode: 'en', isManualOverride: false);
}

/// Deterministic theme, for the same reason as [_LocalePrefsNotifier].
class _ThemePrefsNotifier extends ThemeNotifier {
  @override
  Future<ThemePreference> build() async =>
      const ThemePreference(mode: 'system');
}

/// Empty history: the actual data repository is waiting for the database, including the channel.
/// The "Create" button never works in the test environment — HistoryScreen.
/// resterait en spinner.
class _EmptyHistoryRepository implements HistoryRepository {
  @override
  Future<List<TrackingEvent>> getAllEventsOrdered({String? babyId}) async =>
      const [];

  @override
  Future<List<TrackingEvent>> getEventsByType(
    TrackingType type, {
    String? babyId,
  }) async =>
      const [];

  @override
  Future<bool> updateEvent(
          {required int id, required TrackingEvent event}) async =>
      false;

  @override
  Future<bool> deleteEvent(int id) async => false;
}

/// Fake without a basis: the historical data provider reads the measurement repository.
/// even when using the "all" filter; in testing, the actual factory would be waiting for...
/// channels (base, path_provider) that never respond, and the screen would remain stuck.
/// It can spin indefinitely.
class _FakeMeasurementRepository implements MeasurementRepository {
  @override
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  }) async {}

  @override
  Future<GrowthMeasurement?> latestOfKind(
          String? babyId, MeasureKind kind) async =>
      null;

  @override
  Future<List<GrowthMeasurement>> allForBaby(String? babyId,
          {MeasureKind? kind}) async =>
      const [];

  @override
  Future<void> update(GrowthMeasurement measurement) async {}

  @override
  Future<bool> deleteById(int id) async => false;
}

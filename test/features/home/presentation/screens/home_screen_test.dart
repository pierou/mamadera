import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/l10n/app_localizations.dart';

import 'package:mamadera/core/theme.dart';
import 'package:mamadera/core/config/app_config.dart';
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

/// Helper : trouve un TrackButton par son label.
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

  /// Helper : pompe HomeScreen avec le repo mocked et un bébé actif pour éviter le onboarding.
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trackingRepositoryProvider.overrideWith((ref) async => mockRepo),
          // La rangée de croissance ne doit pas ouvrir la vraie base en test.
          measurementNotifierProvider
              .overrideWith(() => TestMeasurementNotifier(const [])),
          // Override with a test notifier that resolves synchronously via Future.microtask.
          activeBabyProvider.overrideWith(TestActiveBabyNotifier.new),
          anyBabyExistsProvider.overrideWith(TestAnyBabyExistsNotifier.new),
          // La section de rappels (D1) évalue le notifier ; la version de
          // test ne laisse pas le timer de sondage de cinq minutes en attente.
          reminderNotifierProvider
              .overrideWith(NoPollRemindersNotifier.new),
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
  // Affichage des TrackButtons
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
    testWidgets('Nourriture, Sante, Couche, Dodo sont affiches', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('Nourriture'), findsOneWidget);
      expect(find.text('Sant\u00e9'), findsOneWidget);
      expect(find.text('Couche'), findsOneWidget);
      expect(find.text('Dodo'), findsOneWidget);
    });

    testWidgets('chaque TrackButton a la couleur AppTheme attendue', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // TrackButtons now use outlined cards with accent-colored borders and text
      final trackButtons = tester.widgetList<TrackButton>(find.byType(TrackButton)).toList();
      expect(trackButtons.length, 4);

      final colors = trackButtons.map((b) => b.color).toSet();
      expect(colors.contains(AppTheme.miam), isTrue, reason: 'Nourriture');
      expect(colors.contains(AppTheme.sante), isTrue, reason: 'Sant\u00e9');
      expect(colors.contains(AppTheme.caca), isTrue, reason: 'Couche');
      expect(colors.contains(AppTheme.dodo), isTrue, reason: 'Dodo');
    });

    testWidgets('no BottomNavigationBar in HomeScreen (provided by AppShell)', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // HomeScreen no longer renders a Scaffold or BottomNavigationBar.
      // Those are provided by AppShell via go_router ShellRoute.
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });

  // ──────────────────────────────────────────────
  // Rappels dus sous les boutons (D1, M6)
  // ──────────────────────────────────────────────
  group('Rappels dus sous les boutons (D1)', () {
    /// Même harnais que [pumpHome], mais avec un dépôt de rappels en
    /// mémoire : la chaîne réelle produit les 4 préréglages dus du bébé
    /// actif, la liste sous les boutons est stable et les 4 lignes lisibles.
    Future<void> pumpHomeWithDueReminders(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 900);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trackingRepositoryProvider
                .overrideWith((ref) async => mockRepo),
            measurementNotifierProvider
                .overrideWith(() => TestMeasurementNotifier(const [])),
            activeBabyProvider.overrideWith(TestActiveBabyNotifier.new),
            anyBabyExistsProvider.overrideWith(TestAnyBabyExistsNotifier.new),
            remindersRepositoryProvider
                .overrideWith((ref) async => MockRemindersRepository()),
            reminderNotifierProvider
                .overrideWith(NoPollRemindersNotifier.new),
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

    testWidgets('les 4 rappels dus sont lisibles, grille et boutons de '
        'croissance inchangés', (tester) async {
      await pumpHomeWithDueReminders(tester);

      // Les 4 TrackButtons et les 3 boutons de croissance existent toujours.
      expect(find.byType(TrackButton), findsNWidgets(4));
      expect(find.byType(MeasurementButton), findsNWidgets(3));

      // Les 4 rappels dus sont listés, pas agrégés en « +2 ».
      expect(find.text('Rappels à faire'), findsOneWidget);
      expect(find.byType(ReminderRow), findsNWidgets(4));
      expect(find.text('Vitamine D'), findsOneWidget);
      expect(find.text('Vitamine K'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
      expect(find.text('Nettoyage du visage'), findsOneWidget);
    });

    testWidgets('la grille reste utilisable : Nourriture ouvre sa feuille',
        (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);
      await pumpHomeWithDueReminders(tester);

      await tester.tap(findTrackButton('Nourriture'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('les boutons de croissance restent utilisables : Poids '
        'ouvre sa feuille', (tester) async {
      await pumpHomeWithDueReminders(tester);

      // La feuille de mesure est plus haute que l'écran du harnais 600x900 :
      // on passe sur un écran de la hauteur d'une feuille, comme le harnais
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
  // Repris en main (M6) : ces tests pompaient HomeScreen seul, sans le
  // routeur — la barre de navigation n'existait pas et le tap ne pouvait
  // qu'exploser, d'où les anciens skips. Ils pompent maintenant le vrai
  // routeur de l'app, avec des providers déterministes (même recette que
  // test/core/router_test.dart) : le dépôt d'historique, la locale et le
  // thème sont remplacés, parce que les canaux qu'ils attendent (base de
  // données, path_provider) ne répondent jamais dans l'environnement de
  // test et laisseraient les écrans en spinner indéfiniment.
  // ──────────────────────────────────────────────
  group('Navigation via bottom nav', () {
    /// Pompe le vrai routeur de l'app : splash → accueil, avec des providers
    /// déterministes (préférences acceptées, bébés en mémoire, mesures
    /// vides, rappels dus stables, profils résolus à vide).
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider
                .overrideWith(_AcceptedPrefsNotifier.new),
            trackingRepositoryProvider
                .overrideWith((ref) async => mockRepo),
            measurementNotifierProvider
                .overrideWith(() => TestMeasurementNotifier(const [])),
            activeBabyProvider.overrideWith(TestActiveBabyNotifier.new),
            anyBabyExistsProvider.overrideWith(TestAnyBabyExistsNotifier.new),
            babyProfileListProvider
                .overrideWith((ref) async => const <BabyProfile>[]),
            remindersRepositoryProvider
                .overrideWith((ref) async => MockRemindersRepository()),
            reminderNotifierProvider
                .overrideWith(NoPollRemindersNotifier.new),
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
    testWidgets('tap Nourriture -> ouvre FeedingTrackingDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      final miamBtn = find.text('Nourriture');
      expect(miamBtn, findsOneWidget);

      await tester.tap(miamBtn);
      await tester.pumpAndSettle();

      // Un bottom sheet doit être ouvert (le dialog de tracking d'alimentation)
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
    testWidgets('Dodo: Confirmer envoie SleepEvent via insertEvent', (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Durée par défaut (30 min).
  expect(find.text('30 min'), findsOneWidget);

      // Confirmer.
      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // insertEvent a ete appele avec un SleepEvent.
      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<SleepEvent>());
    });

    testWidgets('Dodo: Annuler ne declenche aucun evenement', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Tap en dehors du bottom sheet pour fermer.
      await tester.tapAt(const Offset(400, 50));
      await tester.pumpAndSettle();

      verifyNever(mockRepo.insertEvent(any));
    });

    testWidgets('Sante: Confirmer sans selection -> SnackBar d\'erreur', (tester) async {
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

    testWidgets('Sante: Selection + Confirmer -> HealthEvent via insertEvent', (tester) async {
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

    testWidgets('Couche: Confirmer -> DiaperEvent via insertEvent', (tester) async {
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
  // Date de l'événement à la création
  // ──────────────────────────────────────────────
  group('Date de saisie', () {
    Future<void> openSheetAndConfirm(WidgetTester tester, String buttonLabel) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(findTrackButton(buttonLabel));
      await tester.pumpAndSettle();

      // Toute feuille de saisie expose le champ de date/heure.
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

    testWidgets('Nourriture : la date par défaut est le moment de la saisie', (tester) async {
      final before = DateTime.now();
      await openSheetAndConfirm(tester, 'Nourriture');

      final event =
          verify(mockRepo.insertEvent(captureAny)).captured.single as TrackingEvent;
      expect(event.timestamp.isBefore(before.subtract(const Duration(minutes: 1))), isFalse);
      expect(event.timestamp.isAfter(DateTime.now()), isFalse);
    });

    testWidgets('Dodo : la date par défaut recule de la durée saisie', (tester) async {
      await openSheetAndConfirm(tester, 'Dodo');

      final event =
          verify(mockRepo.insertEvent(captureAny)).captured.single as SleepEvent;
      // Durée par défaut du slider : 30 min → une sieste commencée à 20:30 est
      // enregistrée à 20:30, pas à l'heure du tic.
      final expected = DateTime.now().subtract(const Duration(minutes: 30));
      expect(event.timestamp.difference(expected).inSeconds.abs(), lessThan(65),
          reason: 'timestamp=${event.timestamp}, attendu≈$expected');
    });

    testWidgets('Couche : la date par défaut est le moment de la saisie', (tester) async {
      final before = DateTime.now();
      await openSheetAndConfirm(tester, 'Couche');

      final event =
          verify(mockRepo.insertEvent(captureAny)).captured.single as TrackingEvent;
      expect(event.timestamp.isBefore(before.subtract(const Duration(minutes: 1))), isFalse);
      expect(event.timestamp.isAfter(DateTime.now()), isFalse);
    });

    testWidgets('Santé : la date par défaut est le moment de la saisie', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(findTrackButton('Santé'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDateTimeField), findsOneWidget);

      // Une sélection est obligatoire : choisir un sous-type puis confirmer.
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

      final event =
          verify(mockRepo.insertEvent(captureAny)).captured.single as TrackingEvent;
      expect(event.timestamp.isAfter(DateTime.now().add(const Duration(minutes: 1))), isFalse);
    });
  });

  // ──────────────────────────────────────────────
  // Consistance des selles
  // ──────────────────────────────────────────────
  group('Consistance du caca', () {
    testWidgets('une texture choisie est enregistrée sur l\'événement', (tester) async {
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

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single as DiaperEvent;
      expect(event.stoolTexture, equals(stoolTexturePateuse));
    });

    // Régression : la consistance reste optionnelle. Un parent qui ne saisit
    // rien ne doit pas voir son historique rempli d'un cran deviné.
    testWidgets('aucune texture saisie → événement sans texture', (tester) async {
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

      final event = verify(mockRepo.insertEvent(captureAny)).captured.single as DiaperEvent;
      expect(event.stoolTexture, equals(null));
    });
  });

  // ──────────────────────────────────────────────
  // Onboarding dialog shown only when no profiles exist
  // ──────────────────────────────────────────────
  group('Onboarding dialog', () {
    testWidgets('onboarding NOT shown when baby profiles exist', (tester) async {
      TestAnyBabyExistsNotifier.anyExists = true;
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Onboarding widget should not be present.
      expect(find.byType(OnboardingDialog), findsNothing);
    });

    // Note: le cas positif était resté non couvert — `showModalBottomSheet`
    // débordait des 600x900 du harnais, et l'overflow faisait tomber le test pour
    // une raison étrangère à ce qu'il vérifiait. Il est couvert ci-dessous sur un
    // écran à la hauteur de la feuille.
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Effacé puis réimporté : la base est de nouveau peuplée, mais la feuille
  // d'onboarding était déjà ouverte. Elle ne doit pas survivre à ce retour, et ne
  // doit surtout pas y répondre par un second profil.
  // ─────────────────────────────────────────────────────────────────────────
  group('Onboarding sheet over a restored database', () {
    Future<void> pumpHomeTall(WidgetTester tester) async {
      // L'instance précédente appartient à un notifier détruit : la garder
      // vivante ferait publier un état dans un fournisseur disparu.
      TestAnyBabyExistsNotifier.instance = null;
      // La feuille est plus haute que l'écran du harnais ; sur 900 px elle
      // déborde et le test tombe pour un motif de layout, pas de comportement.
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      // La restauration aboutit pendant que la feuille est affichée.
      TestAnyBabyExistsNotifier.restored();
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDialog), findsNothing);
    });
  });
}

/// Notifier de test pour la croissance : liste fixe, sans dépendance à la base.
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

  /// Fait apparaître un profil alors que la feuille d'onboarding est déjà ouverte
  /// — ce que produit une restauration qui aboutit à ce moment-là.
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

/// Préférences acceptées pour les tests du vrai routeur : le notifier réel
/// ouvrirait le store de l'appareil, absent en test — c'est ce qui
/// bloquait l'ancienne version de ces tests sur la redirection splash.
class _AcceptedPrefsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async => const AppPreferences(
        appVersion: AppConfig.version,
        termsAccepted: true,
        patchNotesOptOut: true,
      );
}

/// Locale déterministe : le vrai notifier attend le canal path_provider,
/// qui ne répond jamais dans l'environnement de test, et MenuScreen resterait
/// en spinner.
class _LocalePrefsNotifier extends LocaleNotifier {
  @override
  Future<LocalePreference> build() async =>
      const LocalePreference(languageCode: 'en', isManualOverride: false);
}

/// Thème déterministe, même raison que [_LocalePrefsNotifier].
class _ThemePrefsNotifier extends ThemeNotifier {
  @override
  Future<ThemePreference> build() async => const ThemePreference(mode: 'system');
}

/// Historique vide : le vrai dépôt attend la base de données, dont le canal
/// de création ne répond jamais dans l'environnement de test — HistoryScreen
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
  Future<bool> updateEvent({required int id, required TrackingEvent event}) async =>
      false;

  @override
  Future<bool> deleteEvent(int id) async => false;
}

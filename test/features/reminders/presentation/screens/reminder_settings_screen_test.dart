import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/repositories/app_settings_repository.dart';
import 'package:mamadera/features/reminders/domain/services/local_notification_service.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/features/reminders/presentation/widgets/reminder_lifecycle_sync.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_sync_notifier.dart';
import 'package:mamadera/features/reminders/presentation/screens/reminder_settings_screen.dart';
import 'package:mamadera/features/reminders/presentation/widgets/custom_reminder_tile.dart';
import 'package:mamadera/features/reminders/presentation/widgets/reminder_hour_control.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

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

/// The switch for the line with the label "[label]".
Finder _switchFor(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(SwitchListTile),
      ),
      matching: find.byType(Switch),
    );

bool _isOn(WidgetTester tester, String label) => tester
    .widget<Switch>(find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(SwitchListTile),
      ),
      matching: find.byType(Switch),
    ))
    .value;

/// Records what the scheduler asks the OS to do; hands out a fixed answer to
/// the permission request (D8).
class _FakeNotificationService implements LocalNotificationService {
  /// Answer handed to `ensurePermission()` / `permissionGranted`.
  bool granted = true;
  int ensurePermissionCalls = 0;
  int cancelAllCount = 0;
  int initCalls = 0;

  /// `id → (title, body, at)` — what is pending in the OS.
  final Map<int, (String title, String body, DateTime at)> scheduled = {};
  final List<int> scheduledIn = [];
  final List<int> cancelled = [];

  @override
  Future<void> init() async => initCalls++;

  @override
  bool get ready => true;

  @override
  Future<bool> ensurePermission() async {
    ensurePermissionCalls++;
    return granted;
  }

  @override
  Future<bool> get permissionGranted async => granted;

  @override
  Future<bool> get exactAlarmsAllowed async => true;

  @override
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    scheduled[id] = (title, body, at);
  }

  @override
  Future<void> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    scheduledIn.add(id);
    scheduled[id] = (title, body, DateTime.now().add(delay));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }
}

/// In-memory stand-in for the `app_settings` table (schema v13).
class _FakeAppSettings implements AppSettingsRepository {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteAll() async => values.clear();

  @override
  Future<Map<String, String>> getAll() async => Map.of(values);
}

/// Deterministic locale for the notification content (no path_provider here).
class _FrLocaleNotifier extends LocaleNotifier {
  @override
  Future<LocalePreference> build() async =>
      const LocalePreference(languageCode: 'fr', isManualOverride: true);
}

void main() {
  late MockRemindersRepository mockReminders;
  late _FakeNotificationService fakeNotifications;
  late _FakeAppSettings fakeSettings;

  /// [withLifecycle] mounts the real `ReminderLifecycleSyncWidget` — the
  /// start-up and resume reconciliation, which is where the D8 de-opt lives.
  Future<void> pumpScreen(WidgetTester tester,
      {bool withLifecycle = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remindersRepositoryProvider
              .overrideWith((ref) async => mockReminders),
          activeBabyProvider.overrideWith(() => _ActiveBabyStub(_baby)),
          // The section under test writes through these; the real ones would
          // reach the plugin and the database. The scheduler stays real, so
          // "opt out ⇒ cancelAll" is asserted on what actually reaches the OS.
          appSettingsRepositoryProvider
              .overrideWith((ref) async => fakeSettings),
          localNotificationServiceProvider
              .overrideWith((ref) async => fakeNotifications),
          babyProfileListProvider.overrideWith((ref) async => [_baby]),
          localeProvider.overrideWith(_FrLocaleNotifier.new),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: withLifecycle
              ? const ReminderLifecycleSyncWidget(
                  child: ReminderSettingsScreen())
              : const ReminderSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockReminders = MockRemindersRepository();
    fakeNotifications = _FakeNotificationService();
    fakeSettings = _FakeAppSettings();
  });

  group('ReminderSettingsScreen', () {
    testWidgets('affiche le titre et la promesse de confidentialité',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Rappels'), findsOneWidget);
      expect(
        find.text(
          "Bandeaux affichés sur l'accueil tant que le soin n'a pas été saisi, "
          'et — si vous les activez — notifications système. '
          'Tout reste sur cet appareil.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('liste les quatre rappels préréglés avec leur fréquence',
        (tester) async {
      await pumpScreen(tester);

      // Please provide the full name of the treatment, not the abbreviation from the welcome tablet.
      expect(find.text('Vitamine D'), findsOneWidget);
      expect(find.text('Vitamine K'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
      expect(find.text('Nettoyage du visage'), findsOneWidget);

      expect(find.text('Tous les jours'), findsNWidgets(3));
      // B33 Part 1: vitamin K is a **single occurrence** at the baby's first
      // month, so it is announced by its day (birthdate 15/01/2026 ⇒ 15/02/2026)
      // and no longer as a monthly rhythm.
      expect(find.text('Le 15 de chaque mois'), findsNothing);
      expect(find.text('Une seule fois, le 15/02/2026'), findsOneWidget);
    });

    testWidgets(
        'the switches are an opt-out — except vitamin D, off but visible',
        (tester) async {
      // B6 (WHO 2022 Rec 36, owner decision A): a baby created on 1.4.0 starts
      // with vitamin D **off but visible** — the switch sits on screen, that is
      // the whole point of the decision. An install upgraded from 1.3.x has an
      // explicit enabled = 1 row (the v14 seed, D-R1) and still shows it on:
      // covered by 'un enabled enregistré true laisse le rappel activé'.
      await pumpScreen(tester);

      // 4 presets + the "System notifications" opt-in (M6).
      // 4 presets; the "System notifications" opt-in (M6) sits below them and a
      // ListView only builds what it may show, so an exact total here would be a
      // bet on the test viewport — B33's row menu made the row narrower, and this
      // assertion is about the switches existing, not about the scroll extent.
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(4));
      for (final label in [
        'Vitamine K',
        'Nettoyage des yeux',
        'Nettoyage du visage'
      ]) {
        expect(_isOn(tester, label), isTrue, reason: label);
      }
      expect(find.text('Vitamine D'), findsOneWidget,
          reason:
              'off by default means hidden from the due list, not from the list');
      expect(_isOn(tester, 'Vitamine D'), isFalse);
    });

    testWidgets('un rappel déjà éteint est affiché éteint', (tester) async {
      mockReminders.enabledById['eye_cleaning'] = false;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Nettoyage des yeux'), isFalse);
      expect(_isOn(tester, 'Vitamine K'), isTrue);
    });

    testWidgets('un enabled enregistré true laisse le rappel activé',
        (tester) async {
      mockReminders.enabledById['vitamine_d'] = true;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Vitamine D'), isTrue);
    });

    testWidgets('éteindre un rappel l\'enregistre et le switch reste éteint',
        (tester) async {
      // The v1.3.x state after the v14 seed: an explicit row, switch on. This is
      // the path B6's decision A is about — keeping the reminder "until manual
      // turning off", and the turning-off having to be possible.
      mockReminders.enabledById['vitamine_d'] = true;
      await pumpScreen(tester);

      await tester.tap(_switchFor('Vitamine D'));
      await tester.pumpAndSettle();

      expect(mockReminders.enabledById['vitamine_d'], isFalse);
      expect(mockReminders.setEnabledCallCount, 1);
      // There's no going back once the charging process begins.
      expect(_isOn(tester, 'Vitamine D'), isFalse);
    });

    testWidgets('rallumer un rappel éteint l\'enregistre', (tester) async {
      mockReminders.enabledById['face_cleaning'] = false;

      await pumpScreen(tester);

      await tester.tap(_switchFor('Nettoyage du visage'));
      await tester.pumpAndSettle();

      expect(mockReminders.enabledById['face_cleaning'], isTrue);
      expect(_isOn(tester, 'Nettoyage du visage'), isTrue);
    });

    testWidgets('la liste reste affichée quand tout est déjà fait aujourd\'hui',
        (tester) async {
      // The settings have nothing to do with whether a reminder is due or not.
      // The list of presets is displayed even if none of them are overdue.
      mockReminders.lastCompletedByItem['vitamine_d'] = DateTime.now();
      mockReminders.lastCompletedByItem['vitamine_k'] = DateTime.now();
      mockReminders.lastCompletedByItem['eye_cleaning'] = DateTime.now();
      mockReminders.lastCompletedByItem['face_cleaning'] = DateTime.now();

      await pumpScreen(tester);

      // 4 presets + the "System notifications" opt-in (M6).
      // 4 presets; the "System notifications" opt-in (M6) sits below them and a
      // ListView only builds what it may show, so an exact total here would be a
      // bet on the test viewport — B33's row menu made the row narrower, and this
      // assertion is about the switches existing, not about the scroll extent.
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(4));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ReminderSettingsScreen, rappels personnalisés', () {
    /// Bring a line outside the visible area to the top of the list, then select it.
    Future<void> tapRow(WidgetTester tester, Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      } else {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
      }
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    void store({
      int id = 1,
      String label = 'Crème du change',
      ReminderFrequency? frequency,
    }) {
      mockReminders.customRemindersById[id] = CustomReminder(
        id: id,
        label: label,
        subtypeValue: 'nettoyage_nez',
        frequency: frequency ?? const ReminderFrequency.daily(),
      );
    }

    Finder customSwitch() => find.descendant(
          of: find.byType(CustomReminderTile),
          matching: find.byType(Switch),
        );

    testWidgets("la section est annoncée vide tant qu'on n'a rien créé",
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Rappels personnalisés'), findsOneWidget);
      expect(
        find.text("Aucun rappel personnalisé pour l'instant."),
        findsOneWidget,
      );
      expect(find.text('Ajouter un rappel'), findsOneWidget);
      expect(find.byType(CustomReminderTile), findsNothing);
    });

    testWidgets(
        'une ligne existante porte le nom choisi par le parent, pas le nom du soin',
        (tester) async {
      store(label: 'Crème du change');

      await pumpScreen(tester);

      // The preset setting indicates the type of treatment; a personalized reminder tells the parent what to do.
      // He wanted to keep it, but "nose cleaning" would be a lie in this context.
      expect(find.text('Crème du change'), findsOneWidget);
      expect(find.text('Tous les jours'), findsNWidgets(4));
      expect(find.byType(CustomReminderTile), findsOneWidget);
    });

    testWidgets(
        'un rythme mensuel est annoncé sur le jour de naissance du bébé',
        (tester) async {
      store(
          label: 'Bilan du mois',
          frequency: const ReminderFrequency.monthly(dayOfMonth: 1));

      await pumpScreen(tester);

      // Only the custom reminder now claims the birth day: vitamin K became a
      // one-shot (B33 Part 1) and names its own date instead.
      expect(find.text('Le 15 de chaque mois'), findsOneWidget);
      expect(find.text('Une seule fois, le 15/02/2026'), findsOneWidget);
    });

    testWidgets(
        'un rappel détaché s\'affiche sans soin inventé, avec son avertissement',
        (tester) async {
      mockReminders.customRemindersById[1] = CustomReminder(
        id: 1,
        label: 'Thermomètre',
        frequency: const ReminderFrequency.customInterval(days: 2),
        subtypeValue: null,
        completionSource: completionManual,
      );

      await pumpScreen(tester);

      expect(find.byType(CustomReminderTile), findsOneWidget);
      // The wording of the label, its rhythm...
      expect(find.text('Thermomètre'), findsOneWidget);
      expect(find.text('Tous les 2 jours'), findsOneWidget);
      // ...and the warning about manual completion—without any invented care names.
      // behind a reminder that doesn't actually serve as one.
      expect(
        find.text("S'efface quand vous le marquez fait."),
        findsOneWidget,
      );
      expect(find.text('Nettoyage du nez'), findsNothing);
    });

    testWidgets(
        'le switch d\'une ligne personnalisée éteint le rappel sous sa propre clé',
        (tester) async {
      store();

      await pumpScreen(tester);
      await tapRow(tester, customSwitch());

      expect(mockReminders.enabledById['custom_1'], isFalse);
      expect(mockReminders.setEnabledCallCount, 1);
      // These settings are not affected by this shutdown.
      expect(mockReminders.enabledById.keys, ['custom_1']);
    });

    testWidgets('un rappel personnalisé déjà éteint est affiché éteint',
        (tester) async {
      store();
      mockReminders.enabledById['custom_1'] = false;

      await pumpScreen(tester);

      expect(tester.widget<Switch>(customSwitch()).value, isFalse);
    });

    testWidgets(
        "ajouter un rappel l'enregistre et l'affiche sans quitter l'écran",
        (tester) async {
      await pumpScreen(tester);

      final haptics = <MethodCall>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tapRow(tester, find.text('Ajouter un rappel'));
      expect(find.text('Nouveau rappel'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du rappel'),
        'Sérum visage',
      );
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(mockReminders.insertCustomCallCount, 1);
      expect(mockReminders.customRemindersById.values.single.label,
          'Sérum visage');
      expect(find.byType(CustomReminderTile), findsOneWidget);
      expect(find.text('Sérum visage'), findsOneWidget);

      // B17 — a creation is felt at the moment it commits, with one magnitude for
      // every creation in the app. Emulators do not vibrate: what is pinned here is
      // that the platform was asked for `selectionClick`, nothing more.
      expect(
        haptics.map((call) => call.arguments),
        contains('HapticFeedbackType.selectionClick'),
        reason: 'custom-reminder creation used to be silent to the finger',
      );
      // Nothing is modal anymore: the screen has reappeared, ready for a second input.
      expect(find.text('Nouveau rappel'), findsNothing);
    });

    testWidgets(
        'renommer un rappel passe par le formulaire prérempli et ne le duplique pas',
        (tester) async {
      store(label: 'Crème du change');

      await pumpScreen(tester);
      await tapRow(tester, find.text('Crème du change'));

      expect(find.text('Modifier le rappel'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'Nom du rappel'))
            .controller
            ?.text,
        'Crème du change',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du rappel'),
        'Crème du change, le soir',
      );
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(mockReminders.editCustomCallCount, 1);
      expect(mockReminders.insertCustomCallCount, 0);
      expect(mockReminders.customRemindersById, hasLength(1));
      expect(find.text('Crème du change, le soir'), findsOneWidget);
    });

    testWidgets("supprimer demande un accord et n'efface rien sans lui",
        (tester) async {
      store();

      await pumpScreen(tester);
      await tapRow(
        tester,
        find.descendant(
          of: find.byType(CustomReminderTile),
          matching: find.byType(PopupMenuButton<CustomReminderAction>),
        ),
      );
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      // The name of the item being referenced in the question, and the promised details in the answer.
      expect(find.text('Supprimer ce rappel ?'), findsOneWidget);
      expect(
        find.text(
          "Le rappel disparaît de l'accueil. Les événements déjà enregistrés "
          'sont conservés.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(mockReminders.deleteCustomCallCount, 0);
      expect(mockReminders.customRemindersById, hasLength(1));
      expect(find.byType(CustomReminderTile), findsOneWidget);
    });

    testWidgets(
        'supprimer après accord retire la ligne et sa position de switch',
        (tester) async {
      store();
      mockReminders.enabledById['custom_1'] = false;

      await pumpScreen(tester);
      await tapRow(
        tester,
        find.descendant(
          of: find.byType(CustomReminderTile),
          matching: find.byType(PopupMenuButton<CustomReminderAction>),
        ),
      );
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(mockReminders.deleteCustomCallCount, 1);
      expect(mockReminders.customRemindersById, isEmpty);
      expect(mockReminders.enabledById, isEmpty);
      expect(find.byType(CustomReminderTile), findsNothing);
      expect(find.text("Aucun rappel personnalisé pour l'instant."),
          findsOneWidget);
    });

    testWidgets('la création est refusée avant même la base si le nom manque',
        (tester) async {
      await pumpScreen(tester);

      await tapRow(tester, find.text('Ajouter un rappel'));
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(find.text('Donnez un nom au rappel'), findsOneWidget);
      expect(mockReminders.insertCustomCallCount, 0);
      expect(find.byType(CustomReminderTile), findsNothing);
    });

    // Without these two specific cases, a rejected writing would simply result in a sign that...
    // The farm was closed without any explanation: the exception would disappear in a future that no one anticipated.
    testWidgets(
        'un enregistrement refusé le dit au lieu de disparaître en silence',
        (tester) async {
      mockReminders.failCustomWrites = true;

      await pumpScreen(tester);
      await tapRow(tester, find.text('Ajouter un rappel'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du rappel'),
        'Sérum visage',
      );
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(find.text("Le rappel n'a pas pu être enregistré. Réessayez."),
          findsOneWidget);
      // Nothing was fabricated: no lines were added, and no false memories were created.
      expect(mockReminders.customRemindersById, isEmpty);
      expect(find.byType(CustomReminderTile), findsNothing);
    });

    testWidgets('une suppression refusée laisse le rappel en place et le dit',
        (tester) async {
      store();
      mockReminders.failCustomDelete = true;

      await pumpScreen(tester);
      await tapRow(
        tester,
        find.descendant(
          of: find.byType(CustomReminderTile),
          matching: find.byType(PopupMenuButton<CustomReminderAction>),
        ),
      );
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text("Le rappel n'a pas pu être supprimé. Réessayez."),
          findsOneWidget);
      expect(mockReminders.deleteCustomCallCount, 1);
      // The reminder is still there, including the text and the switch: nothing has been changed.
      // half.
      expect(mockReminders.customRemindersById, hasLength(1));
      expect(find.byType(CustomReminderTile), findsOneWidget);
    });
  });

  // BACKLOG B30: the hour lives on the row. What the parent must see is the
  // hour that *applies*, marked as inherited or as their own — and the way to
  // change both.
  group('per-reminder hour (B30)', () {
    testWidgets('every row shows the global hour, marked as inherited',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      await pumpScreen(tester);

      // Four presets, all without an hour of their own.
      expect(find.text('À 20:30 (par défaut)'), findsNWidgets(4));
      expect(find.byTooltip('Utiliser l\'heure par défaut'), findsNothing,
          reason: 'nothing to take back on a row that never set one');
    });

    testWidgets('a row with its own hour shows it, and offers to let go of it',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      mockReminders.timeOfDayById['eye_cleaning'] = '06:15';
      await pumpScreen(tester);

      expect(find.text('À 06:15'), findsOneWidget);
      expect(find.byTooltip('Utiliser l\'heure par défaut'), findsOneWidget);
      expect(find.text('À 20:30 (par défaut)'), findsNWidgets(3),
          reason: 'the other three still inherit');
    });

    testWidgets('tapping the hour opens the picker for this reminder',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      await pumpScreen(tester);

      await tester.tap(find.text('À 20:30 (par défaut)').first);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(find.text('Heure de notification de ce rappel'), findsOneWidget);
    });

    testWidgets('a custom reminder row shows its own hour too (B30 parity)',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      mockReminders.customRemindersById[7] = const CustomReminder(
        id: 7,
        label: 'Crème du change',
        subtypeValue: 'nettoyage_nez',
        frequency: ReminderFrequency.daily(),
      );
      mockReminders.timeOfDayById['custom_7'] = '06:15';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            remindersRepositoryProvider
                .overrideWith((ref) async => mockReminders),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(_baby)),
            appSettingsRepositoryProvider
                .overrideWith((ref) async => fakeSettings),
            localNotificationServiceProvider
                .overrideWith((ref) async => fakeNotifications),
            babyProfileListProvider.overrideWith((ref) async => [_baby]),
            localeProvider.overrideWith(_FrLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const ReminderSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // B30 §6: the custom row carries the same control as a preset row — the
      // mirror defect (UI sets an hour the scheduler never reads) must not be
      // possible for either kind.
      // The row sits below the fold in a lazily built list — the group's own
      // helper scrolls before it taps, and the same applies to a finder.
      await tester.scrollUntilVisible(
        find.text('Crème du change'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(CustomReminderTile),
          matching: find.textContaining('06:15'),
        ),
        findsOneWidget,
        reason: 'the custom row carries the same hour line as a preset row',
      );
      expect(find.byTooltip('Utiliser l\'heure par défaut'), findsOneWidget);
    });

    testWidgets('confirming the picker stores the hour for that reminder only',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      await pumpScreen(tester);

      await tester.tap(find.text('À 20:30 (par défaut)').first);
      await tester.pumpAndSettle();
      // Accepted as it opens: the picker starts at the hour the row actually
      // uses, so confirming without typing stores 20:30 as its own.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(mockReminders.setItemTimeCallCount, 1);
      expect(mockReminders.timeOfDayById['vitamine_d'], '20:30',
          reason: 'the first preset row is the one that was tapped');
      expect(mockReminders.timeOfDayById.keys, hasLength(1),
          reason: 'the other reminders keep inheriting');
      expect(find.text('À 20:30 (par défaut)'), findsNWidgets(3));
    });

    testWidgets('the reset button writes the hour back to inherited',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      mockReminders.enabledById['eye_cleaning'] = false;
      mockReminders.timeOfDayById['eye_cleaning'] = '06:15';
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Utiliser l\'heure par défaut'));
      await tester.pumpAndSettle();

      expect(mockReminders.clearItemTimeCallCount, 1);
      expect(mockReminders.timeOfDayById, isEmpty);
      expect(mockReminders.enabledById['eye_cleaning'], isFalse,
          reason: 'letting go of an hour must not touch the switch (B6 state)');
      expect(find.text('À 06:15'), findsNothing);
      expect(find.text('À 20:30 (par défaut)'), findsNWidgets(4));
    });

    testWidgets('the edit sheet of a preset reminder carries its hour (B30)',
        (tester) async {
      // The panel that edits a reminder offered a name, a rhythm and an end, and
      // not the hour — so the number a parent most often wants to move was the
      // one thing the "edit" panel could not reach. What is pinned here is that
      // the sheet carries the control, that it writes through the same
      // column-scoped writer as the row, and that the row keeps its own hour line
      // (a copy of the affordance, not a move).
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Modifier le rappel').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(find.descendant(of: sheet, matching: find.text('Fin')),
          findsOneWidget,
          reason: 'the edit sheet did open');
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Heure de notification'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.byType(ReminderHourControl)),
        findsOneWidget,
        reason: 'the same control as the row, not a re-implementation of it',
      );

      await tester.tap(
        find.descendant(of: sheet, matching: find.text('À 20:30 (par défaut)')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(mockReminders.setItemTimeCallCount, 1);
      expect(mockReminders.timeOfDayById['vitamine_d'], '20:30');
      expect(
        find.descendant(of: sheet, matching: find.text('À 20:30')),
        findsOneWidget,
        reason: 'the sheet shows the hour it just stored, without reopening',
      );
      expect(
        find.descendant(
          of: find.byType(SwitchListTile),
          matching: find.byType(ReminderHourControl),
        ),
        findsAtLeastNWidgets(1),
        reason: 'the row keeps its hour line',
      );
    });

    testWidgets('a custom reminder row shows its hour too, same control',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      mockReminders.customRemindersById[4] = CustomReminder(
        id: 4,
        label: 'Crème du change',
        frequency: const Daily(),
        subtypeValue: 'nettoyage_nez',
        completionSource: completionFromEvents,
      );
      mockReminders.timeOfDayById['custom_4'] = '17:45';
      await pumpScreen(tester);

      expect(find.text('Crème du change'), findsOneWidget);
      expect(find.text('À 17:45'), findsOneWidget);
    });
    testWidgets('the edit panel of a custom reminder carries its hour (B35)',
        (tester) async {
      // The owner-reported defect: the panel that edits a custom reminder
      // offered everything except the hour it fires at — the hour lived only
      // on the row behind the panel. Pinned: the panel carries the shared
      // control, starting from the reminder's own stored hour.
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      mockReminders.customRemindersById[4] = CustomReminder(
        id: 4,
        label: 'Crème du change',
        frequency: const Daily(),
        subtypeValue: 'nettoyage_nez',
        completionSource: completionFromEvents,
      );
      mockReminders.timeOfDayById['custom_4'] = '06:15';
      await pumpScreen(tester);

      await tester.scrollUntilVisible(
        find.text('Crème du change'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crème du change'));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Modifier le rappel')),
        findsOneWidget,
        reason: 'the edit sheet did open',
      );
      expect(
        find.descendant(of: sheet, matching: find.byType(ReminderHourControl)),
        findsOneWidget,
        reason: 'the panel owns the hour, not only the row behind it',
      );
      expect(
        find.descendant(of: sheet, matching: find.text('À 06:15')),
        findsOneWidget,
        reason: "the panel starts from the reminder's own stored hour",
      );
    });

    testWidgets(
        'the hour picked in the custom edit panel is stored on confirm (B35)',
        (tester) async {
      // The write path: the sheet keeps its "writes nothing" contract, the
      // screen performs the column-write after the reminder exists — the
      // same second-write shape as the end (D-R5).
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      mockReminders.customRemindersById[4] = CustomReminder(
        id: 4,
        label: 'Crème du change',
        frequency: const Daily(),
        subtypeValue: 'nettoyage_nez',
        completionSource: completionFromEvents,
      );
      await pumpScreen(tester);

      await tester.scrollUntilVisible(
        find.text('Crème du change'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crème du change'));
      await tester.pumpAndSettle();

      final inheritedLine = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('À 20:30 (par défaut)'),
      );
      await tester.ensureVisible(inheritedLine);
      await tester.pumpAndSettle();
      await tester.tap(inheritedLine);
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      // Accepted as it opens: the picker starts at the hour the reminder
      // inherits, and confirming makes that hour its own.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(mockReminders.setItemTimeCallCount, 0,
          reason: 'the sheet writes nothing before the confirm');

      await tester.ensureVisible(find.text('Confirmer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(mockReminders.setItemTimeCallCount, 1,
          reason: 'the screen writes the hour after the reminder exists');
      expect(mockReminders.timeOfDayById['custom_4'], '20:30');
      expect(mockReminders.timeOfDayById.keys, ['custom_4'],
          reason: 'no other reminder is dragged off the global hour');
      expect(find.text('À 20:30'), findsOneWidget,
          reason: 'the row shows the hour the panel just stored');
    });
  });

  group('System notifications section (M6, D8)', () {
    final optInLabel = 'Me notifier quand un rappel est dû';

    // The section trails the list, so its switch is below the fold at rest.
    // `scrollUntilVisible` is this file's idiom for reaching a lower row.
    Future<void> revealOptIn(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        _switchFor(optInLabel),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> toggleOptIn(WidgetTester tester) async {
      await revealOptIn(tester);
      await tester.tap(_switchFor(optInLabel));
      await tester.pumpAndSettle();
    }

    testWidgets('renders OFF by default and never asks before the switch',
        (tester) async {
      await pumpScreen(tester);

      await revealOptIn(tester);
      expect(find.text('Notifications système'), findsOneWidget);
      expect(_isOn(tester, optInLabel), isFalse);
      // AGENTS.md: the permission is asked for at the switch, never at launch.
      expect(fakeNotifications.ensurePermissionCalls, 0);
      expect(fakeNotifications.scheduled, isEmpty);
      await revealOptIn(tester);
      expect(find.text('Les notifications sont désactivées dans les réglages'),
          findsNothing);
    });

    testWidgets('the time row is dead while the switch is off', (tester) async {
      await pumpScreen(tester);

      await revealOptIn(tester);
      final row = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Heure de notification'),
          matching: find.byType(ListTile),
        ),
      );
      expect(row.enabled, isFalse);
      expect(find.widgetWithText(ListTile, '09:00'), findsOneWidget);
    });

    testWidgets('ON asks the OS, persists 1 on grant and schedules now',
        (tester) async {
      // This section is about the OS opt-in, so the plan is the one an install
      // upgraded from 1.3.x has: the v14 seed left an explicit vitamin D row
      // (D-R1), so all four presets are pending. A baby created on 1.4.0 gets
      // three — asserted in reminder_scheduler_test.dart.
      mockReminders.enabledById['vitamine_d'] = true;
      await pumpScreen(tester);
      await toggleOptIn(tester);

      expect(fakeNotifications.ensurePermissionCalls, 1);
      expect(fakeSettings.values[settingsKeyNotificationsOptIn], '1');
      expect(_isOn(tester, optInLabel), isTrue);
      // Léa's four presets are all pending. Asserted by content, not by id:
      // past the preferred hour every item is a catch-up, and catch-ups live
      // in their own id band (D5), so the ids depend on the wall clock.
      expect(fakeNotifications.scheduled, hasLength(4));
      expect(
        fakeNotifications.scheduled.values.map((e) => e.$1).toSet(),
        {
          'Vitamine D',
          'Vitamine K',
          'Nettoyage des yeux',
          'Nettoyage du visage',
        },
      );
      expect(fakeNotifications.cancelAllCount, 0);
    });

    testWidgets('denied keeps the switch off, stores nothing, shows the hint',
        (tester) async {
      fakeNotifications.granted = false;
      await pumpScreen(tester);
      await toggleOptIn(tester);

      expect(fakeNotifications.ensurePermissionCalls, 1);
      // Nothing persisted as ON that the OS would not honour (D8).
      expect(fakeSettings.values[settingsKeyNotificationsOptIn], isNull);
      expect(fakeNotifications.scheduled, isEmpty);
      expect(
        find.text('Les notifications sont désactivées dans les réglages du '
            'système. Activez-les là-bas pour recevoir les notifications de '
            'rappel.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'stored ON with the permission revoked reads OFF after the start-up '
        'sync (D8 de-opt)', (tester) async {
      // The parent opted in weeks ago and has since revoked the permission in
      // system settings. The de-opt belongs to the start-up/resume sync, so
      // this mounts the lifecycle observer the app really runs.
      fakeSettings.values[settingsKeyNotificationsOptIn] = '1';
      fakeNotifications.granted = false;

      await pumpScreen(tester, withLifecycle: true);

      // No tap: the first frame's sync did the work. Tapping here would be a
      // fresh opt-in and would ask the OS, which is not what this asserts.
      expect(fakeSettings.values[settingsKeyNotificationsOptIn], '0');
      // The section is below the fold (a ListView builds what it may show), so
      // bring it on stage before reading its switch — the same reason the custom
      // rows above scroll before tapping.
      await revealOptIn(tester);
      expect(_isOn(tester, optInLabel), isFalse);
      // Reflecting reality is not the same as re-asking: no prompt here.
      expect(fakeNotifications.ensurePermissionCalls, 0);
      // And nothing is left ringing: the schedule is empty, not merely unstored.
      expect(fakeNotifications.cancelAllCount, 1);
      expect(fakeNotifications.scheduled, isEmpty);
    });

    testWidgets('turning it off persists 0 and cancels every notification',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationsOptIn] = '1';
      // Upgraded-install state, see the opt-in test above: four presets pending.
      mockReminders.enabledById['vitamine_d'] = true;
      // With the lifecycle observer, so the start-up sync really schedules the
      // four entries this test then expects cancelAll() to clear.
      await pumpScreen(tester, withLifecycle: true);

      await revealOptIn(tester);
      expect(_isOn(tester, optInLabel), isTrue);
      expect(fakeNotifications.scheduled, hasLength(4));

      await tester.tap(_switchFor(optInLabel));
      await tester.pumpAndSettle();

      expect(fakeSettings.values[settingsKeyNotificationsOptIn], '0');
      // Asserted on the fake OS, through the real scheduler.
      expect(fakeNotifications.cancelAllCount, 1);
      expect(fakeNotifications.scheduled, isEmpty);
    });

    testWidgets('the stored time is displayed, and the row wakes up',
        (tester) async {
      fakeSettings.values[settingsKeyNotificationsOptIn] = '1';
      fakeSettings.values[settingsKeyNotificationTime] = '20:30';
      await pumpScreen(tester);
      await revealOptIn(tester);

      final row = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Heure de notification'),
          matching: find.byType(ListTile),
        ),
      );
      expect(row.enabled, isTrue);
      expect(find.widgetWithText(ListTile, '20:30'), findsOneWidget);
    });
  });

  group('setTime (M6)', () {
    test('persists zero-padded HH:mm and reconciles through the sync cycle',
        () async {
      fakeSettings.values[settingsKeyNotificationsOptIn] = '1';
      // Upgraded-install plan: four presets pending, see the opt-in tests above.
      mockReminders.enabledById['vitamine_d'] = true;
      final container = ProviderContainer(
        overrides: [
          remindersRepositoryProvider
              .overrideWith((ref) async => mockReminders),
          appSettingsRepositoryProvider
              .overrideWith((ref) async => fakeSettings),
          localNotificationServiceProvider
              .overrideWith((ref) async => fakeNotifications),
          babyProfileListProvider.overrideWith((ref) async => [_baby]),
          localeProvider.overrideWith(_FrLocaleNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationSettingsProvider.future);
      await container.read(reminderSyncNotifierProvider.notifier).syncNow();
      final initCalls = fakeNotifications.initCalls;
      expect(fakeNotifications.scheduled, hasLength(4));

      await container
          .read(notificationSettingsProvider.notifier)
          .setTime(hour: 20, minute: 7);

      // The storage contract of this layer: zero-padded HH:mm, never '8:7'.
      expect(fakeSettings.values[settingsKeyNotificationTime], '20:07');
      expect(fakeSettings.values[settingsKeyNotificationsOptIn], '1');
      // The UI state the row reads back.
      expect(
        container.read(notificationSettingsProvider).requireValue.timeLabel,
        '20:07',
      );
      // A reconciliation ran, and it left exactly four items pending — never
      // eight (the plugin replaces a pending entry by id; nothing stacks).
      expect(fakeNotifications.initCalls, greaterThan(initCalls));
      expect(fakeNotifications.scheduled, hasLength(4));
      expect(
        fakeNotifications.scheduled.values.map((e) => e.$1).toSet(),
        hasLength(4),
      );
    });
  });
}

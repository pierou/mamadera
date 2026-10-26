import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/widgets/lifecycle_sync.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/repositories/app_settings_repository.dart';
import 'package:mamadera/features/reminders/domain/services/local_notification_service.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_sync_notifier.dart';
import 'package:mamadera/features/reminders/presentation/screens/reminder_settings_screen.dart';
import 'package:mamadera/features/reminders/presentation/widgets/custom_reminder_tile.dart';
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
  }) async {
    scheduled[id] = (title, body, at);
  }

  @override
  Future<void> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delay,
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

  /// [withLifecycle] mounts the real `LifecycleSyncWidget` — the start-up and
  /// resume reconciliation, which is where the D8 de-opt lives.
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
              ? const LifecycleSyncWidget(child: ReminderSettingsScreen())
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
      // Vitamin K is set to the date of birth (15) in the active profile.
      expect(find.text('Le 15 de chaque mois'), findsOneWidget);
    });

    testWidgets(
        'tout est activé par défaut : les rappels sont une option de retrait',
        (tester) async {
      await pumpScreen(tester);

      // 4 presets + the "System notifications" opt-in (M6).
      expect(find.byType(SwitchListTile), findsNWidgets(5));
      for (final label in [
        'Vitamine D',
        'Vitamine K',
        'Nettoyage des yeux',
        'Nettoyage du visage'
      ]) {
        expect(_isOn(tester, label), isTrue, reason: label);
      }
    });

    testWidgets('un rappel déjà éteint est affiché éteint', (tester) async {
      mockReminders.enabledById['eye_cleaning'] = false;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Nettoyage des yeux'), isFalse);
      expect(_isOn(tester, 'Vitamine D'), isTrue);
    });

    testWidgets('un enabled enregistré true laisse le rappel activé',
        (tester) async {
      mockReminders.enabledById['vitamine_d'] = true;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Vitamine D'), isTrue);
    });

    testWidgets('éteindre un rappel l\'enregistre et le switch reste éteint',
        (tester) async {
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
      expect(find.byType(SwitchListTile), findsNWidgets(5));
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

      expect(find.text('Le 15 de chaque mois'), findsNWidgets(2));
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

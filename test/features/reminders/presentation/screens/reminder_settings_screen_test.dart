import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
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

bool _isOn(WidgetTester tester, String label) =>
    tester.widget<Switch>(find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(SwitchListTile),
      ),
      matching: find.byType(Switch),
    ))
        .value;

void main() {
  late MockRemindersRepository mockReminders;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remindersRepositoryProvider.overrideWith((ref) async => mockReminders),
          activeBabyProvider.overrideWith(() => _ActiveBabyStub(_baby)),
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
  }

  setUp(() {
    mockReminders = MockRemindersRepository();
  });

  group('ReminderSettingsScreen', () {
    testWidgets('affiche le titre et la promesse de confidentialité', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Rappels'), findsOneWidget);
      expect(
        find.text(
          "Bandeaux affichés sur l'accueil tant que le soin n'a pas été saisi. "
          'Aucune notification système n\'est envoyée : tout reste sur cet appareil.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('liste les quatre rappels préréglés avec leur fréquence', (tester) async {
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

    testWidgets('tout est activé par défaut : les rappels sont une option de retrait', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(SwitchListTile), findsNWidgets(4));
      for (final label in ['Vitamine D', 'Vitamine K', 'Nettoyage des yeux', 'Nettoyage du visage']) {
        expect(_isOn(tester, label), isTrue, reason: label);
      }
    });

    testWidgets('un rappel déjà éteint est affiché éteint', (tester) async {
      mockReminders.enabledById['eye_cleaning'] = false;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Nettoyage des yeux'), isFalse);
      expect(_isOn(tester, 'Vitamine D'), isTrue);
    });

    testWidgets('un enabled enregistré true laisse le rappel activé', (tester) async {
      mockReminders.enabledById['vitamine_d'] = true;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Vitamine D'), isTrue);
    });

    testWidgets('éteindre un rappel l\'enregistre et le switch reste éteint', (tester) async {
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

    testWidgets('la liste reste affichée quand tout est déjà fait aujourd\'hui', (tester) async {
      // The settings have nothing to do with whether a reminder is due or not.
      // The list of presets is displayed even if none of them are overdue.
      mockReminders.lastCompletedByItem['vitamine_d'] = DateTime.now();
      mockReminders.lastCompletedByItem['vitamine_k'] = DateTime.now();
      mockReminders.lastCompletedByItem['eye_cleaning'] = DateTime.now();
      mockReminders.lastCompletedByItem['face_cleaning'] = DateTime.now();

      await pumpScreen(tester);

      expect(find.byType(SwitchListTile), findsNWidgets(4));
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

    testWidgets('une ligne existante porte le nom choisi par le parent, pas le nom du soin',
        (tester) async {
      store(label: 'Crème du change');

      await pumpScreen(tester);

      // The preset setting indicates the type of treatment; a personalized reminder tells the parent what to do.
      // He wanted to keep it, but "nose cleaning" would be a lie in this context.
      expect(find.text('Crème du change'), findsOneWidget);
      expect(find.text('Tous les jours'), findsNWidgets(4));
      expect(find.byType(CustomReminderTile), findsOneWidget);
    });

    testWidgets('un rythme mensuel est annoncé sur le jour de naissance du bébé',
        (tester) async {
      store(label: 'Bilan du mois', frequency: const ReminderFrequency.monthly(dayOfMonth: 1));

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

    testWidgets('le switch d\'une ligne personnalisée éteint le rappel sous sa propre clé',
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

    testWidgets("ajouter un rappel l'enregistre et l'affiche sans quitter l'écran",
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
      expect(mockReminders.customRemindersById.values.single.label, 'Sérum visage');
      expect(find.byType(CustomReminderTile), findsOneWidget);
      expect(find.text('Sérum visage'), findsOneWidget);
      // Nothing is modal anymore: the screen has reappeared, ready for a second input.
      expect(find.text('Nouveau rappel'), findsNothing);
    });

    testWidgets('renommer un rappel passe par le formulaire prérempli et ne le duplique pas',
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

    testWidgets('supprimer après accord retire la ligne et sa position de switch',
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
    testWidgets('un enregistrement refusé le dit au lieu de disparaître en silence',
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
}

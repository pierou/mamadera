import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
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

/// Le switch de la ligne dont le titre est [label].
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

      // Nom complet du soin, pas l'abréviation de la pastille d'accueil.
      expect(find.text('Vitamine D'), findsOneWidget);
      expect(find.text('Vitamine K'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
      expect(find.text('Nettoyage du visage'), findsOneWidget);

      expect(find.text('Tous les jours'), findsNWidgets(3));
      // Vit. K est calée sur le jour de naissance (15) du profil actif.
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
      // Pas de retour en arrière le temps d'un rechargement.
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
      // Les réglages n'ont rien à voir avec le fait qu'un rappel soit dû ou non :
      // la liste des préréglages s'affiche même si aucun n'est en retard.
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
    /// Amène une ligne hors écran en haut de la liste, puis la touche.
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

      // Le préréglage dit quel soin ; un rappel personnalisé dit ce que le parent
      // a voulu retenir. « Nettoyage du nez » ici serait un mensonge.
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

    testWidgets('le switch d\'une ligne personnalisée éteint le rappel sous sa propre clé',
        (tester) async {
      store();

      await pumpScreen(tester);
      await tapRow(tester, customSwitch());

      expect(mockReminders.enabledById['custom_1'], isFalse);
      expect(mockReminders.setEnabledCallCount, 1);
      // Les préréglages ne sont pas touchés par cette extinction.
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
      // Plus rien de modale : l'écran est revenu, prêt à une seconde saisie.
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

      // Le nom du rappel dans la question, l'historique promis dans la réponse.
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

    // Sans ces deux cas, une écriture refusée se traduirait par un panneau qui se
    // ferme sans rien : l'exception partirait dans un futur que personne n'attend.
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
      // Rien n'a été inventé : pas de ligne, pas de faux souvenir.
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
      // Le rappel est toujours là, texte et switch compris : rien n'a été fait à
      // moitié.
      expect(mockReminders.customRemindersById, hasLength(1));
      expect(find.byType(CustomReminderTile), findsOneWidget);
    });
  });
}

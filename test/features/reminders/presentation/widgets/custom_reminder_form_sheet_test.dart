import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/presentation/widgets/custom_reminder_form_sheet.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

/// Ce que la feuille a rendu au Navigator.
CustomReminder? _popped;

Finder _labelField() => find.widgetWithText(TextFormField, 'Nom du rappel');
Finder _intervalField() =>
    find.widgetWithText(TextFormField, 'Intervalle en jours');
Finder _frequencyField() =>
    find.byType(DropdownButtonFormField<CustomReminderFrequencyChoice>);

/// Ouvre la feuille et garde en mémoire ce qu'elle rend.
Future<void> _open(
  WidgetTester tester, {
  CustomReminder? existing,
}) async {
  _popped = null;
  // Une feuille ouverte survivrait au `pumpWidget` suivant — le Navigator est
  // réutilisé tel quel — et son voile empêcherait le prochain tap. On démonte
  // l'arbre entre deux ouvertures.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                _popped = await showModalBottomSheet<CustomReminder>(
                  context: context,
                  isScrollControlled: true,
                  builder: (sheetContext) =>
                      CustomReminderFormSheet(existing: existing),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

Future<void> _pickFrequency(WidgetTester tester, String label) async {
  await tester.tap(_frequencyField());
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.text('Confirmer'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    _popped = null;
  });

  group('CustomReminderFormSheet', () {
    testWidgets('parle de nouveau rappel à la création', (tester) async {
      await _open(tester);

      expect(find.text('Nouveau rappel'), findsOneWidget);
    });

    testWidgets('parle de modification quand un rappel est préchargé',
        (tester) async {
      await _open(
        tester,
        existing: CustomReminder(
          id: 7,
          label: 'Sérum',
          subtypeValue: HealthSubtype.nettoyageYeux.value,
          frequency: const ReminderFrequency.daily(),
        ),
      );

      expect(find.text('Modifier le rappel'), findsOneWidget);
    });

    testWidgets('un nom est exigé avant de rendre quoi que ce soit',
        (tester) async {
      await _open(tester);

      await _confirm(tester);

      expect(find.text('Donnez un nom au rappel'), findsOneWidget);
      // La feuille est toujours ouverte : le parent n'a rien perdu de sa saisie.
      expect(find.text('Nouveau rappel'), findsOneWidget);
      expect(_popped, isNull);
    });

    testWidgets('un nom composé uniquement d\'espaces est refusé',
        (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), '   ');

      await _confirm(tester);

      expect(find.text('Donnez un nom au rappel'), findsOneWidget);
      expect(_popped, isNull);
    });

    testWidgets('rend le rappel saisi, les espaces en moins', (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), '  Crème du change  ');

      await _confirm(tester);

      expect(_popped, isNotNull);
      expect(_popped!.label, 'Crème du change');
      // Le soin par défaut est celui que les parents demandent le plus souvent,
      // et l'id reste null : c'est l'appelant qui écrit, donc qui numérote.
      expect(_popped!.subtypeValue, HealthSubtype.nettoyageNez.value);
      expect(_popped!.frequency, const ReminderFrequency.daily());
      expect(_popped!.id, isNull);
    });

    testWidgets('le soin associé est celui du menu déroulant', (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), 'Gouttes du soir');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vitamine D'));
      await tester.pumpAndSettle();

      await _confirm(tester);

      expect(_popped!.subtypeValue, HealthSubtype.vitamineD.value);
    });

    testWidgets('le champ intervalle n\'existe que pour un roulement',
        (tester) async {
      await _open(tester);
      expect(find.byType(TextFormField), findsNWidgets(1));

      await _pickFrequency(tester, 'Intervalle en jours');

      // Deux champs : le nom, puis l'intervalle apparu avec le rythme choisi.
      expect(find.byType(TextFormField), findsNWidgets(2));
      // Une valeur de départ évite un refus de validation sur un champ vide.
      expect(tester.widget<TextFormField>(_intervalField()).controller?.text, '3');
    });

    testWidgets('un roulement rend le nombre de jours demandé', (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), 'Sérum visage');
      await _pickFrequency(tester, 'Intervalle en jours');
      await tester.enterText(_intervalField(), '12');

      await _confirm(tester);

      expect(_popped!.frequency, const ReminderFrequency.customInterval(days: 12));
    });

    testWidgets('un intervalle hors des bornes est refusé', (tester) async {
      for (final value in ['0', '366', 'deux']) {
        await _open(tester);
        await tester.enterText(_labelField(), 'Sérum visage');
        await _pickFrequency(tester, 'Intervalle en jours');
        await tester.enterText(_intervalField(), value);

        await _confirm(tester);

        expect(find.text('Indiquez un nombre de jours, de 1 à 365'),
            findsOneWidget,
            reason: value);
        expect(_popped, isNull, reason: value);
      }
    });

    testWidgets('le jour de naissance est proposé comme rythme mensuel',
        (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), 'Bilan du mois');
      await _pickFrequency(tester, 'Le jour de naissance, chaque mois');

      // Un rythme mensuel ne demande pas de jour : il est celui de naissance du
      // bébé, et un champ pour le choisir serait un piège entre deux bébés.
      expect(find.byType(TextFormField), findsNWidgets(1));

      await _confirm(tester);

      // Le jour rendu est le repli, qui sera remplacé par le jour de naissance
      // du bébé actif au moment où la liste d'accueil se construit.
      expect(
        _popped!.frequency,
        const ReminderFrequency.monthly(
          dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
        ),
      );
    });

    testWidgets('un rappel hebdomadaire est rendu sans jour de semaine',
        (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), 'Pesée');
      await _pickFrequency(tester, 'Chaque semaine');

      await _confirm(tester);

      expect(_popped!.frequency, isA<Weekly>());
    });

    testWidgets('la modification préremplit le formulaire et rend l\'id',
        (tester) async {
      await _open(
        tester,
        existing: CustomReminder(
          id: 7,
          label: 'Crème du change',
          subtypeValue: HealthSubtype.nettoyageYeux.value,
          frequency: const ReminderFrequency.customInterval(days: 5),
        ),
      );

      expect(tester.widget<TextFormField>(_labelField()).controller?.text,
          'Crème du change');
      // Le rythme enregistré se retrouve sélectionné, intervalle compris.
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.widget<TextFormField>(_intervalField()).controller?.text, '5');
      expect(
        tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        ).initialValue,
        HealthSubtype.nettoyageYeux.value,
      );

      await tester.enterText(_labelField(), 'Crème du change, le soir');
      await _confirm(tester);

      expect(_popped!.id, 7);
      expect(_popped!.label, 'Crème du change, le soir');
      expect(_popped!.frequency, const ReminderFrequency.customInterval(days: 5));
    });

    testWidgets('annuler ne rend rien et n\'écrit rien', (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), 'Rappel abandonné');

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(_popped, isNull);
      expect(find.text('Rappel abandonné'), findsNothing);
    });
  });
}

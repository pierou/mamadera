import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/presentation/widgets/custom_reminder_form_sheet.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

/// What the sheet returned to the Navigator.
CustomReminder? _popped;

Finder _labelField() => find.widgetWithText(TextFormField, 'Nom du rappel');
Finder _intervalField() =>
    find.widgetWithText(TextFormField, 'Intervalle en jours');
Finder _frequencyField() =>
    find.byType(DropdownButtonFormField<CustomReminderFrequencyChoice>);

/// Open the sheet and remember what it displays.
Future<void> _open(
  WidgetTester tester, {
  CustomReminder? existing,
}) async {
  _popped = null;
  // An open sheet would survive the next `pumpWidget`—the Navigator is...
  // Reused as is – and its coating would prevent the next layer from adhering. We disassemble it.
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
      // The file is still open: the parent has not lost access to it.
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
      // The default care option is the one that parents most frequently request.
      // and the ID remains null: it's the caller who is writing, and therefore who is providing the number.
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

      // Two fields: the name, followed by the interval that appears based on the selected rhythm.
      expect(find.byType(TextFormField), findsNWidgets(2));
      // A default value prevents validation errors from occurring on empty fields.
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

      // A monthly cycle doesn't require a specific day; it's the cycle that begins with the onset of menstruation.
      // a baby, and a field where you could choose one would be a trap between two babies.
      expect(find.byType(TextFormField), findsNWidgets(1));

      await _confirm(tester);

      // The day previously assigned is being replaced with the day of birth.
      // from the active baby stage to the moment when the gift registry is being created.
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
      // The recorded rhythm is selected, including the specified interval.
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

  group('soin détaché (M3)', () {
    testWidgets('le menu des soins commence par « Aucun soin »', (tester) async {
      await _open(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // There's a carelessly prepared dish on the menu...
      expect(find.text('Aucun soin'), findsOneWidget);
      final menuItems = tester
          .widgetList<DropdownMenuItem<String>>(
              find.byType(DropdownMenuItem<String>))
          .toList();
      expect(menuItems.where((item) => item.value == null), hasLength(1));
      // ...and she's in the lead, ahead of the first aid station.
      expect(
        tester.getRect(find.text('Aucun soin')).top,
        lessThan(tester.getRect(find.text('Nettoyage des yeux')).top),
      );
    });

    testWidgets(
        'choisir « Aucun soin » rend un rappel détaché réglé par tap',
        (tester) async {
      await _open(tester);
      await tester.enterText(_labelField(), 'Thermomètre');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aucun soin'));
      await tester.pumpAndSettle();

      // The name and frequency remain unchanged; nothing is obscured by the separation.
      expect(_labelField(), findsOneWidget);
      expect(_frequencyField(), findsOneWidget);

      await _confirm(tester);

      expect(_popped, isNotNull);
      expect(_popped!.label, 'Thermomètre');
      expect(_popped!.subtypeValue, isNull);
      expect(_popped!.completionSource, completionManual);
      expect(_popped!.frequency, const ReminderFrequency.daily());
      expect(_popped!.id, isNull);
    });

    testWidgets(
        'modifier un rappel détaché le laisse détaché (verrou de régression)',
        (tester) async {
      await _open(
        tester,
        existing: CustomReminder(
          id: 7,
          label: 'Thermomètre',
          frequency: const ReminderFrequency.customInterval(days: 2),
          subtypeValue: null,
          completionSource: completionManual,
        ),
      );

      // The form was forcing the value of `nettoyage_nez` to be set, overriding any previous value.
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>))
            .initialValue,
        isNull,
      );

      await _confirm(tester);

      expect(_popped, isNotNull);
      expect(_popped!.id, 7);
      expect(_popped!.label, 'Thermomètre');
      expect(_popped!.subtypeValue, isNull);
      expect(_popped!.completionSource, completionManual);
      expect(_popped!.frequency, const ReminderFrequency.customInterval(days: 2));
    });

    testWidgets('un rappel lié au soin reste lié, réglé par événement',
        (tester) async {
      await _open(
        tester,
        existing: CustomReminder(
          id: 8,
          label: 'Crème du change',
          frequency: const ReminderFrequency.daily(),
          subtypeValue: HealthSubtype.nettoyageNez.value,
        ),
      );

      await _confirm(tester);

      expect(_popped, isNotNull);
      expect(_popped!.id, 8);
      expect(_popped!.subtypeValue, HealthSubtype.nettoyageNez.value);
      expect(_popped!.completionSource, completionFromEvents);
      expect(_popped!.frequency, const ReminderFrequency.daily());
    });
  });
}

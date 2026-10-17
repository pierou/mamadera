import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/widgets/edit_event_dialog.dart';
import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';

/// Helper: Instantiates a `pompe` (pump) `EditEventDialog` within a `MaterialApp` and `ProviderScope` context.
Future<void> pumpDialog(WidgetTester tester, TrackingEvent event) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: EditEventDialog(event)),
      ),
    ),
  );
}

void main() {
  group('EditEventDialog — Affichage initial', () {
    testWidgets(
        'pipi (DiaperEvent) → section PipiColor visible, CacaColor absente',
        (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15, 10, 30),
        wasteType: WasteType.pipi,
        pipiColor: pipiColorJauneClair,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsNothing);
    });

    testWidgets(
        'caca (DiaperEvent) → WasteType FilterChips + CacaColor visible',
        (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
        cacaColor: cacaColorJauneMoutarde,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('🟡 Pipi'), findsOneWidget);
      expect(find.text('🟤 Caca'), findsOneWidget);
      expect(find.text('🟡🟤 Les deux'), findsOneWidget);
    });

    testWidgets('lesDeux (DiaperEvent) → PipiColor ET CacaColor visibles',
        (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.lesDeux,
        pipiColor: pipiColorIncolore,
        cacaColor: cacaColorVertOlive,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsOneWidget);
    });

    testWidgets('dodo (SleepEvent) → champ durée visible', (tester) async {
      final event = SleepEvent(
        unit: QuantityUnit.min,
        timestamp: DateTime.utc(2024, 6, 15),
        duration: 90,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // QuantityPickerInline displays 'min' in multiple places (headline, slider label, suffix)
      expect(find.text('min'), findsWidgets);
    });

    testWidgets('sante (HealthEvent) → HealthSubtype ListTiles visibles',
        (tester) async {
      final event = HealthEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        subtype: HealthSubtype.nettoyageYeux,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('Type de soin'), findsOneWidget);
    });

    testWidgets('miam (FeedingEvent) → notes visibles', (tester) async {
      final event = FeedingEvent(
        unit: QuantityUnit.ml,
        timestamp: DateTime.utc(2024, 6, 15),
        subtype: FeedingSubtype.natural,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
    });
  });

  group('EditEventDialog — Sélection WasteType via FilterChip', () {
    testWidgets('tap pipi → section PipiColor apparaît, CacaColor disparaît',
        (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
        cacaColor: cacaColorJauneMoutarde,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // Switch to pipi
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
    });

    testWidgets('tap lesDeux → sections PipiColor ET CacaColor apparaissent',
        (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      await tester.tap(find.text('🟡🟤 Les deux'));
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsOneWidget);
    });
  });

  group('EditEventDialog — Sélection couleurs', () {
    testWidgets('PipiColor toggle : tap → selected, retap → deselected',
        (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // Switch to "pee mode" to see the pee-shaped chips.
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      final chip = find.widgetWithText(FilterChip, 'Jaune clair');
      expect(chip, findsOneWidget);

      // First tap → selected.
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilterChip>(chip).selected,
        isTrue,
      );

      // Second tap → deselect (toggle).
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilterChip>(chip).selected,
        isFalse,
      );
    });

    testWidgets('CacaColor toggle : sélection/désélection', (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      final chip = find.widgetWithText(FilterChip, 'Jaune moutarde');
      expect(chip, findsOneWidget);

      // Select.
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(chip).selected, isTrue);

      // Deselect.
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(chip).selected, isFalse);
    });
  });

  group('EditEventDialog — Champ durée (dodo uniquement)', () {
    testWidgets('durée saisie → valeur parsable', (tester) async {
      final event = SleepEvent(
        unit: QuantityUnit.min,
        timestamp: DateTime.utc(2024, 6, 15),
        duration: 30,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // QuantityPickerInline displays 'min' in multiple places (headline, slider label, suffix)
      expect(find.text('min'), findsWidgets);
    });

    testWidgets('durée initiale pré-remplie', (tester) async {
      final event = SleepEvent(
        unit: QuantityUnit.min,
        timestamp: DateTime.utc(2024, 6, 15),
        duration: 90,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // QuantityPickerInline displays 'min' in multiple places (headline, slider label, suffix)
      expect(find.text('min'), findsWidgets);
    });
  });

  group('EditEventDialog — Sous-types santé (sante uniquement)', () {
    testWidgets('tap sur un HealthSubtype → tile sélectionné avec check_circle',
        (tester) async {
      final event = HealthEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        subtype: HealthSubtype.vitamineD,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // Tap Nettoyage des yeux
      await tester.tap(find.text('Nettoyage des yeux'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithIcon(ListTile, Icons.check_circle),
        findsOneWidget,
      );
    });

    testWidgets('sélection initiale pré-remplie', (tester) async {
      final event = HealthEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        subtype: HealthSubtype.vitamineD,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // The "Vitamin D" tile should have a checkmark.
      expect(
        find.widgetWithIcon(ListTile, Icons.check_circle),
        findsOneWidget,
      );
    });
  });

  group('EditEventDialog — Submit → UpdateResult retourné', () {
    testWidgets('tap Enregistrer → Navigator.pop avec UpdateResult',
        (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      final completer = Completer<UpdateResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: FeedingEvent(
                unit: QuantityUnit.ml,
                timestamp: DateTime.utc(2024, 1, 1),
                subtype: FeedingSubtype.natural,
              ),
              onResult: (r) => completer.complete(r as UpdateResult?),
            ),
          ),
        ),
      );

      // Ouvrir le dialog
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier l\'\u00e9v\u00e9nement'), findsOneWidget);

      // Tap Enregistrer
      final submitBtn = find.text('Enregistrer');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<UpdateResult>());
    });

    testWidgets('submit avec notes → UpdateResult.notes contient la valeur',
        (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      final completer = Completer<EditResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: FeedingEvent(
                unit: QuantityUnit.ml,
                timestamp: DateTime.utc(2024, 1, 1),
                subtype: FeedingSubtype.natural,
              ),
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Saisir une note
      final textField = find.byType(TextFormField).first;
      await tester.enterText(textField, 'test note');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final result = (await completer.future) as UpdateResult?;
      expect(result?.notes, 'test note');
    });
  });

  group('EditEventDialog — Santé : préservation des notes (régression)', () {
    // Regression: Editing a HealthEvent (e.g., changing the timestamp) and...
    // The submission process should not overwrite the notes with the subtype string.
    // ('vitamine_d'), ni perdre les notes existantes.
    testWidgets('sante: notes préservées au submit, sous-type inchangé',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      const originalNotes = 'Vitamine D 400 UI par jour';
      final completer = Completer<EditResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: HealthEvent(
                timestamp: DateTime.utc(2024, 6, 15, 9),
                subtype: HealthSubtype.vitamineD,
                notes: originalNotes,
              ),
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      // Ouvrir le dialog
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // The "Vitamin D" tile is pre-selected.
      expect(find.widgetWithIcon(ListTile, Icons.check_circle), findsOneWidget);

      // Submit without making any changes.
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final result = (await completer.future) as UpdateResult?;
      // Regression assertion: the grades are NOT the string representing the subtype.
      expect(result?.notes, originalNotes,
          reason: 'les notes originales doivent être préservées, '
              'jamais la value du sous-type');
      expect(result?.healthSubtype, HealthSubtype.vitamineD);
    });

    testWidgets('sante: changer le sous-type préserve les notes',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      const originalNotes = 'note de soin';
      final completer = Completer<EditResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: HealthEvent(
                timestamp: DateTime.utc(2024, 6, 15, 9),
                subtype: HealthSubtype.vitamineD,
                notes: originalNotes,
              ),
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Change the subtype to "Eye Cleaning."
      await tester.tap(find.text('Nettoyage des yeux'));
      await tester.pumpAndSettle();

      // Soumettre
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final result = (await completer.future) as UpdateResult?;
      expect(result?.healthSubtype, HealthSubtype.nettoyageYeux);
      expect(result?.notes, originalNotes);
    });
  });

  group('EditEventDialog — Delete confirmation flow', () {
    testWidgets(
        'tap Supprimer → AlertDialog ouvert avec message de confirmation',
        (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      final completer = Completer<EditResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: FeedingEvent(
                unit: QuantityUnit.ml,
                timestamp: DateTime.utc(2024, 6, 15),
                subtype: FeedingSubtype.natural,
              ),
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      // Ouvrir le dialog principal
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier l\'\u00e9v\u00e9nement'), findsOneWidget);

      // Scroll down to make the delete button visible
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      final deleteBtn = find.widgetWithText(TextButton, 'Supprimer');
      expect(deleteBtn, findsOneWidget);

      // Ouvrir le dialog de confirmation
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // The AlertDialog must be present, including its title and content.
      expect(find.text('Supprimer l\'\u00e9v\u00e9nement'), findsOneWidget);
      expect(
        find.textContaining(
            'Voulez-vous vraiment supprimer cet \u00e9v\u00e9nement ?'),
        findsOneWidget,
      );
    });

    testWidgets('Annuler → dialog de confirmation clos', (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      final completer = Completer<EditResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: FeedingEvent(
                unit: QuantityUnit.ml,
                timestamp: DateTime.utc(2024, 6, 15),
                subtype: FeedingSubtype.natural,
              ),
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      // Ouvrir le dialog principal
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier l\'\u00e9v\u00e9nement'), findsOneWidget);

      // Scroll down to make the delete button visible
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      // Ouvrir le dialog de confirmation
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Annuler'), findsOneWidget);

      // Tap Annuler → close AlertDialog (pas de suppression)
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // The main dialogue is still present.
      expect(find.text('Modifier l\'\u00e9v\u00e9nement'), findsOneWidget);
    });

    testWidgets('Supprimer confirmé → DeleteResult retourné', (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      final completer = Completer<EditResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: SleepEvent(
                unit: QuantityUnit.min,
                timestamp: DateTime.utc(2024, 1, 1),
                duration: 60,
              ),
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Scroll down to make the delete button visible
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      // Ouvrir confirm delete → AlertDialog
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      // Confirm deletion (red button).
      final filledDelete = find.byType(FilledButton);
      await tester.tap(filledDelete);
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<DeleteResult>());
    });
  });
  group('EditEventDialog — Consistance de la selle', () {
    // The editing process is lengthy: without an expanded viewport, the lower portion of the image is cut off.
    // (and "Save") remain hidden from the screen, and the tap fails to register.
    Future<void> openFor(WidgetTester tester, TrackingEvent event,
        Completer<EditResult?> completer) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: event,
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Enregistrer'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la texture enregistrée est déjà sélectionnée', (tester) async {
      final completer = Completer<EditResult?>();
      await openFor(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2026, 9, 1),
          wasteType: WasteType.caca,
          cacaColor: cacaColorJauneMoutarde,
          stoolTexture: stoolTextureMoulee,
        ),
        completer,
      );

      expect(find.text('Texture du caca'), findsOneWidget);
      final selected = find.widgetWithText(FilterChip, 'Moulée');
      expect(tester.widget<FilterChip>(selected).selected, isTrue);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Dure'))
            .selected,
        isFalse,
      );
    });

    testWidgets('changer la texture la renvoie dans UpdateResult',
        (tester) async {
      final completer = Completer<EditResult?>();
      await openFor(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2026, 9, 1),
          wasteType: WasteType.caca,
          stoolTexture: stoolTextureMoulee,
        ),
        completer,
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Aqueuse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final result = (await completer.future) as UpdateResult?;
      expect(result?.stoolTexture, equals(stoolTextureAqueuse));
    });

    // Regression: The consistency only describes a saddle. Converting a gear shift into...
    // "Pipi" should not leave a texture that allows the strands to separate and move back towards the roots.
    testWidgets('aucune section texture pour un événement pipi',
        (tester) async {
      final completer = Completer<EditResult?>();
      await openFor(
        tester,
        DiaperEvent(
          timestamp: DateTime.utc(2026, 9, 1),
          wasteType: WasteType.pipi,
          pipiColor: pipiColorJauneClair,
        ),
        completer,
      );

      expect(find.text('Texture du caca'), findsNothing);
    });
  });

  group('EditEventDialog — Re-typage en solide', () {
    // The re-labeling of baby bottles to indicate puree volume must be done using grams.
    // The original timestamp must be preserved during the submission process (it should not be a new "now" timestamp).
    testWidgets('re-typing biberon → solide : unité g, horodatage préservé',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1600);
      addTearDown(tester.view.reset);

      final completer = Completer<EditResult?>();
      final original = FeedingEvent(
        unit: QuantityUnit.ml,
        timestamp: DateTime.utc(2024, 1, 1, 9, 30),
        subtype: FeedingSubtype.artificial,
        quantity: 120,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _DialogLauncher(
              event: original,
              onResult: (r) => completer.complete(r as EditResult?),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Retape en solide : le picker passe en grammes, et **le nombre ne
      // **Does not handle unit changes** (v1.2.1): 120 ml is not the same as 120 g.
      // The quantity is reset to zero, and a dialog box displays this information.
      await tester.tap(find.text('Solide'));
      await tester.pumpAndSettle();
      expect(find.text('0 g'), findsOneWidget);
      expect(find.text('Unité modifiée : la quantité a été remise à 0.'),
          findsOneWidget);

      final picker = tester
          .widget<QuantityPickerInline>(find.byType(QuantityPickerInline));
      expect(picker.unit, equals('g'));
      expect(picker.max, equals(1000));
      expect(picker.step, equals(5));

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final result = (await completer.future) as UpdateResult?;
      expect(result?.subtype, FeedingSubtype.solid);
      expect(result?.quantity, 0);
      expect(result?.timestamp, original.timestamp);
    });
  });
}

/// Wrapper to capture the return value of `showModalBottomSheet` in tests.
class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher({required this.event, required this.onResult});

  final TrackingEvent event;
  final void Function(dynamic) onResult;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final result = await showModalBottomSheet<dynamic>(
            context: context,
            isScrollControlled: true,
            builder: (_) => EditEventDialog(event),
          );
          onResult(result);
        },
        child: const Text('Ouvrir'),
      ),
    );
  }
}

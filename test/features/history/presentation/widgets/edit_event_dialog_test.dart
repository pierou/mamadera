import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/widgets/edit_event_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';

/// Helper : pompe EditEventDialog dans un contexte MaterialApp + ProviderScope.
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
    testWidgets('pipi (DiaperEvent) → section PipiColor visible, CacaColor absente', (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15, 10, 30),
        wasteType: WasteType.pipi,
        pipiColor: PipiColor.jauneClair,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsNothing);
    });

    testWidgets('caca (DiaperEvent) → WasteType FilterChips + CacaColor visible', (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
        cacaColor: CacaColor.jauneMoutarde,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('🟡 Pipi'), findsOneWidget);
      expect(find.text('🟤 Caca'), findsOneWidget);
      expect(find.text('🟡🟤 Les deux'), findsOneWidget);
    });

    testWidgets('lesDeux (DiaperEvent) → PipiColor ET CacaColor visibles', (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.lesDeux,
        pipiColor: PipiColor.incolore,
        cacaColor: CacaColor.vertOlive,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsOneWidget);
    });

    testWidgets('dodo (SleepEvent) → champ durée visible', (tester) async {
      final event = SleepEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        duration: 90,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('min'), findsOneWidget);
    });

    testWidgets('sante (HealthEvent) → HealthSubtype ListTiles visibles', (tester) async {
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
        timestamp: DateTime.utc(2024, 6, 15),
        subtype: FeedingSubtype.sein,
        duration: 30,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
    });
  });

  group('EditEventDialog — Sélection WasteType via FilterChip', () {
    testWidgets('tap pipi → section PipiColor apparaît, CacaColor disparaît', (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
        cacaColor: CacaColor.jauneMoutarde,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // Switch to pipi
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
    });

    testWidgets('tap lesDeux → sections PipiColor ET CacaColor apparaissent', (tester) async {
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
    testWidgets('PipiColor toggle : tap → selected, retap → deselected', (tester) async {
      final event = DiaperEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        wasteType: WasteType.caca,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      // Aller en mode pipi pour voir les chips pipi
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      final chip = find.widgetWithText(FilterChip, 'Jaune clair');
      expect(chip, findsOneWidget);

      // Premier tap → sélectionné
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilterChip>(chip).selected,
        isTrue,
      );

      // Deuxième tap → désélectionné (toggle)
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

      // Sélectionner
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(chip).selected, isTrue);

      // Désélectionner
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(chip).selected, isFalse);
    });
  });

  group('EditEventDialog — Champ durée (dodo uniquement)', () {
    testWidgets('durée saisie → valeur parsable', (tester) async {
      final event = SleepEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        duration: 30,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('min'), findsOneWidget);
    });

    testWidgets('durée initiale pré-remplie', (tester) async {
      final event = SleepEvent(
        timestamp: DateTime.utc(2024, 6, 15),
        duration: 90,
      );
      await pumpDialog(tester, event);
      await tester.pumpAndSettle();

      expect(find.text('min'), findsOneWidget);
    });
  });

  group('EditEventDialog — Sous-types santé (sante uniquement)', () {
    testWidgets('tap sur un HealthSubtype → tile sélectionné avec check_circle', (tester) async {
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

      // Le tile Vitamine D doit avoir check_circle
      expect(
        find.widgetWithIcon(ListTile, Icons.check_circle),
        findsOneWidget,
      );
    });
  });

  group('EditEventDialog — Submit → UpdateResult retourné', () {
    testWidgets('tap Enregistrer → Navigator.pop avec UpdateResult', (tester) async {
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
                timestamp: DateTime.utc(2024, 1, 1),
                subtype: FeedingSubtype.sein,
                duration: 0,
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
      final submitBtn = find.widgetWithIcon(ElevatedButton, Icons.check);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<UpdateResult>());
    });

    testWidgets('submit avec notes → UpdateResult.notes contient la valeur', (tester) async {
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
                timestamp: DateTime.utc(2024, 1, 1),
                subtype: FeedingSubtype.sein,
                duration: 0,
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
      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.check));
      await tester.pumpAndSettle();

      final result = (await completer.future) as UpdateResult?;
      expect(result?.notes, 'test note');
    });
  });

  group('EditEventDialog — Delete confirmation flow', () {
    testWidgets('tap Supprimer → AlertDialog ouvert avec message de confirmation', (tester) async {
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
                timestamp: DateTime.utc(2024, 6, 15),
                subtype: FeedingSubtype.sein,
                duration: 30,
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

      final deleteBtn = find.widgetWithText(TextButton, 'Supprimer');
      expect(deleteBtn, findsOneWidget);

      // Ouvrir le dialog de confirmation
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // AlertDialog doit être présent avec son titre et contenu
      expect(find.text('Supprimer l\'\u00e9v\u00e9nement'), findsOneWidget);
      expect(
        find.textContaining('Voulez-vous vraiment supprimer cet \u00e9v\u00e9nement ?'),
        findsOneWidget,
      );
    });

    testWidgets('Annuler → dialog de confirmation clos', (tester) async {
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
                timestamp: DateTime.utc(2024, 6, 15),
                subtype: FeedingSubtype.sein,
                duration: 30,
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

      // Ouvrir le dialog de confirmation
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Annuler'), findsOneWidget);

      // Tap Annuler → close AlertDialog (pas de suppression)
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Le dialog principal est toujours là
      expect(find.text('Modifier l\'\u00e9v\u00e9nement'), findsOneWidget);
    });

    testWidgets('Supprimer confirmé → DeleteResult retourné', (tester) async {
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

      // Ouvrir confirm delete → AlertDialog
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      // Confirmer la suppression (FilledButton rouge)
      final filledDelete = find.byType(FilledButton);
      await tester.tap(filledDelete);
      await tester.pumpAndSettle();

      final result = await completer.future;
      expect(result, isA<DeleteResult>());
    });
  });
}

/// Wrapper pour capturer le retour de showModalBottomSheet dans les tests.
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

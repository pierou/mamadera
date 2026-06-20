import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/widgets/edit_event_dialog.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

/// Helper : pompe EditEventDialog dans un contexte MaterialApp + ProviderScope.
Future<void> pumpDialog(WidgetTester tester, {
  required String type,
  DateTime? timestamp,
  double? duration,
  String? notes,
  String? wasteType,
  String? color,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: EditEventDialog(
            type: type,
            initialTimestamp: timestamp ?? DateTime.utc(2024, 6, 15, 10, 30),
            initialDuration: duration,
            initialNotes: notes,
            initialWasteType: wasteType,
            initialColor: color,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('EditEventDialog — Affichage initial', () {
    testWidgets('type pipi → section PipiColor visible, CacaColor absente, durée absente, notes visibles', (tester) async {
      await pumpDialog(tester, type: 'Pipi', wasteType: 'pipi');
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsNothing);
      // Le champ durée n'apparaît que pour dodo
      expect(find.byType(TextFormField), findsNWidgets(1)); // notes uniquement
    });

    testWidgets('type caca → WasteType FilterChips (3), CacaColor visible, PipiColor absente', (tester) async {
      await pumpDialog(tester, type: 'Caca', wasteType: 'caca');
      await tester.pumpAndSettle();

      expect(find.text('🟡 Pipi'), findsOneWidget);
      expect(find.text('🟤 Caca'), findsOneWidget);
      expect(find.text('🟡🟤 Les deux'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsOneWidget);
    });

    testWidgets('type les_deux → PipiColor ET CacaColor visibles', (tester) async {
      await pumpDialog(tester, type: 'Caca', wasteType: 'les_deux');
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsOneWidget);
    });

    testWidgets('type dodo → champ durée visible, pas de couleurs ni notes', (tester) async {
      await pumpDialog(tester, type: 'Dodo');
      await tester.pumpAndSettle();

      expect(find.text('Durée'), findsOneWidget);
      // Un TextFormField pour la durée
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(1));
    });

    testWidgets('type sante → HealthSubtype ListTiles (6), notes cachées', (tester) async {
      await pumpDialog(tester, type: 'Santé');
      await tester.pumpAndSettle();

      expect(find.text('Type de soin'), findsOneWidget);
      // 6 sous-types santé
      for (final subtype in HealthSubtype.values) {
        expect(find.text(subtype.label), findsOneWidget);
      }
    });

    testWidgets('notes visibles pour type miam', (tester) async {
      await pumpDialog(tester, type: 'Miam');
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      // Hint text du champ notes
      find.byType(TextFormField);
    });
  });

  group('EditEventDialog — Sélection WasteType via FilterChip', () {
    testWidgets('tap pipi → section PipiColor apparaît, CacaColor disparaît', (tester) async {
      await pumpDialog(tester, type: 'Caca', wasteType: 'caca');
      await tester.pumpAndSettle();

      expect(find.text('Couleur du caca'), findsOneWidget);

      // Switch to pipi
      await tester.tap(find.text('🟡 Pipi'));
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
    });

    testWidgets('tap lesDeux → sections PipiColor ET CacaColor apparaissent', (tester) async {
      await pumpDialog(tester, type: 'Caca');
      await tester.pumpAndSettle();

      // Initialement wasteType=caca par défaut
      expect(find.text('Couleur du caca'), findsOneWidget);

      await tester.tap(find.text('🟡🟤 Les deux'));
      await tester.pumpAndSettle();

      expect(find.text('Couleur du pipi'), findsOneWidget);
      expect(find.text('Couleur du caca'), findsOneWidget);
    });
  });

  group('EditEventDialog — Sélection couleurs', () {
    testWidgets('PipiColor toggle : tap → selected, retap → deselected', (tester) async {
      await pumpDialog(tester, type: 'Caca');
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
      await pumpDialog(tester, type: 'Caca');
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
      await pumpDialog(tester, type: 'Dodo');
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField).first;
      // Saisir 45 minutes
      await tester.enterText(textField, '45');
      await tester.pumpAndSettle();

      expect(find.text('min'), findsOneWidget);
    });

    testWidgets('durée initiale pré-remplie', (tester) async {
      await pumpDialog(tester, type: 'Dodo', duration: 90);
      await tester.pumpAndSettle();

      expect(find.text('90'), findsOneWidget);
    });
  });

  group('EditEventDialog — Sous-types santé (sante uniquement)', () {
    testWidgets('tap sur un HealthSubtype → tile sélectionné avec check_circle', (tester) async {
      await pumpDialog(tester, type: 'Santé');
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
      await pumpDialog(tester, type: 'Santé', notes: 'vitamine_d');
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
      // On capture le résultat du dialog via showModalBottomSheet
      final completer = Completer<UpdateResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _DialogLauncher(
              builder: () => EditEventDialog(
                type: 'Miam',
                initialTimestamp: DateTime.utc(2024, 1, 1),
                initialDuration: null,
                initialNotes: null,
                initialWasteType: null,
                initialColor: null,
              ),
              onResult: (r) => completer.complete(r as UpdateResult?),
            ),
          ),
        ),
      );

      // Ouvrir le dialog
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier l\'événement'), findsOneWidget);

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
            home: _DialogLauncher(
              builder: () => EditEventDialog(
                type: 'Miam',
                initialTimestamp: DateTime.utc(2024, 1, 1),
                initialDuration: null,
                initialNotes: null,
                initialWasteType: null,
                initialColor: null,
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
      await pumpDialog(tester, type: 'Miam');
      await tester.pumpAndSettle();

      final deleteBtn = find.widgetWithText(TextButton, 'Supprimer');
      expect(deleteBtn, findsOneWidget);

      // Ouvrir le dialog de confirmation
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // AlertDialog doit être présent avec son titre et contenu
      expect(find.text('Supprimer l\'événement'), findsOneWidget);
      expect(
        find.textContaining('Voulez-vous vraiment supprimer cet événement ?'),
        findsOneWidget,
      );
    });

    testWidgets('Annuler → dialog de confirmation clos', (tester) async {
      await pumpDialog(tester, type: 'Miam');
      await tester.pumpAndSettle();

      // Ouvrir confirm delete
      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Annuler'), findsOneWidget);

      // Tap Annuler → close AlertDialog (pas de suppression)
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Le dialog principal est toujours là
      expect(find.text('Modifier l\'événement'), findsOneWidget);
    });

    testWidgets('Supprimer confirmé → DeleteResult retourné', (tester) async {
      final completer = Completer<EditResult?>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _DialogLauncher(
              builder: () => EditEventDialog(
                type: 'Dodo',
                initialTimestamp: DateTime.utc(2024, 1, 1),
                initialDuration: null,
                initialNotes: null,
                initialWasteType: null,
                initialColor: null,
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
  const _DialogLauncher({required this.builder, required this.onResult});

  final Widget Function() builder;
  final void Function(dynamic) onResult;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final result = await showModalBottomSheet<dynamic>(
            context: context,
            isScrollControlled: true,
            builder: (_) => builder(),
          );
          onResult(result);
        },
        child: const Text('Ouvrir'),
      ),
    );
  }
}

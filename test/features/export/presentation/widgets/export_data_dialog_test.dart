// ignore_for_file: lines_longer_than_80_chars
// Tests du dialogue d'export : l'avertissement de confidentialité doit passer
// AVANT toute action, et aucun détail technique interne ne doit s'afficher.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/export/domain/repositories/export_repository.dart';
import 'package:mamadera/features/export/presentation/providers/export_providers.dart';
import 'package:mamadera/features/export/presentation/widgets/export_data_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Contrôleur stub : renvoie un résultat décidé à l'avance. Ni partage réel,
/// ni disque, ni base — la feuille de partage ne s'ouvre jamais en test.
class _StubController extends ExportController {
  _StubController(this._outcome);

  final ExportOutcome _outcome;

  @override
  ExportOutcome build() => const ExportIdle();

  @override
  Future<ExportOutcome> shareExport() async => _outcome;
}

/// Contrôleur stub bloqué : permet d'observer l'état de chargement.
class _HangingController extends ExportController {
  final Completer<ExportOutcome> _completer = Completer<ExportOutcome>();

  @override
  ExportOutcome build() => const ExportIdle();

  @override
  Future<ExportOutcome> shareExport() => _completer.future;

  void finish(ExportOutcome outcome) => _completer.complete(outcome);
}

Future<_HangingController> _pumpHanging(
  WidgetTester tester,
) async {
  final controller = _HangingController();
  await _pumpDialog(tester, () => controller);
  return controller;
}

/// Le type `Override` n'est pas exposé par Riverpod 3 : on passe donc une
/// fabrique de contrôleur typée plutôt qu'une liste d'overrides.
Future<void> _pumpDialog(
  WidgetTester tester,
  ExportController Function() controllerFactory,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exportControllerProvider.overrideWith(controllerFactory),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const ExportDataDialog(),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('ouvrir'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

const _counts = ExportCounts(
  babyProfiles: 1,
  trackingEvents: 12,
  reminderSettings: 2,
  reminderDismissals: 1,
);

void main() {
  group('ExportDataDialog — consentement', () {
    testWidgets("l'avertissement de confidentialité s'affiche avant toute action", (tester) async {
      await _pumpDialog(
        tester,
        () => _StubController(const ExportIdle()),
      );

      expect(find.text('Exporter mes données'), findsOneWidget);
      expect(
        find.text('Ce fichier contiendra toutes vos données, y compris les notes de santé en texte lisible. Vous choisissez où l\'enregistrer : rien n\'est envoyé automatiquement.'),
        findsOneWidget,
      );
      expect(find.text('Exporter'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      // Tant que l'utilisateur n'a pas confirmé, rien n'a été exporté.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('annuler ferme sans exporter', (tester) async {
      await _pumpDialog(
        tester,
        () => _StubController(const ExportIdle()),
      );

      await tester.tap(find.text('Annuler'));
      // Deux pumps : le premier déclenche la frame qui initie le pop, le
      // second laisse la route se retirer réellement de l'arbre.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Exporter'), findsNothing);
    });
  });

  group('ExportDataDialog — résultats', () {
    testWidgets('succès : message localisé, aucun détail interne', (tester) async {
      await _pumpDialog(
        tester,
        () => _StubController(const ExportSuccess(counts: _counts)),
      );

      await tester.tap(find.text('Exporter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Export terminé'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('base vide : message vide, pas de panic', (tester) async {
      await _pumpDialog(
        tester,
        () => _StubController(const ExportNothingToExport()),
      );

      await tester.tap(find.text('Exporter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Aucune donnée à exporter'), findsOneWidget);
    });

    testWidgets('échec : message generic, jamais l\'exception brute', (tester) async {
      await _pumpDialog(
        tester,
        () => _StubController(
          const ExportFailure(
            message: "PathNotFoundException: Cannot open file, path = '/private/var/tmp/x'",
          ),
        ),
      );

      await tester.tap(find.text('Exporter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('L\'export a échoué'), findsOneWidget);
      // Un message d'exception non localisé trahirait des chemins internes à
      // l'écran, exactement ce que l'écran d'erreur du routeur évite déjà.
      expect(find.textContaining('PathNotFoundException'), findsNothing);
      expect(find.textContaining('/private/var'), findsNothing);
    });

    testWidgets('état de chargement pendant l\'export', (tester) async {
      final controller = await _pumpHanging(tester);

      await tester.tap(find.text('Exporter'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.finish(const ExportSuccess(counts: _counts));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Export terminé'), findsOneWidget);
    });
  });
}

// ignore_for_file: lines_longer_than_80_chars
// Export dialogue tests: the privacy warning must pass.
// Before taking any action, and no internal technical details should be displayed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/export/domain/repositories/export_repository.dart';
import 'package:mamadera/features/export/presentation/providers/export_providers.dart';
import 'package:mamadera/features/export/presentation/widgets/export_data_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Stub controller: returns a pre-determined result. No actual interaction.
/// Neither a disk nor a database — the sharing sheet never opens during testing.
class _StubController extends ExportController {
  _StubController(this._outcome);

  final ExportOutcome _outcome;

  @override
  ExportOutcome build() => const ExportIdle();

  @override
  Future<ExportOutcome> shareExport() async => _outcome;
}

/// Stub controller locked: allows you to monitor the charging status.
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

/// The `Override` type is not exposed by Riverpod 3; therefore, we pass a...
/// It's a controller factory that creates controllers based on types, rather than a list of overrides.
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
  customReminders: 0,
  reminderSettings: 2,
  reminderDismissals: 1,
  measurements: 0,
  reminderCompletions: 0,
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
      // Nothing will be exported until the user confirms.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('annuler ferme sans exporter', (tester) async {
      await _pumpDialog(
        tester,
        () => _StubController(const ExportIdle()),
      );

      await tester.tap(find.text('Annuler'));
      // Two pumps: the first triggers the mechanism that initiates the pop, while the...
      // Secondly, allow the road to gradually move away from the tree.
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
      // An exceptional, non-localized message would reveal internal pathways within...
      // the screen, which is exactly what the router's error message already prevents.
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

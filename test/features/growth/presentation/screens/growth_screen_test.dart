import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/growth/presentation/screens/growth_screen.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Notifier de test : liste fixe, sans dépendance à la base.
class _TestMeasurementNotifier extends MeasurementNotifier {
  _TestMeasurementNotifier(this.measurements);

  final List<GrowthMeasurement> measurements;

  @override
  Future<List<GrowthMeasurement>> build() async => measurements;
}

void main() {
  group('GrowthScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      List<GrowthMeasurement> measurements,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementNotifierProvider.overrideWith(
              () => _TestMeasurementNotifier(measurements),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.theme,
            home: const Scaffold(
              body: SafeArea(child: GrowthScreen()),
            ),
          ),
        ),
      );
    }

    testWidgets('shows the empty state when the baby has no measurements',
        (tester) async {
      await pumpScreen(tester, const []);
      await tester.pumpAndSettle();

      expect(find.text('Croissance'), findsOneWidget);
      expect(find.text("Aucune mesure pour l'instant."), findsOneWidget);
    });

    testWidgets('shows the three latest cards and the full history',
        (tester) async {
      await pumpScreen(
        tester,
        [
          GrowthMeasurement(
            id: 3,
            kind: MeasureKind.taille,
            unit: 'cm',
            value: 51.2,
            recordedAt: DateTime.utc(2025, 6, 3),
          ),
          GrowthMeasurement(
            id: 2,
            kind: MeasureKind.poids,
            unit: 'g',
            value: 3400,
            recordedAt: DateTime.utc(2025, 6, 2),
          ),
          GrowthMeasurement(
            id: 1,
            kind: MeasureKind.temperature,
            unit: 'degC',
            value: 36.5,
            recordedAt: DateTime.utc(2025, 6, 1),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Dernier poids'), findsOneWidget);
      expect(find.text('Dernière taille'), findsOneWidget);
      expect(find.text('Dernière température'), findsOneWidget);
      // Chaque valeur apparaît deux fois : carte « dernier » + ligne d'historique.
      expect(find.text('3,4 kg'), findsNWidgets(2));
      expect(find.text('51,2 cm'), findsNWidgets(2));
      expect(find.text('36,5 °C'), findsNWidgets(2));

      // L'historique porte la date formatée (jj/mm/aaaa hh:mm en fr).
      expect(find.text('03/06/2025 00:00'), findsOneWidget);
      expect(find.text('02/06/2025 00:00'), findsOneWidget);
      expect(find.text('01/06/2025 00:00'), findsOneWidget);
    });

    testWidgets('a missing kind leaves its latest card empty', (tester) async {
      await pumpScreen(
        tester,
        [
          GrowthMeasurement(
            id: 1,
            kind: MeasureKind.poids,
            unit: 'g',
            value: 3400,
            recordedAt: DateTime.utc(2025, 6, 2),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // Les deux cartes sans mesure affichent un tiret, pas un nombre.
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text("Aucune mesure pour l'instant."), findsNothing);
    });
  });
}

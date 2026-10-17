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

/// Test notification: fixed list, independent of the database.
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
      // Each value appears twice: once as the "last" card, and once in the history log.
      expect(find.text('3,4 kg'), findsNWidgets(2));
      expect(find.text('51,2 cm'), findsNWidgets(2));
      expect(find.text('36,5 °C'), findsNWidgets(2));

      // The date format displayed is (dd/mm/yyyy hh:mm).
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

      // The two cards without a measurement display a hyphen, not a number.
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text("Aucune mesure pour l'instant."), findsNothing);
    });

    testWidgets('a promoted kilogram value is never contradicted by a bare gram label',
        (tester) async {
      await pumpScreen(
        tester,
        [
          GrowthMeasurement(
            id: 1,
            kind: MeasureKind.poids,
            unit: 'g',
            value: 6180,
            recordedAt: DateTime.utc(2025, 6, 2),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('6,18 kg'), findsNWidgets(2));
      // The label displayed `displayUnit`," indicating the storage unit: "6.18 kg."
      // Above a "g," the text read "6.18 grams." The title states:
      // unit, the trailing label never repeats it.
      expect(find.text('g'), findsNothing);
    });

    testWidgets('english locale renders a full timestamp, minutes included',
        (tester) async {
      // The bug in the screenshot feature, version 1.2.0, only affected the `en` locale – a change to...
      // The French language would not prove anything about this ticket.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementNotifierProvider.overrideWith(
              () => _TestMeasurementNotifier([
                GrowthMeasurement(
                  id: 1,
                  kind: MeasureKind.temperature,
                  unit: 'degC',
                  value: 37.4,
                  // DateTime **local**: This formatting option displays the local time.
                  // Therefore, a UTC time would result in a time that depends on the time zone.
                  // de la machine de test.
                  recordedAt: DateTime(2026, 10, 8, 19, 43),
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: const [Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.theme,
            home: const Scaffold(body: SafeArea(child: GrowthScreen())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10/08/2026 07:43 PM'), findsOneWidget);
    });
  });
}

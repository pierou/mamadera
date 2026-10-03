import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/growth/presentation/widgets/measurement_button.dart';
import 'package:mamadera/features/growth/presentation/widgets/measurement_sheet.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Notifier de test : liste fixe, sans dépendance à la base.
class _TestMeasurementNotifier extends MeasurementNotifier {
  _TestMeasurementNotifier(this.measurements);

  final List<GrowthMeasurement> measurements;

  @override
  Future<List<GrowthMeasurement>> build() async => measurements;
}

void main() {
  group('MeasurementButtonRow', () {
    Future<void> pumpRow(
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
            home: const Scaffold(body: MeasurementButtonRow()),
          ),
        ),
      );
    }

    testWidgets('renders the three measurement buttons in order', (tester) async {
      await pumpRow(tester, const []);
      await tester.pumpAndSettle();

      expect(find.text('Poids'), findsOneWidget);
      expect(find.text('Taille'), findsOneWidget);
      expect(find.text('Température'), findsOneWidget);

      final buttons =
          tester.widgetList<MeasurementButton>(find.byType(MeasurementButton)).toList();
      expect(buttons.map((b) => b.kind).toList(), [
        MeasureKind.poids,
        MeasureKind.taille,
        MeasureKind.temperature,
      ]);
    });

    testWidgets('shows an em dash when the baby has no measurements', (tester) async {
      await pumpRow(tester, const []);
      await tester.pumpAndSettle();

      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('shows the latest value of each kind, formatted', (tester) async {
      // Contrat du notifier : liste triée du plus récent au plus ancien.
      await pumpRow(
        tester,
        [
          GrowthMeasurement(
            id: 3,
            kind: MeasureKind.poids,
            unit: 'g',
            value: 3200,
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

      // Premier élément du kind : 3200 g, pas 3400.
      expect(find.text('3,2 kg'), findsOneWidget);
      expect(find.text('36,5 °C'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('an undecryptable value is never shown as a number', (tester) async {
      await pumpRow(
        tester,
        [
          GrowthMeasurement(
            id: 1,
            kind: MeasureKind.taille,
            unit: 'cm',
            value: null,
            recordedAt: DateTime.utc(2025, 6, 1),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Valeur illisible'), findsOneWidget);
      expect(find.text('0 cm'), findsNothing);
    });

    testWidgets('tapping a button opens the measurement sheet for its kind',
        (tester) async {
      await pumpRow(tester, const []);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Taille'));
      await tester.pumpAndSettle();

      final sheet = tester.widget<MeasurementSheet>(find.byType(MeasurementSheet));
      expect(sheet.kind, MeasureKind.taille);
    });

    testWidgets('buttons never show an error style', (tester) async {
      await pumpRow(tester, const []);
      await tester.pumpAndSettle();

      // L'état de bouton est soit une valeur, soit un tiret — jamais une
      // chaîne d'erreur colorée.
      final texts = find.descendant(
        of: find.byType(MeasurementButton),
        matching: find.byType(Text),
      );
      expect(texts, findsNWidgets(6));
      expect(find.textContaining('erreur'), findsNothing);
    });
  });
}

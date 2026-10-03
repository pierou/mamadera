import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/domain/repositories/measurement_repository.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/growth/presentation/widgets/measurement_sheet.dart';
import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

/// Fake repo en mémoire : enregistre ce que la feuille lui envoie.
class _FakeMeasurementRepository implements MeasurementRepository {
  final List<GrowthMeasurement> stored = [];
  GrowthMeasurement? lastAdded;

  @override
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  }) async {
    if (!kind.contains(value)) {
      throw ArgumentError.value(value, 'value');
    }
    lastAdded = GrowthMeasurement(
      id: stored.length + 1,
      babyId: babyId,
      kind: kind,
      value: value,
      unit: kind.unit,
      recordedAt: recordedAt,
      notes: notes,
    );
    stored.insert(0, lastAdded!);
  }

  @override
  Future<GrowthMeasurement?> latestOfKind(String? babyId, MeasureKind kind) async {
    for (final m in stored) {
      if (m.kind == kind && m.babyId == babyId) return m;
    }
    return null;
  }

  @override
  Future<List<GrowthMeasurement>> allForBaby(String? babyId, {MeasureKind? kind}) async {
    return stored
        .where((m) => m.babyId == babyId && (kind == null || m.kind == kind))
        .toList();
  }
}

/// Notifier de test : liste fixe, sans dépendance à la base.
class _TestMeasurementNotifier extends MeasurementNotifier {
  _TestMeasurementNotifier(this.measurements);

  final List<GrowthMeasurement> measurements;

  @override
  Future<List<GrowthMeasurement>> build() async => measurements;
}

/// Bébé actif synchronise pour la feuille.
class _TestActiveBabyNotifier extends ActiveBabyNotifier {
  @override
  Future<BabyProfile?> build() {
    state = const AsyncValue.data(null);
    return Future.value(null);
  }
}

void main() {
  group('MeasurementSheet', () {
    late _FakeMeasurementRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeMeasurementRepository();
    });

    Future<void> pumpSheet(WidgetTester tester, MeasureKind kind) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => fakeRepo),
            measurementNotifierProvider.overrideWith(
              () => _TestMeasurementNotifier(const []),
            ),
            activeBabyProvider.overrideWith(_TestActiveBabyNotifier.new),
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
            home: Scaffold(body: MeasurementSheet(kind: kind)),
          ),
        ),
      );
    }

    Finder valueField() => find.descendant(
          of: find.byType(QuantityPickerInline),
          matching: find.byType(TextField),
        );

    Finder saveButton() => find.widgetWithText(ElevatedButton, 'Enregistrer');

    testWidgets('opens out of range: inline error shown and save disabled',
        (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      expect(find.text('Valeur hors plage : entre 200 et 20000 g.'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);
    });

    testWidgets('typed value in range clears the error and enables save',
        (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      await tester.enterText(valueField(), '3500');
      await tester.pumpAndSettle();

      expect(find.text('Valeur hors plage : entre 200 et 20000 g.'), findsNothing);
      expect(find.text('3500 g'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('save calls the repository with the picked value and no note',
        (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      await tester.enterText(valueField(), '3500');
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(fakeRepo.lastAdded, isNotNull);
      expect(fakeRepo.lastAdded!.value, 3500);
      expect(fakeRepo.lastAdded!.kind, MeasureKind.poids);
      expect(fakeRepo.lastAdded!.unit, 'g');
      expect(fakeRepo.lastAdded!.notes, isNull);
      // La feuille est fermée après enregistrement.
      expect(find.byType(MeasurementSheet), findsNothing);
    });

    testWidgets('a typed note is saved, an empty one is not', (tester) async {
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      await tester.enterText(valueField(), '36.5');
      await tester.pumpAndSettle();

      final noteField = find.descendant(
        of: find.byType(MeasurementSheet),
        matching: find.byType(TextField),
      ).last;
      await tester.enterText(noteField, 'sous le bras');
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(fakeRepo.lastAdded!.value, 36.5);
      expect(fakeRepo.lastAdded!.notes, 'sous le bras');
    });

    testWidgets('cancel closes the sheet without saving', (tester) async {
      await pumpSheet(tester, MeasureKind.taille);
      await tester.pumpAndSettle();

      await tester.enterText(valueField(), '50');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();

      expect(fakeRepo.stored, isEmpty);
      expect(find.byType(MeasurementSheet), findsNothing);
    });

    testWidgets(
        'temperature: the tenth of degree survives the whole path — typed '
        '37,4 is stored as 37.4, not rounded to 37 or 37,5', (tester) async {
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      // Le slider offre un cran par dixième : 90 crans sur la plage.
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 90);
      expect(slider.max - slider.min, 9);

      await tester.enterText(valueField(), '37,4');
      await tester.pumpAndSettle();

      // Trois endroits où un arrondi pourrait se glisser : l'affichage, la
      // valeur transmise, et ce que le repository reçoit.
      expect(find.text('37,4 °C'), findsWidgets);

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(fakeRepo.lastAdded!.value, 37.4,
          reason: 'la valeur doit traverser la feuille intacte : stocker 37,5 '
              'ou 37 serait une mesure fausse au dixième près');
      expect(fakeRepo.lastAdded!.unit, 'degC');
    });

    testWidgets('weight stepper: + moves by 10 g', (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      await tester.enterText(valueField(), '3500');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('3510 g'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('3500 g'), findsOneWidget);
    });

    testWidgets('titles follow the kind', (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();
      expect(find.text('Nouveau poids'), findsOneWidget);

      await pumpSheet(tester, MeasureKind.taille);
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle taille'), findsOneWidget);

      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle température'), findsOneWidget);
    });
  });
}

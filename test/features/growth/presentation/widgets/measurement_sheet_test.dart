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

/// In-memory fake repository: This stores the data that the sheet sends to it.
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
  Future<GrowthMeasurement?> latestOfKind(
      String? babyId, MeasureKind kind) async {
    for (final m in stored) {
      if (m.kind == kind && m.babyId == babyId) return m;
    }
    return null;
  }

  @override
  Future<List<GrowthMeasurement>> allForBaby(String? babyId,
      {MeasureKind? kind}) async {
    return stored
        .where((m) => m.babyId == babyId && (kind == null || m.kind == kind))
        .toList();
  }

  @override
  Future<void> update(GrowthMeasurement measurement) async {
    final value = measurement.value;
    if (value == null || !measurement.kind.contains(value)) {
      throw ArgumentError.value(value, 'value');
    }
    final index = stored.indexWhere((m) => m.id == measurement.id);
    if (index == -1) return;
    stored[index] = measurement;
  }

  @override
  Future<bool> deleteById(int id) async {
    final index = stored.indexWhere((m) => m.id == id);
    if (index == -1) return false;
    stored.removeAt(index);
    return true;
  }
}

/// Test notification: fixed list, independent of the database.
class _TestMeasurementNotifier extends MeasurementNotifier {
  _TestMeasurementNotifier(this.measurements);

  final List<GrowthMeasurement> measurements;

  @override
  Future<List<GrowthMeasurement>> build() async => measurements;
}

/// Baby Active synchronizes with the sheet.
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

    Future<void> pumpSheet(
      WidgetTester tester,
      MeasureKind kind, {
      String locale = 'fr',
    }) async {
      // The sheet unfolds as a bottom sheet on a phone: the view of...
      // The test is designed to fit the dimensions of a modern smartphone (412x915 dp).
      // not at the default 800x600 resolution, which was never its intended target size.
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider.overrideWith((ref) async => fakeRepo),
            measurementNotifierProvider.overrideWith(
              () => _TestMeasurementNotifier(const []),
            ),
            activeBabyProvider.overrideWith(_TestActiveBabyNotifier.new),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            supportedLocales: [Locale(locale)],
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

    testWidgets(
        'temperature opens with an empty field, the default as hint, and a '
        'disabled save', (tester) async {
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      // The field is left blank: a pre-filled value would be considered a measurement.
      // It was invented. The display shows the reference number of the type.
      expect(tester.widget<TextField>(valueField()).controller!.text, isEmpty);
      expect(find.text('37,0 °C'), findsOneWidget);
      expect(
        find.text('Valeur hors plage : entre 33 et 42 °C.'),
        findsNothing,
      );
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);
    });

    testWidgets(
        'weight opens with an empty field, the default as hint, and a '
        'disabled save', (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      // For weights exceeding 1000 grams, the display shows the weight in kilograms: the additional weight is "3.5 kg."
      expect(find.text('3,5 kg'), findsOneWidget);
      expect(
        find.text('Valeur hors plage : entre 200 et 20000 g.'),
        findsNothing,
      );
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);
    });

    testWidgets(
        'height opens with an empty field, the default as hint, and a '
        'disabled save', (tester) async {
      await pumpSheet(tester, MeasureKind.taille);
      await tester.pumpAndSettle();

      expect(find.text('50,0 cm'), findsOneWidget);
      expect(
        find.text('Valeur hors plage : entre 30 et 110 cm.'),
        findsNothing,
      );
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);
    });

    testWidgets('cancelling a freshly opened sheet stores nothing',
        (tester) async {
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();

      expect(fakeRepo.stored, isEmpty);
      expect(fakeRepo.lastAdded, isNull);
    });

    testWidgets('typed value in range clears the error and enables save',
        (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      await tester.enterText(valueField(), '3500');
      await tester.pumpAndSettle();

      expect(
          find.text('Valeur hors plage : entre 200 et 20000 g.'), findsNothing);
      expect(find.text('3500 g'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets(
        'weight: out-of-range input shows the range error and disables save, '
        'back in range clears it', (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      // 99999 g is not a valid weight for a newborn; the entered number will remain.
      // Displayed as is (never clipped), the sheet reveals its error.
      // existing, and the backup feature is disabled.
      await tester.enterText(valueField(), '99999');
      await tester.pumpAndSettle();

      expect(find.text('99999 g'), findsOneWidget);
      expect(
        find.text('Valeur hors plage : entre 200 et 20000 g.'),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);

      // Back in the safe zone: the error is resolved, and the backup system is reactivated.
      await tester.enterText(valueField(), '3500');
      await tester.pumpAndSettle();

      expect(
        find.text('Valeur hors plage : entre 200 et 20000 g.'),
        findsNothing,
      );
      expect(find.text('3500 g'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets(
        'temperature: out-of-range input shows the range error and disables '
        'save, back in range clears it', (tester) async {
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      // 45°C is above the maximum: the same principle applies as with weight.
      await tester.enterText(valueField(), '45');
      await tester.pumpAndSettle();

      expect(find.text('45,0 °C'), findsOneWidget);
      expect(
        find.text('Valeur hors plage : entre 33 et 42 °C.'),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);

      await tester.enterText(valueField(), '37,4');
      await tester.pumpAndSettle();

      expect(
        find.text('Valeur hors plage : entre 33 et 42 °C.'),
        findsNothing,
      );
      expect(find.text('37,4 °C'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNotNull);
    });

    // The comma is used as the decimal separator for the French locale (fr), but the application still functions.
    // In all three locations, the value "37.4" must be parsed without any range errors.
    // everywhere. The field retains the entered text, and the wider display is formatted.
    // in the usual location.
    for (final (tag, display) in const [
      ('en', '37.4 °C'),
      ('fr', '37,4 °C'),
      ('es', '37,4 °C'),
    ]) {
      testWidgets(
          'temperature: comma decimal 37,4 parses and shows $display in $tag',
          (tester) async {
        await pumpSheet(tester, MeasureKind.temperature, locale: tag);
        await tester.pumpAndSettle();

        await tester.enterText(valueField(), '37,4');
        await tester.pumpAndSettle();

        expect(find.text(display), findsOneWidget);
        // The only elevated button on the sheet is the "Save" button: its value.
        // While she's on vacation, she needs to stay active.
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull,
        );
      });
    }

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
      // The sheet is closed after saving.
      expect(find.byType(MeasurementSheet), findsNothing);
    });

    testWidgets('a typed note is saved, an empty one is not', (tester) async {
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      await tester.enterText(valueField(), '36.5');
      await tester.pumpAndSettle();

      final noteField = find
          .descendant(
            of: find.byType(MeasurementSheet),
            matching: find.byType(TextField),
          )
          .last;
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
    });

    testWidgets(
        'temperature: the tenth of degree survives the whole path — typed '
        '37,4 is stored as 37.4, not rounded to 37 or 37,5', (tester) async {
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      // A single slider, covering the entire range of 33–42 °C with a step of 0.1: the...
      // The precision to the tenth of a unit comes from the input field and the +/- stepper, not from something else.
      // of a second cursor (removed - docs/BACKLOG.md B2).
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 33);
      expect(slider.max, 42);
      expect(slider.divisions, 90);

      await tester.enterText(valueField(), '37,4');
      await tester.pumpAndSettle();

      // Here are three places where a rounding error might occur: the display, the...
      // the value that is passed, and what the repository receives.
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

    // ---- Settings v1.2.1 — Reported issues on the device (2026-10-13) ----
    //
    // The header displays "Last: 4.2 kg" as soon as it opens, but the slider...
    // and the ± buttons were used to adjust the settings based on the reference values (3.5 kg / 37 °C):
    // The initial contact therefore caused the value to jump to a number that no one...
    // has been measured. The target must be precisely where it is intended to be — without ever...
    // Pre-populate the field: a cursor position is not considered input.

    testWidgets(
        'weight: with a prior measurement, the slider and the steppers start on '
        'that measurement, not on the 3,5 kg type default', (tester) async {
      fakeRepo.stored.add(
        GrowthMeasurement(
          id: 1,
          kind: MeasureKind.poids,
          unit: 'g',
          value: 4200,
          recordedAt: DateTime(2026, 10, 1),
        ),
      );
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      // The indicator clearly shows the latest measurement...
      expect(find.text('Dernière : 4,2 kg'), findsOneWidget);
      // ...and that's precisely the one the cursor is targeting.
      expect(tester.widget<Slider>(find.byType(Slider)).value, 4200);

      // The "no invented value" clause holds: empty field and...
      // The save function is disabled as long as the parent hasn't entered any information.
      expect(tester.widget<TextField>(valueField()).controller!.text, isEmpty);
      expect(tester.widget<ElevatedButton>(saveButton()).onPressed, isNull);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('4210 g'), findsOneWidget);
      expect(find.text('3510 g'), findsNothing);
    });

    testWidgets(
        'temperature: + from the last measurement gives 36,9 °C — the tenth '
        'above it — and never 37,1 °C off the type default', (tester) async {
      fakeRepo.stored.add(
        GrowthMeasurement(
          id: 1,
          kind: MeasureKind.temperature,
          unit: 'degC',
          value: 36.8,
          recordedAt: DateTime(2026, 10, 1),
        ),
      );
      await pumpSheet(tester, MeasureKind.temperature);
      await tester.pumpAndSettle();

      expect(find.text('Dernière : 36,8 °C'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 36.8);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('36,9 °C'), findsOneWidget);
      expect(find.text('37,1 °C'), findsNothing);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('36,8 °C'), findsOneWidget);

      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(fakeRepo.lastAdded!.value, 36.8);
    });

    testWidgets('a prior measurement of another kind never moves the cursor',
        (tester) async {
      fakeRepo.stored.add(
        GrowthMeasurement(
          id: 1,
          kind: MeasureKind.temperature,
          unit: 'degC',
          value: 36.8,
          recordedAt: DateTime(2026, 10, 1),
        ),
      );
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      // No weight measurements are taken; the reference type serves as the starting point.
      expect(tester.widget<Slider>(find.byType(Slider)).value, 3500);
      expect(find.text('3,5 kg'), findsOneWidget);
    });

    testWidgets(
        'saving reloads measurementNotifierProvider so home shows the new value '
        'without leaving the screen', (tester) async {
      await pumpSheet(tester, MeasureKind.poids);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MeasurementSheet)),
        listen: false,
      );
      await container.read(measurementNotifierProvider.future);
      expect(container.read(measurementNotifierProvider).value, isEmpty);

      await tester.enterText(valueField(), '4300');
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      // The welcome message displayed should indicate: "No automatic saving."
      // It would remain displayed on the previous setting until a new baby was registered.
      final values = container.read(measurementNotifierProvider).value;
      expect(values, hasLength(1));
      expect(values!.single.value, 4300);
      expect(fakeRepo.lastAdded!.value, 4300);
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

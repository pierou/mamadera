import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/presentation/widgets/edit_measurement_sheet.dart';
import 'package:mamadera/features/home/presentation/widgets/quantity_picker_inline.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Hôte minimal : `showModalBottomSheet` a besoin d'un Navigator, et le
/// résultat du pop est capturé ici pour être vérifié tel quel.
class _Host extends StatelessWidget {
  const _Host({required this.measurement, required this.onResult});

  final GrowthMeasurement measurement;
  final void Function(MeasurementEditResult?) onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.theme,
      home: Scaffold(
        body: Center(
          // `Builder` : le contexte de `build` de `_Host` est **au-dessus** du
          // MaterialApp qu'il crée — `showModalBottomSheet` y échoue sans
          // MaterialLocalizations. Il faut un contexte descendu sous la route.
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await EditMeasurementSheet.show(
                  context,
                  measurement: measurement,
                );
                if (result != null) onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}

GrowthMeasurement _weight({
  double? value = 4200,
  String? notes,
  DateTime? recordedAt,
}) {
  return GrowthMeasurement(
    id: 7,
    kind: MeasureKind.poids,
    unit: 'g',
    value: value,
    notes: notes,
    recordedAt: recordedAt ?? DateTime(2026, 10, 12, 8),
  );
}

void main() {
  Future<void> openSheet(
    WidgetTester tester,
    GrowthMeasurement measurement, {
    Size size = const Size(412, 915),
    void Function(MeasurementEditResult?)? onResult,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _Host(measurement: measurement, onResult: onResult ?? (_) {}),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder valueField() => find.descendant(
        of: find.byType(QuantityPickerInline),
        matching: find.byType(TextField),
      );

  Finder noteField() => find
      .descendant(
        of: find.byType(EditMeasurementSheet),
        matching: find.byType(TextField),
      )
      .last;

  Finder saveButton() => find.widgetWithText(FilledButton, 'Enregistrer');

  group('EditMeasurementSheet', () {
    testWidgets('opens prefilled with the stored value and an active save',
        (tester) async {
      await openSheet(tester, _weight());

      expect(tester.widget<TextField>(valueField()).controller!.text, '4200');
      expect(find.text('4200 g'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 4200);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets(
        'the steppers move from the stored value, never from the default',
        (tester) async {
      await openSheet(tester, _weight());

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('4210 g'), findsOneWidget);
      expect(find.text('3510 g'), findsNothing);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('4200 g'), findsOneWidget);
    });

    testWidgets(
        'a corrected value pops a MeasurementUpdated with the id intact',
        (tester) async {
      MeasurementEditResult? result;
      await openSheet(tester, _weight(), onResult: (r) => result = r);

      await tester.enterText(valueField(), '4150');
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(result, isA<MeasurementUpdated>());
      final updated = (result as MeasurementUpdated).measurement;
      expect(updated.id, 7);
      expect(updated.kind, MeasureKind.poids);
      expect(updated.unit, 'g');
      expect(updated.value, 4150);
    });

    testWidgets(
        'notes round-trip: existing note prefilled, blanked note saved as null',
        (tester) async {
      MeasurementEditResult? result;
      await openSheet(tester, _weight(notes: 'après le bain'),
          onResult: (r) => result = r);

      expect(tester.widget<TextField>(noteField()).controller!.text,
          'après le bain');

      await tester.enterText(noteField(), '   ');
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect((result as MeasurementUpdated).measurement.notes, isNull);
    });

    testWidgets(
        'out of range keeps the typed number, shows the error and blocks save',
        (tester) async {
      await openSheet(tester, _weight());

      await tester.enterText(valueField(), '99999');
      await tester.pumpAndSettle();

      expect(find.text('99999 g'), findsOneWidget);
      expect(
        find.text('Valeur hors plage : entre 200 et 20000 g.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await tester.enterText(valueField(), '4100');
      await tester.pumpAndSettle();
      expect(
          find.text('Valeur hors plage : entre 200 et 20000 g.'), findsNothing);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('deleting pops MeasurementDeleted with the row id',
        (tester) async {
      MeasurementEditResult? result;
      await openSheet(tester, _weight(), onResult: (r) => result = r);

      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(result, isA<MeasurementDeleted>());
      expect((result as MeasurementDeleted).id, 7);
    });

    testWidgets('an undecryptable value opens on the kind reference, not blank',
        (tester) async {
      await openSheet(tester, _weight(value: null));

      // Édition d'en-tête : la référence du type est un point de départ
      // éditable, jamais une mesure affirmée — le champ est pré-rempli pour
      // que le parent n'ait qu'à corriger.
      expect(tester.widget<TextField>(valueField()).controller!.text, '3500');
      expect(find.text('Modifier le poids'), findsOneWidget);
    });

    // Un overflow horizontal est invisible dans un test de widget qui agrandit
    // son propre viewport ; il ne l'est pas sur un téléphone. Vérifié ici à la
    // largeur la plus étroite visée par la gate de release.
    testWidgets('the action row and the sheet fit a 320 dp screen',
        (tester) async {
      await openSheet(tester, _weight(), size: const Size(320, 653));

      expect(tester.takeException(), isNull);

      final save = find.widgetWithText(FilledButton, 'Enregistrer');
      expect(save, findsOneWidget);
      expect(tester.getRect(save).right, lessThanOrEqualTo(320));
      expect(tester.getRect(find.byIcon(Icons.delete_outline)).left,
          greaterThanOrEqualTo(0));
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    });
  });
}

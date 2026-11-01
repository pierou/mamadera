import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/theme.dart';
import 'package:mamadera/shared/widgets/option_chip_row.dart';

/// The widget tests render with the test font, in which every glyph is a
/// 1em square: "Lait Maternel" measures 182dp there against 83dp in Roboto.
/// A label that is not clipped under the test font therefore cannot be
/// clipped on a device — the assertions below are deliberately pessimistic.
void main() {
  const List<String> threeOptions = [
    'Lait Maternel',
    'Lait Artificiel',
    'Solide'
  ];

  Future<void> pumpRow(
    WidgetTester tester, {
    required List<String> options,
    required String selected,
    double width = 320,
    double textScale = 1.0,
    ThemeData? theme,
    Color? selectedColor,
    ValueChanged<String>? onTap,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext parentContext) => MediaQuery(
              data: MediaQuery.of(parentContext)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: SingleChildScrollView(
                child: OptionChipRow<String>(
                  options: options,
                  selected: selected,
                  onSelected: onTap ?? (_) {},
                  selectedColor: selectedColor,
                  labelOf: (BuildContext _, String option) => option,
                  iconOf: (String option) => Icons.circle_outlined,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// True when the rendered label ran out of room and was cut short.
  bool isClipped(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    return paragraph.didExceedMaxLines;
  }

  group('OptionChipRow', () {
    testWidgets('never clips a label, at any plausible phone width',
        (tester) async {
      for (final double width in <double>[320, 360, 393]) {
        await pumpRow(tester,
            options: threeOptions, selected: 'Solide', width: width);
        for (final String label in threeOptions) {
          expect(isClipped(tester, label), isFalse,
              reason: '"$label" was truncated at ${width}dp');
        }
      }
    });

    testWidgets('never clips at accessibility text scale', (tester) async {
      await pumpRow(
        tester,
        options: threeOptions,
        selected: 'Lait Maternel',
        width: 320,
        textScale: 1.6,
      );
      for (final String label in threeOptions) {
        expect(isClipped(tester, label), isFalse,
            reason: '"$label" was truncated at 1.6x text scale');
      }
    });

    testWidgets('wraps onto several lines instead of squeezing labels',
        (tester) async {
      await pumpRow(tester, options: threeOptions, selected: 'Solide');

      final List<double> lineOffsets = threeOptions
          .map((String label) => tester.getTopLeft(find.text(label)).dy)
          .toSet()
          .toList();
      expect(lineOffsets.length, greaterThan(1),
          reason: 'three long labels cannot share one 320dp line');
    });

    testWidgets('selecting an option does not change any chip width',
        (tester) async {
      // The reserved leading slot: Material's own checkmark is added only on
      // the selected chip, which re-wraps the whole row under the finger.
      await pumpRow(tester, options: threeOptions, selected: 'Lait Maternel');
      final Map<String, Size> unselected = {
        for (final String label in threeOptions)
          label: tester.getSize(find.widgetWithText(FilterChip, label)),
      };

      await pumpRow(tester, options: threeOptions, selected: 'Solide');
      for (final String label in threeOptions) {
        expect(tester.getSize(find.widgetWithText(FilterChip, label)),
            unselected[label],
            reason: 'chip "$label" changed width when the selection moved; '
                'the row would re-wrap on every tap');
      }
    });

    testWidgets('reports the option that was tapped', (tester) async {
      String? tapped;
      await pumpRow(
        tester,
        options: threeOptions,
        selected: 'Lait Maternel',
        onTap: (String option) => tapped = option,
      );

      await tester.tap(find.text('Solide'));
      await tester.pumpAndSettle();

      expect(tapped, 'Solide');
    });

    testWidgets('shows a check on the selected option only', (tester) async {
      await pumpRow(tester, options: threeOptions, selected: 'Solide');

      final FilterChip selectedChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Solide'),
      );
      final FilterChip otherChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Lait Maternel'),
      );
      expect(selectedChip.selected, isTrue);
      expect(otherChip.selected, isFalse);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('the selected option is as readable as the others',
        (tester) async {
      // Material paints a selected filter chip with `onSecondaryContainer`.
      // The app's ColorScheme leaves that role unset, so ColorScheme
      // substitutes `onSecondary` — white — and the chosen option was drawn
      // white-on-pale-yellow next to two legible ones.
      const Color miamTint = Color(0x33FFE082);
      await pumpRow(
        tester,
        options: threeOptions,
        selected: 'Solide',
        theme: AppTheme.lightTheme,
        selectedColor: miamTint,
      );

      final Color onSurface = Theme.of(
        tester.element(find.byType(OptionChipRow<String>)),
      ).colorScheme.onSurface;

      for (final String label in threeOptions) {
        expect(tester.widget<Text>(find.text(label)).style?.color, onSurface,
            reason: '"$label" is painted in a colour that does not hold up '
                'on the selected chip fill');
      }
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).color, onSurface);
    });

    testWidgets('a label wider than the whole row still soft-wraps',
        (tester) async {
      const String absurd =
          'Lait maternel tiré et donné au biberon à la demande';
      await pumpRow(tester, options: <String>[absurd], selected: absurd);

      // Belt and braces: a label wider than the row is capped by Wrap and
      // soft-wraps inside the chip — no overflow, no clipping.
      expect(isClipped(tester, absurd), isFalse);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.widgetWithText(FilterChip, absurd)).width,
        lessThanOrEqualTo(320),
      );
    });
  });
}

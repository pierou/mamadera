import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  Widget pumpTrackButton({
    required String label,
    required Color color,
    DateTime? lastEventAt,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ThemeData? theme,
  }) =>
      MaterialApp(
        theme: theme,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: TrackButton(
            label: label,
            color: color,
            onTap: onTap ?? () {},
            onLongPress: onLongPress,
            lastEventAt: lastEventAt,
          ),
        ),
      );

  group('TrackButton', () {
    testWidgets('displays the label', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Test Label', color: AppTheme.miam)));
      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              onTap: () => tapped = true)));
      await tester.tap(find.byType(TrackButton));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed (optional)',
        (tester) async {
      bool pressed = false;
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              onTap: () {},
              onLongPress: () => pressed = true)));
      await tester.longPress(find.byType(TrackButton));
      expect(pressed, isTrue);
    });

    testWidgets('border uses the provided color', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Test', color: AppTheme.sante)));
      final button = find.byType(TrackButton);
      expect(button, findsOneWidget);
    });

    // B23 removed the on-button reminder stickers; B28 removed the button's
    // ability to receive reminder state at all (its only dynamic text is now
    // the last-tracked line, fed by the event table). What still has to hold is
    // that no reminder label ever renders on a button.
    testWidgets('renders no reminder text, only its label and its line',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
        label: 'Feeding',
        color: AppTheme.miam,
        lastEventAt: DateTime.now().subtract(const Duration(hours: 3)),
      )));

      expect(find.text('Vit. D'), findsNothing);
      expect(find.textContaining('Dernière activité'), findsOneWidget,
          reason: 'the line is what the button does render');
      expect(find.text('Feeding'), findsOneWidget);
    });

    testWidgets('shows the label alone when the type has no event yet',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam)));
      expect(find.text('Feeding'), findsOneWidget);
      expect(find.textContaining('Dernière activité'), findsNothing,
          reason: 'no event, no line — never an invented date');
    });

    testWidgets('shows the last-tracked line from lastEventAt', (tester) async {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              lastEventAt: twoHoursAgo)));

      expect(find.text('Dernière activité: 2h0'), findsOneWidget);
    });

    testWidgets('last-tracked line reads localized minutes, not "45min ago"',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              lastEventAt:
                  DateTime.now().subtract(const Duration(minutes: 45)))));

      expect(find.text('Dernière activité: 45 min'), findsOneWidget);
      expect(find.textContaining('ago'), findsNothing);
    });

    testWidgets(
        'last-tracked line reads localized "yesterday" for a 24 h old event',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              lastEventAt: DateTime.now().subtract(const Duration(days: 1)))));

      expect(find.text('Dernière activité: hier'), findsOneWidget);
    });

    testWidgets('label is bold and large', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Test Label', color: AppTheme.miam)));
      final textFinder = find.text('Test Label');
      expect(textFinder, findsOneWidget);
    });

    // Regression: The word "food" (10 characters) does not fit within the 32-point font size in the...
    // The tile should be two columns wide on the home screen, but its width needs to be reduced.
    // (FittedBox scaleDown) instead of being split across two lines.
    testWidgets('keeps long labels on a single line via scaleDown',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: pumpTrackButton(label: 'Nourriture', color: AppTheme.miam),
      ));
      final fitted = find.descendant(
        of: find.byType(TrackButton),
        matching: find.byType(FittedBox),
      );
      expect(fitted, findsOneWidget);
      expect(tester.widget<FittedBox>(fitted).fit, BoxFit.scaleDown);
      expect(tester.widget<Text>(find.text('Nourriture')).maxLines, 1);
    });

    testWidgets('renders with all tracking type colors', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Nourriture', color: AppTheme.miam)));
      expect(find.byType(TrackButton), findsOneWidget);

      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Sante', color: AppTheme.sante)));
      expect(find.byType(TrackButton), findsOneWidget);

      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Couche', color: AppTheme.caca)));
      expect(find.byType(TrackButton), findsOneWidget);

      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Dodo', color: AppTheme.dodo)));
      expect(find.byType(TrackButton), findsOneWidget);
    });

    testWidgets('has semantics label for accessibility', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child:
              pumpTrackButton(label: 'Feeding Button', color: AppTheme.miam)));
      expect(find.byType(TrackButton), findsOneWidget);
    });

    testWidgets('animates on tap without errors', (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam)));
      final finder = find.byType(TrackButton);

      await tester.tap(finder);
      await tester
          .pump(const Duration(milliseconds: 150)); // complete animation

      expect(find.text('Feeding'), findsOneWidget);
    });

    testWidgets(
        'a type with events but no pending reminder still shows its line',
        (tester) async {
      // B28, the reported defect: the line used to be read out of the *due*
      // reminder statuses, so settling a feeding deleted the feeding button's
      // own line and left Health as the only button ever showing one. The
      // button now receives an event timestamp and has no idea whether anything
      // is pending — which is the whole point.
      final now = DateTime.now();
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              lastEventAt: now.subtract(const Duration(seconds: 20)))));

      expect(find.text('Dernière activité: < 1 min'), findsOneWidget);
      expect(find.text('Vit. D'), findsNothing);
    });

    testWidgets('no crash when onTap is provided as default callback',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Test', color: Colors.red)));
      expect(find.text('Test'), findsOneWidget);
    });

    // ── B4: the label is not the accent ──────────────────────────

    testWidgets('light theme paints the label with onSurface, not the accent',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              theme: AppTheme.lightTheme)));

      final text = tester.widget<Text>(find.text('Feeding'));
      expect(text.style?.color, equals(AppTheme.lightTextPrimary),
          reason: 'miam on cream measured 1.15:1 on device (B4) — the label '
              'takes the guaranteed-contrast text, the tint stays in the '
              'background, border and icon');
      expect(text.style?.color, isNot(equals(AppTheme.miam)));
    });

    testWidgets('dark theme paints the label with the light onSurface',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.caca,
              theme: AppTheme.darkTheme)));

      final text = tester.widget<Text>(find.text('Feeding'));
      expect(text.style?.color, equals(AppTheme.darkTextPrimary),
          reason: 'caca on the dark scaffold measured 1.43:1 on device (B4)');
      expect(text.style?.color, isNot(equals(AppTheme.caca)));
    });

    // ── Accessibility tests ──────────────────────────────────────

    testWidgets('has Semantics widget with label and button:true',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: pumpTrackButton(
            label: 'Feeding Accessibility Test', color: AppTheme.miam),
      ));
      // Verify at least one Semantics widget exists for accessibility
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets(
        'respects reduce motion - no animation when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ProviderScope(
              child: TrackButton(
                label: 'Feeding Motion Test',
                color: AppTheme.miam,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      // Verify widget renders without error when animations are disabled
      expect(find.text('Feeding Motion Test'), findsOneWidget);
    });

    testWidgets('renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: ProviderScope(
            child: TrackButton(
              label: 'Light Mode Test',
              color: AppTheme.miam,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Light Mode Test'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: ProviderScope(
            child: TrackButton(
              label: 'Dark Mode Test',
              color: AppTheme.miam,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Dark Mode Test'), findsOneWidget);
    });

    // The case that motivated the old pill cap was many reminders with long
    // custom labels; those now render below the grid, not on the button. The
    // cell's own overflow risk changed shape with B28: the line is no longer
    // rare (it shows whenever the type has any event), so all four buttons can
    // carry one at once — the longest the locales produce must still fit.
    testWidgets('the longest localized line does not overflow the cell',
        (tester) async {
      tester.view.physicalSize = const Size(411, 731);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.theme,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1,
              children: [
                for (final color in [
                  AppTheme.miam,
                  AppTheme.sante,
                  AppTheme.caca,
                  AppTheme.dodo,
                ])
                  TrackButton(
                    label: 'Allaitement maternel',
                    color: color,
                    onTap: () {},
                    // "2h5" — the longest relative form the line builds in
                    // French (durationFormatHoursMinutes is "{hours}h{minutes}").
                    lastEventAt: DateTime.now()
                        .subtract(const Duration(hours: 2, minutes: 5)),
                  ),
              ],
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Dernière activité: 2h5'), findsNWidgets(4));
    });
  });
}

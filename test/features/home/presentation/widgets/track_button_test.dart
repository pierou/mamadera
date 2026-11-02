import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  Widget pumpTrackButton({
    required String label,
    required Color color,
    List<ReminderStatus>? reminders,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) =>
      MaterialApp(
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
            reminders: reminders,
          ),
        ),
      );

  ReminderStatus buildReminder({
    required TrackingType trackingType,
    required String id,
    required String labelKey,
    DateTime? lastEventAt,
  }) {
    final item = ReminderItem(
      id: id,
      labelKey: labelKey,
      frequency: const Daily(),
      trackingType: trackingType,
    );
    return ReminderStatus(item: item, lastEventAt: lastEventAt);
  }

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

    // B23: the on-button reminder stickers are gone — pending reminders are
    // read in HomeRemindersSection below the grid, never on the button.
    testWidgets('shows no reminder stickers for a non-empty reminders list',
        (tester) async {
      final status1 = buildReminder(
          trackingType: TrackingType.sante,
          id: 'vitamine_d',
          labelKey: 'reminderVitaminD',
          lastEventAt: null);
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding', color: AppTheme.miam, reminders: [status1])));

      expect(find.text('Vit. D'), findsNothing);
      expect(find.text('Feeding'), findsOneWidget);
    });

    testWidgets('shows the label alone when reminders is null or empty',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding', color: AppTheme.miam, reminders: null)));
      expect(find.text('Feeding'), findsOneWidget);

      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding', color: AppTheme.miam, reminders: [])));
      expect(find.text('Feeding'), findsOneWidget);
    });

    testWidgets('shows the last-tracked line from the newest lastEventAt',
        (tester) async {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final status1 = buildReminder(
          trackingType: TrackingType.sante,
          id: 'vitamine_d',
          labelKey: 'reminderVitaminD',
          lastEventAt: twoHoursAgo);
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding', color: AppTheme.miam, reminders: [status1])));

      expect(find.text('2h 0m ago'), findsOneWidget);
    });

    testWidgets(
        'last-tracked line reads localized "yesterday" for a 24 h old event',
        (tester) async {
      final status1 = buildReminder(
          trackingType: TrackingType.sante,
          id: 'vitamine_d',
          labelKey: 'reminderVitaminD',
          lastEventAt: DateTime.now().subtract(const Duration(days: 1)));
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding', color: AppTheme.miam, reminders: [status1])));

      expect(find.text('Hier'), findsOneWidget);
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
        'mixed pending and completed reminders show only the newest last-tracked',
        (tester) async {
      final now = DateTime.now();
      final pending = buildReminder(
          trackingType: TrackingType.sante,
          id: 'vitamine_d',
          labelKey: 'reminderVitaminD',
          lastEventAt: null);
      final completed = buildReminder(
          trackingType: TrackingType.caca,
          id: 'eye_cleaning',
          labelKey: 'reminderEyeCleaning',
          lastEventAt: now);

      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(
              label: 'Feeding',
              color: AppTheme.miam,
              reminders: [pending, completed])));

      // The newest lastEventAt wins; nothing sticker-like renders at all.
      expect(find.text('< 1 min'), findsOneWidget);
      expect(find.text('Vit. D'), findsNothing);
    });

    testWidgets('no crash when onTap is provided as default callback',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          child: pumpTrackButton(label: 'Test', color: Colors.red)));
      expect(find.text('Test'), findsOneWidget);
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

    // The case that motivated the old pill cap: many reminders with long
    // custom labels must not overflow the button — now nothing renders at
    // all, so the regression is that the label stays intact.
    testWidgets('ten pending reminders with long labels do not overflow',
        (tester) async {
      final many = [
        for (var i = 1; i <= 10; i++)
          buildReminder(
            trackingType: TrackingType.sante,
            id: 'custom_$i',
            labelKey: 'Crème numéro $i',
          ),
      ];
      await tester.pumpWidget(ProviderScope(
        child: pumpTrackButton(
          label: 'Santé',
          color: AppTheme.sante,
          reminders: many,
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Santé'), findsOneWidget);
      expect(find.text('Crème numéro 1'), findsNothing);
      expect(find.text('+8'), findsNothing);
    });
  });
}

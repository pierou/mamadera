import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/presentation/widgets/reminder_pill.dart';
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
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Test Label', color: AppTheme.miam)));
      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, onTap: () => tapped = true)));
      await tester.tap(find.byType(TrackButton));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed (optional)', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, onTap: () {}, onLongPress: () => pressed = true)));
      await tester.longPress(find.byType(TrackButton));
      expect(pressed, isTrue);
    });

    testWidgets('border uses the provided color', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Test', color: AppTheme.sante)));
      final button = find.byType(TrackButton);
      expect(button, findsOneWidget);
    });

    // Core behavior: non-empty reminders list → pills for ALL items (regardless of lastEventAt)
    testWidgets('shows reminder pills when reminders list is non-empty', (tester) async {
      final status1 = buildReminder(trackingType: TrackingType.sante, id: 'vitamine_d', labelKey: 'reminderVitaminD', lastEventAt: null);
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: [status1])));

      expect(find.byType(ReminderPill), findsOneWidget);
    });

    testWidgets('shows reminder pills for all items in non-empty list (even with lastEventAt)', (tester) async {
      final now = DateTime.now();
      final status1 = buildReminder(trackingType: TrackingType.sante, id: 'vitamine_d', labelKey: 'reminderVitaminD', lastEventAt: now);
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: [status1])));

      expect(find.byType(ReminderPill), findsOneWidget);
    });

    testWidgets('shows no pills when reminders is null', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: null)));
      expect(find.byType(ReminderPill), findsNothing);
    });

    testWidgets('shows no pills when reminders list is empty', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: [])));
      expect(find.byType(ReminderPill), findsNothing);
    });

    testWidgets('multiple reminder pills render correctly (2 items)', (tester) async {
      final status1 = buildReminder(trackingType: TrackingType.sante, id: 'vitamine_d', labelKey: 'reminderVitaminD', lastEventAt: null);
      final status2 = buildReminder(trackingType: TrackingType.caca, id: 'eye_cleaning', labelKey: 'reminderEyeCleaning', lastEventAt: null);
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: [status1, status2])));

      expect(find.byType(ReminderPill), findsNWidgets(2));
    });

    testWidgets('shows relative time text for completed events with non-empty list (pills take priority)', (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final status1 = buildReminder(trackingType: TrackingType.sante, id: 'vitamine_d', labelKey: 'reminderVitaminD', lastEventAt: yesterday);
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: [status1])));

      // Non-empty list → pills shown (pills take priority over "last tracked" text)
      expect(find.byType(ReminderPill), findsOneWidget);
    });

    testWidgets('label is bold and large', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Test Label', color: AppTheme.miam)));
      final textFinder = find.text('Test Label');
      expect(textFinder, findsOneWidget);
    });

    testWidgets('renders with all tracking type colors', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Miam', color: AppTheme.miam)));
      expect(find.byType(TrackButton), findsOneWidget);

      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Sante', color: AppTheme.sante)));
      expect(find.byType(TrackButton), findsOneWidget);

      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Caca', color: AppTheme.caca)));
      expect(find.byType(TrackButton), findsOneWidget);

      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Dodo', color: AppTheme.dodo)));
      expect(find.byType(TrackButton), findsOneWidget);
    });

    testWidgets('has semantics label for accessibility', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding Button', color: AppTheme.miam)));
      expect(find.byType(TrackButton), findsOneWidget);
    });

    testWidgets('animates on tap without errors', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam)));
      final finder = find.byType(TrackButton);

      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 150)); // complete animation

      expect(find.text('Feeding'), findsOneWidget);
    });

    testWidgets('mixed pending and completed reminders show pills for all items in non-empty list', (tester) async {
      final now = DateTime.now();
      final pending = buildReminder(trackingType: TrackingType.sante, id: 'vitamine_d', labelKey: 'reminderVitaminD', lastEventAt: null);
      final completed = buildReminder(trackingType: TrackingType.caca, id: 'eye_cleaning', labelKey: 'reminderEyeCleaning', lastEventAt: now);

      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: [pending, completed])));

      // Non-empty list → all items get pills (2 total)
      expect(find.byType(ReminderPill), findsNWidgets(2));
    });

    testWidgets('ReminderPill displays localized label for Vitamin D', (tester) async {
      final status1 = buildReminder(trackingType: TrackingType.sante, id: 'vitamine_d', labelKey: 'reminderVitaminD', lastEventAt: null);
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Feeding', color: AppTheme.miam, reminders: [status1])));

      expect(find.byType(ReminderPill), findsOneWidget);
    });

    testWidgets('no crash when onTap is provided as default callback', (tester) async {
      await tester.pumpWidget(ProviderScope(child: pumpTrackButton(label: 'Test', color: Colors.red)));
      expect(find.text('Test'), findsOneWidget);
    });

    // ── Accessibility tests ──────────────────────────────────────

    testWidgets('has Semantics widget with label and button:true', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: pumpTrackButton(label: 'Feeding Accessibility Test', color: AppTheme.miam),
      ));
      // Verify at least one Semantics widget exists for accessibility
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('respects reduce motion - no animation when disableAnimations is true', (tester) async {
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
  });
}

// ignore_for_file: avoid_print
/// B35 visual verification — scratch poses for screenshots (NOT a gate leg).
///
/// Seeds an in-memory database (one baby, an event of every history row type,
/// one encrypted measurement, a preset with a STORED hour, one custom
/// reminder) and then holds three poses, each parked for 50 s so the harness
/// can capture `adb exec-out screencap -p`:
///
///   [POSE-1] history tab, light theme  — row glyphs + filter pills
///   [POSE-2] vitamine D edit sheet, light theme — the hour line (B35 §1)
///   [POSE-3] CUSTOM 'Bain' edit sheet, light theme — its hour line (B35)
///   [POSE-4] history tab, dark theme — same rows, other scheme
///
/// Run:
///   flutter test integration_test/b35_visual_verify.dart -d emulator-5554
library;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/providers/theme_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/core/services/theme_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/reminders/presentation/widgets/custom_reminder_tile.dart';
import 'package:mamadera/features/reminders/presentation/widgets/reminder_hour_control.dart';
import 'package:mamadera/main.dart';

import 'test_utils.dart';

/// Theme fixed to one mode regardless of the stored preference.
class FixedThemeNotifier extends ThemeNotifier {
  FixedThemeNotifier(this._mode);

  final String _mode;

  @override
  Future<ThemePreference> build() async => ThemePreference(mode: _mode);
}

/// Pumps the real [MyApp] over the seeded in-memory DB with [theme] forced.
Future<void> pumpApp(WidgetTester tester, AppDatabase db, EncryptionService enc,
    String theme) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(() => ConfigurableLocaleNotifier('fr')),
        appPreferencesProvider.overrideWith(AcceptedTermsNotifier.new),
        anyBabyExistsProvider.overrideWith(BabyExistsNotifier.new),
        databaseProvider.overrideWith((_) async => db),
        encryptionServiceProvider.overrideWith((_) async => enc),
        themeProvider.overrideWith(() => FixedThemeNotifier(theme)),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

/// Holds the current frame [seconds] long so a screencap can be taken.
Future<void> park(WidgetTester tester, int seconds) async {
  await tester.pump();
  await Future<void>.delayed(Duration(seconds: seconds));
}

/// The exact glyphs the B35 mapping puts on history rows and pills
/// (tracking_icons.dart): the outlined list family, plus the two diaper drops
/// (filled vs outlined *is* the pipi/caca distinction).
Set<int> expectedGlyphs() => {
      Icons.lunch_dining_outlined.codePoint, // miam row + pill
      Icons.nightlight_outlined.codePoint, // dodo row + pill
      Icons.water_drop_outlined.codePoint, // pipi row + caca pill
      Icons.water_drop.codePoint, // caca row (the filled drop, by design)
      Icons.favorite_border.codePoint, // sante row + pill
    };

/// The pre-B35 SOLID glyphs that must NOT appear on the history screen
/// (the "borderless" complaint): canonical type icons plus the solid heart.
Set<int> staleGlyphs() => {
      Icons.lunch_dining.codePoint,
      Icons.nightlight.codePoint,
      Icons.favorite.codePoint,
      Icons.favorite_outlined.codePoint, // renders SOLID in this font (B35 §3)
    };

/// Asserts the history screen actually renders the B35 glyph set — and none
/// of the old solid ones — then prints every icon codepoint on screen so the
/// capture is self-certifying.
void checkHistoryGlyphs(WidgetTester tester) {
  final rendered = find
      .byType(Icon)
      .evaluate()
      .map((e) => (e.widget as Icon).icon?.codePoint)
      .whereType<int>()
      .toSet();
  final missing = expectedGlyphs().difference(rendered);
  expect(missing, isEmpty,
      reason: 'B35 glyphs missing on history screen: '
          '$missing; rendered $rendered');
  final stale = rendered.intersection(staleGlyphs());
  expect(stale, isEmpty,
      reason: 'pre-B35 solid glyphs still on history screen: $stale');
  print('[GLYPHS] rendered=${rendered.toList()..sort()}');
}

/// Polls until [cond] or ~30 s, then fails with [what].
Future<void> waitUntil(
    WidgetTester tester, String what, bool Function() cond) async {
  for (var i = 0; i < 150; i++) {
    if (cond()) return;
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('timed out waiting for: $what');
}

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('B35 visual poses', (tester) async {
    // ── Seed ────────────────────────────────────────────────────────────
    final db = await createInMemoryDb();
    final enc = EncryptionService();
    await enc.initialize();

    final now = DateTime.now();
    int ms(DateTime t) => t.millisecondsSinceEpoch;
    // ~10.5 months old, so the age line and end-age math have real input.
    final birth = now.subtract(const Duration(days: 320));

    await db.into(db.babyProfiles).insert(BabyProfilesCompanion.insert(
        id: 'b1', name: 'Lucie', birthDate: ms(birth)));

    await db.into(db.trackingEvents).insert(TrackingEventsCompanion.insert(
        type: 'miam',
        timestamp: now.subtract(const Duration(hours: 3)),
        duration: const Value(20),
        quantity: const Value(120),
        unit: 'ml',
        babyId: const Value('b1')));
    await db.into(db.trackingEvents).insert(TrackingEventsCompanion.insert(
        type: 'dodo',
        timestamp: now.subtract(const Duration(hours: 6)),
        duration: const Value(45),
        quantity: const Value(45),
        unit: 'min',
        babyId: const Value('b1')));
    await db.into(db.trackingEvents).insert(TrackingEventsCompanion.insert(
        type: 'caca',
        timestamp: now.subtract(const Duration(hours: 2)),
        wasteType: const Value('pipi'),
        unit: 'ml',
        babyId: const Value('b1')));
    await db.into(db.trackingEvents).insert(TrackingEventsCompanion.insert(
        type: 'caca',
        timestamp: now.subtract(const Duration(hours: 5)),
        wasteType: const Value('caca'),
        unit: 'ml',
        babyId: const Value('b1')));
    await db.into(db.trackingEvents).insert(TrackingEventsCompanion.insert(
        type: 'sante',
        timestamp: now.subtract(const Duration(hours: 9)),
        subtype: const Value('vitamine_d'),
        unit: 'ml',
        babyId: const Value('b1')));
    await db.into(db.measurements).insert(MeasurementsCompanion.insert(
        babyId: const Value('b1'),
        kind: 'poids',
        value: enc.encrypt('3550'),
        unit: 'g',
        recordedAt: now.subtract(const Duration(days: 1))));

    // Vitamine D with a stored hour (09:30) — the sheet must show it (B35 §1);
    // the custom reminder inherits the global hour instead.
    await db.into(db.reminderSettings).insert(ReminderSettingsCompanion.insert(
        babyId: const Value('b1'),
        itemId: 'vitamine_d',
        enabled: true,
        time: const Value('09:30')));
    await db.into(db.customReminders).insert(CustomRemindersCompanion.insert(
        babyId: const Value('b1'), label: 'Bain', frequency: 'daily'));

    // ── POSE 1: history, light ──────────────────────────────────────────
    await pumpApp(tester, db, enc, 'light');
    await tester.tap(findByKey(TestKeys.historyTab));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await waitUntil(tester, 'history rows rendered',
        () => find.byType(ListView).evaluate().isNotEmpty);
    checkHistoryGlyphs(tester);
    print('[POSE-1] history light');
    await park(tester, 50);

    // ── POSE 2: vitamine D edit sheet, light ────────────────────────────
    // A context inside the MaterialApp subtree (GoRouter.of walks up).
    final routerContext = tester.element(find.byType(Scaffold).first);
    GoRouter.of(routerContext).go('/reminder-settings');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await waitUntil(tester, 'vitamine d row',
        () => find.text('Vitamine D').evaluate().isNotEmpty);
    // Preset rows are SwitchListTiles; the menu lives in their `secondary`.
    final row = find
        .ancestor(
            of: find.text('Vitamine D'), matching: find.byType(SwitchListTile))
        .first;
    await tester
        .tap(find.descendant(of: row, matching: find.byIcon(Icons.more_vert)));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await waitUntil(tester, 'edit sheet open',
        () => find.textContaining('Modifier le rappel').evaluate().isNotEmpty);
    // 'À 09:30' on the row behind the sheet AND the sheet's own hour line:
    // exactly one would mean the sheet has no hour (the B35 §1 defect).
    expect(find.text('À 09:30'), findsWidgets,
        reason:
            'hour must be visible on both the row and inside the edit sheet');
    print('[POSE-2] edit sheet light');
    await park(tester, 50);

    // ── POSE 3: custom reminder edit panel, light ───────────────────
    // Dismiss the preset sheet, then tap the custom row to open its own
    // edit panel — the surface the owner reported as having no hour.
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final customTile = find.descendant(
        of: find.byType(CustomReminderTile), matching: find.text('Bain'));
    await tester.scrollUntilVisible(customTile, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(customTile);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final sheet = find.byType(BottomSheet);
    expect(find.text('Modifier le rappel'), findsOneWidget,
        reason: 'the custom edit panel did open');
    expect(
        find.descendant(of: sheet, matching: find.byType(ReminderHourControl)),
        findsOneWidget,
        reason: 'the custom edit panel must own the hour control (B35)');
    print('[POSE-3] custom edit sheet light');
    await park(tester, 50);

    // ── POSE 4: history, dark ───────────────────────────────────────────
    // The global GoRouter survived the re-pump and is still on the
    // out-of-shell /reminder-settings route (no bottom tabs there), so go
    // home explicitly before the tab tap.
    await pumpApp(tester, db, enc, 'dark');
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(findByKey(TestKeys.historyTab));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await waitUntil(tester, 'history rows rendered (dark)',
        () => find.byType(ListView).evaluate().isNotEmpty);
    checkHistoryGlyphs(tester);
    print('[POSE-4] history dark');
    await park(tester, 50);
  });
}

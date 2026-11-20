// ignore_for_file: avoid_print
/// M9 leg 2, pre-upgrade — seed a database WRITTEN BY THE 1.3.2 BINARY.
///
/// The release gate (AGENTS.md) forbids proving the v13 → v14 migration on a
/// fresh database, because a fresh install creates the schema directly. This
/// leg builds that old data the honest way: run the real 1.3.2 app, accept
/// the terms, create the two babies the Vitamin K one-shot test needs,
/// record events, and manually switch Vitamin D off for one of them. Then
/// this branch's build is installed over it and the post-upgrade leg reads
/// the same file.
///
/// Birthdates (device date 2026-11-19) are set through a direct SQL
/// `UPDATE` after the UI creation: the 1.3.2 onboarding sheet's date picker
/// cannot be driven reliably on the 4-inch target (keyboard + sheet drag
/// fight for the tap), and the v14 migration never touches
/// `baby_profiles` — the value is fixture data for the Vitamin K math, not
/// input to the migration under test. Every row the migration sees was
/// written by the 1.3.2 app.
///   dave — 2026-10-19 ⇒ birth + 1 month = TODAY   (due-now catch-up leg)
///   bob  — 2026-10-20 ⇒ birth + 1 month = TOMORROW (scheduled-once leg)
///
/// Run with a clean app state (the test asserts true first-launch):
/// ```bash
/// adb -s emulator-5554 shell pm clear com.pvjio.mamadera
/// flutter test integration_test/gate_v140_seed_v132.dart -d emulator-5554 --no-uninstall
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/core/providers/database_provider.dart';

import 'test_utils.dart';

int msLocal(int y, int m, int d, [int h = 12]) =>
    DateTime(y, m, d, h).millisecondsSinceEpoch;

/// Closes the soft keyboard the way the framework hides it: drop focus, then
/// send the platform `TextInput.hide`. (`tester.pageBack` looks for a
/// Cupertino back button; the shell `input` binary cannot run from the test
/// process — both dead ends, learned on 2026-11-19.)
Future<void> hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await tester.pump();
}

/// Poll until [cond] is true or fail with [what].
Future<void> waitUntil(
    WidgetTester tester, String what, bool Function() cond) async {
  for (var i = 0; i < 150; i++) {
    if (cond()) return;
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('timed out waiting for: $what');
}

/// Taps a bottom sheet's action button and proves it worked: the 1.3.2
/// sheets overflow the 4-inch screen (Confirm rendered at y=657 on a 640px
/// viewport) and are only reachable after a scroll, and a soft keyboard that
/// is still animating away eats taps aimed under it. Tap, verify the sheet
/// closed, retry with the keyboard explicitly dismissed.
Future<void> tapSheetConfirmed(WidgetTester tester, String label) async {
  for (var attempt = 1; attempt <= 5; attempt++) {
    final f = find.text(label);
    if (f.evaluate().isEmpty) return; // closed between attempts
    await Scrollable.ensureVisible(tester.element(f.last));
    await tester.pump();
    await tester.tap(f.last);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await tester.pump();
    if (find.text(label).evaluate().isEmpty) return;
    print(
        '[SEED] $label tap did not close the sheet (attempt $attempt) — closing keyboard, retrying');
    await hideKeyboard(tester);
  }
  fail('$label was never confirmed');
}

/// The 1.3.2 settings screen tolerates a provider notification arriving
/// mid-build (Flutter logs it as an allowed error); the test binding turns
/// every FlutterError into a failure. Drain exactly that race, fail on
/// anything else.
void drainKnownRaces(WidgetTester tester) {
  for (var i = 0; i < 5; i++) {
    final e = tester.takeException();
    if (e == null) return;
    if (e.toString().contains('called during build')) {
      print('[SEED] (drained the known 1.3.2 mid-build refresh race)');
      continue;
    }
    fail('unexpected exception: $e');
  }
  fail('too many pending exceptions to drain');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seed v13: dave (Vit D off) + bob, events, no opt-in',
      (tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    await pumpMamadera(
      tester,
      useInMemoryDb: false,
      termsNotAccepted: true,
      babyExistsOverride: false,
    );

    // 1. Terms of service — the real accept button, keyed for tests.
    await tester.tap(findByKey(TestKeys.termsAcceptButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await waitUntil(tester, 'the onboarding sheet',
        () => find.text('Welcome to Mamadera!').evaluate().isNotEmpty);

    // 2. First-baby onboarding sheet: dave (birth fixed by SQL below).
    await tester.enterText(find.byType(TextField).first, 'dave');
    await hideKeyboard(tester);
    await waitUntil(
        tester,
        'the onboarding Confirm to be tappable',
        () => find
            .widgetWithText(ElevatedButton, 'Confirm')
            .evaluate()
            .isNotEmpty);
    await tapSheetConfirmed(tester, 'Confirm');
    await waitUntil(tester, 'the onboarding sheet to close (dave created)',
        () => find.text('Welcome to Mamadera!').evaluate().isEmpty);
    print('[SEED] dave: created');

    // 3. Events for dave.
    await tester.tap(findByKey(TestKeys.trackMiam));
    await waitUntil(tester, 'the feeding confirm sheet',
        () => find.text('Confirm').evaluate().isNotEmpty);
    await tapSheetConfirmed(tester, 'Confirm');
    print('[SEED] dave: feeding recorded');

    await tester.tap(findByKey(TestKeys.trackDodo));
    await waitUntil(tester, 'the sleep confirm sheet',
        () => find.text('Confirm').evaluate().isNotEmpty);
    await tapSheetConfirmed(tester, 'Confirm');
    print('[SEED] dave: sleep recorded');

    // Weight: wait for the sheet's own Save button, not any TextField.
    await openWeightSheet(tester);
    await tester.enterText(find.byType(TextField).first, '4200');
    await hideKeyboard(tester);
    await waitUntil(tester, 'the weight Save button',
        () => find.text('Save').evaluate().isNotEmpty);
    await tapSheetConfirmed(tester, 'Save');
    print('[SEED] dave: weight 4200 g recorded');

    // 4. Second baby via the menu: bob.
    await tester.tap(findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle();
    await waitUntil(tester, 'the menu screen',
        () => find.text('Add Baby').evaluate().isNotEmpty);
    await tester.tap(find.text('Add Baby'));
    await waitUntil(tester, 'the add-baby dialog',
        () => find.byType(TextField).evaluate().isNotEmpty);
    await tester.enterText(find.byType(TextField).first, 'bob');
    await hideKeyboard(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Add Baby'));
    await waitUntil(tester, 'bob in the profile list',
        () => find.text('bob').evaluate().isNotEmpty);
    print('[SEED] bob created');

    // 5. The M1 trap, planted honestly: Vitamin D manually OFF for dave
    // (dave is the active baby; bob was created with isActive: false).
    final settingsRow = find.text('Choose which reminders to show');
    await Scrollable.ensureVisible(tester.element(settingsRow));
    await tester.pumpAndSettle();
    await tester.tap(settingsRow);
    await waitUntil(
        tester,
        'the reminder settings screen',
        () => find
            .widgetWithText(SwitchListTile, 'Vitamin D')
            .evaluate()
            .isNotEmpty);
    final vitD = find.widgetWithText(SwitchListTile, 'Vitamin D');
    final sw = find.descendant(of: vitD, matching: find.byType(Switch)).first;
    expect((sw.evaluate().single.widget as Switch).value, isTrue,
        reason: 'a never-touched scope starts enabled');
    await tester.tap(sw);
    await tester.pumpAndSettle();
    drainKnownRaces(tester);
    final sw2 = find.descendant(of: vitD, matching: find.byType(Switch)).first;
    expect((sw2.evaluate().single.widget as Switch).value, isFalse,
        reason: 'the manual off must stick');
    print('[SEED] dave: Vitamin D switched OFF');
    // Let the settings provider's refetch settle inside the body: if it
    // completes during teardown it marks the scope dirty mid-unmount and the
    // test fails on a framework race, not on seed state.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 6. Birthdates for the Vitamin K math (fixture adjustment, see header).
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final db = await container.read(databaseProvider.future);
    final dave = (await db
            .customSelect("SELECT id FROM baby_profiles WHERE name='dave'")
            .get())
        .single;
    final bob = (await db
            .customSelect("SELECT id FROM baby_profiles WHERE name='bob'")
            .get())
        .single;
    await db.customStatement(
        "UPDATE baby_profiles SET birth_date=${msLocal(2026, 10, 19)} WHERE id='${dave.data['id']}'");
    await db.customStatement(
        "UPDATE baby_profiles SET birth_date=${msLocal(2026, 10, 20)} WHERE id='${bob.data['id']}'");
    print('[SEED] birthdates set: dave 2026-10-19, bob 2026-10-20');

    // 7. Dump the file database — the contract the post-upgrade leg verifies.
    final babies = await db
        .customSelect(
            'SELECT id, name, birth_date, is_active FROM baby_profiles ORDER BY name')
        .get();
    for (final r in babies) {
      print('[SEED-DB] baby_profiles: ${r.data}');
    }
    final settings = await db
        .customSelect('SELECT baby_id, item_id, enabled FROM reminder_settings')
        .get();
    for (final r in settings) {
      print('[SEED-DB] reminder_settings: ${r.data}');
    }
    final events = await db
        .customSelect('SELECT COUNT(*) AS n FROM tracking_events')
        .get();
    print('[SEED-DB] tracking_events: ${events.first.data['n']}');
    final version = await db.customSelect('PRAGMA user_version').get();
    print('[SEED-DB] user_version: ${version.first.data['user_version']}');
    expect(version.first.data['user_version'], 13,
        reason: 'this database must still be a 1.3.2 database');

    print('[SEED] PASS — old data written by the 1.3.2 binary');
  });
}

Future<void> openWeightSheet(WidgetTester tester) async {
  final poids = find.byKey(const ValueKey('measure-poids'));
  await waitUntil(tester, 'the weight row', () => poids.evaluate().isNotEmpty);
  for (var attempt = 1; attempt <= 3; attempt++) {
    await Scrollable.ensureVisible(tester.element(poids), alignment: 0.75);
    await tester.pumpAndSettle();
    await tester.tap(poids);
    await tester.pump();
    for (var i = 0; i < 25 && find.text('Save').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text('Save').evaluate().isNotEmpty) return;
    print('[SEED] weight sheet did not open (attempt $attempt) — retrying');
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
  }
  fail('the weight sheet never opened');
}

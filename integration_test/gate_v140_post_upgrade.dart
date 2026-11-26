// ignore_for_file: avoid_print
/// Release gate v1.4.0 — the post-upgrade leg (AGENTS.md: the migration is
/// proved on a database written by the 1.3.2 binary, never on a fresh one).
///
/// Precondition, on the host, in order:
///
///   1. A clean AVD, the 1.3.2 binary (a `git worktree` of the `v1.3.2` tag)
///      installed, with `gate_v140_seed_v132.dart` run against it — the file
///      database on disk is a v13 file written by the 1.3.2 app: two babies
///      (dave, Vitamin D manually OFF; bob, never touched), one feeding, one
///      sleep, one 4200 g weight, no opt-in.
///   2. This test, run from THIS branch: `flutter test` installs the 1.4.0
///      debug build **over** the 1.3.2 one (same debug keystore), so the
///      v13 → v14 migration runs on the first launch of the new binary.
///   3. Before leg `test3a`, grant the notification permission on the host
///      (the in-app request cannot be driven from a test):
///
///        adb -s <device> shell pm grant \
///          com.pvjio.mamadera android.permission.POST_NOTIFICATIONS
///
/// Legs (`GATE_ONLY` takes one or a comma list):
///
///   test1  continuity: the v13 rows survive, user_version is 14, the B6 seed
///          rows exist, dave's manual-off is kept, dave's Vitamin K shows the
///          due-now catch-up on Home, and the export is format 5.
///   test2  a baby created AFTER the upgrade (carmen) shows Vitamin D OFF on
///          the settings screen — the four-site default observed, not assumed.
///   test3a bob (birth + 1 month = tomorrow) + opt-in: the one-shot Vitamin K
///          is armed exactly once. The OS plan is read in-band via
///          `getPendingNotificationRequests` — when the test process exits the
///          plugin's exit hook cancels the app's alarms, so a host-side
///          `dumpsys alarm` between legs only ever shows pi_cancelled ghosts.
///   test3b the dose is recorded through the real sante sheet: the one-shot
///          settles — the K row leaves Home, the completion is in the journal,
///          and the OS entry is gone (K-SETTLED, in-band).
///
/// ```bash
/// flutter test integration_test/gate_v140_post_upgrade.dart -d emulator-5554 \
///   --no-uninstall
/// ```
library;

import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/reminders/domain/services/notification_payload.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_sync_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'test_utils.dart';

bool _surfaceConverted = false;

const _only = String.fromEnvironment('GATE_ONLY');

/// `GATE_ONLY` takes one leg or a comma list (`test1,test2,test3a,test3b`).
bool _want(String leg) => _only.isEmpty || _only.split(',').contains(leg);

Future<void> capture(WidgetTester tester, String name) async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  if (!_surfaceConverted) {
    await binding.convertFlutterSurfaceToImage();
    _surfaceConverted = true;
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  final bytes = await binding.takeScreenshot(name);
  final documents = await getApplicationDocumentsDirectory();
  final dir = io.Directory('${documents.path}/gate');
  await dir.create(recursive: true);
  final file = io.File('${dir.path}/$name.png');
  await file.writeAsBytes(bytes);
  print('[CAPTURE] ✓ ${file.path} (${bytes.length} bytes)');
}

/// Poll until [cond] is true or fail with [what].
Future<void> waitUntil(
    WidgetTester tester, String what, bool Function() cond) async {
  for (var i = 0; i < 100 && !cond(); i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(cond(), isTrue, reason: 'timed out waiting for: $what');
}

/// Wait for Home, falling back to the tab tap if a previous leg left the
/// router elsewhere (the app restarts between `testWidgets` bodies).
Future<void> ensureHome(WidgetTester tester) async {
  const miam = ValueKey('track-miam');
  for (var i = 0; i < 40 && find.byKey(miam).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // An earlier leg may have left the app on a pushed route (the reminder
  // settings has no tab bar), so Home is neither on screen nor one tab-tap
  // away. Pop until the scaffold is back, then switch to the home tab.
  for (var i = 0; i < 4 && find.byKey(miam).evaluate().isEmpty; i++) {
    final home = findByKey(TestKeys.homeTab);
    if (home.evaluate().isNotEmpty) {
      await tester.tap(home.first);
      await tester.pumpAndSettle();
      break;
    }
    final navs = find.byType(Navigator).evaluate();
    if (navs.isEmpty) break;
    final nav = Navigator.of(navs.last); // an Element is a BuildContext
    if (!nav.canPop()) break;
    nav.pop();
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
  expect(find.byKey(miam), findsWidgets,
      reason: 'Home must be on screen before anything else');
  // The 1.3.2 → 1.4.0 upgrade raises the patch-notes dialog on first launch;
  // any leftover dialog blocks the grid.
  for (final label in const ['Got it', 'Close', 'OK']) {
    final f = find.widgetWithText(TextButton, label);
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first);
      await tester.pumpAndSettle();
      print('[GATE] dismissed the "$label" dialog');
    }
  }
}

Future<AppDatabase> _db(WidgetTester tester) async {
  final container =
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  return container.read(databaseProvider.future);
}

class _StashingSharePlatform extends SharePlatform {
  String? content;

  @override
  Future<ShareResult> share(ShareParams p) async {
    final file = io.File(p.files!.single.path);
    content = file.existsSync() ? file.readAsStringSync() : null;
    return const ShareResult('gate-pass', ShareResultStatus.success);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => _surfaceConverted = false);

  testWidgets('1. continuity: v13 rows survive, B6 seed, B30, v5 export',
      (tester) async {
    if (!_want('test1')) return;
    WidgetsApp.debugAllowBannerOverride = false;
    await pumpMamadera(tester, useInMemoryDb: false);
    await tester.pumpAndSettle();
    await ensureHome(tester);

    // Old data visible on the new build. The app bar title, the measurements
    // section and the reminder section all load asynchronously after launch —
    // wait for each marker instead of racing the first frame.
    await waitUntil(tester, 'the active baby on the app bar',
        () => find.text('dave').evaluate().isNotEmpty);
    expect(find.text('dave'), findsWidgets,
        reason: 'the seeded active baby is on the app bar');
    await waitUntil(tester, 'the seeded weight on Home',
        () => find.text('4.2 kg').evaluate().isNotEmpty);
    expect(find.text('4.2 kg'), findsWidgets,
        reason:
            'the seeded weight survives readable — encryption and rows intact');
    // The Home row resolves its label through the health subtype (the full
    // "Vitamin K", not the "Vit. K" short form of the reminder key) — the
    // diagnostic run proved the item is due; this text is what the row shows.
    await waitUntil(tester, 'the due Vitamin K row on Home',
        () => find.text('Vitamin K').evaluate().isNotEmpty);
    expect(find.text('Vitamin K'), findsWidgets,
        reason:
            'dave (birth 2026-10-19, one-shot at birth + 1 month) is due now '
            'on the new build — the catch-up shows on Home');
    await capture(tester, 'gate-v140-01-home-after-migration');

    final db = await _db(tester);

    // user_version: 13 → 14.
    final version = await db.customSelect('PRAGMA user_version').get();
    expect(version.first.data['user_version'], 14,
        reason: 'the migration must have run on the 1.3.2 file database');

    // Profiles: both survive, dave still active, birthdates untouched.
    final babies = await db
        .customSelect('SELECT id, name, birth_date, is_active '
            'FROM baby_profiles ORDER BY name')
        .get();
    expect(babies.length, 2);
    final byName = <String, Map<String, Object?>>{
      for (final r in babies) r.data['name'] as String: r.data,
    };
    // This Dart SDK's `Map[]` returns nullable — the codebase's own idiom is
    // the explicit `!` where the row is known present (two rows were asserted).
    final daveRow = byName['dave']!;
    final bobRow = byName['bob']!;
    expect(daveRow['is_active'], 1);
    expect(bobRow['is_active'], 0);
    expect(daveRow['birth_date'], msLocal(2026, 10, 19));
    expect(bobRow['birth_date'], msLocal(2026, 10, 20));

    // Events and the measurement survive.
    final events = await db
        .customSelect('SELECT COUNT(*) AS n FROM tracking_events')
        .get();
    expect(events.first.data['n'], 2,
        reason: 'feeding + sleep seeded by 1.3.2');
    final measures =
        await db.customSelect('SELECT COUNT(*) AS n FROM measurements').get();
    expect(measures.first.data['n'], 1);

    // B6: the seed wrote 1 or nothing, never 0. The v13 file had exactly one
    // reminder_settings row (dave, enabled=0). After the migration there are
    // three: the profileless scope and bob seeded ON, dave kept OFF.
    final settings = await db
        .customSelect('SELECT baby_id, item_id, enabled, time, removed '
            'FROM reminder_settings ORDER BY baby_id, item_id')
        .get();
    expect(settings.length, 3,
        reason: 'the B6 seed covers the profileless scope and every baby');
    for (final r in settings) {
      expect(r.data['item_id'], 'vitamine_d');
      expect(r.data['time'], isNull,
          reason: 'B30 — the seed must not materialise the global hour');
      expect(r.data['removed'], 0);
    }
    final enabledByScope = {
      for (final r in settings) r.data['baby_id'] as String: r.data['enabled']
    };
    final daveId = daveRow['id'] as String;
    final bobId = bobRow['id'] as String;
    expect(enabledByScope[''], 1,
        reason: 'profileless scope: pre-v14 absence meant ON, kept ON');
    expect(enabledByScope[daveId], 0,
        reason: 'B6 — dave manually turned it off in 1.3.2; the seed never '
            'overwrites an existing row');
    expect(enabledByScope[bobId], 1,
        reason: 'bob was never touched in 1.3.2: absence meant ON, kept ON');
    print('[GATE] B6 seed rows: $enabledByScope');

    // The settings screen agrees with the database: dave's Vit. D is OFF.
    await _settleTap(tester, findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle();
    final tile = find.text('Choose which reminders to show');
    await Scrollable.ensureVisible(tester.element(tile));
    await tester.pumpAndSettle();
    await _settleTap(tester, tile);
    // The settings list shows the full care name ("Vitamin D", per
    // _presetLabel's doc), not the Home abbreviation.
    await waitUntil(
        tester,
        'the reminder settings screen',
        () => find
            .widgetWithText(SwitchListTile, 'Vitamin D')
            .evaluate()
            .isNotEmpty);
    final vitD = find.widgetWithText(SwitchListTile, 'Vitamin D');
    final sw = find.descendant(of: vitD, matching: find.byType(Switch)).first;
    expect((sw.evaluate().single.widget as Switch).value, isFalse,
        reason: "the parent's off is still off, seen on the screen");
    await capture(tester, 'gate-v140-02-settings-vitd-off');
    print('[GATE] continuity PASS');

    // Back to the shell (the settings route sits outside it), then export:
    // the upgraded database is format 5 and carries the v5 keys.
    await tester.pageBack();
    await ensureHome(tester);
    SharePlatform.instance = _StashingSharePlatform();
    await _settleTap(tester, findByKey(TestKeys.menuTab));
    final exportItem = find.text('Export my data');
    await Scrollable.ensureVisible(tester.element(exportItem));
    await tester.pumpAndSettle();
    await _settleTap(tester, exportItem);
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    final stash = SharePlatform.instance;
    final content = stash is _StashingSharePlatform ? stash.content : null;
    expect(content, isNotNull);
    final json = content!;
    // The document is pretty-printed (two-space indent, space after colons).
    expect(json, contains('"exportFormatVersion": 5'),
        reason: 'the v14 database exports as format 5');
    expect(json, contains('"databaseSchemaVersion": 14'));
    expect(json, contains('"reminderSettings"'));
    expect(json, contains('"timeOfDay"'),
        reason: 'B30 — the per-reminder hour key is in the v5 row');
    expect(json.count('"vitamine_d"'), 3,
        reason: 'all three seeded scope rows are in the export');
    expect(json, contains('"enabled": false'),
        reason: "dave's manual-off row is exported as such");
    expect(json, contains('"timeOfDay": null'),
        reason: 'inheritance is exported as null, not as a copied hour');
    print('[GATE] export v5 PASS');
  });

  testWidgets('2. a new baby shows Vitamin D OFF (B6, observed)',
      (tester) async {
    if (!_want('test2')) return;
    WidgetsApp.debugAllowBannerOverride = false;
    await pumpMamadera(tester, useInMemoryDb: false);
    await tester.pumpAndSettle();
    await ensureHome(tester);

    // B9: the app bar title opens the switcher. The sheet's "Add Baby" tile
    // closes the sheet and then opens the dialog, so after a creation the
    // sheet must be reopened to activate the new profile.
    await _settleTap(tester, find.text('dave').first);
    await waitUntil(tester, 'the baby picker sheet',
        () => find.text('bob').evaluate().isNotEmpty);
    // Idempotent: an earlier attempt of this leg may have created carmen
    // already; the sheet reads the live profile list, so it shows her now.
    if (find.text('carmen').evaluate().isEmpty) {
      await _settleTap(tester, find.text('Add Baby').last);
      await waitUntil(tester, 'the add-baby dialog',
          () => find.byType(TextField).evaluate().isNotEmpty);
      await tester.enterText(find.byType(TextField).first, 'carmen');
      await _hideKeyboard(tester);
      await _tapDialogConfirmed(tester, 'Add Baby');
      // Reopen the switcher: it was closed by the "Add Baby" tile.
      await waitUntil(tester, 'Home after the dialog',
          () => find.text('dave').evaluate().isNotEmpty);
      await _settleTap(tester, find.text('dave').first);
      await waitUntil(tester, 'carmen in the picker sheet',
          () => find.text('carmen').evaluate().isNotEmpty);
    }
    await _settleTap(tester, find.text('carmen').last);
    await waitUntil(tester, 'the picker sheet to close (carmen active)',
        () => find.text('carmen').evaluate().length == 1);
    expect(find.text('carmen'), findsOneWidget,
        reason: 'carmen is now the app bar title');
    print('[GATE] carmen created after the upgrade and activated');

    // No stored row for her: absence is the B6 default, which is OFF for
    // Vitamin D. The switch on the screen is the observation the plan asks
    // for — not a provider test.
    final db = await _db(tester);
    final carmenId = (await db
            .customSelect("SELECT id FROM baby_profiles WHERE name='carmen'")
            .get())
        .single
        .data['id'] as String;
    final rows = await db
        .customSelect('SELECT COUNT(*) AS n FROM reminder_settings '
            "WHERE baby_id='$carmenId'")
        .get();
    expect(rows.first.data['n'], 0,
        reason: 'a new scope has no row — the default is resolved, not stored');

    await _settleTap(tester, findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle();
    final tile = find.text('Choose which reminders to show');
    await Scrollable.ensureVisible(tester.element(tile));
    await tester.pumpAndSettle();
    await _settleTap(tester, tile);
    await waitUntil(
        tester,
        'the reminder settings screen',
        () => find
            .widgetWithText(SwitchListTile, 'Vitamin D')
            .evaluate()
            .isNotEmpty);
    final vitD = find.widgetWithText(SwitchListTile, 'Vitamin D');
    final sw = find.descendant(of: vitD, matching: find.byType(Switch)).first;
    expect((sw.evaluate().single.widget as Switch).value, isFalse,
        reason: 'B6 — a baby created under 1.4.0 starts with Vitamin D off');
    await capture(tester, 'gate-v140-03-newbaby-vitd-off');
    print(
        '[GATE-MARKER] test2 done — host: `adb shell dumpsys alarm | grep -c mamadera` must be 0 (no opt-in yet)');
    print('[GATE] B6 new-baby PASS');
  });

  testWidgets('3a. Vitamin K one-shot: bob, opt-in, scheduled once',
      (tester) async {
    if (!_want('test3a')) return;
    WidgetsApp.debugAllowBannerOverride = false;
    await pumpMamadera(tester, useInMemoryDb: false);
    await tester.pumpAndSettle();
    await ensureHome(tester);

    // Switch to bob (birth 2026-10-20 ⇒ K at 2026-11-20 = tomorrow).
    await _settleTap(tester, find.text('carmen').first);
    await waitUntil(tester, 'the baby picker sheet',
        () => find.text('bob').evaluate().isNotEmpty);
    await _settleTap(tester, find.text('bob').last);
    await waitUntil(tester, 'the picker sheet to close (bob active)',
        () => find.text('bob').evaluate().length == 1);

    // Opt-in, on the screen.
    await _settleTap(tester, findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle();
    final tile = find.text('Choose which reminders to show');
    await Scrollable.ensureVisible(tester.element(tile));
    await tester.pumpAndSettle();
    await _settleTap(tester, tile);
    await tester.pumpAndSettle();
    // The notifications section sits at the bottom of the screen's ListView,
    // and a ListView never builds children below the cache extent — so on
    // the 4-inch screen the section's text is not in the tree until the list
    // is scrolled. Drag until it renders, then scroll it fully into view.
    final list = find.byType(ListView).first;
    for (var i = 0; i < 15; i++) {
      if (find.text('System notifications').evaluate().isNotEmpty) break;
      await tester.drag(list, const Offset(0, -450));
      await tester.pump(const Duration(milliseconds: 400));
    }
    final section = find.text('System notifications');
    await waitUntil(tester, 'the system notifications section',
        () => section.evaluate().isNotEmpty);
    await Scrollable.ensureVisible(tester.element(section));
    await tester.pumpAndSettle();
    final optIn =
        find.widgetWithText(SwitchListTile, 'Notify me when a reminder is due');
    final sw = find.descendant(of: optIn, matching: find.byType(Switch)).first;
    expect((sw.evaluate().single.widget as Switch).value, isFalse,
        reason: 'the seed never opted in');
    await tester.tap(sw);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // If the OS permission was not granted on the host, the switch reverts
    // and the denial hint appears — fail loudly instead of scheduling
    // nothing and calling it a pass.
    final swAfter =
        find.descendant(of: optIn, matching: find.byType(Switch)).first;
    expect((swAfter.evaluate().single.widget as Switch).value, isTrue,
        reason: 'opt-in stuck on — if it reverted, the POST_NOTIFICATIONS '
            'permission was not granted: adb shell pm grant '
            'com.pvjio.mamadera android.permission.POST_NOTIFICATIONS');

    // In-band OS plan evidence: when the test process exits, the plugin's
    // exit hook cancels this app's alarms, so a host-side `dumpsys alarm`
    // between legs only ever shows pi_cancelled ghosts. The plan is read
    // from the OS while the app is still alive.
    final plugin = FlutterLocalNotificationsPlugin();
    final pending = await plugin.pendingNotificationRequests();
    print('[GATE] pending OS requests after opt-in:\n    '
        '${pending.map((PendingNotificationRequest r) => '#${r.id} ${r.title} ${r.payload}').join('\n    ')}');

    final db = await _db(tester);
    final bobId = (await db
            .customSelect("SELECT id FROM baby_profiles WHERE name='bob'")
            .get())
        .single
        .data['id'] as String;
    final kRequests = pending
        .where((PendingNotificationRequest r) =>
            r.payload ==
            ReminderNotificationPayload(scope: bobId, itemId: 'vitamine_k')
                .encode())
        .toList();
    expect(kRequests, hasLength(1),
        reason: "bob's one-shot Vitamin K is armed exactly once (B33) — D6 "
            'schedules every baby, so the other scopes are in the plan too');
    print("[GATE] K-ARMED — bob's one-shot (birth + 1 month, at the global "
        "hour) is armed exactly once. D6 schedules every baby, so dave's "
        'due-now K and the daily items are in the plan too — the point of '
        'this leg is the one-shot entry itself.');
    await capture(tester, 'gate-v140-04-optin-on');
    print('[GATE] one-shot armed PASS');
  });

  testWidgets('3b. the dose settles the one-shot', (tester) async {
    if (!_want('test3b')) return;
    WidgetsApp.debugAllowBannerOverride = false;
    await pumpMamadera(tester, useInMemoryDb: false);
    await tester.pumpAndSettle();
    await ensureHome(tester);

    // bob is still the active baby (the choice persists in app state).
    expect(find.text('bob'), findsOneWidget,
        reason: 'bob is on the app bar — his scope is the one under test');

    // Record the dose through the real sante sheet.
    await _settleTap(tester, findByKey(TestKeys.trackSante));
    await waitUntil(tester, 'the health subtype sheet',
        () => find.text('Vitamin K').evaluate().isNotEmpty);
    await _settleTap(tester, find.text('Vitamin K').last);
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(ElevatedButton, 'Confirm');
    await waitUntil(tester, 'the sheet confirm button',
        () => confirm.evaluate().isNotEmpty);
    // The sheet is a SingleChildScrollView: on the 4-inch screen the action
    // row starts below the fold, and a tap aimed at an off-screen centre
    // lands on nothing. Scroll it into view, then tap with retries.
    for (var attempt = 1; attempt <= 5; attempt++) {
      await Scrollable.ensureVisible(tester.element(confirm.first));
      await tester.pumpAndSettle();
      await tester.tap(confirm.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      if (find.byType(Dialog).evaluate().isEmpty) break;
      print('[GATE] confirm tap attempt $attempt did not close the sheet');
    }
    await waitUntil(
        tester,
        'the sheet to close (dose recorded)',
        () =>
            find.byType(Dialog).evaluate().isEmpty &&
            find.text('Vitamin K').evaluate().isEmpty);
    print('[GATE] vitamin K dose recorded through the sante sheet');

    // The one-shot is settled: the row leaves Home permanently (a passed
    // one-shot stays due until completed; completion removes it).
    await waitUntil(tester, 'the Vitamin K row to leave Home',
        () => find.text('Vitamin K').evaluate().isEmpty);
    await capture(tester, 'gate-v140-05-after-dose');

    // The completion is a health event in the journal, scoped to bob.
    final db = await _db(tester);
    final bobId = (await db
            .customSelect("SELECT id FROM baby_profiles WHERE name='bob'")
            .get())
        .single
        .data['id'] as String;
    final doses = await db
        .customSelect('SELECT COUNT(*) AS n FROM tracking_events '
            "WHERE type='sante' AND subtype='vitamine_k' AND baby_id='$bobId'")
        .get();
    expect(doses.first.data['n'], 1,
        reason: 'the dose landed in the journal for bob');

    // K-SETTLED, in-band (see test3a for why the host dumpsys is ghosts-only):
    // bob's one-shot entry is gone from the OS plan. In production the
    // polling tick (reminder_notifier._tick) re-runs this same syncNow within
    // the poll interval — "completions and dismissals change the next due
    // instants"; the gate triggers the identical call directly so the leg
    // does not wait the interval out.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await container.read(reminderSyncNotifierProvider.notifier).syncNow();
    await tester.pumpAndSettle();

    final plugin = FlutterLocalNotificationsPlugin();
    final pendingAfter = await plugin.pendingNotificationRequests();
    print('[GATE] pending OS requests after the dose: '
        '${pendingAfter.map((PendingNotificationRequest r) => r.payload).join(' | ')}');
    expect(
        pendingAfter.where((PendingNotificationRequest r) =>
            r.payload ==
            ReminderNotificationPayload(scope: bobId, itemId: 'vitamine_k')
                .encode()),
        isEmpty,
        reason: 'K-SETTLED — the one-shot OS entry is gone');

    // Negative control: the diff removed the settled entry, not the whole
    // plan — dave's K is due now and never settled, so his entry survives.
    final daveId = (await db
            .customSelect("SELECT id FROM baby_profiles WHERE name='dave'")
            .get())
        .single
        .data['id'] as String;
    expect(
        pendingAfter.where((PendingNotificationRequest r) =>
            r.payload ==
            ReminderNotificationPayload(scope: daveId, itemId: 'vitamine_k')
                .encode()),
        isNotEmpty,
        reason: "dave's unsettled due-now K must still be scheduled (D6)");
    print('[GATE] one-shot settled PASS');
  });
}

Future<void> _settleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// `tester.pageBack` cannot reach the IME: unfocus first, then hide the
/// input channel explicitly (the seed file learned this the hard way).
Future<void> _hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await tester.pump();
}

/// Taps a dialog action button with keyboard-aware retries: a soft keyboard
/// still animating away eats the first tap aimed at the action row (the
/// same trap the seed file's tapSheetConfirmed documents for sheets).
Future<void> _tapDialogConfirmed(WidgetTester tester, String label) async {
  for (var attempt = 1; attempt <= 5; attempt++) {
    final f = find.widgetWithText(TextButton, label);
    if (f.evaluate().isEmpty) return; // closed between attempts
    await tester.tap(f.last);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await tester.pump();
    if (find.widgetWithText(TextButton, label).evaluate().isEmpty) return;
    print('[GATE] "$label" tap did not close the dialog (attempt $attempt) '
        '— closing keyboard, retrying');
    await _hideKeyboard(tester);
  }
  fail('"$label" was never confirmed');
}

int msLocal(int y, int m, int d, [int h = 12]) =>
    DateTime(y, m, d, h).millisecondsSinceEpoch;

extension _Count on String {
  int count(String needle) {
    var n = 0;
    var i = 0;
    while ((i = indexOf(needle, i)) != -1) {
      n++;
      i += needle.length;
    }
    return n;
  }
}

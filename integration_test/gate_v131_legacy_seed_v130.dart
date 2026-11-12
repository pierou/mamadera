// ignore_for_file: avoid_print
/// v1.3.1 release gate, part 1 — seed the device with data written by the
/// PREVIOUS release.
///
/// **Run this file from a worktree checked out at tag `v1.3.0`**, not from
/// the release branch — the point of the leg is that the bytes on disk are
/// written by 1.3.0's own code, so the harness must be 1.3.0's too:
///
/// ```bash
/// git worktree add /tmp/v130tree v1.3.0
/// cp integration_test/gate_v131_legacy_seed_v130.dart /tmp/v130tree/integration_test/
/// cd /tmp/v130tree && flutter pub get && flutter test integration_test/legacy_seed_v130.dart \
///   -d <device> --no-uninstall --dart-define=GATE_EXPORT_OUT=...   # then build the
///   # new build, `adb install -r` over it, and run gate_v131_upgrade.dart.
/// ```
///
/// Kept in the tree because the upgrade evidence quoted in the release PR was
/// produced by it, and the next release needs the same harness. Both sides of
/// the upgrade must be signed by the SAME key: the released APK is signed with
/// the production key, so a locally built artifact can only be installed over a
/// locally built old build (`install -r` across keys fails with
/// INSTALL_FAILED_UPDATE_INCOMPATIBLE, which is what the 2026-11-11 attempt hit
/// with the v1.3.0 GitHub asset).
///
/// Everything goes through the real UI on the on-device database: onboarding,
/// the feeding sheet, the sleep sheet, the weight sheet. The export runs
/// against the real share path, with a recorder that captures the exact JSON
/// the OS would have received.
///
/// The host then injects a duplicated `(baby_id, item_id)` pair into
/// `reminder_completions` — the journal shape the 1.3.0 importer refused
/// (BACKLOG B25) — and the file becomes the restore fixture for the new build.
///
/// ```bash
/// flutter test integration_test/legacy_seed_v130.dart -d <device> --no-uninstall \
///   --dart-define=GATE_EXPORT_OUT=/data/user/0/com.pvjio.mamadera/app_flutter/gate/v130-export.json
/// ```
library;

import 'dart:io' as io;

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'test_utils.dart';

bool _surfaceConverted = false;

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

Future<void> waitFor(WidgetTester tester, Finder finder,
    {String? reason}) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets, reason: reason);
}

/// Dismiss the on-screen keyboard, scroll the button to the middle of its
/// scrollable, tap the BUTTON (not the label) — on the 4.7-inch target a tap
/// aimed at the label, or made while the keyboard is up, is silently dropped.
Future<void> tapModalButton(WidgetTester tester, String label,
    {int tries = 3}) async {
  final btn = find.widgetWithText(ElevatedButton, label);
  for (var attempt = 1; attempt <= tries; attempt++) {
    if (btn.evaluate().isEmpty) return;
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(btn.last), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(btn.last);
    await tester.pumpAndSettle();
    if (find.text(label).evaluate().isEmpty) return;
    print('[GATE] tap on "$label" missed (attempt $attempt) — retrying');
  }
  fail('the "$label" button stayed on screen after $tries taps');
}

Future<int> eventCount(AppDatabase db, String type) async {
  final rows = await db.customSelect(
      'SELECT COUNT(*) AS n FROM tracking_events WHERE type = ?',
      variables: [Variable<String>(type)]).get();
  return (rows.single.data['n'] as num).toInt();
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => _surfaceConverted = false);

  testWidgets('1.3.0 seeds the device through its own UI, then exports',
      (tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    SharePlatform.instance = _StashingSharePlatform();
    await pumpMamadera(tester, useInMemoryDb: false, babyExistsOverride: false);
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final db = await container.read(databaseProvider.future);

    if (find.text('Nova').evaluate().isEmpty) {
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget,
          reason: 'a fresh database must raise the welcome sheet');
      await tester.enterText(nameField, 'Nova');
      await tester.pump();
      await tapModalButton(tester, 'Confirm');
      for (var i = 0;
          i < 30 && find.byType(TextField).evaluate().isNotEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      print('[GATE] v1.3.0: baby "Nova" created');

      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle();
      await tapModalButton(tester, 'Confirm');
      expect(await eventCount(db, 'miam'), greaterThanOrEqualTo(1),
          reason: 'the feeding must reach the 1.3.0 database');
      print('[GATE] v1.3.0: feeding recorded');

      await tester.tap(findByKey(TestKeys.trackDodo));
      await tester.pumpAndSettle();
      await tapModalButton(tester, 'Confirm');
      expect(await eventCount(db, 'dodo'), greaterThanOrEqualTo(1),
          reason: 'the sleep must reach the 1.3.0 database');
      print('[GATE] v1.3.0: sleep recorded');

      // Vitamin D: an event-settled routine, which is exactly the case B28
      // got wrong — logging it used to delete its own « last tracked » line.
      await tester.tap(findByKey(TestKeys.trackSante));
      await tester.pumpAndSettle();
      await waitFor(tester, find.text('Vitamin D'),
          reason: 'the 1.3.0 health sheet lists routines');
      final vitD = find.text('Vitamin D').last;
      await Scrollable.ensureVisible(tester.element(vitD), alignment: 0.4);
      await tester.pumpAndSettle();
      await tester.tap(vitD);
      await tester.pumpAndSettle();
      await tapModalButton(tester, 'Confirm');
      expect(await eventCount(db, 'sante'), greaterThanOrEqualTo(1),
          reason: 'the routine must reach the 1.3.0 database');
      print('[GATE] v1.3.0: Vitamin D recorded');

      final poids = find.byKey(const ValueKey('measure-poids'));
      await Scrollable.ensureVisible(tester.element(poids), alignment: 0.75);
      await tester.pumpAndSettle();
      await tester.tap(poids);
      await waitFor(tester, find.byType(TextField),
          reason: 'the weight sheet must render its fields');
      await tester.enterText(find.byType(TextField).first, '3900');
      await tester.pumpAndSettle();
      await tapModalButton(tester, 'Save');
      print('[GATE] v1.3.0: weight 3900 g recorded');
    } else {
      print('[GATE] v1.3.0: already seeded — skipping entry steps');
    }

    // What the OLD build shows with events recorded and reminders settled:
    // the B28 premise. This is the pre-upgrade photograph.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final lines = find.textContaining('Last tracked').evaluate().length;
    print('[GATE] v1.3.0 « Last tracked » lines with settled events: $lines '
        '(0 is the reported B28 defect — the line was reminder-fed)');
    await capture(tester, 'gate-v130-home');

    await tester.tap(findByKey(TestKeys.historyTab));
    await tester.pumpAndSettle();
    await capture(tester, 'gate-v130-history');
    await tester.tap(findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle();
    await capture(tester, 'gate-v130-menu');

    await tester.tap(findByKey(TestKeys.homeTab));
    await tester.pumpAndSettle();
    await tester.tap(findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle();
    final exportItem = find.text('Export my data');
    await tester.ensureVisible(exportItem);
    await tester.pumpAndSettle();
    await tester.tap(exportItem);
    await tester.pumpAndSettle();
    await tapModalButton(tester, 'Export');

    final stash = SharePlatform.instance;
    final json = stash is _StashingSharePlatform ? stash.content : null;
    expect(json, isNotNull, reason: 'the share step must have read the file');
    expect(json, contains('"exportFormatVersion": 4'));
    expect(json, contains('"Nova"'));
    print('[GATE] v1.3.0 export captured (${json!.length} chars)');

    const out = String.fromEnvironment('GATE_EXPORT_OUT');
    if (out.isNotEmpty) {
      await io.File(out).writeAsString(json);
      print('[GATE] legacy export written to $out');
    }
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['legacyExport'] = json;
    print('[GATE] LEGACY SEED PASS — data written and exported by 1.3.0');
  });
}

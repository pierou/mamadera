// ignore_for_file: avoid_print
/// B31 release gate — the lost active baby profile self-heals on a device.
///
/// Seeds the **exact** broken state the old delete-then-switch flow used to
/// commit (profiles exist, no row claims active), launches the app against
/// the file-backed database, and verifies:
///
/// 1. the menu still lists every baby;
/// 2. the reminder settings screen resolves the active baby — four per-baby
///    presets instead of the two-item profileless fallback the broken state
///    used to render;
/// 3. the promotion is persisted on the oldest profile by `(birth_date, id)`;
/// 4. deleting the active baby through the real UI leaves a committed state
///    with exactly one active row (the survivor) — the kill-in-the-gap is
///    closed at the source.
///
/// The test prints `GATE-SHOT: <screen>` markers and holds the screen stable
/// for a while after each marker; the host captures the release-gate
/// screenshots with `adb exec-out screencap -p` during those windows:
///
/// ```bash
/// flutter drive \
///   --target=integration_test/gate_b31_active_profile_selfheal.dart \
///   --driver=test_driver/integration_test.dart \
///   -d <emulator>
/// ```
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/data/local/database.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a broken state heals on launch and delete closes the gap',
      (tester) async {
    final db = await createAppDatabase();

    // ── Step 0: the exact broken state, on the file-backed database ──
    for (final leftover in await db.getAllBabyProfiles()) {
      await db.deleteBabyProfile(leftover.id);
    }
    await db.insertBabyProfile(BabyProfilesCompanion(
      id: const Value('gate-luna'),
      name: const Value('Luna'),
      birthDate: Value(DateTime(2026, 3, 15).millisecondsSinceEpoch),
      isActive: const Value(false),
    ));
    await db.insertBabyProfile(BabyProfilesCompanion(
      id: const Value('gate-max'),
      name: const Value('Max'),
      birthDate: Value(DateTime(2026, 7, 1).millisecondsSinceEpoch),
      isActive: const Value(false),
    ));
    // Precondition check on the RAW table: getActiveBabyProfile would heal
    // the state on read, which is exactly the point of the gate.
    final seeded = await db.getAllBabyProfiles();
    expect(seeded, hasLength(2));
    expect(seeded.every((p) => !p.isActive), isTrue,
        reason: 'precondition — profiles exist, none claims active');

    // ── Step 1: launch the app against the real database ──
    await pumpMamadera(tester, useInMemoryDb: false, localeCode: 'en');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Both babies are still listed — nothing was invented or hidden.
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);

    // Stable window for the gate screenshot of the menu (baby section).
    print('GATE-SHOT: menu');
    await tester.pump(const Duration(seconds: 15));

    // ── Step 2: reminder settings resolves the active baby ──
    final remindersTile = find.text('Choose which reminders to show');
    await tester.scrollUntilVisible(remindersTile, 80);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(remindersTile);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Reminders'), findsOneWidget,
        reason: 'on the reminder settings screen');

    // The broken state used to render the two-item profileless fallback
    // (Vitamin D + Vitamin K). The healed state lists the four per-baby
    // presets under their full care names.
    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('Vitamin K'), findsOneWidget);
    expect(find.text('Eye Cleaning'), findsOneWidget);
    expect(find.text('Face Cleaning'), findsOneWidget);

    // Stable window for the gate screenshot of the reminder settings.
    print('GATE-SHOT: reminder-settings');
    await tester.pump(const Duration(seconds: 15));

    // The promotion is persisted on the oldest profile by birth date.
    final active = await db.getActiveBabyProfile();
    expect(active, isNotNull, reason: 'self-heal promoted a profile');
    expect(active!.id, equals('gate-luna'),
        reason: 'oldest by (birth_date, id) wins');

    // ── Step 3: delete the active baby through the real UI ──
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(findByKey(TestKeys.menuTab));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Open the popup menu on the first row (Luna, the active baby) and tap
    // Delete — the menu may still be scrolled down from the settings tile.
    await tester.scrollUntilVisible(find.text('Luna'), 80);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Confirmation dialog: Cancel + Delete — confirm with the last one.
    final dialogButtons = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextButton));
    await tester.tap(dialogButtons.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Luna is gone, Max remains…
    expect(find.text('Luna'), findsNothing);
    expect(find.text('Max'), findsOneWidget);

    // …and the committed state has exactly one active row: the survivor.
    final afterDelete = await db.getAllBabyProfiles();
    expect(afterDelete, hasLength(1));
    expect(afterDelete.single.id, equals('gate-max'));
    expect(
      afterDelete.single.isActive,
      isTrue,
      reason: 'the survivor was re-activated inside the delete transaction',
    );
  });
}

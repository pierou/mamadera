// ignore_for_file: avoid_print
/// Release gate — B28: the « last tracked » line is event history.
///
/// The reported symptom was that the line showed under **Health only**. It was
/// not a styling bug: the line was read out of `reminderNotifierProvider`,
/// which answers "what is overdue right now" — so a type whose reminder had
/// been settled (which is exactly what logging a feeding does, since
/// `miam`/`caca`/`dodo` reminders are settled by the events themselves) lost its
/// line, while the hand-ticked health routines kept theirs.
///
/// This leg seeds one event per type for one baby, with four different ages,
/// and requires four lines on screen at once — on the smallest target, where
/// four dynamic lines are a new shape for the cell (the old pill cap was the
/// reason the cell was defensive about text).
///
/// ## Run
///
/// ```bash
/// flutter test integration_test/gate_v131_last_tracked_lines.dart \
///   --no-uninstall -d emulator-5554
/// ```
///
/// Captures land in the app sandbox; extract one with
/// `adb -s emulator-5554 exec-out run-as com.pvjio.mamadera cat
/// app_flutter/gate/NAME.png > NAME.png`.
library;

import 'dart:io' as io;

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/home/presentation/providers/last_event_by_type_provider.dart';
import 'package:mamadera/features/home/presentation/widgets/onboarding_dialog.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
import 'package:path_provider/path_provider.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _surfaceConverted = false);

  testWidgets('every tracked type shows its own line', (tester) async {
    await pumpMamadera(tester, babyExistsOverride: false);
    await tester.pumpAndSettle();

    // A first launch has no baby, so the sheet opens; the parent below is a
    // returning one whose database is already populated, so close it.
    if (find.byType(OnboardingDialog).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }

    final container = ProviderScope.containerOf(
        tester.element(find.byType(TrackButton).first));
    final db = await container.read(databaseProvider.future);

    final now = DateTime.now();
    await db.into(db.babyProfiles).insert(BabyProfilesCompanion.insert(
          id: 'baby_gate',
          name: 'Nala',
          birthDate:
              now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
        ));
    for (final (type, age) in [
      ('miam', const Duration(minutes: 40)),
      ('dodo', const Duration(hours: 3)),
      ('caca', const Duration(days: 1, hours: 2)),
      ('sante', const Duration(days: 5)),
    ]) {
      await db.insertEvent(TrackingEventsCompanion(
        unit: Value(type == 'miam'
            ? 'ml'
            : type == 'dodo'
                ? 'min'
                : 'g'),
        type: Value(type),
        timestamp: Value(now.subtract(age)),
        babyId: const Value('baby_gate'),
      ));
    }
    container
      ..invalidate(activeBabyProvider)
      ..invalidate(lastEventByTypeProvider);
    await tester.pumpAndSettle();

    // The header proves the seed is the baby on screen: without it, four lines
    // could be scored from unowned rows and prove nothing about scoping.
    expect(find.text('Nala'), findsWidgets);

    final lines = tester
        .widgetList<Text>(find.textContaining('Last tracked'))
        .map((t) => t.data)
        .toList();
    print('[GATE] last-tracked lines on screen: $lines');
    expect(lines, hasLength(4),
        reason: 'all four types have an event, so all four must speak — the '
            'reported bug was that only Health did');

    // The ages differ, so one line cannot be the same value four times.
    expect(lines.toSet(), hasLength(4),
        reason: 'one line per distinct age: $lines');

    expect(find.byType(OnboardingDialog), findsNothing);
    await capture(tester, 'v131-b28-four-lines');

    // And a type with no event still shows nothing rather than an invented
    // date: wipe the health events and its line must disappear.
    await (db.delete(db.trackingEvents)..where((t) => t.type.equals('sante')))
        .go();
    container.invalidate(lastEventByTypeProvider);
    await tester.pumpAndSettle();

    final after =
        tester.widgetList<Text>(find.textContaining('Last tracked')).length;
    print('[GATE] lines after deleting the health events: $after');
    expect(after, 3);
    await capture(tester, 'v131-b28-three-lines');
  });
}

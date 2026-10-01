// ignore_for_file: avoid_print
/// App Store screenshot driver: captures the six store screens in portrait
/// and landscape from the seeded driver target (`lib/asc_driver_main.dart`).
///
/// Raw PNGs are written to `screenshots/ios/asc/raw/` at the simulator's
/// native resolution (iPhone 17: 1206×2622 / 2622×1206); a separate step
/// resizes them to the exact ASC dimensions
/// (1242×2688 / 2688×1242 and 1284×2778 / 2778×1284).
///
/// Run with:
/// ```bash
/// flutter drive \
///   --target=lib/asc_driver_main.dart \
///   --driver=test_driver/asc_screenshots.dart \
///   -d "iPhone 17"
/// ```
library;

import 'dart:io' as io;

import 'package:flutter_driver/flutter_driver.dart';

// Overridable via the ASC_RAW_DIR host env var so the same driver can feed
// other device pipelines (e.g. the iPad run writes to
// screenshots/ios/asc-ipad/raw-11 / raw-13 without touching iPhone raws).
final _dir = io.Platform.environment['ASC_RAW_DIR'] ?? 'screenshots/ios/asc/raw';

// Semantic keys (must match lib/core/router.dart + home screen ValueKeys).
const _homeTab = 'home-tab';
const _historyTab = 'history-tab';
const _menuTab = 'menu-tab';
const _trackMiam = 'track-miam';
const _trackDodo = 'track-dodo';
const _trackCaca = 'track-caca';

Future<void> sleep(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

Future<void> main() async {
  io.Directory(_dir).createSync(recursive: true);
  final driver = await FlutterDriver.connect();
  try {
    print('[SETUP] Waiting for home tab...');
    await driver.waitFor(
      find.byValueKey(_homeTab),
      timeout: const Duration(seconds: 40),
    );
    print('[SETUP] Home tab found.');

    // ---- Portrait set ----
    await capture(driver, 'home');
    await sheetShot(driver, _trackMiam, 'feeding', landscape: false,
        dismissAnchor: "Suivre l'Alimentation");
    await sheetShot(driver, _trackDodo, 'sleep', landscape: false,
        dismissAnchor: 'Durée du sommeil');
    await sheetShot(driver, _trackCaca, 'diaper', landscape: false,
        dismissAnchor: 'Type de selle');
    await tabShot(driver, _historyTab, 'history');
    await tabShot(driver, _menuTab, 'menu');

    // ---- Landscape set ----
    // Skipped when ASC_LANDSCAPE=0: iPadOS ignores
    // SystemChrome.setPreferredOrientations (see asc-ipad pipeline), so the
    // iPad run captures portrait only.
    if (io.Platform.environment['ASC_LANDSCAPE'] != '0') {
      print('[ROTATE] -> landscape');
      await driver.requestData('ascRotate:landscape');
      await waitOrientation(driver, landscape: true);

      // The portrait set ends on the menu tab: return home first.
      await driver.tap(find.byValueKey(_homeTab),
          timeout: const Duration(seconds: 10));
      await sleep(900);
      await capture(driver, 'home_landscape');
      await sheetShot(driver, _trackMiam, 'feeding_landscape', landscape: true,
          dismissAnchor: "Suivre l'Alimentation");
      await sheetShot(driver, _trackDodo, 'sleep_landscape', landscape: true,
          dismissAnchor: 'Durée du sommeil');
      await sheetShot(driver, _trackCaca, 'diaper_landscape', landscape: true,
          dismissAnchor: 'Type de selle');
      await tabShot(driver, _historyTab, 'history_landscape');
      await tabShot(driver, _menuTab, 'menu_landscape');

      // Restore portrait for the next run.
      print('[ROTATE] -> portrait');
      await driver.requestData('ascRotate:portrait');
      await waitOrientation(driver, landscape: false);
    } else {
      print('[SKIP] Landscape set (ASC_LANDSCAPE=0)');
    }
  } finally {
    await driver.close();
  }
  print('[DONE] Screenshots in $_dir/');
}

/// Captures [name] to `$_dir/<name>.png`.
Future<void> capture(FlutterDriver driver, String name) async {
  await sleep(600); // let animations settle
  final bytes = await driver.screenshot();
  await io.File('$_dir/$name.png').writeAsBytes(bytes);
  final (w, h) = _pngSize(bytes);
  print('[SAVED] $name.png (${bytes.length} bytes, ${w}x$h)');
}

/// Taps the tracked-event button on Home, captures the opened bottom sheet,
/// then dismisses it via its "Annuler" (Cancel) button.
Future<void> sheetShot(
  FlutterDriver driver,
  String trackKey,
  String name, {
  required bool landscape,
  required String dismissAnchor,
}) async {
  await driver.tap(find.byValueKey(_homeTab), timeout: const Duration(seconds: 10));
  await sleep(900);
  final button = find.byValueKey(trackKey);
  await driver.waitFor(button, timeout: const Duration(seconds: 10));
  if (landscape) {
    // The 2×2 square grid overflows the short landscape viewport: row 2
    // (Dodo/Caca) sits below the fold. Scroll the grid until the button is
    // actually tappable (waitForTappable checks hit-testability, unlike
    // waitFor which only checks existence).
    try {
      await driver.waitForTappable(button, timeout: const Duration(seconds: 2));
    } on Object {
      // Scrollable.ensureVisible on the app side: finds the scrollable
      // ancestor of the button itself, so no direction math and no
      // ambiguous byType('Scrollable') finder needed.
      await driver.scrollIntoView(button, timeout: const Duration(seconds: 10));
      await driver.waitForTappable(button, timeout: const Duration(seconds: 5));
      await sleep(400);
    }
  }
  await driver.tap(button, timeout: const Duration(seconds: 10));
  await sleep(1500); // sheet slide-in + field layout
  await capture(driver, name);
  // Dismiss: tap the sheet's cancel button ("Annuler" — locale is pinned to
  // French by the driver target). Never tap the nav tabs while the sheet is
  // open: driver taps wait for the finder to be hit-testable, and the tab is
  // covered by the sheet's barrier forever.
  // In landscape the sheet content overflows the short viewport, so the
  // button may sit below the fold inside the sheet's own scroll view: scroll
  // the sheet content down using its (always visible) title as the drag
  // anchor, but only when the button is actually not tappable.
  try {
    await driver.waitForTappable(find.text('Annuler'),
        timeout: const Duration(seconds: 2));
  } on Object {
    // "Annuler" sits below the fold inside the sheet's scroll view:
    // Scrollable.ensureVisible scrolls the sheet to it.
    await driver.scrollIntoView(find.text('Annuler'),
        timeout: const Duration(seconds: 10));
    await driver.waitForTappable(find.text('Annuler'),
        timeout: const Duration(seconds: 5));
    await sleep(400);
  }
  await driver.tap(find.text('Annuler'), timeout: const Duration(seconds: 10));
  await sleep(900);
  await driver.waitFor(find.byValueKey(_trackMiam),
      timeout: const Duration(seconds: 10)); // sheet is gone, home grid back
}

Future<void> tabShot(FlutterDriver driver, String tabKey, String name) async {
  await driver.tap(find.byValueKey(tabKey), timeout: const Duration(seconds: 10));
  await sleep(900);
  await capture(driver, name);
}

/// Rotates and polls screenshots until the requested orientation is active.
Future<void> waitOrientation(FlutterDriver driver, {required bool landscape}) async {
  for (var i = 0; i < 40; i++) {
    final bytes = await driver.screenshot();
    final (w, h) = _pngSize(bytes);
    if ((w > h) == landscape) {
      print('[ORIENT] ${landscape ? 'landscape' : 'portrait'} confirmed (${w}x$h)');
      return;
    }
    await sleep(500);
  }
  throw StateError('Orientation did not switch to '
      '${landscape ? 'landscape' : 'portrait'} within 20s');
}

/// Decodes the PNG header (IHDR) width/height from raw bytes.
(int, int) _pngSize(List<int> bytes) {
  if (bytes.length < 24) {
    throw StateError('Screenshot too small to be a PNG (${bytes.length} bytes)');
  }
  int be32(int offset) =>
      (bytes[offset] << 24) | (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) | bytes[offset + 3];
  return (be32(16), be32(20));
}

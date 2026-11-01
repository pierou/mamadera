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

/// Locale of this run — **must** be the same `--dart-define=APP_LOCALE=<code>`
/// the target (`lib/asc_driver_main.dart`) pins, default `fr`.
///
/// Every label the driver taps is resolved from it instead of being written as a
/// literal. The hardcoded `'Croissance'` / `'Annuler'` / `'Retour'` this file used
/// to carry are exactly what broke the first `fr`-only assumption: an `en` or `es`
/// run cannot find a tile whose label it guessed wrong. The Android pipeline hit the
/// same wall on 2026-10-18 (`scrollUntilVisible`, tile « Croissance »).
///
/// **Read the host environment first.** `--dart-define` is handed to the *target
/// app*; it is not injected into the driver script, which `flutter drive` runs as a
/// plain `dart` process. So `String.fromEnvironment` here silently stayed at its
/// default `fr` on every `es` and `en` run: the app rendered Spanish, the driver
/// looked for « Annuler », and `scrollIntoView` timed out two screenshots in —
/// leaving `raw/` with one Spanish frame and five French ones, which
/// `postprocess.sh` then resized and renamed as if the run had succeeded. Measured
/// 2026-11-01. Invoke it as:
///
///     APP_LOCALE=es flutter drive --target=lib/asc_driver_main.dart \
///       --driver=test_driver/asc_screenshots.dart -d "iPhone 17" \
///       --dart-define=APP_LOCALE=es
///
/// Both channels: env for this script, dart-define for the app. A disagreement
/// between the two is a wrong run, so it throws instead of shipping mixed frames.
final String _localeCode = _resolveLocale();

String _resolveLocale() {
  final env = io.Platform.environment['APP_LOCALE'];
  const fromDefine = String.fromEnvironment('APP_LOCALE', defaultValue: '');
  if (env != null && fromDefine.isNotEmpty && env != fromDefine) {
    throw StateError('APP_LOCALE mismatch: driver env=$env, app --dart-define=$fromDefine');
  }
  return env ?? (fromDefine.isNotEmpty ? fromDefine : 'fr');
}

/// App strings, in the locale the target renders. `cancel` dismisses every sheet.
///
/// **Plain maps, not `lookupAppLocalizations`.** A driver script is compiled by `dart` on the
/// host (`flutter drive` runs it as `dart test_driver/<file>.dart`), where `dart:ui` does not
/// exist and `app_localizations.dart` pulls in `flutter/material.dart`. Importing either made
/// the CFE die inside the FFI use-site transformer — `type 'InvalidType' is not a subtype of
/// type 'FunctionType' in type cast` — which is what broke every iOS capture run since
/// `9420097` (2026-10-18); the raws on disk predate that commit. Values read from
/// `lib/l10n/app_<locale>.arb` on 2026-11-01, not guessed — the same convention as
/// [_backTooltipByLocale] below, whose comment already says the driver cannot reach the delegate.
const _cancelByLocale = {'fr': 'Annuler', 'es': 'Cancelar', 'en': 'Cancel'};
const _growthTileByLocale = {'fr': 'Croissance', 'es': 'Crecimiento', 'en': 'Growth'};

String get _cancel => _cancelByLocale[_localeCode] ?? 'Cancel';

/// `backButtonTooltip` of the AppBar back button, from **GlobalMaterialLocalizations**
/// (read from the SDK's `material_{fr,es,en}.arb`, 2026-10-18 — not guessed). The
/// driver cannot reach that delegate, so the three values live here; if the app ever
/// registers a different delegate, this map is the thing that breaks.
const _backTooltipByLocale = {'fr': 'Retour', 'es': 'Atrás', 'en': 'Back'};

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

/// Tile that opens `/growth` — the menu tile carries no ValueKey
/// (`menu_screen.dart` navigates by `context.push('/growth')`), so the driver
/// targets it by its label, in the locale of this run.
///
/// The label appears TWICE on the menu (section header at `menu_screen.dart:101`
/// and tile title at `:109`), and `scrollIntoView` throws `Bad state: Too many
/// elements` on an ambiguous finder — so the match is scoped to the ListTile.
final _growthTile = find.descendant(
  of: find.byType('ListTile'),
  matching: find.text(_growthTileByLocale[_localeCode] ?? 'Growth'),
);

/// Tooltip of the AppBar back button — localized by GlobalMaterialLocalizations
/// (`main.dart` registers the delegate, `fr` is supported).
// `final`, not `const`: a map lookup is not a constant expression.
final _backTooltip = _backTooltipByLocale[_localeCode] ?? 'Back';

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
    // v1.2.0 — last of the portrait set: `/growth` is a pushed route with no
    // bottom nav, so it is opened from the menu we are already on and closed
    // with the AppBar back button before anything else is tapped.
    await growthShot(driver, 'growth');

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
      await growthShot(driver, 'growth_landscape');

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
/// then dismisses it via its cancel button (`_cancel`, locale-aware).
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
  // Dismiss: tap the sheet's cancel button, resolved in the locale of this run. Never tap the nav tabs while the sheet is
  // open: driver taps wait for the finder to be hit-testable, and the tab is
  // covered by the sheet's barrier forever.
  // In landscape the sheet content overflows the short viewport, so the
  // button may sit below the fold inside the sheet's own scroll view: scroll
  // the sheet content down using its (always visible) title as the drag
  // anchor, but only when the button is actually not tappable.
  try {
    await driver.waitForTappable(find.text(_cancel),
        timeout: const Duration(seconds: 2));
  } on Object {
    // The cancel button sits below the fold inside the sheet's scroll view:
    // Scrollable.ensureVisible scrolls the sheet to it.
    await driver.scrollIntoView(find.text(_cancel),
        timeout: const Duration(seconds: 10));
    await driver.waitForTappable(find.text(_cancel),
        timeout: const Duration(seconds: 5));
    await sleep(400);
  }
  await driver.tap(find.text(_cancel), timeout: const Duration(seconds: 10));
  await sleep(900);
  await driver.waitFor(find.byValueKey(_trackMiam),
      timeout: const Duration(seconds: 10)); // sheet is gone, home grid back
}

Future<void> tabShot(FlutterDriver driver, String tabKey, String name) async {
  await driver.tap(find.byValueKey(tabKey), timeout: const Duration(seconds: 10));
  await sleep(900);
  await capture(driver, name);
}

/// Ouvre `/growth` depuis le menu (on y est déjà), capture, puis revient à la
/// coque. La tuile peut être sous le pli du menu : `scrollIntoView` la ramène
/// avant le tap, comme pour les feuilles en paysage.
Future<void> growthShot(FlutterDriver driver, String name) async {
  final tile = _growthTile;
  await driver.tap(find.byValueKey(_menuTab), timeout: const Duration(seconds: 10));
  await sleep(900);
  try {
    await driver.waitForTappable(tile, timeout: const Duration(seconds: 3));
  } on Object {
    await driver.scrollIntoView(tile, timeout: const Duration(seconds: 10));
    await driver.waitForTappable(tile, timeout: const Duration(seconds: 5));
    await sleep(400);
  }
  await driver.tap(tile, timeout: const Duration(seconds: 10));
  // Les valeurs chiffrées arrivent par le notifier async (repo + déchiffrement).
  await sleep(1800);
  await capture(driver, name);
  await backFromGrowth(driver);
}

/// Ferme `/growth` (route poussée, sans navigation basse) via le bouton de
/// retour de l'AppBar, et vérifie que la coque est revenue.
Future<void> backFromGrowth(FlutterDriver driver) async {
  await driver.tap(find.byTooltip(_backTooltip), timeout: const Duration(seconds: 10));
  await sleep(900);
  await driver.waitFor(find.byValueKey(_menuTab),
      timeout: const Duration(seconds: 10));
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

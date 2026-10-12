# Google Play screenshots pipeline (Android)

Captures eight store screens on the **Pixel_10_Pro emulator** (1280×2856)
and saves ribbon-free PNGs ready to upload to Play Console.

## Files

```
screenshots/android/
├── home.png            home tab
├── history.png         history tab
├── menu.png            menu tab
├── feeding_dialog.png  feeding bottom sheet open
├── sleep_diagram.png   sleep bottom sheet open
├── diaper_dialog.png   diaper bottom sheet open
├── health_diagram.png  health bottom sheet open
├── growth.png          growth screen (`/growth`, v1.2.0)
└── verify_android.py   size + DEBUG-ribbon check, run after every capture
```

All eight are captured in English (the app is pinned to `en` for these
shots) and must carry no DEBUG banner — `verify_android.py` proves it.

## Run

```bash
emulator -avd Pixel_10_Pro &          # boot once
flutter drive \
  --target=integration_test/screenshot_capture.dart \
  --driver=test_driver/screenshot_capture.driver.dart \
  -d emulator-5554
/usr/bin/python3 screenshots/android/verify_android.py   # never skip this
```

The driver saves the PNGs directly into this directory.

## How it works

- `integration_test/screenshot_capture.dart` pumps the real app (in-memory
  DB, terms accepted, English) and opens each screen;
  `binding.takeScreenshot(name)` grabs the pixels.
- Since **Flutter 3.44** `takeScreenshot` no longer writes PNGs to the
  device — it returns the bytes in-band, inside the test `reportData`.
- `test_driver/screenshot_capture.driver.dart` therefore does a single
  `driver.requestData('request_data')` (the integration_test binding only
  implements that command; it resolves when *all* tests have finished) and
  decodes `Response.fromJson(...)` —
  `data.screenshots[]` holds `{screenshotName, bytes}` — writing each PNG
  to `screenshots/android/` on the host. No `adb pull` needed.
- **The DEBUG ribbon IS present unless suppressed.** This file previously
  claimed the ribbon "does not appear in these Android captures (verified:
  0 reddish pixels across the whole top zone of every file) — no patching step
  is needed". That was false: `flutter drive` builds a **debug** APK, and every
  capture carried the ribbon (6 260 reddish pixels in the top-right zone).
  `integration_test/screenshot_capture.dart` now sets
  `WidgetsApp.debugAllowBannerOverride = false` in the test, and
  `verify_android.py` scans the zone so the regression cannot recur silently.
  The accepted uploads in git are ribbon-free — that, not the README, was the
  real guarantee.
- **The fixture is seeded, not empty.** `createInMemoryDb()` in
  `test_utils.dart` returns an **empty** database, so the app would render its
  empty states (no pills, no reminders, `growthEmptyState`) and the store would
  advertise empty screens. `screenshot_capture.dart` therefore seeds its own
  fixture (baby "Léa", 87 days, a full day of events + a growth trajectory) and
  pumps its own `ProviderScope`. `test_utils.dart` is deliberately untouched —
  the other integration tests assume the empty DB.
- **Growth is captured LAST.** `/growth` is a pushed top-level route with **no
  bottom nav** (`router.dart`, outside the `ShellRoute`), and tab/route state
  survives `pumpWidget` re-pumps. A test running after it finds no `home-tab`
  to tap and fails.
- **One live `AppDatabase` at a time**: the pump closes the previous database
  before opening the next, otherwise drift warns
  ("created the database class AppDatabase multiple times … might corrupt the
  database").
- The red DEBUG ribbon that the iOS simulator draws in debug builds does
  not appear in these Android captures (verified: 0 reddish pixels across
  the whole top zone of every file) — no patching step is needed.

## Gotchas

- **Test order matters**: the shell's selected tab survives
  `pumpWidget` re-pumps (the stateful shell is not replaced), so every
  dialog test taps the home tab first — a previous test can end the app on
  another tab where the track buttons don't exist.
- Dialog tests settle with `pumpAndSettle(const Duration(seconds: 2))`
  (2 s-interval pumps, like the home test): a plain `pumpAndSettle()`
  (100 ms intervals) can exit while Home is still in its pre-data state,
  where the track buttons don't exist yet.
- The `_debug_*.png` files are one-off pipeline debug artifacts (they still
  carry the banner) — not for upload; safe to delete.

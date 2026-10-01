# Google Play screenshots pipeline (Android)

Captures seven store screens on the **Pixel_10_Pro emulator** (1280×2856)
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
└── health_diagram.png  health bottom sheet open
```

All seven are captured in English (the app is pinned to `en` for these
shots) and carry no DEBUG banner.

## Run

```bash
emulator -avd Pixel_10_Pro &          # boot once
flutter drive \
  --target=integration_test/screenshot_capture.dart \
  --driver=test_driver/screenshot_capture.driver.dart \
  -d emulator-5554
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

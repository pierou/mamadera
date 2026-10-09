# ASC screenshots pipeline (iPad)

Captures the seven store screens on the **iPad Pro 11" and 13" (M5)
simulators** and produces the ribbon-free, ASC-exact-size PNGs ready to
upload to App Store Connect.

## Layout

```
screenshots/ios/asc-ipad/
├── raw-11/        11" Pro simulator captures, native 1668×2388 (RGBA)
├── raw-13/        13" Pro simulator captures, native 2064×2752 (RGBA)
├── 1668x2388/     ASC iPad 11" slot — portrait (6 PNGs)
├── 2048x2732/     ASC iPad 13" slot — portrait (6 PNGs)
└── postprocess_ipad.py   resize + alpha strip + verification
```

Seven screens per size: `home`, `feeding`, `sleep`, `diaper` (bottom sheets),
`history`, `menu`, `growth` (`/growth`, v1.2.0) — captured last, because
`/growth` is a pushed route with no bottom nav and closing it needs the AppBar
back button.

**Portrait only.** iPadOS ignores
`SystemChrome.setPreferredOrientations`, and this host has no
Simulator.app GUI to drive the *I/O ▸ Rotate* menu, so landscape iPad
captures are not part of the pipeline. The ASC iPad slots listed above are
portrait slot sizes.

## Step 1 — Capture

Same driver target/driver as the iPhone pipeline
(`lib/asc_driver_main.dart` + `test_driver/asc_screenshots.dart`), with two
environment flags:

```bash
# 11" Pro
ASC_RAW_DIR=screenshots/ios/asc-ipad/raw-11 ASC_LANDSCAPE=0 \
  flutter drive \
    --target=lib/asc_driver_main.dart \
    --driver=test_driver/asc_screenshots.dart \
    --dart-define=ASC_NO_BANNER=true \
    -d "iPad Pro 11-inch (M5)"

# 13" Pro
ASC_RAW_DIR=screenshots/ios/asc-ipad/raw-13 ASC_LANDSCAPE=0 \
  flutter drive \
    --target=lib/asc_driver_main.dart \
    --driver=test_driver/asc_screenshots.dart \
    --dart-define=ASC_NO_BANNER=true \
    -d "iPad Pro 13-inch (M5)"
```

- `ASC_NO_BANNER=true` disables the simulator DEBUG ribbon at app level
  (`WidgetsApp.debugAllowBannerOverride = false`), so the raw captures need
  no pixel patching — unlike the iPhone pipeline, which *keeps* the ribbon
  because `Patch.swift` depends on it.
- `ASC_LANDSCAPE=0` skips the landscape set (see above).
- `ASC_RAW_DIR` points the driver at the output directory for this run.

## Step 2 — Resize + verify

```bash
/usr/bin/python3 screenshots/ios/asc-ipad/postprocess_ipad.py
```

Produces and verifies **14** files (7 screens × 2 sizes).

For each raw capture: converts to 24-bit RGB (ASC rejects PNGs carrying an
alpha channel, even fully opaque ones), resizes with LANCZOS to the exact
slot size (the 13" raws 2064×2752 → 2048×2732), and writes the 12 output
files. Then verifies all 12: exact dimensions, `mode == RGB`, and a
red-pixel scan of the top-right banner zone returning 0.

## Verification criteria (must all pass)

- exact slot dimensions (1668×2388 / 2048×2732)
- no alpha channel (24-bit RGB)
- 0 reddish pixels in the ribbon zone (guard against a future run losing
  the `ASC_NO_BANNER` flag)

## Dependencies & gotchas

- Uses the *system* Python (`/usr/bin/python3`) with Pillow — no venv.
- Re-running the driver overwrites `raw-11/` / `raw-13/` and therefore
  everything downstream — re-run `postprocess_ipad.py` afterwards.
- The driver run seeds the same fixtures as the iPhone run (locale `fr`,
  baby "Léa", terms accepted), so the content matches
  [`../asc/`](../asc/README.md).
- Simulators must be booted first
  (`xcrun simctl boot "iPad Pro 11-inch (M5)"` etc.).

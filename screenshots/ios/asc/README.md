# ASC screenshots pipeline (iPhone)

Captures the seven store screens on the **iPhone 17 simulator** and produces the
ribbon-free, ASC-exact-size PNGs ready to upload to App Store Connect.

## Layout

```
screenshots/ios/asc/
├── raw/          simulator captures, native res (1206×2622 / 2622×1206)
├── clean/        ribbon removed, still native res
├── 1242x2688/    ASC iPhone 6.5" (3D Touch) — portrait
├── 2688x1242/    ASC iPhone 6.5" (3D Touch) — landscape
├── 1284x2778/    ASC iPhone 6.7" (3D Touch) — portrait
├── 2778x1284/    ASC iPhone 6.7" (3D Touch) — landscape
├── Patch.swift   pixel-level ribbon removal (Swift, CoreGraphics)
└── postprocess.sh orchestrates clean → resize
```

Six screens per orientation: `home`, `feeding`, `sleep`, `diaper` (bottom
sheets), `history`, `menu`. Seven since v1.2.0: `growth` (`/growth`) joins the
set — it is the release's headline feature, and a set that omits it advertises
the app without it.

The same driver target is also used for the iPad pipeline — see
[`../asc-ipad/README.md`](../asc-ipad/README.md).

## Step 1 — Capture

Seeded driver target (`lib/asc_driver_main.dart`) + host-side driver
(`test_driver/asc_screenshots.dart`, scrollIntoView-based navigation):

```bash
flutter drive \
  --target=lib/asc_driver_main.dart \
  --driver=test_driver/asc_screenshots.dart \
  -d "iPhone 17"
```

Writes `raw/<name>.png` and `raw/<name>_landscape.png`. The simulator's red
**DEBUG ribbon** (diagonal stripe, top-right corner) is present on every
capture and is removed in step 2.

## Step 2 — Clean + resize

```bash
bash screenshots/ios/asc/postprocess.sh
```

`Patch.swift` (top-down `NSBitmapImageRep` buffers — no manual row flipping):

- **portrait**: pastes the top 170 px status-bar strip from the accepted
  reference `screenshots/ios/home.png` (19:28 clock, Dynamic Island,
  signal/Wi-Fi/battery icons — verified 0 red pixels), then erases the
  diagonal stripe tail (rows 160–210, top-right) that extends below the
  pasted strip, with the flat `#2D2D2D` background.
- **landscape**: paints the top-right corner zone (x ≥ 2400, y < 320) with
  per-column colors sampled from y = 340 — that zone is the black screen
  corner curve, so the result is seamless.

Then `sips -z` resizes each clean PNG into the four ASC folders (exact
dimensions, verified at the end of the script).

## Verification

`postprocess.sh` validates every one of the 28 output files at the end:
exact dimensions **and** no alpha channel — `sips -g hasAlpha` must be
`no` for all of them, and the count must be 28. **This check only began
working in this campaign**: the validation loop iterated the DIM array, which
the script never defined, so it examined zero files and printed its OK line
unconditionally. DIM is now populated and the count asserted, and the expected
size is compared against the folder *name* (`${d##*/}`) — comparing
`1242x2688` to the full path `screenshots/ios/asc/1242x2688` never matches,
so even a populated DIM would have failed every file.
App Store Connect rejects PNGs carrying an alpha
channel, even when fully opaque, so `Patch.swift` writes 24-bit RGB
(`samplesPerPixel: 3, hasAlpha: false`) rather than RGBA.

For the ribbon itself, a red-pixel scan of the ribbon zones must return 0:

- portrait: rows 0–210 → `0 reddish pixels`
- landscape: x ≥ 2350, rows 0–340 → `0 reddish pixels`

(Working scan: `swift` one-liner loading `NSBitmapImageRep`, test
`r > 100 && r > g + 30 && r > b + 30`.)

## Driver environment flags

`test_driver/asc_screenshots.dart` honors three host env vars (iPhone runs
use all defaults):

| Flag | Default | Effect |
|------|---------|--------|
| `ASC_RAW_DIR` | `screenshots/ios/asc/raw` | where the raw captures are written (the iPad pipeline redirects to `asc-ipad/raw-11` / `raw-13`) |
| `ASC_LANDSCAPE` | `1` | set to `0` to skip the landscape set (iPad runs — iPadOS ignores orientation locking) |
| `ASC_NO_BANNER` (dart-define) | off | set to `true` to suppress the DEBUG ribbon *at app level* (`debugAllowBannerOverride = false`); the iPhone pipeline deliberately keeps the ribbon because `Patch.swift` depends on it |

## Dependencies & gotchas

- **No associative arrays.** The resize loop switches on the folder name
  (`1242x2688|1284x2778`), not on a declared map: `/bin/bash` on macOS is
  **3.2.57**, which has no `declare -A` (`value too great for base`), while a
  brew bash on `PATH` is 5.x — so `./postprocess.sh` and `bash postprocess.sh`
  would not behave alike. Keep it portable.
- **The script resolves its own root** from its own location instead of a
  hardcoded `/Users/pvjacquier/DEV/mamadera`, so a campaign run from a git
  worktree writes into that worktree and not into the other checkout.
- **`/growth` is captured last in each orientation set**: a pushed route with
  no bottom nav, opened from the menu and closed with the AppBar back button
  (`find.byTooltip('Retour')`, localized by `GlobalMaterialLocalizations`). Its
  menu tile label doubles as the section header, so the tap finder is scoped
  with `find.descendant(of: find.byType('ListTile'), ...)` — an ambiguous
  finder makes `scrollIntoView` throw `Bad state: Too many elements`.
- **Reference strip**: `screenshots/ios/home.png` must stay ribbon-free — it
  is the status-bar donor for every portrait capture.
- Raw captures need the simulator's *native* resolution (no Retina scaling
  surprises): iPhone 17 is 1206×2622 portrait / 2622×1206 landscape.
- Re-running the driver overwrites `raw/` and therefore everything downstream
  — re-run `postprocess.sh` afterwards.
- The landscape captures switch orientation via the driver; the home/menu
  landscape shots explicitly re-tap the home tab first (a portrait run ends
  on the menu tab).

## Store presentation / promo images

Separate from screenshots: `mamadera_banner_final.py` (Pillow, repo root)
generates the branded promo images in `store/`:

```
store/appstore_promo[_lang].png                       1280×800   web / App Store presence
store/appstore_promo_portrait_1242x2688[_lang].png    1242×2688  ASC portrait slot
store/appstore_promo_portrait_1284x2778[_lang].png    1284×2778  ASC portrait slot
store/appstore_promo_portrait_1668x2388[_lang].png    1668×2388  ASC iPad promo (11")
store/appstore_promo_portrait_2048x2732[_lang].png    2048×2732  ASC iPad promo (13")
store/play_feature_graphic[_lang].png                 1024×500   Google Play
```

`[_lang]` = unsuffixed fr, `_en`, `_es`. Regenerate with
`/usr/bin/python3 mamadera_banner_final.py`.

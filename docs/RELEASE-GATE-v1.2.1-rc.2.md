# Release gate pass — v1.2.1-rc.2 (2026-10-13/14)

Emulator release-gate per `AGENTS.md`, run on branch `develop` above `v1.2.1-rc.1` (`d100305`),
pubspec `1.2.1+10`. Debug builds both sides (release signing lives in CI).

## Contents of this rc versus rc.1

- **Removal of the B2 slider pair (coarse/fine)**: one full-range slider
  (min→max, fine step kept) on the 5 input surfaces; the ± buttons and the keyboard field
  keep the exact input. No column nor schema touched.
- **`HistoryTile`: date and time on two lines** — the English date with minutes
  (« 10/13/2026 9:32 PM ») overflowed 360 dp on Small_Phone.
- **`HistoryTile`: the nap reads as « Durée » alone** — the half-display of B13; the model
  still writes both columns (half-model = **B13**, post-v1.2.1).
- **Built-in gate**: `integration_test/pickers_gate_rc2.dart` — 8 cases, programmatic proofs
  printed in the log + captures written in the Documents of the app.

## 1. Migration path v11 → v12, on a device that had old data

**Small_Phone (emulator-5554, Android 17 / API 37, 720×1280):**

1. Fresh `adb install` of **v1.2.0** (worktree of the tag, debug) → onboarding, baby `Léa`,
   locale EN (`migration/01-v120-home-seeded.png`).
2. Seeded via the v1.2.0 UI: breastfeed **120 ml**, bottle **100 ml**, puree/solid
   **40 g**, nap — authentic v11 database (`PRAGMA user_version = 11`, no `unit` column).
3. `adb install -r` of **rc.2** (`1.2.1+10` debug) over it. Launch: dialog
   « What's New in Mamadera 1.2.1 » (`migration/02-rc2-patch-notes.png`).
4. Database extracted via `run-as` + host `sqlite3`: `user_version = **12**`; `unit` backfilled
   per the code (`app_db.dart` v11→v12, `6133af9`): `miam`/`natural` and `miam`/
   `artificial` → `ml` (column default), `miam`/`solid` → `g`, `dodo` → `min`,
   `caca`/`sante` → NULL (quantity is NULL there); `''` reminder rows (v1.2.0 sentinel)
   re-attributed to the single baby.
5. History after migration (`migration/03-v12-history-migre.png`): all the events
   visible with the right units (120 ml / 100 ml / 40 g).

**Honesty note**: the database verification is done on the v12 point build (data layer);
the two display fixes (`history_tile.dart`) landed after, on a layer that does
not touch schema nor migrations — `app_db.dart` (schemaVersion 12 + backfill) is byte-identical to
the one verified (last commit touching it: `6133af9`). The final build does render
schema v12 data: gate case 8, on both platforms (`08_historique.png`).

## 2. Gate — 8 cases, both platforms

Commands:

```
flutter test integration_test/pickers_gate_rc2.dart --no-uninstall -d emulator-5554
flutter test integration_test/pickers_gate_rc2.dart --no-uninstall -d <udid iPhone 17 Pro>
```

The raw logs (`gate-*.log`, in `docs/release-evidence/v1.2.1-rc.2/` on the
pass machine) are not committed (`*.log` is gitignored) — all the useful `[GATE]` and
`[CAPTURE]` lines are reproduced in the table below.

The captures are written **inside** the app sandbox (`Documents/gate/`) then extracted
(`adb exec-out run-as … cat` / simulator container copy) — hence `--no-uninstall`: a
plain `flutter test` uninstalls the app in teardown and takes the captures with it.

| # | Case | Proof `[GATE]` (identical on the 2 platforms) |
|---|-----|---------------------------------------------------|
| 1 | feed · new | 1 slider, min=0 max=120, divisions=120 |
| 2 | feed · edit (110 ml) | 1 slider, min=0 max=300, divisions=30, value=110 |
| 3 | nap · edit (95 min) | 1 slider, min=0 max=480, divisions=96, value=95 |
| 4 | weight · new | 1 slider, min=200 max=20000, divisions=1980, value=3500 |
| 5 | weight · edit (6,12 kg) | 1 slider, min=200 max=20000, divisions=1980, value=6120 |
| 6 | temperature · edit (37,2 °C) | 1 slider, min=33 max=42, divisions=90 (step 0,1), value=37.2 |
| 7 | manual entry + export | 22 min on the stepper → `miam/min/22.0` in the database AND in the export; export **format 3, schema 12, 5 events, 3 measurements** |
| 8 | history timeline | the nap reads as « Durée: 95 min » alone — no « Quantité », no exception, date/time on two lines |

**8/8 on Small_Phone** and **8/8 on iPhone 17 Pro** (FR locale in the gate; the EN
overflowing case is covered by the §5 widget regression test). Each case 1–6 additionally asserts
the absence of the B2 pair labels and `takeException() isNull`. Export documents pulled from the
sandbox: `export-small_phone.json`, `export-iphone17pro.json`.

## 3. Screenshots

- `screenshots/gate/android/` — 8 PNG, Small_Phone 720×1280.
- `screenshots/gate/ios/` — 8 PNG, iPhone 17 Pro 1206×2622.
- `migration/01..03` above.

## 4. Test suite

- `flutter analyze --fatal-infos --fatal-warnings`: **no issues**.
- `flutter test`: **1382 passing**.
- The overflow regression test (`history_tile_test.dart`) loads the **real Roboto** from the
  SDK cache: in widget test, the default font (Ahem) is square and ~2× wider than Roboto, which
  biases any dp reasoning. At 360×640 dp, EN locale, it expects `takeException() isNull`
  (a RenderFlex overflow is a debug exception). Proven guard: putting the date back on one
  line makes the test fail (overflow 9,5 px); restored, it passes.

## 5. Known gaps

- No iOS pass on a small screen: the smallest iOS (iPhone SE, 375 dp) is already wider than
  Small_Phone (360 dp); the overflow observed only existed at 360 dp.
- B13 (double write `quantity`/`duration` of sleep): display paid here, model deferred.

# BUG — Android never gets past the splash ( Small_Phone, 360×640 dp )

**Status:** **CLOSED — cause found: `android:theme="@style/LaunchTheme"` missing from the manifest.**
Neither a branch regression, nor a memory starvation. See `BUG-baby-name-under-status-bar.md`. · **Opened:** 2026-10-04 · **Platform:** Android ( two emulators )
**Build:** app-debug.apk of the branch `feat/v1.2.0-growth-and-baby-scoped-reminders` (95 835 048 bytes), installed with `install -r -g` → Success.

## Fact established, not assumed
- `am start -W -n com.pvjio.mamadera/.MainActivity` → **`Status: timeout`** : the activity never
  reports its first render. This is not a slow screen, it is a first render that does not arrive.
- The process **lives** (pid 6346), the Flutter engine starts, the surface is created at 720x1280, the
  viewport metrics are sent — then nothing but **"Skipped N frames"** (64, 116, 34, 57).
  No exception, no FATAL, no crash in the `crash` buffer.
- `FlutterRenderer: Width is zero. 0,0` appears twice at startup, before the surface creation.
- The same screens **succeed** under `flutter test integration_test` on this same emulator
  (rendering_validation_test.dart + feeding_tracking_flow_test.dart → all passed). So the widget
  tree knows how to render on this device: the difference is the launcher, not the rendering.
- `FlutterSecureStorage` completed its migration without error in a previous run
  (pid 4902, 17:52) — "Data migration completed successfully". The key-store is therefore not
  proven guilty; it is a suspect, not a verdict.
- iOS (iPhone 17, same build): no splash hang, all screens rendered and verified visually.

## What the pass missed
The manual walkthrough (bottle in ml, solid food in g, weight, exported JSON inspected) and the
consent screen really tapped were **not** done: the app does not leave the splash.

## Next diagnostics, in this order
1. `am start -W` on `Pixel_10_Pro` (same build): if it starts, the problem is tied to the
   Small_Phone configuration (resolution/density/API), not to the application code.
2. `logcat` filtered on the current pid, looking for the **last** line before the silence — to
   know whether the block is before `runApp`, in a plugin channel, or in the Dart main.
3. `flutter run --verbose -d emulator-5554`: the engine↔app handshake is visible, unlike
   `am start`.
4. Do not mask the symptom (no splash timeout, no `postFrameCallback` workaround)
   before having the cause: a splash that never ends on a shipped Android device is a
   lost user, not a cosmetic detail.

## Evidence preserved
`/tmp/sp.png` `/tmp/sp2.png` `/tmp/sp3.png` `/tmp/small_home.png` `/tmp/clean.png` (splash)
`/tmp/name.jpg` (iOS, home with the first name) · logs: `/tmp/integ.log` `/tmp/emu.log`

## Decisive A/B — it is our branch, not the emulator
Same emulator (emulator-5556, Pixel_10_Pro), same build machine, two APKs:

| build | \`am start -W\` | first render | screen seen |
|---|---|---|---|
| **v1.1.1 (main)** | **\`Status: ok\`** | **TotalTime 4021 ms** | Terms displayed, « I Accept » button rendered |
| **v1.2.0 (this branch)** | **\`Status: timeout\`** | never | native splash, light screen, no Flutter content |

Reproduced on \`Small_Phone\` (360×640 dp) **and** \`Pixel_10_Pro\`: this is not a screen
configuration. And the released version works on the same device: **it is a regression introduced
by this branch.**

## What this implies for the iOS verification (honesty, not a footnote)
The iOS pass was done with **a v10 database planted then migrated**: it proves the upgrade
v10 → v11 and the rendering, it does **not** prove a fresh \`onCreate\` v11 from a truly
fresh install. The very first iOS launch of v1.2.0 did display the terms — but the database is
in \`LazyDatabase\`: it is created only on first access, so after consent. **No
platform has yet exercised \`onCreate\` v11 to the end.** Suspect n°1 is therefore a blocking
initialization path before the first Android render — the main lead being the init of the
secure storage / the encryption service invoked at startup, which the integration tests
short-circuit.

## Next diagnostics, in this order
1. \`flutter run --verbose -d emulator-5556\` on the branch: the engine↔app handshake is visible,
   unlike \`am start\` — we will see where it blocks.
2. \`logcat\` filtered on the current pid, chase the **last** line before the silence, looking for
   \`FlutterSecureStorage\`, \`EncryptionService\`, \`drift\`, \`SQLite\`.
3. Bisect the branch: provisional \`git revert\` of M5 (growth module) then M1 (schema v11)
   on a throwaway branch, to bracket the regression by commit.
4. Verify a fresh \`onCreate\` v11 from a truly fresh install, on **both**
   platforms, before any PR opening.

Do not mask the symptom (no splash timeout, no \`postFrameCallback\` workaround)
before having the cause.

## Clarification of the method (my errors, noted so they are not repeated)
- The 708 Ko and 37 Ko captures were **the Android launcher**, not the app: the rich wallpaper
  explains the size. A capture is a fact only after having been looked at AND identified.
- `am start -W` → `Status: timeout` does not prove the process death: the app was alive and
  `topResumedActivity` was indeed `com.pvjio.mamadera/.MainActivity`.
- What is established, by convergence and not by a single signal: living process, activity in
  the foreground, empty `crash` buffer, no `AndroidRuntime`/`F DEBUG`/`MissingPlugin` line,
  and the screen stays the **native splash** (light background, while the verified app is dark) for
  minutes. Therefore: **the first Flutter render never replaces the splash.**
- The rule missing from the start: comparing capture sizes tells nothing. `dumpsys` to
  know which activity is in the foreground, then look at the image, then conclude.

## Closure — my conclusion was wrong
Another workstation (same repo, same HEAD `a112d5a`, same Flutter, identical emulator images) builds
the branch APK and runs:

| launch | result |
|---|---|
| `install -r` + prefs (consent accepted) | \`Status: ok\`, TotalTime **1756 ms** → **« Nouveautés de Mamadera 1.2.0 » screen rendered** |
| `pm clear` (fresh install, no consent) | \`Status: ok\`, TotalTime **1920 ms** → **Terms rendered, « I Accept » button** |
| tap « I Accept » | **home rendered** with the baby add dialog → **a fresh \`onCreate\` v11 runs without blocking** |
| \`logcat -s flutter:* ActivityManager:*\` for 60 s | no Flutter error, no \`MissingPlugin\`, no crash |

So there is **no code regression.** The cause is the original host: the memory limiter of the
Mac starves or restarts qemu. The symptoms fit exactly a starved render thread rather
than a blocked Dart — bursts of « Skipped N frames » (a true block before \`runApp\` would not produce
frame drops, there would be no frame loop at all), \`FlutterRenderer: Width is
zero\`, engine alive without first render, and integration tests green on this same emulator.

**What my A/B was not: an A/B.** Comparing 1.1.1 and 1.2.0 on the same emulator *after*
several heavy builds on a workstation already under memory pressure does not compare two builds, it
compares two states of the host. Lesson to keep: an A/B only holds if the environment is held
constant, and « ça marche sur une autre machine » is a datum that must come before a conclusion,
not after.

## What this closure validates in passing (and which had never been verified)
- **\`onCreate\` v11 from a truly fresh install**, executed and rendered — the point that the
  iOS pass (planted and migrated database) did not prove.
- **The 1.2.0 patch notes screen really rendered** on the device.

## Still open
The manual walkthrough (bottle in ml, breastfeed in min, solid food in g, weight) and the inspection of the exported JSON.

## Actual cause (found, not guessed)
`MainActivity` did not have `android:theme="@style/LaunchTheme"` (`Theme.Light.NoTitleBar`). Without it,
Android mounts a native ActionBar « Mamadera » and keeps the light theme by default: what I took
for a blocked splash was **the app rendered behind the native bar**, on a light background. The splash
hang belonged to the default theme. The first name, set at the top of the scrollable body, fell at
`y=32` — under the system bar.

**What I wrongly asserted, in order:** (1) « branch regression » — no, `main` has the
same manifest; (2) « the Mac's memory limiter starves qemu » — no longer, it was the theme;
(3) captures of the launcher and a capture behind the ActionBar read as evidence. Each
conclusion rested on a single signal instead of the convergence. The missing rule: identify
the screen (dumpsys + look) before interpreting, and do the A/B on **two machines** before
concluding a regression.

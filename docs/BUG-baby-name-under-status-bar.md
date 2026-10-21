# BUG — baby name is under the status bar (Android), invisible

**Status:** **FIXED** (manifest + name moved into the `AppBar`) · **Platform:** Android
**Root cause:** `android:theme="@style/LaunchTheme"` missing on `MainActivity`. `LaunchTheme` is
`Theme.Light.NoTitleBar`; without it, Android raises a native ActionBar « Mamadera » AND keeps the
light default theme. It is precisely this native bar and this light background seen in the captures — I
had taken them for the Flutter app bar and for a blocked splash.

**Provenance — verified:** `main` does not have this theme either (`git show main:android/app/src/main/AndroidManifest.xml`).
So **not a regression of this branch**: a defect **already present in the published version**,
latent since `892ff41` (2026-07-26), which the branch merely made visible by placing content
in that band. In production, the ghost ActionBar bar therefore exists today as well.

## Finding, verified by eye and by the dump
- Android capture (`/tmp/mamadera-path/step8-home-lea.png`): top bar « Mamadera », no
  trace of « Lea » above the grid.
- `uiautomator`: the « Lea / 4 months old » node is at **[337,32][383,72]** — i.e. inside the band of
  the system status bar, top right.
- On iOS the same spot lands right next to the clock (« 16:18 Léa ») and remains readable: the
  defect is Android, but the *placement* is already suspicious on both platforms.

## Mechanism, established (and not « probable »)
Without `LaunchTheme`, the activity receives a default theme **with** ActionBar: this bar occupies the
system band and pushes the Flutter content down, while the name was placed at the top of the
scrollable body → `y=32`, under the bar. iOS has no native ActionBar, so the same placement there
lands right next to the clock and remains readable. The « splash qui ne finit jamais » (splash that never ends) of
`BUG-android-splash-hang.md` was therefore **not** a memory famine: it was this same theme defect.

## What is NOT a bug (noted to avoid a false lead)
The third row (`Poids` / `Taille` / `Température` — weight / height / temperature) cut at mid-height is **normal**: the home
is a `SingleChildScrollView` and the content at the fold ends at the screen. Verified in the scroll
parent before concluding.

## To do
1. Place the name **inside** the `SafeArea` of the `Scaffold` — ideally as `title` of the `AppBar`
   (or inside the body, under the bar), never in the system band.
2. Re-verify on Android AND iOS, capture viewed, `dumpsys` confirming the activity in the foreground.
3. Test a long name (30+ characters) after repositioning — the current ellipsize is validated in
   test, not by eye on the new placement.

## Context
Discovered during the 2026-10-04 manual pass, which also validated: bottle 90 ml,
solid **40 g** (correct unit on screen), weight 3500 → **+10 = 3510 g**, temperature **37,4 °C**
exact (French comma accepted in fr locale, refused in en — behaviour to confirm as intended),
history with the right unit per line, complete export format 2 (7 sections, unique ids, notes and
weight value encrypted at rest, decrypted at export by design).

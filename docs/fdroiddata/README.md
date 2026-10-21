# F-Droid submission artifacts

This directory is the source of record for Mamadera's F-Droid presence. It
holds two kinds of files that live in *different* repositories:

| File | Goes to |
|------|---------|
| `com.pvjio.mamadera.yml` | fork of https://gitlab.com/fdroid/fdroiddata → `metadata/` |
| `disable-release-signing-guard.patch` | same fork → `patches/com.pvjio.mamadera/` |
| (the `metadata/` tree at the repo root) | **this repo** — F-Droid 2.0 fetches localized descriptions, changelogs and screenshots from the app's own source |

## One-time submission (status: prepared 2026-10-21, not yet submitted)

1. The stable tag `v1.1.0` was added at `3780a25` (the `v1.1.0-rc.2` commit —
   v1.1.0 shipped from that RC; there was never a stable tag). All six
   `Builds` entries reference pushed tags only.
2. Fork `fdroiddata` (GitLab), add `metadata/com.pvjio.mamadera.yml` and
   `patches/com.pvjio.mamadera/disable-release-signing-guard.patch`, open a MR
   labelled **"New App"**. The fdroiddata pipeline builds, scans and signs.
3. This app has **no network transport at all** (offline-only mandate), so the
   scanner should report no `AntiFeatures` and no licence hits beyond the
   FOSS Flutter/Dart ecosystem.

## Per-release upkeep (every stable tag)

- `Builds:` — new entry: `versionName`/`versionCode` straight from the tagged
  `pubspec.yaml` (`X.Y.Z+N`; N is monotonic across RCs — never renumber),
  `commit: vX.Y.Z`, same prebuild/build/output block, `patch:` if the
  signing guard exists in that tag (it does in every tag ≥ v1.1.0).
- `CurrentVersion` / `CurrentVersionCode` — bump to the new release.
- `metadata/<locale>/changelogs/<N>.txt` — one file per **versionCode**
  (not per versionName), ≤ 500 chars per locale; reuse the store "What's new"
  blocks (they are already counted against Play's 500-char limit).
- `metadata/<locale>/short_description.txt` (≤ 80 chars) and
  `full_description.txt` — keep in sync with `store/source/<locale>/`
  (en) and the aligned `store/v<N>/fields/play-<locale>-*.txt`.
- `metadata/en-US/images/` — refresh `icon.png` (512×512, downsample of the
  iOS marketing icon) and `phoneScreenshots/` when screens change
  (`screenshots/android/` is the verified en set).

The auto-update check (`UpdateCheckMode: Tags` + `UpdateCheckData` on
`pubspec.yaml`) then picks up the new tag without touching this file — as
long as the tag matches `^v[0-9]+\.[0-9]+\.[0-9]+$` (RC tags are excluded on
purpose: their +N codes are higher and would be read as releases).

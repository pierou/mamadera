# F-Droid submission artifacts

This directory is the source of record for Mamadera's F-Droid presence. It
holds two kinds of files that live in *different* repositories:

| File | Goes to |
|------|---------|
| `com.pvjio.mamadera.yml` | fork of https://gitlab.com/fdroid/fdroiddata → `metadata/` |
| `disable-release-signing-guard.patch` | same fork → `metadata/com.pvjio.mamadera/` (per-app dir — **not** the legacy 1.x `patches/` tree, which no longer exists on master; `patch:` entries resolve against `metadata/<appid>/`, cf. `a2dp.Vol`) |
| `remove-java-toolchain-pin.patch` | same per-app dir | v1.2.0+ only — see scanner/build notes below |
| (the `metadata/` tree at the repo root) | **this repo** — F-Droid 2.0 fetches localized descriptions, changelogs and screenshots from the app's own source |

## One-time submission (status: MR opened 2026-10-22)

1. The stable tag `v1.1.0` was added at `3780a25` (the `v1.1.0-rc.2` commit —
   v1.1.0 shipped from that RC; there was never a stable tag). All six
   `Builds` entries reference pushed tags only.
2. Fork `fdroiddata` (GitLab), add `metadata/com.pvjio.mamadera.yml` and
   `metadata/com.pvjio.mamadera/disable-release-signing-guard.patch`, open a MR
   labelled **"New App"**. The fdroiddata pipeline builds, scans and signs.
   **Done:** MR [!53740](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/53740)
   opened 2026-10-22 from fork `pvjacquier/fdroiddata`, branch
   `mamadera-new-app` (the label had to be added by hand in the browser —
   the submitter token has no label rights on the upstream project).
3. This app has **no network transport at all** (offline-only mandate), so the
   scanner should report no `AntiFeatures` and no licence hits beyond the
   FOSS Flutter/Dart ecosystem.

## fdroiddata formatting — what fails the pipeline

The first pipeline run (2026-10-22) failed on three jobs, all formatting:

- **`fdroid build`** — fdroidserver joins *all* `prebuild` items with `"; "`
  into a single `bash -e -u -o pipefail -c` invocation (`fdroidserver/common.py`,
  `run_prebuild`), exactly like it joins `build` items. A multi-line `prebuild`
  item that ends with a newline (a YAML `|` block scalar always does) puts a
  bare `;` at the start of the next line → `bash: syntax error near unexpected
  token ';'`. Rule: **every `prebuild`/`build` item is a single-line value**.
  A value that genuinely needs two statements is one double-quoted item with
  an escaped `\n` between them (no trailing newline). Working reference
  recipes in fdroiddata: `app.kryfo`, `app.veil.veil`.
- **`fdroid rewritemeta` / `checkupdates`** — both fail if the file is not
  byte-identical to fdroidserver's own canonical rewrite. The canonical form
  (2.0): no comments, `output` right after `commit`, `build` last in the entry,
  `AutoName` in the header block (checkupdates --auto fetches it from the
  AndroidManifest label and adds it), and `AutoUpdateMode`/`UpdateCheckMode`/
  `UpdateCheckData`/`CurrentVersion`/`CurrentVersionCode` **after** `Builds:`
  at the end of the file.
- **Scanner (run by `fdroid build`)** — two Flutter-specific traps, both
  fixed in the current file:
  - the Flutter template's `org.gradle.toolchains.foojay-resolver-convention`
    plugin in `android/settings.gradle.kts` is a **usual suspect** (it
    downloads JVM toolchains over the network). Every Flutter app in fdroiddata
    strips it in prebuild: `sed -i -e '/foojay/d' android/settings.gradle.kts`
    (see `app.fluffy`). `android/gradle/gradle-daemon-jvm.properties` is
    removed automatically by fdroidserver — no patch needed.
  - `scanignore`/`scandelete` paths are resolved inside the **scanned source
    dir**, and srclibs are checked out *outside* it — `build/srclib/flutter`
    entries are "non-exist + unused" errors. Only `.pub-cache` (created
    inside the source by `PUB_CACHE=$(pwd)/.pub-cache`) belongs there.
- **`patch:` files live in `metadata/<appid>/`, not `patches/<appid>/`.**
  The legacy 1.x `patches/` tree no longer exists on fdroiddata master and
  fdroidserver does not look there: it resolves `patch:` entries against
  `metadata/<appid>/` (exactly like `a2dp.Vol/gradle.patch`). A patch in the
  wrong tree fails the build with `Can't open patch file … : No such file or
  directory`.
- **The v1.2.0 toolchain pin is a second F-Droid-only patch.**
  Upstream (v1.2.0+, scar tissue from a dead foojay redirect on the GitHub
  ubuntu runner) pins `jvmToolchain(17)` + `kotlin.jvm.toolchain=17`
  (`auto-download=false`). Pre-v1.2.0 tags have no pin and compile fine on
  the fdroid builder's daemon JVM; v1.2.0+ then dies with `Cannot find a
  Java installation … matching {languageVersion=17}` because the foojay
  plugin has been stripped and no local JDK 17 exists. So v1.2.0/v1.2.1 get
  `remove-java-toolchain-pin.patch` (drops the pin in
  `android/app/build.gradle.kts` and `android/gradle.properties`) **on top
  of** the signing-guard patch. Upstream CI is untouched: it keeps the pin
  and installs JDK 17.

Before pushing any change to the fork, run locally (the pipeline uses the
Debian-trixie `fdroidserver` package; any recent fdroidserver gets you most of
the way — if the versions diverge, the `fdroid rewritemeta` job's diff shows
the remaining delta exactly, so convergence takes at most one extra push):

```bash
fdroid rewritemeta com.pvjio.mamadera   # then git diff must be empty
fdroid lint com.pvjio.mamadera
```

## Per-release upkeep (every stable tag)

- `Builds:` — new entry: `versionName`/`versionCode` straight from the tagged
  `pubspec.yaml` (`X.Y.Z+N`; N is monotonic across RCs — never renumber),
  `commit: vX.Y.Z`, same prebuild/build/output block, `patch:` if the
  signing guard exists in that tag (it does in every tag ≥ v1.1.0). Keep the
  entry in canonical key order (`versionName`, `versionCode`, `commit`,
  `patch`, `output`, `srclibs`, `rm`, `prebuild`, `scanignore`, `scandelete`,
  `build`) — the `rewritemeta` job above is the check.
- `CurrentVersion` / `CurrentVersionCode` — bump to the new release (the block
  lives at the **end** of the file, after `Builds:`).
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

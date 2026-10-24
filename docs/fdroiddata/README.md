# F-Droid submission artifacts

This directory is the source of record for Mamadera's F-Droid presence. It
holds two kinds of files that live in *different* repositories:

| File | Goes to |
|------|---------|
| `com.pvjio.mamadera.yml` | fork of https://gitlab.com/fdroid/fdroiddata → `metadata/` |
| (the `fastlane/metadata/android/` tree at the repo root) | **this repo** — F-Droid 2.0 fetches localized descriptions, changelogs and screenshots from the app's own source, in **fastlane layout** (required by the New App checklist — a plain `metadata/` dir happens to be read too, but it is not accepted for inclusion) |

## One-time submission (status: MR opened 2026-10-22)

1. The stable tag `v1.1.0` was added at `3780a25` (the `v1.1.0-rc.2` commit —
   v1.1.0 shipped from that RC; there was never a stable tag). All six
   `Builds` entries reference pushed tags only.
2. Fork `fdroiddata` (GitLab), add `metadata/com.pvjio.mamadera.yml`, open a MR
   labelled **"New App"**. The fdroiddata pipeline builds, scans and signs.
   **Done:** MR [!53740](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/53740)
   opened 2026-10-22 from fork `pvjacquier/fdroiddata`, branch
   `mamadera-new-app` (the label had to be added by hand in the browser —
   the submitter token has no label rights on the upstream project).
3. This app has **no network transport at all** (offline-only mandate), so the
   scanner should report no `AntiFeatures` and no licence hits beyond the
   FOSS Flutter/Dart ecosystem.

## Review round (2026-10-24) — what a maintainer asked for

`seekme-seekyou` reviewed !53740 after six green source builds and asked for
three things. All three are policy/style, none contested the app:

1. **No patch files.** The house idiom for Flutter is `sed` in `prebuild:`
   (1175 apps on master strip foojay that way; ~470 delete `keystore`/`signingConfig`
   blocks with sed). Both patches were folded into three one-line seds and
   `metadata/com.pvjio.mamadera/` was deleted. For reference the two facts the
   patches encoded, now as seds:
   - `sed -i -e 's/releaseBuildRequested && !hasReleaseSigning/false/' android/app/build.gradle.kts`
     — upstream deliberately throws when a release build has no keystore (so we
     never ship debug-signed); F-Droid re-signs, so the guard is off there only.
   - `sed -i -e '/Pin the compile toolchain/,/^}/d' android/app/build.gradle.kts`
     + `sed -i -e '/kotlin.jvm.toolchain/d' -e '/java.installations.auto-download/d' android/gradle.properties`
     — v1.2.0+ pins `jvmToolchain(17)` with `auto-download=false`; once foojay
     is stripped nothing can satisfy that pin (`Cannot find a Java installation
     … {languageVersion=17}`), while pre-v1.2.0 tags have no pin and build on
     the builder's daemon JVM. Delete the range, not just the inner line — the
     comment header goes with it. `^kotlin {` alone would leave it orphaned.
2. **Only the latest version before merge** — the New App checklist says it
   verbatim ("Only the latest versions should be kept in the metadata before
   it's merged"), and pointed at `templates/build-flutter.yml`. The six
   `Builds` entries (1.0.0→1.2.1) collapse to one: **1.2.1 / 11**. Nothing is
   lost: the app was never on F-Droid, and the older tags stay tag-exact in
   the app repo. `rm:` grew to cover every leftover template platform dir
   (`ios linux macos web windows` — all five exist in this repo).
3. **fastlane in the repo** — see the table above: `fastlane/metadata/android/`.

*Gotcha to remember:* the MR description embedded screenshot URLs from
`raw.githubusercontent.com/pierou/mamadera/develop/metadata/…`. Moving to
fastlane 404s those, and a broken image in the abstract reads as a missing
screenshot. Pin them to the **immutable tag** (`/raw/v1.2.1/…`), which never
moves and matches the only version being built.

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
  directory`. Kept as a fact — this app no longer ships patches at all (see
  the review round above), fdroiddata maintainers prefer sed.

Before pushing any change to the fork, run locally (the pipeline uses the
Debian-trixie `fdroidserver` package; any recent fdroidserver gets you most of
the way — if the versions diverge, the `fdroid rewritemeta` job's diff shows
the remaining delta exactly, so convergence takes at most one extra push):

```bash
fdroid rewritemeta com.pvjio.mamadera   # then git diff must be empty
fdroid lint com.pvjio.mamadera
```

## Per-release upkeep (every stable tag)

- `Builds:` — **replace** the previous entry with the new release (the
  pre-merge rule is one entry only; keep it that way, it is also what the
  builders prefer): `versionName`/`versionCode` straight from the tagged
  `pubspec.yaml` (`X.Y.Z+N`; N is monotonic across RCs — never renumber),
  `commit: vX.Y.Z`, and the same prebuild/build/output block. The three seds
  belong in every new entry — the signing guard is in every tag ≥ v1.1.0 and
  the toolchain pin in every tag ≥ v1.2.0. Keep the entry in canonical key
  order (`versionName`, `versionCode`, `commit`, `output`, `srclibs`, `rm`,
  `prebuild`, `scandelete`, `build`) — the `rewritemeta` job above is the check.
- `CurrentVersion` / `CurrentVersionCode` — bump to the new release (the block
  lives at the **end** of the file, after `Builds:`).
- `fastlane/metadata/android/<locale>/changelogs/<N>.txt` — one file per
  **versionCode** (not per versionName), ≤ 500 chars per locale; reuse the store
  "What's new" blocks (they are already counted against Play's 500-char limit).
- `fastlane/metadata/android/<locale>/short_description.txt` (≤ 80 chars) and
  `full_description.txt` — keep in sync with `store/source/<locale>/`
  (en) and the aligned `store/v<N>/fields/play-<locale>-*.txt`.
- `fastlane/metadata/android/en-US/images/` — refresh `icon.png` (512×512,
  downsample of the iOS marketing icon) and `phoneScreenshots/` when screens
  change (`screenshots/android/` is the verified en set). Locale lives in the
  directory here, so filenames stay `1.png`/`2.png`/`3.png` — the
  locale-in-filename rule applies to the *capture* dirs under `screenshots/`,
  not to fastlane.

The auto-update check (`UpdateCheckMode: Tags` + `UpdateCheckData` on
`pubspec.yaml`) then picks up the new tag without touching this file — as
long as the tag matches `^v[0-9]+\.[0-9]+\.[0-9]+$` (RC tags are excluded on
purpose: their +N codes are higher and would be read as releases).

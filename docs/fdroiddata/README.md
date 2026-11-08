# F-Droid submission artifacts

This directory is the source of record for Mamadera's F-Droid presence. It
holds two kinds of files that live in *different* repositories:

| File | Goes to |
|------|---------|
| `com.pvjio.mamadera.yml` | fork of https://gitlab.com/fdroid/fdroiddata → `metadata/` |
| (the `fastlane/metadata/android/` tree at the repo root) | **this repo** — F-Droid 2.0 fetches localized descriptions, changelogs and screenshots from the app's own source, in **fastlane layout** (required by the New App checklist — a plain `metadata/` dir happens to be read too, but it is not accepted for inclusion) |

## Current status (2026-11-08 — the recipe pins `v1.3.1`, build **15**)

`com.pvjio.mamadera.yml` in this directory is **byte-identical** to
`metadata/com.pvjio.mamadera.yml` on the MR branch (`mamadera-new-app` of
`~/fdroiddata`, fork `pvjacquier/fdroiddata`). Keep them identical — `cmp` the
two after every bump; a comment or a wrap added on one side only breaks the
other's pipeline job. Current content: one `Builds` entry (1.3.1 / **15**,
`commit: v1.3.1`), `rm: [ios]` (re-derived from the tag tree, which still has
only `ios`), `CurrentVersion: 1.3.1` / `CurrentVersionCode: **15**`.

**Why 15 and not 14:** `1.3.1+14` was already uploaded to App Store Connect by
Xcode Cloud's build-on-push-to-`main` (PR #68), and the two 1.3.1 fixes — the
completion-journal restore rejection and the first-launch profile list — needed
a new iOS build. Apple and Play both refuse a reused build number, so the
version under test stayed 1.3.1 and the build moved: `pubspec.yaml` is
`1.3.1+15`, and `fastlane/metadata/android/<locale>/changelogs/15.txt` replaces
`14.txt`. F-Droid reads the changelog by **versionCode at the tag**, so the
three must agree at `v1.3.1` — tag it only after those fixes are on `main`.

The fork commit for that entry is **held unpushed** on `mamadera-new-app`
until the `v1.3.1` tag exists and is pushed: pushing the branch updates MR
!53740, whose pipeline immediately builds the entry against `commit: v1.3.1`
and fails on a ref that does not exist yet. At push time the MR abstract's
screenshot URLs move from `…/v1.3.0/fastlane/…` to `…/v1.3.1/fastlane/…`
(same files, now refreshed with the 1.3.1 UI).

Checked on 2026-11-01 with fdroidserver master (`cdfdce8`) and Debian trixie's
`ruamel.yaml 0.18.10`: `fdroid lint` clean, and `fdroid rewritemeta` is a fixed
point of the file (see the verification block below — this matters, the
formatting is version-sensitive in two ways now documented there).

**Pipeline `3015561025` (2026-11-01, commit `569a1376`) is green on all 9 jobs**,
including the one that matters: **`fdroid build` succeeded in 508 s** — v1.3.0's
core-library desugaring compiles on F-Droid's builder (build 11 took 634 s
without it, so the new D8 work is not even a wall-clock problem), and the
trimmed `rm:` list built instead of raising. `fdroid lint`, `fdroid rewritemeta`,
`schema validation`, `check source code`, `git redirect`, `check apk` and
`checkupdates` green too. Note these pipelines are cited by **global id**, not
iid — `3015561025` here, `2985018099` for the 1.2.1 review round.

Where the ball sits, read off all 14 notes rather than inferred: **all three of
their asks are answered; our two questions are unanswered.** The review of
2026-10-24 arrived as **two notes but three requests** — sed instead of patch
files, latest version only, fastlane in the repo (enumerated in the review round
below) — and all three were done that day. Our own reply of 2026-10-24 19:34
closed by asking them two things, and nothing has answered them since:

- universal `app-release.apk` (current) or `--split-per-abi` with one block per ABI?
- should the `sudo:` + upstream-path block for reproducible builds go in now, or as
  a follow-up once the app is included?

So `waiting-on-response` is plausibly accurate rather than stale — it can be the
unanswered side of that exchange. The next note to the reviewer should re-raise
both questions; they are the only content that can move the MR past "green but
silently waiting".

**The error that nearly deleted those questions:** reading notes through the API
and truncating bodies at 800 characters, then concluding absence from the truncated
view — which produced a doc commit claiming `--split-per-abi` "has no source in the
MR" when it sits verbatim in our own note, and an edit removing the auditor's
accurate parenthetical. Rule: grep full note bodies for the term before ever
writing that something is absent from a thread (`per_page=100` does not truncate the
payload — printing does).

### The MR abstract had to be corrected, not just re-pinned

Re-pinning the screenshots was the small part (all four URLs under
`…/mamadera/v1.3.0/fastlane/…` verified `200` with real byte counts before the
edit). The description itself had gone **factually wrong** with v1.3.0, in ways a
reviewer's `check apk` step catches immediately:

- it claimed the app "requests **no permissions**". The released APK declares
  `POST_NOTIFICATIONS`, `USE_EXACT_ALARM`, `VIBRATE` and
  `com.pvjio.mamadera.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. `VIBRATE` is
  **not in our `AndroidManifest`** — `flutter_local_notifications`' library
  manifest contributes it at merge time, which is why no amount of reading the
  repo would have surfaced it. The fourth is AndroidX's own
  `protectionLevel="signature"` permission for non-exported receivers
  (`0x00000002` in `aapt2 dump xmltree`).
- the privacy claim was rewritten to rest on what is still provable — **no
  `INTERNET` permission**, so the APK cannot reach the network — rather than on
  the now-false absolute.
- the fastlane checklist line claimed icon **and** images for all three locales;
  `fr`/`es` ship text only. Disprovable in seconds from the repo.
- the "Build notes" section still promised "All six stable releases are included
  (1.0.0+1 … 1.2.1+11)" and described
  `patches/com.pvjio.mamadera/disable-release-signing-guard.patch` — six entries
  is precisely what review asked us to delete, and that patch file was deleted in
  the same round.

**Upkeep rule this teaches: after building a release, diff the MR description
against the artifact**, not against the repo. One command for the permission
half (`apksigner`/`aapt2` from any build-tools dir):

```bash
gh release download v1.3.0 -R pierou/mamadera -p app-release.apk
dumpBin=$(ls -d ~/Library/Android/sdk/build-tools/*/ | tail -1)
${dumpBin}aapt2 dump badging app-release.apk | grep -E "^(package|uses-permission|targetSdk)"
${dumpBin}aapt2 dump xmltree app-release.apk --file AndroidManifest.xml \
  | grep -B2 -A3 DYNAMIC_RECEIVER_NOT_EXPORTED   # protectionLevel of the AndroidX one
```

The v1.2.1 SHA-pin workaround is retired (section below). The branch
`fdroid-metadata-v1.2.1` is **pushed** (`refs/heads/` on origin), and it is
still the only ref that keeps `5fcd9b1` reachable — pipeline `2985018099` built
the reviewed 1.2.1 APK from it, so deleting it before !53740 merges would make
already-reviewed evidence unbuildable. Delete it **after** the merge:

```bash
git push origin --delete fdroid-metadata-v1.2.1    # in the mamadera repo
```

The MR abstract's screenshot URLs have to move off that branch **before** the
delete, i.e. to the tag:

```
https://raw.githubusercontent.com/pierou/mamadera/v1.3.0/fastlane/metadata/android/en-US/images/icon.png
…/v1.3.0/fastlane/metadata/android/en-US/images/phoneScreenshots/{1,2,3}.png
```

Same pixels either way — `git diff 5fcd9b1 v1.3.0 -- fastlane/` adds only the
three `changelogs/12.txt` — but a deleted branch 404s them, and a broken image
in the abstract reads as a missing screenshot.

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
screenshot. Pin them to a **commit SHA**, which never moves.

### The tag predates its own metadata — the trap behind "create fastlane in repo"

fdroidserver ingests descriptions, changelogs and screenshots from the source
**at the commit it builds** (`update.py` scans
`build/<appid>/fastlane/metadata/android/<locale>`, and a root `metadata/` too).
Tag `v1.2.1` was cut *before* PR #45 added the metadata tree, so
`git ls-tree v1.2.1` has no `metadata/` and no `fastlane/` at all — a
`Builds` entry pinned to that tag produces a **bare listing**: name + category,
no description, no changelog, no screenshots. `fdroid lint` does not catch it;
only looking at the listing does.

`develop` is not the fix either: it is three refactoring commits past the
release (144-file canonical reformat, domain-free-of-Flutter, screenshot
campaign) — building it would publish **unreleased code under a released
versionCode**. The pin is therefore:

- branch `fdroid-metadata-v1.2.1` @ `5fcd9b1` = tag `v1.2.1` + the fastlane
  tree **and nothing else** (`git diff v1.2.1 <sha> -- lib/ android/ pubspec.yaml`
  is empty, so the APK *is* the released 1.2.1 / versionCode 11), and
- `commit: 5fcd9b1…` in fdroiddata, screenshot URLs in the MR abstract pinned
  to the same SHA.

**Retired 2026-11-01, at v1.3.0.** That tag *does* carry the tree: `git ls-tree
-r --name-only v1.3.0 fastlane/` lists `en-US`, `fr` and `es` each with
`short_description.txt`, `full_description.txt` and `changelogs/12.txt`, plus
`en-US/images/icon.png` (512×512) and three `phoneScreenshots` (1280×2856).
`fr`/`es` ship text only — screenshots are not required per locale. There is no
`title.txt` anywhere, so `AutoName: Mamadera` supplies the name. The entry is
back to `commit: v1.3.0`, which is the only form writable *inside* the release
commit the tag points at (a pinned SHA would need a second commit after the
tag, which is what the branch existed to avoid).

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
- **"no comments" is literal, not stylistic.** `_app_to_yaml()` and
  `_builds_to_yaml()` rebuild the document field by field into fresh
  `CommentedMap`/`CommentedSeq` objects, so a `#` line *anywhere* in the file is
  deleted by the rewrite and the job's `git diff --exit-code` then fails.
  Verified 2026-11-01: a comment added above a `Builds` item vanished on the
  next `rewritemeta`, and `grep -l "^[[:space:]]*#" metadata/*.yml | wc -l`
  across upstream master returns **0 of 9740** files. Rationale goes in the
  commit message and in this README — never in the YAML. (The v1.3.0 entry
  briefly carried a four-line `#` explanation here in `docs/fdroiddata/`; that
  is why it no longer does.)
- **the canonical line wrap comes from the distro's `ruamel.yaml`, not from
  fdroidserver.** With `ruamel.yaml 0.18.x` (Debian trixie = the pipeline) a
  long plain scalar stays on **one** line; with `0.19.x` (what `uv`/PyPI resolve
  today) the same value is folded at width 80 with a **trailing space** before
  the break, which is what upstream looks like in `com.github.metacubex.clash.meta`
  but not what trixie emits. A file generated the wrong way differs by whitespace
  only and still fails the job.
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

Before pushing any change to the fork, run the pipeline's own tools. The
pipeline installs the Debian `fdroidserver` package and *then* puts a git
checkout of master ahead of it on the PATH — `.gitlab-ci.yml` does `checkout -B
master <pin>` followed by `pull origin master --ff-only`, so **the pin is a
floor, not the version in use**: the code is master tip, the libraries are
trixie's. That combination is reproducible here without a VM:

```bash
cd ~/fdroiddata
uv run --python 3.12 --with "ruamel.yaml==0.18.10" \
   --with "fdroidserver @ git+https://gitlab.com/fdroid/fdroidserver.git" \
   fdroid rewritemeta com.pvjio.mamadera    # run it twice
uv run --python 3.12 --with "ruamel.yaml==0.18.10" \
   --with "fdroidserver @ git+https://gitlab.com/fdroid/fdroidserver.git" \
   fdroid lint com.pvjio.mamadera
cmp metadata/com.pvjio.mamadera.yml \
   ~/DEV/mamadera/docs/fdroiddata/com.pvjio.mamadera.yml
```

Two checks, not one: **idempotence** (the second rewrite must leave the file
alone — the job diffs against your commit, so what has to be stable is what you
push) and **equality with this repo's copy**. Pinning `ruamel.yaml==0.18.10` is
not cosmetic: unpinned it resolves 0.19.1 and rewrites the four `sed` items into
folded lines trixie's writer would reject. Both were run on 2026-11-01 against
fdroidserver `cdfdce8` and `a35fdfdd` (the CI pin) — the two versions agree on
this file, which is why the recipe change below is safe to push.

## Per-release upkeep (every stable tag)

- **Make sure the tag contains `fastlane/metadata/android/`.** Metadata added
  on `develop` after a tag is cut is invisible to the build of that tag (see
  the trap above) — the fastlane tree must be merged before the tag, not after.
- `Builds:` — **replace** the previous entry with the new release (the
  pre-merge rule is one entry only; keep it that way, it is also what the
  builders prefer): `versionName`/`versionCode` straight from the tagged
  `pubspec.yaml` (`X.Y.Z+N`; N is monotonic across RCs — never renumber),
  `commit: vX.Y.Z`, and the same prebuild/build/output block. The three seds
  belong in every new entry — the signing guard is in every tag ≥ v1.1.0 and
  the toolchain pin in every tag ≥ v1.2.0. Keep the entry in canonical key
  order (`versionName`, `versionCode`, `commit`, `output`, `srclibs`, `rm`,
  `prebuild`, `scandelete`, `build`) — the `rewritemeta` job above is the check.
- `rm:` — **every entry must exist at the commit being built.** `rm` is resolved
  through `common.getpaths()`, and `getpaths()` raises
  `FDroidException("Some glob paths did not match any files/dirs: …")` for a path
  that matches nothing — before the `"…but it didn't exist"` log line in the
  `rm` loop can ever print. This is what v1.3.0 would have died on: `linux`,
  `macos`, `web` and `windows` were deleted from the repo between v1.2.1 and
  v1.3.0 (`git ls-tree --name-only -d v1.3.0` now shows only `ios`), so the
  entry copied forward from v1.2.1 would have failed on a **recipe path list**
  rather than on anything the release changed. Re-derive the list from the tag
  every release instead of copying it forward; the same rule covers `subdir`
  and every other globbed field.
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

## What v1.3.0 changed under the build — and what was re-checked

v1.3.0 adds `flutter_local_notifications` (+ `timezone`), core library
desugaring, two permissions and drift schema v13. Schema and Dart are none of
fdroidserver's business; the Gradle side is, so each item was re-checked against
the tag rather than assumed (`/tmp` checkout of `git archive v1.3.0`):

- **the four `sed` items still do their job, and spare the new code.** The
  toolchain-pin range `/Pin the compile toolchain/,/^}/d` ends at the `}` that
  closes `kotlin { … }` (line ~15); the `dependencies {
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }` block
  added in v1.3.0 sits at line ~87, **outside** the range, so desugaring is not
  silently deleted by our own prebuild. `foojay` line goes, the signing guard
  becomes `if (false)`, both pins leave `gradle.properties`. Note the seds were
  run here with BSD `sed -i ''`: GNU `sed -i -e …` (the builder) and BSD
  `sed -i -e …` (this Mac) are *not* interchangeable — BSD sed eats `-e` as the
  backup suffix, so a copy-paste of the recipe locally edits the wrong thing
  and looks successful.
- **`desugar_jdk_libs:2.1.4` is fetched from Google Maven like any other
  dependency** — no recipe change, and there is upstream precedent for building
  with it (`com.github.metacubex.clash.meta` injects `2.1.5` by sed). Residual
  risk is memory, not policy: D8 desugaring is new work in the builder VM that
  v1.2.1 never asked for. `org.gradle.jvmargs=-Xmx8G` is unchanged from v1.2.1.
- **`flutterVersion=$(sed …)` still resolves.** Run against the tagged
  `.github/workflows/ci.yml` (79 lines of it changed in v1.3.0) it prints
  `3.44.8`. If that key ever stops matching, the recipe does **not** fail — it
  quietly builds the `${flutterVersion:-3.44.8}` default, i.e. a Flutter that
  may not be the one that shipped. Re-run the sed against the tag each release.
- **`flutter pub get --offline --enforce-lockfile` at the tag: exit 0**, so the
  `--enforce-lockfile` in `prebuild` has a lockfile that matches `pubspec.yaml`.
- **new dependencies are clean:** every added package is MIT except `dbus`
  (MPL-2.0, used only by the linux/windows variants), and all of it lives under
  `.pub-cache`, which `scandelete` already covers.
- **two new permissions**, `POST_NOTIFICATIONS` and `USE_EXACT_ALARM`, both
  requested at runtime on opt-in. Neither is an F-Droid AntiFeature and the
  recipe does not change, but they will be listed on the app page — that is the
  reviewer seeing them first, so it belongs in the MR description.

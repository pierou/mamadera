# RELEASE PLAN — v1.1.0 (target: Google Play update + first App Store release)

Status: **draft — awaiting Phase 0 decisions.** Source: `feature/audit-corrections-and-db-export`
(31 commits ahead of `main`, not in `develop`). Content: custom reminders tied to a care, preset
reminder toggles, stool texture on diapers, date/time picker for new events, manual JSON export
via share sheet, l10n/privacy/backup-leak fixes, DB layer: SQLCipher dropped → field-level
AES-GCM, `schemaVersion` 10.

## Verified state (measured 2026-09-15, do not re-litigate)

| Fact | Evidence |
|---|---|
| The branch has **never been built by any CI** | No Actions runs exist for `feature/*`; pushes there don't trigger the workflow |
| **Google Play is live with v1.0.1** (AAB built by Actions with the production keystore secrets) | releases `v1.0.0`/`v1.0.1` carry `app-release.aab`; user confirmed |
| pubspec is still `1.0.1+2` → Play will **reject a duplicate versionCode**; CI version-sync check fails if `AppConfig.version` isn't bumped too | `pubspec.yaml`, `lib/core/config/app_config.dart` |
| Patch notes only cover `1.0.0`/`1.0.1` → a `1.1.0` entry (en/es/fr, noun-form rule for fr/es) is required | `assets/patch_notes/*.json` |
| **GitHub Actions `build-ios` never produces a store-usable artifact**: builds `--no-codesign`, and `zip -r ../../../../ios-Runner-app.zip` from `build/ios/iphoneos` lands ONE DIR ABOVE the workspace; `upload-artifact@v4` default `if-no-files-found: warn` made every upload "succeed" empty → every GitHub release since v1.0.0 silently ships **no iOS artifact** | run `31974833367` steps vs `/artifacts` API; releases show only apk+aab |
| **The real Apple failure is Xcode Cloud** (not Actions): "Archive - iOS" Build 2, branch `main`, 2026-08-16 23:53, failed after **26 s** with `Could not resolve package dependencies: .../ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage doesn't exist in file system` | screenshot `Capture d'écran 2026-09-15 à 21.54.33.png` |
| Root cause: iOS plugins are integrated via **SPM**; `ios/Flutter/ephemeral/` is **gitignored and Flutter-tool-generated**. Xcode Cloud clones the repo and runs `xcodebuild archive` directly; the repo has **no `ci_scripts/ci_post_clone.sh`**, so Flutter never runs on the Xcode Cloud VM → the local package the pbxproj references (10 refs) is absent → fails at dependency resolution, before compiling anything | `ls ci_scripts` empty, `git ls-files ci_scripts` = 0, local `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage` exists, `ios/.gitignore` |
| ⇒ "broken for some dependencies" = **missing generated package**, not a dependency *version* problem. Plugin compilation on current Xcode is still untested anywhere | 26 s duration = failed pre-compile |
| ASC app **`mamadera` exists** (Build 2 visible under Builds → app registration + Xcode Cloud workflow already created) | screenshot |
| Local toolchain: Flutter **3.44.8**, Xcode **27**; Actions pin **3.44.1**; Actions `build-ios` runs `macos-14` (old Xcode) | `flutter --version`, `xcodebuild -version`, ci.yml |
| Self-hosted runner `actions.runner.pierou-mamadera.macbook-pro` runs on this Mac (label `mamadera-ci`, integration gate only — it does not build iOS) | `ps`, `launchctl`, `~/actions-runner` |
| ⚠️ **Upgrade path**: live Play users go 1.0.1 → 1.1.0 (drift schema → v10). SQLCipher in v1.0.1 was a **dead dependency** — never referenced in `lib/` — so storage format is unchanged; risk is the multi-version schema migration, incl. the pre-v7 `reminder_settings` fix. CI integration tests cover fresh installs only | `git grep -il sqlcipher v1.0.1` → only pubspec/docs; lockfile diff; `app_db.dart:73` |

## Phase 0 — decisions (RESOLVED 2026-09-15)

1. **Version: `1.1.0+3`** — approved.
2. **Apple route: fix Xcode Cloud** (Phase 2B) — approved. Local Xcode Archive = fallback.

## Phase 1 — Release-prep commit (on the feature branch)

- [x] `pubspec.yaml`: `version: 1.1.0+3`
- [x] `lib/core/config/app_config.dart`: `version = '1.1.0'` (CI hard-checks this; also re-pinned `test/core/config/app_config_test.dart`)
- [x] `assets/patch_notes/{en,es,fr}.json`: added `"1.1.0"` entry — fr/es **noun form** per AGENTS.md, en natural phrasing
- [x] Unify Flutter pin to **3.44.8** in `.github/workflows/ci.yml` (5 places); Phase 2B script pins the same
- [x] `make ci` green locally (analyze clean, all unit/widget tests pass, coverage 85% ≥ 80%)

## Phase 2A — Prove iOS compiles locally (catches real dependency/version issues)

- [ ] `flutter build ipa --release --export-method app-store` on this Mac (Xcode 27).
      If a plugin package (share_plus 13, flutter_secure_storage 10) demands a higher
      `IPHONEOS_DEPLOYMENT_TARGET`, bump in Runner project + Package settings — NOT by
      version-downgrading dependencies.
- [ ] Keep the `.ipa` — it's the local-archive fallback for Phase 6.

## Phase 2B — Fix Xcode Cloud (the actual "Apple CI" fix)

Create **`ci_scripts/ci_post_clone.sh`** at repo root (exec bit committed, `#!/bin/bash`).
Runs on the Xcode Cloud VM after clone, **must finish < 10 min**. Sketch:

```bash
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."                       # repo root = $CI_WORKSPACE

FLUTTER_VERSION=3.44.8                        # keep in sync with ci.yml
ZIP="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"
[ -d ./flutter ] || { curl -fL "$ZIP" -o /tmp/flutter.zip && unzip -q /tmp/flutter.zip -d .; }
export PATH="$PWD/flutter/bin:$PATH"
flutter --version
flutter config --no-analytics
flutter pub get
flutter precache --ios
flutter build ios --config-only --release     # generates ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage
```

- [ ] Script must also `chmod +x` after committing; verify `git show --stat` keeps mode `100755`
- [ ] Push to the release branch; Xcode Cloud → trigger Archive on that branch
      (current workflow builds `main` — retarget it or add a branch)
- [ ] First green archive ⇒ build number/version in ASC shows up under Builds

## Phase 3 — Make GitHub Actions iOS honest (same PR; store path is Xcode Cloud, but stop the lie)

- [ ] Zip to `"${{ github.workspace }}/ios-Runner-app.zip"` (fix `../../../../` off-by-one)
- [ ] `if-no-files-found: error` on the iOS upload so an empty artifact **fails the job**
- [ ] Either move the job to `macos-latest` (+ `xcode-select` to a version ≥ local) so the
      compile check is meaningful, or delete the job and let Xcode Cloud be the single iOS build
      (recommended once 2B is green: one toolchain, one place)
- [ ] Keep the release workflow's iOS asset optional-or-required decision consistent with the above

## Phase 4 — Merge & tag (existing flow)

- [ ] PR `feature/... → develop`, then develop → main (PR #5 pattern). Gates: security-audit,
      lint-test (incl. version-sync), **integration-tests-local runs on this Mac's runner**
      (~3 min native arm64 — keep this Mac awake & runner online during the tag build)
- [ ] Tag `v1.1.0-rc.1` → verify: Actions AAB+APK signed, Xcode Cloud archive → ASC build
- [ ] Fix-forward, then final tag `v1.1.0`

## Phase 5 — Google Play (update of live app)

- [ ] **Upgrade gate (blocking)**: install published 1.0.1 APK (GitHub release `v1.0.1`,
      signed by the production key) on a device, create data (baby, events, notes, reminders),
      install 1.1.0 over it → all data intact, export works. Plain-SQLite storage format is
      UNCHANGED (SQLCipher was a dead dep — never referenced in `lib/` at v1.0.1, verified
      2026-09-15), so this is a drift schema-migration test (→ v10, incl. the pre-v7
      `reminder_settings` fix 246fc87), not a decryption migration. Still gates the release.
- [ ] Upload `app-release.aab` from the v1.1.0 GitHub release (never rebuild/sign elsewhere —
      same release keystore or Play rejects the update)
- [ ] Play Console: release notes ×3 languages (reuse patch notes) → internal testing → production
      (staged rollout optional). Data safety answers unchanged ("no data collected").

## Phase 6 — App Store via Xcode Cloud archive

- [ ] In ASC: new version `1.1.0`, What's New (reuse patch notes), select the Xcode Cloud build
- [ ] Metadata still required for a first submission: screenshots 6.7″ + 5.5″ (≥3 per language,
      en/fr/es), privacy policy URL
      (`https://raw.githubusercontent.com/pierou/mamadera/main/.github/PRIVACY.md`), age rating,
      `ITSAppUsesNonExemptEncryption` already `true` in Info.plist
- [ ] TestFlight first: run the **same upgrade test** as Phase 5 (1.0.1 data came from Play;
      on iOS it's fresh — still test a schema v≤9 → v10 upgrade with an old local build if one
      was ever installed)
- [ ] Submit for review (1–3 days first review)

## Phase 7 — Post-release hygiene

- [ ] Update `docs/SUBMISSION-CHECKLIST.md` (Apple enrollment + ASC creation are done; add
      Xcode Cloud reality) and `docs/app-store-setup.md` (SPM + `ci_scripts`, not Podfile)
- [ ] Optional: real signed-IPA pipeline in Actions via the existing local runner (Xcode 27 +
      keychain + ASC API key) — only if Xcode Cloud's limits ever hurt

## Risks / non-negotiables

1. **Do not ship without the 1.0.1→1.1.0 upgrade test** (Phase 5 gate) — schema v10 migration
   across many versions; storage format itself is unchanged (SQLCipher was never live).
2. AAB must come from the **production keystore** (Actions secrets), versionCode ≥ 3.
3. Xcode Cloud `ci_post_clone.sh` pins Flutter = Actions pin (3.44.8); bump both together forever.
4. Never move `ephemeral/` under git; the fix is the post-clone hook.
5. No analytics/telemetry sneaks in with share_plus etc. (privacy mandate) — already reviewed in
   the branch, re-verify at tag time with `make audit-trivy`.

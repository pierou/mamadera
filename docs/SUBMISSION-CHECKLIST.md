# Store Submission Master Checklist

This is your end-to-end guide for releasing mamadera on all three stores. Follow the phases in order.

---

## Phase 1 & 2 — Code Changes ✅ DONE

All code changes have been implemented (see commits). Verify with:

```bash
make lint        # Should pass with zero warnings
flutter analyze --fatal-infos --fatal-warnings   # Clean output
```

---

## Phase 3 — Manual Store Setup

### 📦 Step 0 — Build the store package (before touching any console)

The deliverable is **built from one canonical source**, never typed into a console:

```bash
make store-prose     # TranslateGemma en→fr/es, raw archived under machine/, then aligned to the ARB
make store-check     # consoles' limits + note consistency + screenshot inventory
```

Output: [`store/v<version>/`](../store/v1.3.0/) — one paste-ready file per console
field per language, plus the screenshots per device slot. Every field the consoles accept is
length-checked, so a 106-character keyword list fails here instead of at upload.

- [ ] `store/v<version>/` built from `store/source/en/` (nothing hand-written inside it)
- [ ] `store/v<version>/machine/<locale>/` present — proof the fr/es prose is TranslateGemma output
- [ ] `make store-check` passes (ASC WARN lines are decisions, not accidents: read them)
- [ ] FR/ES prose read by a human before submission — machine output is the floor, not the
      ceiling. The Apple "What's New" renders from `assets/patch_notes/<locale>.json` (reviewed,
      human-owned): fix wording there and re-run `make store-package`; `store/v*/machine/` stays
      raw (it is the traceability evidence) and `fields/` is regenerated, never hand-edited

---

### 📋 Shared Prerequisites (do these first)

- [ ] **Privacy policy is publicly accessible**  
      URL: `https://raw.githubusercontent.com/pierou/mamadera/main/.github/PRIVACY.md`  
      Verify it loads in an incognito browser window.

- [ ] **App icon assets are ready**  
  - iOS: Already generated via `flutter_launcher_icons` (1024×1024)
  - Android: Same source, will auto-generate from AAB upload

---

### 🔐 Step A — Generate Release Keystore & Configure CI

Follow → [`docs/keystore-setup.md`](keystore-setup.md)

- [ ] Generated `mamadera-release.jks` + backed it up securely
- [ ] Base64-encoded keystore copied to clipboard
- [ ] Added 4 GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `_PASSWORD`, `_ALIAS`, `_KEY_PASSWORD`)
- [ ] Tested with a tag push — CI built signed APK & AAB successfully

---

### 🍎 Step B — Apple App Store (iOS)

Follow → [`docs/app-store-setup.md`](app-store-setup.md)

| Task | Status |
|------|--------|
| Enroll in Apple Developer Program ($99/year) | ✅ done |
| Create app entry in App Store Connect (`com.pvjio.mamadera`) | ✅ done |
| Archive + sign + upload via **Xcode Cloud** (auto on `main` push; auto-managed signing) | ✅ first green build 2026-09-20 — 1.1.0 build in ASC, ready to attach |
| Fill metadata (name, subtitle, description × 3 languages — **from `store/v<version>/fields/`**; the v1.1.0 block in `docs/app-store-setup.md` Step 5 is superseded) | ☐ |
| Paste What's New × 3 (`store/v<version>/release-notes/apple-whatsnew-<locale>.txt` — rendered from `assets/patch_notes/`, never hand-edited) | ☐ |
| Upload iPhone screenshots — **exactly four sizes, all else is rejected**: 1206×2622 and 2622×1206 (iPhone 17), 1179×2556 and 2556×1179 (iPhone 17e), 7 screens per locale (`store/v<version>/screenshots/asc/<locale>/<size>/`). The old 1242×2688 / 1284×2778 set stopped being uploadable in B24 (2026-11-03) and `store/v1.3.0/screenshots/asc/` is still built from it — do not take a set from there | ☐ |
| Set privacy policy URL | ☐ |
| Complete age rating questionnaire | ☐ |
| Declare no non-exempt encryption — `ITSAppUsesNonExemptEncryption = false` in Info.plist, matching the ASC export-compliance answer | ✅ done |
| Submit for review | ☐ |

**Expected timeline:** First review takes 1–3 business days.

---

### 🤖 Step C — Google Play Store (Android)

**Status — the one-time Play setup is done (recorded 2026-09-29):** account,
app entry, data safety, IARC, listing ×3, graphics and the internal→production
track exist; 1.1.0 was in production as of that date (shipped 2026-09-15,
updated from 1.0.1).

**Which version is live is not recorded in this repo, and this file is not the
place that gets decided.** `v1.2.0`, `v1.2.1` and `v1.3.0` have been tagged
since that note and nothing here records a Play upload of any of them —
`docs/PLAN-release-1.3.0-then-1.3.1.md` §6.1 keeps it as an open question on
purpose, because the answer decides version numbering. Read the Play Console.

Follow → [`docs/google-play-setup.md`](google-play-setup.md)

**One-time (done):**

| Task | Status |
|------|--------|
| Create developer account ($25 one-time fee) | ✅ 2026-09-29 |
| Create app entry (`com.pvjio.mamadera`) | ✅ 2026-09-29 |
| Complete Data Safety section ("No data collected") | ✅ 2026-09-29 |
| Complete IARC questionnaire (Everyone rating expected) | ✅ 2026-09-29 |
| Set privacy policy URL | ✅ 2026-09-29 |

**Every release (this is the part that repeats):**

| Task | Status |
|------|--------|
| Fill store listing + localizations × 3 languages — **from `store/v1.3.1/fields/`** + `release-notes/play-<locale>.txt` (the v1.1.0 copy in `docs/google-play-setup.md` Step 6 is superseded) | ☐ |
| Upload feature graphic (1024×500), app icon (512×512), screenshots (≥3) — `store/v1.3.1/screenshots/play/`, 8 screens × fr/es/en at 1280×2856, recaptured 2026-11-11 | ☐ |
| Signed AAB from the release tag (Actions, production keystore) — as `v1.3.0` was in CI run 41353557027 | ☐ |
| Upload to Internal Testing track first | ☐ |
| Complete internal testing → move to Production | ☐ |

The gating checks that were learned the hard way, and that a green CI cannot
replace: the upgrade test on a device still holding the **previous** schema, and
the export/restore round-trip (`RELEASE-PLAN-v1.1.0.md` Phase 5 — schema → v10
at the time; v1.3.0 is schema v13 / backup format v4). See the release gate in
AGENTS.md.

**Expected timeline:** First review takes 2–5 business days. Closed testing requires minimum 14 days for new developers (may be exempt).

---

### 🦊 Step D — F-Droid

Follow → [`docs/fdroiddata/README.md`](fdroiddata/README.md) — that README is
the working record: pipeline history, the maintainer review round, what fails
the build, and how to run the pipeline's own tools locally.

The previous version of this table described a **GitHub** fork, a `meta/`
directory, a PR titled "New package: Mamadera" and a
`.f-droid/description/en-US/mamadera.md` file attached to it. None of that is
how the submission works: fdroiddata is on **GitLab**, the directory is
`metadata/`, and the listing text comes from the **`fastlane/metadata/android/`
tree in this repo at the commit F-Droid builds** (`.f-droid/` does not exist in
the tree any more).

| Task | Status |
|------|--------|
| fastlane tree in this repo, present **at the release tag** | ✅ v1.3.1 (this was the v1.2.1 blocker) — descriptions ×3, `changelogs/15.txt` ×3, icon + 3 screenshots. Caveat: the screenshots are the 2026-11-08 captures, three days before the store recapture that followed B28 — see `docs/fdroiddata/README.md` |
| `com.pvjio.mamadera.yml` canonical + lint-clean under the pipeline's fdroidserver | ✅ 2026-11-12, one `Builds` entry 1.3.1 / 15, `commit: v1.3.1` — `rewritemeta` idempotent under fdroidserver master *and* the CI pin, `lint` clean, byte-identical to this repo's copy |
| Fork fdroiddata (GitLab), MR labelled **New App** | ✅ MR [!53740](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/53740), opened 2026-10-22 |
| Push the release recipe to the MR branch | ✅ 2026-11-12 (`mamadera-new-app@12b317fe`) — pipeline `3062096455`, **`fdroid build` succeeded (581 s)** on tag `v1.3.1`; v1.3.0's build was `3015561025` (508 s) |
| Re-pin the MR abstract to `v1.3.1` | ✅ 2026-11-12 — URLs verified 200 at the new tag; two claims the bump had made false corrected in place (the `Builds` line, and "the MR adds exactly two files…patch": it adds one) |
| Maintainer review → merge | ☐ (~2–6 weeks. All three 2026-10-24 asks — sed instead of patches, latest version only, fastlane in the repo — are answered; **our two questions of the same day, per-ABI splits and whether the `sudo:`/reproducible-build block goes in now, are unanswered**, which is probably what `waiting-on-response` refers to) |
| Delete branch `fdroid-metadata-v1.2.1` | ☐ **after** the merge — see `docs/AUDIT-2026-10-21.md` addendum |

**Note:** F-Droid builds from source on its own builders and re-signs the APK —
we upload nothing. The recipe *is* the deliverable, which is why a formatting
detail like `fdroid rewritemeta` ownership decides whether the app is listed.

---

## Quick Commands Reference

```bash
# Build locally with release signing (set env vars first!)
export KEYSTORE_PATH=/path/to/mamadera-release.jks
export KEYSTORE_PASSWORD="store_pass"
export KEY_ALIAS=mamadera-key
export KEY_PASSWORD="key_pass"

make build-android   # APK for F-Droid / sideloading
make build-aab       # AAB for Google Play Store

# Validate signature
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk

# iOS: no local signed build needed — Xcode Cloud archives, signs (auto-managed)
# and uploads on every push to main. Local fallback:
flutter build ios --config-only   # generates the gitignored SPM package, then archive in Xcode

# Test CI pipeline with a release candidate tag
git tag v1.0.0-rc.1 && git push origin v1.0.0-rc.1
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `apksigner` not found | Install via SDK Manager: `sdkmanager "build-tools;34.0.0"` or use Homebrew: `brew install android-build-tools` |
| Xcode signing errors | Delete DerivedData (`~/Library/Developer/Xcode/DerivedData`) and re-open `.xcworkspace` |
| Xcode Cloud: `Post-Clone script not found at ci_scripts/ci_post_clone.sh` | The hook must live in `ios/ci_scripts/` — next to `ios/Runner.xcworkspace`, NOT the repo root (Apple detection convention, see `docs/app-store-setup.md` Step 3) |
| Xcode Cloud: `Could not resolve package dependencies … FlutterGeneratedPluginSwiftPackage` | The post-clone hook did not run (see above) — the SPM package is gitignored and Flutter-tool-generated |
| Google Play says package name mismatch | Verify `android/app/build.gradle.kts` has `applicationId = "com.pvjio.mamadera"` — must match exactly |
| App Store Connect can't find bundle ID | Wait 10–30 minutes after creating it, or manually create in Developer Portal → Identifiers |

## Emulator pass (mandatory before every PR — AGENTS.md)

- [ ] Old build installed, data seeded, new build installed OVER it — migration verified with pre-existing data
- [ ] Screenshots taken and inspected on `Small_Phone` and one normal target
- [ ] Manual entry: feeding + sleep + measurement recorded, exported, JSON inspected
- [ ] Simulator id and what was seen recorded in the PR description

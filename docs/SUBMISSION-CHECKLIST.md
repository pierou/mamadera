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
| Enroll in Apple Developer Program ($99/year) | ☐ |
| Create app entry in App Store Connect (`com.pvjio.mamadera`) | ☐ |
| Build & upload first IPA via Xcode Archive | ☐ |
| Fill metadata (name, subtitle, description × 3 languages) | ☐ |
| Upload screenshots (iPhone 6.7" + 5.5") — at least 3 per language | ☐ |
| Set privacy policy URL | ☐ |
| Complete age rating questionnaire | ☐ |
| Verify `ITSAppUsesNonExemptEncryption = false` is in Info.plist ✅ done | ☐ |
| Submit for review | ☐ |

**Expected timeline:** First review takes 1–3 business days.

---

### 🤖 Step C — Google Play Store (Android)

Follow → [`docs/google-play-setup.md`](google-play-setup.md)

| Task | Status |
|------|--------|
| Create developer account ($25 one-time fee) | ☐ |
| Create app entry (`com.pvjio.mamadera`) | ☐ |
| Complete Data Safety section ("No data collected") | ☐ |
| Complete IARC questionnaire (Everyone rating expected) | ☐ |
| Fill store listing + localizations × 3 languages | ☐ |
| Upload feature graphic (1024×500), app icon (512×512), screenshots (≥3) | ☐ |
| Build & sign AAB locally OR use CI artifacts | ☐ |
| Upload to Internal Testing track first | ☐ |
| Complete internal testing → move to Production | ☐ |
| Set privacy policy URL | ☐ |

**Expected timeline:** First review takes 2–5 business days. Closed testing requires minimum 14 days for new developers (may be exempt).

---

### 🦊 Step D — F-Droid

Follow → [`docs/fdroiddata/com.pvjio.mamadera.yml`](fdroiddata/com.pvjio.mamadera.yml)

| Task | Status |
|------|--------|
| Review & customize the YAML metadata (maintainer email, version info) | ☐ |
| Fork [f-droid/fdroiddata](https://github.com/f-droid/fdroiddata) on GitHub | ☐ |
| Copy `com.pvjio.mamadera.yml` to their `meta/` directory in your fork | ☐ |
| Open Pull Request against upstream fdroiddata with title "New package: Mamadera" | ☐ |
| Attach the F-Droid description file (`.f-droid/description/en-US/mamadera.md`) content in PR comment | ☐ |
| Wait for maintainer review & build verification (~2–6 weeks) | ☐ |

**Note:** F-Droid builds from source on their own infrastructure. They'll verify the APK is reproducible and free of non-free dependencies.

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

# iOS unsigned IPA (use Xcode to sign + archive)
make build-ipa

# Test CI pipeline with a release candidate tag
git tag v1.0.0-rc.1 && git push origin v1.0.0-rc.1
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `apksigner` not found | Install via SDK Manager: `sdkmanager "build-tools;34.0.0"` or use Homebrew: `brew install android-build-tools` |
| Xcode signing errors | Delete DerivedData (`~/Library/Developer/Xcode/DerivedData`) and re-open `.xcworkspace` |
| Google Play says package name mismatch | Verify `android/app/build.gradle.kts` has `applicationId = "com.pvjio.mamadera"` — must match exactly |
| App Store Connect can't find bundle ID | Wait 10–30 minutes after creating it, or manually create in Developer Portal → Identifiers |
| F-Droid rejects build due to sqlcipher EOL tag | Reply to maintainer explaining the dependency is GPL-compatible; they may accept with note |

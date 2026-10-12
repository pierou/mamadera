# iOS Code Signing Setup for GitHub Actions

This guide walks you through setting up iOS code signing in your CI pipeline to eliminate the `"Building for device with codesigning disabled"` warning and produce signed IPAs ready for TestFlight/App Store submission.

---

## Overview

The CI workflow now builds **signed IPAs** instead of unsigned apps. Signing only runs on version tags (`refs/tags/v*`) to keep secrets secure.

---

## Step 1 — Export Your Signing Certificate

### From Keychain Access

1. Open **Keychain Access** on your Mac
2. Go to **Login** keychain → **Certificates** category
3. Find your **Apple Distribution** or **Apple Development** certificate
4. Right-click → **Export "Apple Distribution: ..."**
5. Save as `ios-signing.p12`
6. Set a strong password (remember it — you'll need it for GitHub Secrets)

### Alternative: Export via Terminal

```bash
# If you already have the .p12 file exported from Keychain Access
base64 ios-signing.p12 > ios-signing.p12.b64
cat ios-signing.p12.b64 | pbcopy  # Copy to clipboard
rm ios-signing.p12 ios-signing.p12.b64  # Clean up
```

### ⚠️ Important

- **Back up your .p12 file immediately** — if lost, you cannot sign updates
- Store it in a password manager or encrypted drive
- **Never commit** the .p12 file to git

---

## Step 2 — Export Your Provisioning Profile

### Find Your Profile

```bash
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

You should see files like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.mobileprovision`.

### Base64 Encode

```bash
# Replace with your actual profile filename
base64 ~/Library/MobileDevice/Provisioning\ Profiles/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.mobileprovision > profile.b64
cat profile.b64 | pbcopy  # Copy to clipboard
rm profile.b64  # Clean up
```

### Ensure Profile Matches

The provisioning profile must match:
- **Bundle ID**: `com.pvjio.mamadera` (from `ios/Runner/Info.plist`)
- **App ID**: Must be enabled for distribution
- **Certificate**: Must be the same certificate in your .p12 file
- **Team**: Your Apple Developer team ID

---

## Step 3 — Add GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `IOS_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate | `MIIF...` (long string) |
| `IOS_CERTIFICATE_PASSWORD` | Password for the .p12 file | `my-secure-password` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded provisioning profile | `MHZy...` (long string) |

---

## Step 4 — CI Workflow Changes

The following changes were made to `.github/workflows/ci.yml`:

### Before (unsigned build):

```yaml
- name: Build IPA
  run: |
    flutter build ios --release --no-codesign --split-debug-info=build/
```

### After (signed build with certificate installation):

```yaml
- name: Install iOS Signing Certificates
  if: startsWith(github.ref, 'refs/tags/')
  uses: apple-actions/import-codesign-certs@v1
  with:
    p12-file-base64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
    p12-password: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}

- name: Install Provisioning Profile
  if: startsWith(github.ref, 'refs/tags/')
  run: |
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    echo "${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/Runner.mobileprovision

- name: Build Signed IPA
  run: |
    flutter build ios --release --split-debug-info=build/
  env:
    CODE_SIGN_IDENTITY: "iPhone Distribution"
    PROVISIONING_PROFILE: "Runner"
```

### Key Points

- **`if: startsWith(github.ref, 'refs/tags/')`** — Signing steps only run on version tags
- **`apple-actions/import-codesign-certs@v1`** — Official Apple action for secure certificate import
- **`--no-codesign` removed** — Build now produces properly signed apps
- **Push/PR builds** — Still run but without signing (no warning, just unsigned artifacts)

---

## Step 5 — Test the Workflow

### Create a Test Tag

```bash
# Check current tag
git tag -l

# Create a new tag (increment version)
git tag v0.0.2

# Push the tag
git push origin v0.0.2
```

### Verify in GitHub Actions

1. Go to **Actions** tab in your repository
2. Watch the `CI & Secure Build` workflow run
3. Check the **build-ios** job logs for:
   - ✅ `Install iOS Signing Certificates` — should show certificate import success
   - ✅ `Install Provisioning Profile` — should show profile installation
   - ✅ `Build Signed IPA` — should complete without codesigning warnings

### Download Signed Artifact

After the workflow completes:
1. Go to the **Actions** run → **Artifacts** section
2. Download `ios-release` (contains `ios-Runner-app.zip`)
3. Extract and verify the app is signed:

```bash
unzip ios-Runner-app.zip -d ios-signed
codesign -dvvv ios-signed/Runner.app/Runner
```

You should see signing information instead of "not signed" errors.

---

## Troubleshooting

### Error: `certificate not found`

- Verify the .p12 file is valid: `security cms -D -i profile.mobileprovision | grep -A1 DeveloperCertificates`
- Ensure the certificate password is correct in GitHub Secrets
- Check that the certificate hasn't expired

### Error: `provisioning profile invalid`

- Verify the profile matches your Bundle ID (`com.pvjio.mamadera`)
- Check the profile hasn't expired
- Ensure the profile includes the correct device capabilities (push notifications, etc.)

### Error: `build failed with exit code 65`

- Clean the build: `flutter clean && flutter pub get`
- Check Xcode project signing settings in `ios/Runner.xcworkspace`
- Verify the provisioning profile is installed correctly

### Warning Still Appears on Push/PR

This is **expected**. The signing steps only run on tags. Push/PR builds intentionally skip signing to avoid exposing secrets. The warning is harmless for development builds.

---

## Security Best Practices

1. **Rotate certificates annually** — Apple certificates expire after 1 year
2. **Use minimum permissions** — Only tag pushes can access signing secrets
3. **Never log secrets** — GitHub Actions automatically masks `*SECRET*` variables
4. **Audit access** — Regularly review who has access to repository settings
5. **Backup offline** — Store .p12 files and profile backups in encrypted storage

---

## Related Documentation

- [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
- [Provisioning Profiles](https://developer.apple.com/account/resources/profiles/list)
- [App Store Connect](https://appstoreconnect.apple.com)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [apple-actions/import-codesign-certs](https://github.com/apple-actions/import-codesign-certs)

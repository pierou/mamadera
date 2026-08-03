# Android Release Keystore Setup

This guide walks you through creating a production keystore for Google Play & F-Droid releases, and configuring it as GitHub Secrets for CI signing.

---

## Step 1 — Generate the Keystore

Run this command from your project root (`mamadera`):

```bash
keytool -genkeypair \
  -v \
  -keystore android/app/mamadera-release.jks \
  -alias mamadera-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

You'll be prompted for your distinguished name (country, organization, etc.). You can press Enter to skip most of these — they're not used by Google Play.

### ⚠️ Important

- **Back up `mamadera-release.jks` immediately.** If you lose it, you cannot update your app on Google Play.
- Store it in a password manager or encrypted drive.
- **Never commit this file to git** — `.gitignore` already excludes `*.jks`.

---

## Step 2 — Encode Keystore for GitHub Secrets

```bash
# Base64-encode the keystore (for CI)
base64 android/app/mamadera-release.jks > mamadera-keystore.b64

# Copy the content to your clipboard (macOS)
cat mamadera-keystore.b64 | pbcopy

# Clean up — you don't need this file locally anymore
rm mamadera-keystore.b64 android/app/mamadera-release.jks
```

---

## Step 3 — Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `ANDROID_KEYSTORE_BASE64` | The base64 content from Step 2 | (the long string you copied) |
| `ANDROID_KEYSTORE_PASSWORD` | Your keystore password (`YOUR_STORE_PASSWORD`) | `s3cur3P@ss!` |
| `ANDROID_KEY_ALIAS` | Key alias used above | `mamadera-key` |
| `ANDROID_KEY_PASSWORD` | Individual key password (`YOUR_KEY_PASSWORD`) | `k3yP@ss123` |

---

## Step 4 — Verify CI Signing

Push a tag to trigger a signed build (signing **only** runs on tags):

```bash
git tag v1.0.0-rc.2
git push origin v1.0.0-rc.2
```

> **Important**: Release signing with your production keystore only triggers on tag pushes. PR builds and branch pushes use debug signing automatically.

Check the GitHub Actions run — it should:
1. Decode the base64-encoded keystore from secrets
2. Sign both APK & AAB using absolute workspace paths
3. Upload signed artifacts for download

---

## Step 5 (Optional) — Validate Signature Locally

For local builds with production signing (requires keystore file):

```bash
export KEYSTORE_PATH=$(pwd)/android/app/mamadera-release.jks
export KEYSTORE_PASSWORD="your_store_pass"
export KEY_ALIAS=mamadera-key
export KEY_PASSWORD="your_key_pass"

flutter build apk --release
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

Expected output: `app-release.apk is signed` + key algorithm details (RSA SHA256).

---

## Troubleshooting

### "Keystore file not found" error in CI

This typically means:
1. **Building on a branch/PR instead of a tag** — signing only runs on tags (see Step 4)
2. **GitHub secrets not configured correctly** — verify all 4 secrets exist in Settings → Secrets
3. **Base64 encoding failed** — re-run Step 2 to regenerate the secret

### Local builds fail with "Keystore file not found"

- Make sure `KEYSTORE_PATH` is an **absolute path**: `$(pwd)/android/app/mamadera-release.jks`
- Verify the `.jks` file actually exists at that location

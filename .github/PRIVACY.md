# Privacy Policy 🛡️

**Last Updated**: 2026-08-02

## Introduction

**mamadera** is a privacy-first newborn tracking app. All data stays on your device — there is no cloud, no analytics, no telemetry. This privacy policy explains our commitment to protecting your data and your newborn's information.

## Our Philosophy

### Privacy-First by Design

- 🚫 **No analytics** or tracking (ever)
- 🚫 **No telemetry** or crash reporting
- 🚫 **No network calls** — the app is fully offline
- ✅ **Local-only storage** — all data stays on your device
- ✅ **Open source** — code is transparent and auditable
- ✅ **User control** — you own your data completely

## What Data We Store

### Local-Only Data

All data is stored locally on your device using an encrypted SQLite database (Drift). We store:

- **Baby profiles** — name, birth date, active status
- **Feeding events** — type (breast/bottle), timestamp, duration, volume in ml
- **Sleep events** — timestamp, duration in minutes
- **Diaper events** — timestamp, waste type (urine, stool, both), stool color
- **Health events** — timestamp, health subtype, encrypted notes
- **Reminder settings** — enabled/disabled state, dismissed timestamps

### Encrypted Fields

- **Notes** — user-entered free-text notes on tracking events are encrypted at rest using AES-GCM via `flutter_secure_storage`

## What We Do NOT Collect or Store

- ❌ No personal information (name is stored only locally)
- ❌ No device identifiers
- ❌ No usage statistics or analytics
- ❌ No location data
- ❌ No advertising IDs
- ❌ No cloud backups or sync
- ❌ No third-party SDKs that collect data
- ❌ No photos
- ❌ No growth measurements (weight, height)
- ❌ No developmental milestones

## Data Storage & Security

### Local Database

- **Engine**: Drift (SQLite)
- **Encryption**: SQLCipher for database-level encryption
- **Sensitive fields**: Notes encrypted with AES-GCM using keys from `flutter_secure_storage`
- **No cloud sync**: Your data never leaves your device

### Backup & Export

mamadera provides **no automatic backups**. You can export your data manually if needed.

## Permissions

### Minimal Permissions Policy

| Permission | Required | Purpose |
|------------|----------|---------|
| Notifications | Optional | Reminders (user consent) |
| Internet | Not used | Never |
| Camera | Not used | Never |
| Microphone | Not used | Never |
| Location | Not used | Never |
| Contacts | Not used | Never |
| Storage/Files | Not used | Never |

The app does not request any permissions by default. No Android or iOS permissions are declared in the manifest files.

## Data Retention

- **Forever**: Data remains on your device until you delete it
- **No automatic deletion**: You control when data is removed
- **No remote deletion**: There is no server, so no data can be deleted remotely

## Third-Party Services

### Services We Do NOT Use

- ❌ Google Analytics
- ❌ Firebase / Crashlytics
- ❌ Facebook SDK
- ❌ Ad networks
- ❌ Marketing platforms
- ❌ Data brokers
- ❌ Cloud storage

### Dependencies

We use only the following third-party packages, all of which are offline-only:

| Package | Purpose | Network Access |
|---------|---------|----------------|
| `drift` | Local SQLite database | None |
| `encrypt` | AES-GCM encryption | None |
| `flutter_secure_storage` | Secure key storage | None |
| `flutter_riverpod` | State management | None |
| `go_router` | Routing | None |
| `logger` | Logging | None |
| `url_launcher` | Opening URLs (e.g. GitHub) | Only when explicitly triggered by user |
| `package_info_plus` | Reading app version | None |
| `path_provider` | File paths | None |
| `intl` / `flutter_localizations` | i18n (EN/FR/ES) | None |
| `markdown` | Rendering terms of service | None |

## Your Rights

- **View**: All your data is visible in the app at any time
- **Edit**: You can modify any tracking event or baby profile
- **Delete**: You can remove all data from the app
- **Export**: Data export is available through the app's settings

## Children's Privacy

- mamadera is designed for parents and caregivers, not children
- The only data collected is newborn activity tracking (feeding, sleep, diapers, health)
- No data is transmitted anywhere
- No marketing to minors

## Changes to This Policy

- Any changes will be noted in the app's patch notes
- Significant changes will be communicated before taking effect

## Contact Us

If you have privacy concerns or questions:

- Open an issue on [GitHub](https://github.com/pierou/mamadera/issues)

## Our Commitment

**mamadera believes that:**

1. Privacy is a human right
2. Parents should control their children's data
3. Open source enables trust through transparency
4. Local-first architecture is the most privacy-preserving approach
5. No tracking is better than any privacy policy

---

**Thank you for trusting mamadera with your family's precious moments. Your privacy is our priority. 🍼💙**

*This privacy policy is part of our open-source commitment. Feel free to audit our code on GitHub.*
```
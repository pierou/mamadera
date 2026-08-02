# Privacy Policy 🛡️

**Last Updated**: 2026-06-05

## Introduction

**mamadera** is built with privacy as a fundamental right, not an optional feature. This privacy policy explains our commitment to protecting your data and your newborn's information.

## Our Philosophy

### Privacy-First by Design

- 🚫 **No analytics** or tracking (ever)
- 🚫 **No telemetry** or crash reporting to cloud
- 🚫 **No third-party SDKs** that collect data
- ✅ **Local-first architecture** - all data stays on your device
- ✅ **Open source** - code is transparent and auditable
- ✅ **User control** - you own your data completely

## Data Collection

### What We Collect

**mamadera does NOT collect:**
- No personal information
- No device identifiers
- No usage statistics
- No location data
- No advertising IDs

**Data stored locally on your device:**
- Feed times and duration
- Sleep patterns
- Diaper changes
- Growth measurements (weight, height)
- Developmental milestones
- Notes and observations

### How We Use Your Data

Your data is used **only** for:
- Displaying in your app interface
- Calculating statistics locally
- Generating reports for your personal use
- Enabling data export (your choice)

## Data Storage & Security

### Local Storage

- **Database**: Drift (SQLite) - encrypted for sensitive data
- **Secure Storage**: Flutter Secure Storage - keys and passwords
- **No Cloud Sync**: By default, your data never leaves your device

### Encryption

- Sensitive data (notes, medical info) encrypted at rest
- Export files can be password-protected
- All data accessible only to you via biometric or passcode

### Backup Options

**Local Export Only**:
- JSON format (encrypted option available)
- CSV format (plain text)
- User-controlled when and how to export

**Cloud Backup (Opt-In)**:
- Only if you explicitly enable it
- Uses your password to derive encryption keys
- You control what gets synced
- Can be disabled at any time

## Permissions

### Minimal Permissions Policy

| Permission | Required | Purpose |
|------------|----------|---------|
| Camera | Optional | Photo diary (user consent) |
| Storage | Optional | Export/import data |
| Notifications | Optional | Reminders (user consent) |
| Location | Not used | Never |
| Contacts | Not used | Never |

### Permission Request Flow

1. Permission requested only when feature is needed
2. Clear explanation of why it's needed
3. User can deny without affecting core functionality
4. No persistent request if denied

## Data Retention

- **Forever**: Data remains on your device until you delete it
- **Configurable**: Auto-delete old data (e.g., after 12 months)
- **No automatic deletion**: You control when data is removed

## Third-Party Services

### Services We DO NOT Use

- ❌ Google Analytics
- ❌ Firebase Crashlytics
- ❌ Facebook SDK
- ❌ Ad networks
- ❌ Marketing platforms
- ❌ Data brokers

### Services We MAY Use (Explicitly Opt-In)

- Cloud backup (if enabled by user)
- Photo storage (if user chooses)
- Data visualization (if user chooses)

## Your Rights

### Data Rights (GDPR/CCPA/COPPA Compliant)

- **Access**: View all your data anytime
- **Export**: Download your data in common formats
- **Correction**: Edit any information
- **Deletion**: Permanently remove all data
- **Portability**: Move data to another app

### How to Exercise Your Rights

- **View/Export**: Settings → Data → Export
- **Delete**: Settings → Data → Clear All
- **Notifications**: Settings → Privacy → Manage Permissions

## Children's Privacy

### COPPA Compliance

- mamadera is designed for parents, not children
- No children's data is collected beyond newborn activity tracking
- No marketing to minors
- Parental consent required for all features

## Changes to This Policy

- Any changes will be noted in the app
- Significant changes require your explicit consent

## Contact Us

If you have privacy concerns or questions:

- Open an issue on [GitHub](https://github.com/pierou/mamadera/issues)

## Data Processing

### We Are a Data Processor, Not Controller

- You (the parent) control your data
- We provide tools to manage it
- No data processing for third parties
- No data monetization

## Commitment to Privacy

**mamadera believes that:**

1. Privacy is a human right
2. Parents should control their children's data
3. Open source enables trust through transparency
4. Local-first architecture is the most privacy-preserving
5. No tracking is better than any privacy policy

---

**Thank you for trusting mamadera with your family's precious moments. Your privacy is our priority. 🍼💙**

*This privacy policy is part of our open-source commitment. Feel free to audit our code on GitHub.*
```
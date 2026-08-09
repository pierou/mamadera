# Google Play Store Submission Guide

---

## Step 1 — Create Developer Account

1. Go to **https://play.google.com/console** and sign in with your Google account
2. Pay the **$25 one-time registration fee** (this is non-refundable)
3. Fill in developer profile:
   - **Developer name**: `Pierre-Vincent Jacquier` (or your preferred public name)
   - **Developer address**: Your country
   - **Developer email & phone**: Contact info users will see
4. Accept the Developer Distribution Agreement

---

## Step 2 — Create App Entry

1. In Play Console → **+ Create app**
2. Enter:
   - **Name**: `Mamadera` (display name on Play Store)
   - **App type**: Application
   - **Free/Paid**: Free
3. You'll be taken to your app dashboard

---

## Step 3 — Default Language & Package Name

- Set **Default language** to English (US) or French depending on primary market
- Under **Package name**, verify it shows `com.pvjio.mamadera` (this must match exactly with your AndroidManifest.xml)
- You cannot change this after first upload

---

## Step 4 — App Content & Ratings

### Data Safety Section

Go to **Setup → Store presence → Data safety** and declare:

| Question | Answer |
|----------|--------|
| Do you collect any user data? | **"I don't collect, share, or enable access to any data"** (select this) |
| Is your app intended for children under 13? | Yes — "Children" (baby tracking is used by parents on behalf of infants) |
| Will users download files from other apps to yours? | No |
| Can users interact with others through shared content? | No |

Even though you select "no data collected," add this note:

> All baby tracking data is stored locally on the device using encrypted SQLite database. Data never leaves your phone unless you explicitly export it via CSV or JSON. We do not collect, share, or transmit any user data.

### Content Rating (IARC)

Complete the **Content rating questionnaire** under **Setup → App content**:

Answer honestly — mamadera should get rated **Everyone** or **Everyone 10+**. Key answers:

- Violence and gore: None
- Drug/alcohol/tobacco: None  
- Nudity/sexual content: None (breastfeeding is medical/nurturing, not sexual)
- Profanity: None
- Gambling: None
- User interaction: No online multiplayer or chat

---

## Step 5 — Pricing & Distribution

### Target Countries

Under **Release → Managed open testing** (or Production), select all countries where you want the app available. Recommended start:

| Region | Countries |
|--------|-----------|
| French-speaking | France, Belgium, Switzerland, Canada |
| English-speaking | United States, United Kingdom, Australia, Canada |  
| Spanish-speaking | Spain, Mexico, Colombia, Argentina |

### Distribution

- **Content rating**: Everyone (or as determined by IARC questionnaire)
- **Target audience**: Parents of newborns and infants
- **Age group**: All ages

---

## Step 6 — Store Listings

### Main Listing (English)

| Field | Content |
|-------|---------|
| **Title** | Mamadera Baby Tracker |
| **Short description** (80 chars max) | Privacy-first baby tracker: feedings, sleep, diapers — all offline & encrypted |
| **Full description** | Track your newborn's feedings, sleep patterns, diaper changes, and health routines with complete privacy. All data stays on your device — no cloud, no tracking, no telemetry.<br><br>**Features:**<br>• Breastfeeding & bottle feeding logs<br>• Sleep session tracker<br>• Diaper change history<br>• Health routine reminders (Vitamin D/K)<br>• Multiple baby profiles<br>• Encrypted local storage<br><br>Mamadera is open source under MIT license. Your baby data never leaves your phone. |
| **Editor's note** (optional) | Open-source, offline-first app built with Flutter & Riverpod |

### French Listing

Go to **Store presence → Localizations** → Add French:

| Field | Content |
|-------|---------|
| **Title** | Mamadera Suivi Bébé |
| **Short description** (80 chars max) | Suivi bébé 100% privé : tétées, sommeil, couches — hors-ligne & chiffré |
| **Full description** | Suivez les tétées, le sommeil, les changements de couche et la santé de votre nouveau-né avec une confidentialité totale. Toutes les données restent sur votre appareil — pas de cloud, pas de suivi.<br><br>**Fonctionnalités :**<br>• Historique des tétées (seins/biberons)<br>• Suivi du sommeil<br>• Journal des couches<br>• Rappels santé (Vitamine D/K)<br>• Profils multiples pour bébé<br>• Stockage local chiffré<br><br>Mamadera est open source sous licence MIT. Les données de votre bébé ne quittent jamais votre téléphone. |

### Spanish Listing

| Field | Content |
|-------|---------|
| **Title** | Mamadera Bebé Tracker |
| **Short description** (80 chars max) | Seguimiento privado de bebé: tomas, sueño, pañales — sin nube ni rastreo |
| **Full description** | Registra las tomas, el sueño, los cambios de pañal y la rutina de salud de tu recién nacido con privacidad total. Todos los datos se guardan en tu dispositivo — sin nube, sin telemetría.<br><br>**Características:**<br>• Registro de tomas (pecho/biberón)<br>• Seguimiento del sueño<br>• Historial de pañales<br>• Recordatorios de salud (Vitamina D/K)<br>• Múltiples perfiles de bebé<br>• Almacenamiento local cifrado |

---

## Step 7 — Screenshots & Graphics

### Required Assets

| Asset | Size | Notes |
|-------|------|-------|
| **Phone screenshots** | At least 1 (recommended: 3-8) | Upload at least one high-res phone screenshot |
| **Feature graphic** | 1024 × 500 px | This is your "hero image" — make it clean and appealing |
| **App icon** | 512 × 512 px PNG | Use existing app icon (32 dp, no transparency) |

### Capturing Screenshots

```bash
# Run on an Android emulator or device
flutter run -d <device_id> --release

# Take screenshots with adb (from terminal):
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshots/
```

Or use the built-in screenshot shortcut on your device/emulator. Show at least 3 key screens: home, history view, and baby profile.

### Feature Graphic Design Tips

Create a clean banner showing:
- App name "Mamadera" prominently  
- A subtle icon (baby bottle / heart)
- Tagline like "Privacy-First Baby Tracking"
- Use your app's color scheme (`#FFF0F5` background from splash config)

Tool: Canva, Figma, or even `flutter run` + screenshot editor works fine.

---

## Step 8 — Upload Your AAB (App Bundle)

### Build Locally with Release Signing

```bash
# Set env vars (use your actual passwords):
export KEYSTORE_PATH=/path/to/mamadera-release.jks
export KEYSTORE_PASSWORD="your_store_pass"
export KEY_ALIAS=mamadera-key
export KEY_PASSWORD="your_key_pass"

# Build the App Bundle:
make build-aab
```

The output will be at `build/app/outputs/bundle/release/app-release.aab`.

### Or Use CI Build Artifacts

If you've set up GitHub Secrets, push a tag and download the built AAB from the GitHub release artifacts.

### Upload to Play Console

1. Go to **Release → Internal testing** (start here for validation)
2. Click **"Create new release"** 
3. Under "Android App Bundle", click **"Upload new bundle"**
4. Drag & drop `app-release.aab` or select from disk
5. Fill in release notes: `"Initial internal test build"`
6. Add at least one tester (your own Google account works for Internal testing)
7. Click **Save → Review → Start rollout**

---

## Step 9 — Testing Tracks Progression

Google Play requires you to go through testing tracks before Production:

| Track | Purpose | Duration | Testers Required |
|-------|---------|----------|------------------|
| **Internal Testing** | Quick validation, up to 10 testers | Immediate rollout | You + team members only |
| **Closed Testing** | Optional but recommended for feedback | Minimum 14 days* | External users (friends/family) |
| **Open Testing** | Public beta before launch | At least a few days | Anyone can join via link |
| **Production** | Full release to all stores | After review (~2-5 days) | All users |

\* Google Play requires minimum 14 days of closed testing for first-time developers, unless you qualify for exemption.

### Skipping Closed Testing (if eligible)

If this is a simple utility app and you complete Internal testing successfully, you may be able to request production directly without the 14-day wait. Try submitting from Internal → Production and see if Google flags it.

---

## Privacy Policy URL

Google Play **requires** a publicly accessible privacy policy. Use:

```
https://raw.githubusercontent.com/pvjio/mamadera/main/.github/PRIVACY.md
```

Or host a nicely formatted version on GitHub Pages or Netlify. Set it in **Setup → App content → Privacy policy**.

---

## Checklist Before Submitting to Production

- [ ] Developer account created & verified ($25 paid)
- [ ] Package name matches exactly (`com.pvjio.mamadera`)
- [ ] Data safety section completed ("No data collected")
- [ ] IARC questionnaire submitted (Everyone rating expected)
- [ ] Main store listing + localizations filled in (EN, FR, ES)
- [ ] Feature graphic (1024×500) uploaded
- [ ] App icon (512×512) uploaded  
- [ ] Phone screenshots (at least 3) for each language
- [ ] AAB signed with release keystore & validated (`apksigner verify`)
- [ ] Completed internal testing track successfully
- [ ] Privacy policy URL is live and loads correctly
- [ ] Contact email set in developer profile

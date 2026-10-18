# App Store Connect — listing EN (en-US)

Version **1.2.1** (build 11). Fields pasted verbatim into App Store Connect →
**Versions** → English. ASC limits: name 30, subtitle 30, keywords 100, promotional text
170, description 4 000, What's New 4 000.

## App name — **keep** `Mamadera Baby Tracker` (21/30)

Approved and live since v1.1.0: renaming breaks the ASO history and re-triggers a name
uniqueness review. Change only on an owner decision.

## Subtitle — two options

| option | value | |
|---|---|---|
| **keep** | `Privacy-first newborn tracking` | 30/30 |
| candidate | `Feeding, sleep & growth` | 23/30 |

The candidate names the third measurement axis (weight / height / temperature), absent
from every field since v1.1.0. Owner decision — ASC indexes the subtitle.

## Keywords (100)

```
baby,newborn,feeding,sleep,diaper,tracker,privacy,offline,lactation,backup,growth
```

`growth` is added to the nine original tokens, none removed. 81/100, no accents, no
spaces after commas (ASC counts both).

## Promotional text (170)

```
Weight, height and temperature, encrypted on your device and shown in History next to feeds, sleep and diapers. No data ever leaves the phone.
```

## Description (4 000)

```
Track your baby's feedings, sleep, diapers and health routines — all stored locally on your device with encryption. No cloud, no telemetry, no tracking.

WHAT YOU CAN DO
• Log breast and bottle feeds, solid food in grams, sleep sessions and diaper changes — including stool texture
• Record weight, height and temperature: values are encrypted on the device and read back in History, alongside every other event
• Edit or delete a measurement straight from History
• Follow health routines (Vitamin D & K) with built-in reminders, and create custom reminders tied to any care
• Keep reminders independent for each of your babies
• Record an event with its exact date and time, even after the fact
• Keep separate profiles for each of your babies
• Export all your data as a single JSON file and restore it anytime — fully on-device, no account and no cloud needed

PRIVACY BY DESIGN
Mamadera is privacy-first by construction: sensitive notes and measurements are encrypted at rest, the app asks for no unnecessary permissions, and nothing is ever uploaded. The only way data leaves the device is the JSON export you start yourself, then the share sheet of your device. It is free, open source and MIT licensed.

Perfect for parents who value their privacy — and for newborns who deserve theirs.
```

## What's New — paste-ready file

[`../release-notes/apple-whatsnew-en.txt`](../release-notes/apple-whatsnew-en.txt) —
generated from `assets/patch_notes/en.json`, so the store text and the in-app "What's
New" dialog never say two different things.

## Notes for the review team

- No demo account: the app works from first launch, terms accepted, nothing to connect.
- To see the encrypted measurements: Home → Weight button → save, then the History tab —
  the row appears there with its own unit.
- "Breast milk" offers an ml / minutes toggle; the other feeding types have a fixed unit.
- No medical content, no diagnosis, no advice: the app stores what the parent enters.
  Breastfeeding content is parental, not sexual.

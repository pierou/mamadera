# Google Play Console — listing EN (en-US)

Version **1.2.1** (build 11 → `versionCode` 11). Limits: title 30, short description 80,
full description 4 000, release notes 500.

## Title — two options

| option | value | |
|---|---|---|
| **keep** | `Mamadera Baby Tracker` | 21/30 |
| candidate | `Mamadera: Baby Growth Log` | 24/30 |

Play's title carries the strongest ASO weight on a live listing: rename on strategy,
not per release. Owner decision.

## Short description — two options

| option | value | |
|---|---|---|
| **keep** | `Privacy-first baby tracker: feedings, sleep, diapers — all offline & encrypted` | 78/80 |
| candidate | `Private baby tracker: feeds, weight, sleep, diapers — offline and encrypted` | 75/80 |

The candidate names weight, absent from every listing since v1.1.0 while the measurement
has been in production since v1.2.0.

## Full description (4 000)

```
Track your newborn's feedings, sleep patterns, diaper changes, growth and health routines with complete privacy. All data stays on your device — no cloud, no tracking, no telemetry.

Features:
• Breastfeeding and bottle feeding logs, plus solid food in grams
• Weight, height and temperature — values encrypted on the device
• Growth measurements appear in your History next to every other event, and can be edited or deleted right there
• Diaper change history, with stool texture
• Health routine reminders (Vitamin D/K) — plus your own custom reminders tied to any care
• Reminders kept independent for each child
• Log an event with its exact date and time, even after the fact
• Multiple baby profiles
• JSON backup & restore — export everything, restore anytime, on-device
• Notes encrypted at rest

Mamadera is open source under the MIT license. Your baby's data never leaves your phone, unless you start the JSON export yourself and hand the file to your device's share sheet.
```

## Release notes (500)

Paste [`../release-notes/play-en.txt`](../release-notes/play-en.txt) — 376/500.

## Data safety (unchanged unless something really changed)

"I don't collect, share, or enable access to any data" — unchanged: v1.2.1 adds a `unit`
column to the local database, no network, no new permission. Keep the free-text note:

> All baby tracking data is stored locally on the device in a SQLite database; sensitive
> free-text notes are encrypted field-by-field with AES-256-GCM (the database file itself
> is not encrypted). Data never leaves your phone unless you start the JSON export
> yourself. We do not collect, share, or transmit any user data.

Category: **Health & Fitness** (recommendation — the category currently live on the listing
is not recorded in `docs/`, check it in Console before changing it). Target audience:
parents of newborns, declared "Children" — already in place, unchanged.

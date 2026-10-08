# Neonatal burden — where babies die, 2024

Survey date: 2026-10-05. Purpose: decide *where* mamadera should go, and whether going there is
even the right intervention.

## Method (reproduce this, do not re-guess)

| Step | Command / source | Note |
|---|---|---|
| Rates | `curl -sL "https://ourworldindata.org/grapher/neonatal-mortality-wdi.csv?v=1&csvType=full&useColumnShortNames=true"` | OWID ← WDI/IGME |
| Counts | `curl -sL "https://ourworldindata.org/grapher/number-of-neonatal-deaths-igme.csv?v=1&csvType=full&useColumnShortNames=true"` | OWID ← IGME |
| Join | `join -t$'\t'` on ISO code, year 2024 | aggregate rows `OWID_*`, `AFR/ASI/EUR/LAM/WLD/HIC/LIC/LMC/MIC` must be filtered out |

**Two traps that cost time on 2026-10-05 — recorded so nobody repeats them:**

1. The OWID `neonatal-mortality-wdi` column is a **SHARE IN PERCENT** ("Share of newborns who die
   before reaching 28 days of age"), **not per 1 000**. India returns `1.67`, Nigeria `3.90`.
   Read as per-1000 these look like a 20x error in the opposite direction from reality.
   **Multiply by 10** to get the conventional NMR per 1 000 live births.
2. `api.worldbank.org/v2/...` returns an **HTML 5xx error page** from this Mac for these indicator
   codes — and the codes I first tried (`SH.DTH.NMRT`) were wrong anyway (correct: `SH.DYN.NMRT`,
   `SP.DYN.IMRT.IN`). The World Bank API was unusable in this session; OWID's flat CSV works and is
   the same IGME data. Do not burn time on the WB API again without new information.
3. `apps.who.int/gho/athena` returns an HTML "legacy" shell, not JSON. Dead end too.

## Headline

- **2 271 170 neonatal deaths worldwide, 2024.** Africa 1 178 799 · Asia 978 483 · low-income
  countries 635 706. (OWID `number-of-neonatal-deaths-igme`, aggregate rows.)
- WHO: ~**1 million die in the first 24 hours**; **75% in the first week**; neonatal deaths are
  **47% of all under-5 deaths**; NMR fell 44% since 2000 (18.6 → 10.4/1000); country range
  **0.7–39.4/1000**; **64 countries will miss the 2030 SDG target of NMR < 12/1000**.
  <https://www.who.int/news-room/fact-sheet/detail/newborn-mortality> (2024-03-14)

## Ranked by RATE (NMR per 1 000 live births, 2024)

This ranking answers *"where is a newborn most likely to die?"*

| # | Country | NMR | Neonatal deaths |
|---|---|---|---|
| 1 | South Sudan | 39.5 | 13 744 |
| 2 | Nigeria | 39.0 | 295 006 |
| 3 | Pakistan | 36.1 | 248 523 |
| 4 | Somalia | 34.2 | 27 537 |
| 5 | Zimbabwe | 33.7 | 16 739 |
| 6 | Afghanistan | 33.1 | 49 429 |
| 7 | Liberia | 32.9 | 5 649 |
| 8 | Niger | 32.8 | 36 634 |
| 9 | Guinea-Bissau | 32.0 | 2 080 |
| 10 | Chad | 30.4 | 26 626 |
| 11 | Central African Rep. | 29.9 | 7 362 |
| 12 | Guinea | 29.8 | 14 644 |
| 13 | Lesotho | 28.5 | 1 582 |
| 14 | Sierra Leone | 28.3 | 7 350 |
| 15 | Mali | 28.0 | 27 067 |
| 16 | Côte d'Ivoire | 27.4 | 27 601 |
| 17 | Benin | 27.2 | 13 130 |
| 18 | Djibouti | 27.1 | 662 |
| 19 | Equatorial Guinea | 26.3 | 1 490 |
| 20 | Ethiopia | 25.2 | 104 789 |
| 21 | Mozambique | 25.1 | 32 136 |
| 22 | Eswatini | 25.0 | 735 |
| 23 | Cameroon | 24.8 | 24 029 |
| 24 | Burkina Faso | 23.8 | 17 516 |
| 25 | Sudan | 23.7 | 39 470 |
| 26 | Malawi | 23.6 | 15 906 |
| 27 | DR Congo | 23.6 | 105 425 |
| 28 | Madagascar | 23.1 | 23 361 |
| 29 | Gambia | 23.0 | 1 891 |
| 30 | Togo | 22.6 | 6 606 |

## Ranked by ABSOLUTE DEATHS (2024)

This ranking answers *"where does an app reach the most lives?"* — it is a **different list**.

| # | Country | Neonatal deaths | NMR |
|---|---|---|---|
| 1 | India | 386 212 | 16.7 |
| 2 | Nigeria | 295 006 | 39.0 |
| 3 | Pakistan | 248 523 | 36.1 |
| 4 | DR Congo | 105 425 | 23.6 |
| 5 | Ethiopia | 104 789 | 25.2 |
| 6 | Bangladesh | 62 138 | 17.9 |
| 7 | Afghanistan | 49 429 | 33.1 |
| 8 | Tanzania | 47 450 | 19.9 |
| 9 | Indonesia | 40 915 | 9.2 |
| 10 | Sudan | 39 470 | 23.7 |
| 11 | Uganda | 36 739 | 21.3 |
| 12 | Niger | 36 634 | 32.8 |
| 13 | Egypt | 33 761 | 13.9 |
| 14 | Mozambique | 32 136 | 25.1 |
| 15 | Kenya | 31 481 | 20.7 |
| 16 | Yemen | 29 116 | 20.9 |
| 17 | Côte d'Ivoire | 27 601 | 27.4 |
| 18 | Somalia | 27 537 | 34.2 |
| 19 | Mali | 27 067 | 28.0 |
| 20 | Chad | 26 626 | 30.4 |

**Nigeria and Pakistan are the only countries in the top 3 of BOTH lists** — highest rate and
top-3 absolute burden. That is the intersection worth targeting if one country must be chosen.

## The two rankings disagree, and that is the decision

- Highest **rate** countries are mostly small, fragile, low-literacy, low-connectivity states
  (South Sudan, Somalia, CAR, Chad, Niger, Guinea-Bissau, Djibouti). Reaching them is expensive,
  and several are active-conflict zones.
- Highest **count** countries are large middle-income states with real digital infrastructure and
  mass CHW cadres (India, Bangladesh, Indonesia, Egypt) — but their rate is already lower, and
  India/Indonesia/Egypt are regulated, crowded, sovereign-procurement markets.
- **Nigeria + Pakistan sit in the middle of both curves**: high rate, huge count, big CHW cadres,
  functioning app stores. See [`2026-10-05-delivery-feasibility.md`](2026-10-05-delivery-feasibility.md).

## Verified state of mamadera today (v1.2.0, checked 2026-10-05, not inherited)

| Fact | Evidence |
|---|---|
| Locales shipped: **fr, en, es only** | `lib/l10n/app_{fr,en,es}.arb` |
| `minSdk = flutter.minSdkVersion` resolves to **API 24 / Android 7.0 (2016)** | `android/app/build.gradle.kts:28` + `~/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:26` (`val minSdkVersion: Int = 24`), Flutter **3.44.8** stable |
| Release APK **60 MB**, debug 187 MB | `build/app/outputs/flutter-apk/app-release.apk` (2026-08-03) |
| **No `abiFilters` / splits / deferred-components** → the APK carries every ABI | grep over `android/` |
| `applicationId = com.pvjio.mamadera` | `android/app/build.gradle.kts:27` |
| **NOT published on F-Droid** — checked with the *correct* id after a false negative | `f-droid.org/en/packages/com.pvjio.mamadera/` → **404** (an earlier check against `org.mamadera` also 404'd, but that id was simply wrong) |
| `.f-droid/` holds only `description/en-US/mamadera.md` — metadata staged, repo never submitted | `find .f-droid -type f` |
| **Release build has no INTERNET permission** — offline is enforced by the manifest, not by convention | `android/app/src/main/AndroidManifest.xml` has **zero** `uses-permission`; `INTERNET` appears only in `debug/` and `profile/` |
| Reminders are **in-app banners only — no system notification exists** | `docs/ROADMAP-reminders-and-sync.md` §0: no `flutter_local_notifications` in `pubspec.yaml` |
| **No clinical content of any kind** | `grep -rniE 'danger sign|triage|referral|seek care|warning sign' lib/` → 1 hit, a code comment in `feedback_screen.dart:14` about *bug* triage |
| Tracking surface = 4 types | `TrackingType { miam, sante, caca, dodo }`, `lib/shared/domain/entities/tracking_type.dart` |
| Health subtypes are cosmetic hygiene items | eye/face/nose cleaning, belly button, Vit D daily, Vit K q30d — `reminder_providers`, `track_button.dart` |
| Growth now includes temperature/weight/length | `features/growth/domain/entities/measure_kind.dart` |
| Zero networking, zero sync code | ROADMAP §0: `grep -i sync lib/` → only `dart:async`; no networking dep in `pubspec.yaml` |

**Consequence of the last three rows:** the app today records that a baby was fed and slept, and
never asks *"is this baby sick right now?"*. Every killer in
[`2026-10-05-clinical-evidence.md`](2026-10-05-clinical-evidence.md) — prematurity, birth
asphyxia, neonatal sepsis — is invisible to its current data model.

---
*Archive of a research pass. Related:* [`README.md`](README.md) *for provenance and confidence marks.*

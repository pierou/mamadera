# Store package — mamadera v1.2.1 (build 11)

Everything needed to publish **1.2.1+11** on Google Play and the App Store, per listing
language. Text is paste-ready, one file per console field, so the consoles and this repo
cannot disagree. Run `python3 store/v1.2.1/check.py` before uploading: it enforces the
consoles' own character limits and regenerates the Apple notes from the app's patch notes.

```
store/v1.2.1/
├── README.md                  ← this file: what goes where, what is still missing
├── check.py                   ← verifies limits + note consistency + screenshot inventory
├── capture.sh               ← recaptures Play screenshots for fr/es/en on the emulator
├── fields/                  ← paste-ready listing text, one file per console field × locale
│   ├── apple-<locale>-name.txt / -subtitle.txt (≤30)      ← editorial, never machine
│   ├── apple-<locale>-keywords.txt   (≤100)               ← editorial, never machine
│   ├── apple-<locale>-promo.txt      (≤170)               ← TranslateGemma + aligned
│   ├── apple-<locale>-description.txt (≤4000)             ← TranslateGemma + aligned
│   ├── play-<locale>-title.txt       (≤30)                ← editorial
│   ├── play-<locale>-short.txt       (≤80)                ← TranslateGemma + aligned
│   └── play-<locale>-description.txt (≤4000)              ← TranslateGemma + aligned
├── machine/<locale>/        ← RAW TranslateGemma output, kept: proves who wrote each sentence
├── release-notes/
│   ├── apple-whatsnew-<locale>.txt   ← generated from assets/patch_notes/<locale>.json
│   └── play-<locale>.txt             ← TranslateGemma from source/en, ≤500 (Play's own limit)
├── apple/<locale>.md          ← per-locale ASC guide: keep vs change, review notes
├── play/<locale>.md           ← per-locale Play guide: keep vs change, data safety
├── fdroid/
│   ├── build-entry.yml        ← the 1.2.1 build block for docs/fdroiddata/*.yml (stale at 1.0.1)
│   └── changelogs/11[_<lang>].txt  ← F-Droid changelogs, en/fr/es
└── screenshots/
    ├── play/<locale>/         ← 8 png 1280×2856, ribbon-free, verified,
    │                            NAMED `<locale>-<screen>.png` (fr-home.png …) — the locale is
    │                            in the filename because the folder is not the record
    └── asc/<locale>/<size>/   ← the four iPhone sizes + two iPad sizes, same naming
```

`<locale>` = `fr`, `en`, `es`. Names, subtitles and Play titles are **not** in `fields/` as
translations: they are owner decisions, documented as keep-vs-candidate tables in
`apple/<locale>.md` and `play/<locale>.md`, and carried verbatim in `store/source/<locale>/`.

## How the French and Spanish got here

Built, not typed: `python3 scripts/build_store_package.py --translate`. English canonical in
`store/source/en/` → TranslateGemma (`tg-translate`, box, temp 0) → raw output archived in
`machine/<locale>/` → term alignment cited to `lib/l10n/app_<locale>.arb` → `fields/`. Two
fixes the alignment made here are load-bearing, and both were the model's choices:

- « rien n'est jamais **téléchargé** » → « rien n'est jamais **envoyé** ». In French
  *télécharger* means **download**: the model had turned "nothing is ever uploaded" into a
  weaker claim in the single sentence that carries the privacy promise. Authority:
  `arb:exportDataWarning`, the app's own « rien n'est envoyé automatiquement ».
- « crypté(s) » / « encriptación » → « chiffré(s) » / « cifrado » — register, and consistent
  with the rest of the listing.

## Build identity — check this before uploading anything

| | |
|---|---|
| Version | `1.2.1` |
| `versionCode` / build | `11` (the rc builds shared `+10`; Play rejects one versionCode on two tracks) |
| Tag | `v1.2.1` → `9e61377` (merged to `main` through PR #41 and #42) |
| Schema | v12 — `tracking_events.unit` (additive, no re-key) |
| Export format | 3 (importer accepts 2 and 3) |
| Bundle / package | `com.pvjio.mamadera` |

## Google Play — https://play.google.com/console

Release notes are per-language on Play, so each localization gets its own text.

| Field | fr | en | es | limit |
|---|---|---|---|---|
| Title | keep `Mamadera Suivi Bébé` | keep `Mamadera Baby Tracker` | keep `Mamadera Seguimiento Bebé` | 30 |
| Short description | `fields/play-fr-short.txt` | `fields/play-en-short.txt` | `fields/play-es-short.txt` | 80 |
| Full description | `fields/play-fr-description.txt` | `fields/play-en-description.txt` | `fields/play-es-description.txt` | 4 000 |
| Release notes | `release-notes/play-fr.txt` | `release-notes/play-en.txt` | `release-notes/play-es.txt` | 500 |
| Screenshots | `screenshots/play/fr/` | `screenshots/play/en/` | `screenshots/play/es/` | 8 each, 1280×2856 |

Track sequence: upload the signed AAB from the `v1.2.1` tag (CI `build-android`, production
keystore) → **internal testing** → **production**. Release notes above go in the release's
"Release notes" box, in each language, not only in the store listing.

## App Store — App Store Connect

| Field | fr | en | es | limit |
|---|---|---|---|---|
| Name | keep `Mamadera Suivi Bébé` | keep `Mamadera Baby Tracker` | keep `Mamadera Bebé` | 30 |
| Subtitle | keep, or candidate in `apple/fr.md` | ← | ← | 30 |
| Keywords | `fields/apple-fr-keywords.txt` | `fields/apple-en-keywords.txt` | `fields/apple-es-keywords.txt` | 100 |
| Promotional text | `fields/apple-fr-promo.txt` | `fields/apple-en-promo.txt` | `fields/apple-es-promo.txt` | 170 |
| Description | `fields/apple-fr-description.txt` | `fields/apple-en-description.txt` | `fields/apple-es-description.txt` | 4 000 |
| What's New | `release-notes/apple-whatsnew-fr.txt` | `…-en.txt` | `…-es.txt` | 4 000 |

Build: **Xcode Cloud** archives and uploads on any push to `main` — attach the resulting
build to the 1.2.1 version in ASC. Screenshots go in the Media section, one folder per
device slot (`asc/<locale>/1284x2778`, `1242x2688`, `2688x1242`, `2778x1284`, and the
iPad `1668x2388` / `2048x2732`).

## Marketing art (already produced, trilingual — `store/`)

| File | Size | Slot |
|---|---|---|
| `../play_feature_graphic{,_en,_es}.png` | 1024×500 | Play feature graphic |
| `../appstore_promo{,_en,_es}.png` | 1280×800 | ASC web presence |
| `../asc_header_3840x1646{,_en,_es}.png` | 3840×1646 | ASC product page header |
| `../asc_header_5244x2950{,_en,_es}.png` | 5244×2950 | ASC product page header (large) |
| `../asc_search_result_1200x628{,_en,_es}.png` | 1200×628 | ASC search result card |
| `../appstore_promo_portrait_*_{en,es}.png` | 4 portrait sizes | ASC portrait slots |

No suffixed = French. Regenerate with `/usr/bin/python3 mamadera_banner_final.py`.
App icon: `flutter_launcher_icons` output — 1024×1024 for ASC, 512×512 for Play.

## URLs and declarations (unchanged by 1.2.1)

- **Privacy policy** — `https://raw.githubusercontent.com/pierou/mamadera/main/.github/PRIVACY.md`
  (verified HTTP 2026-10-18). **`docs/google-play-setup.md` line "Step 9" still prints
  `pvjio/mamadera`, which does not exist** — use the `pierou` URL, or fix that doc.
- **Data safety** — "no data collected", unchanged: 1.2.1 adds a local `unit` column, no
  network, no new permission. Free-text note in `play/<locale>.md`.
- **Content rating** — IARC unchanged. ASC export compliance keeps
  `ITSAppUsesNonExemptEncryption = true` (own AES-GCM, not CryptoKit).

## Still to do before upload (the honest gap list)

| # | Gap | Why it matters | Status / fix |
|---|---|---|---|
| 1 | ~~Play screenshots were v1.2.0 UI~~ | the old EN home printed `Last done: 10/08/2026 07:PM` — the exact missing-minutes bug 1.2.1 fixes | **done 2026-10-18** — fr/en/es recaptured, 8 screens each, verifier proves size + ribbon-free, in `screenshots/play/<locale>/` |
| 2 | ~~No ES app screenshots at all~~ | Play wants a set per localization | **done for Play** (`screenshots/play/es/`) — ASC still open |
| 3 | **`screenshots/asc/**` are still v1.2.0 UI** | they show `Quantité : 80 min` **and** `Durée : 80 min` on one sleep row (fixed in rc.2) and no measurement row in the timeline — this release's headline feature | recapture per locale on the simulator: `flutter drive --target=lib/asc_driver_main.dart --driver=test_driver/asc_screenshots.dart -d 'iPhone 17' --dart-define=APP_LOCALE=fr` (then es, en) → `bash screenshots/ios/asc/postprocess.sh` → copy the size folders to `screenshots/asc/<locale>/`. Driver finders became locale-aware today; **the per-locale iOS run has not been executed yet** — that is why `check.py` prints WARN, not ok |
| 4 | The shots show the **B4 contrast defect** | « Alimento » and « Peso » are pale yellow on pale yellow: the first thing a reviewer sees on the home screenshot, and it is the documented readability complaint | open in `docs/BACKLOG.md` **B4** — a theme decision, not a screenshot fix. Do not colour-correct the PNGs |
| 5 | Subtitle/title candidates pending owner decision | Play title and ASC subtitle are indexed; renaming is an ASO decision, not a release task | decide in `apple/<locale>.md` / `play/<locale>.md` |
| 6 | ASC iPhone set is 7 screens, Play is 8 (health included) | not a rejection risk, an inconsistency between the two stores | optional: add the health sheet to `test_driver/asc_screenshots.dart` |

## F-Droid (third store, enrolment still open)

`docs/fdroiddata/com.pvjio.mamadera.yml` is parked at **1.0.1 / versionCode 2** — F-Droid
has never been given 1.1.x, 1.2.0 or this release. `fdroid/build-entry.yml` is the block to
add, and `fdroid/changelogs/11.txt` + `11_fr.txt` + `11_es.txt` are the changelogs for
`metadata/com.pvjio.mamadera/`. They build from source on F-Droid's infrastructure, so the
tag must be public and the build reproducible before the entry can land — that, not the
text, is what has been blocking it.

## Do not

- **Never market this release as reducing infant mortality.** No digital intervention has
  demonstrated a neonatal mortality effect (`docs/research/2026-10-05-clinical-evidence.md`)
  and the archive forbids it. Say what the app does; do not say what it prevents.
- **No percentile / WHO growth-curve wording** in any store text: OMS percentiles were
  explicitly refused (B8), so an ad cannot imply them.
- Do not restate the vitamin D default: B6 (opt-in) is **not** in 1.2.1, so no copy may
  claim a change there.
- Do not edit `release-notes/apple-whatsnew-*.txt` by hand — edit `assets/patch_notes/*.json`
  and run `python3 store/v1.2.1/check.py --write`. One source, two renderings.
- Do not hand-write the French or Spanish `fields/`. They are TranslateGemma's output, aligned
  by cited rules in `scripts/build_store_package.py`. Editing them locally means the next
  `--translate` run silently reverts your sentence — and the listing then ships wording nobody
  reviewed. Change `store/source/en/` (or add an `ALIGN` rule with a citation) instead.
- Do not machine-translate names, subtitles or ASO keywords.

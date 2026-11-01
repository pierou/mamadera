# App Store Connect — listing EN (en-US)

Version **1.2.1** (build 11). English is the **canonical** language: every field here is the
text in `store/source/en/`, copied by the build, never retyped. Fix a word in the source, not
in this guide and not in `../fields/`.

## App name — **keep** `Mamadera Baby Tracker`

Approved and live since v1.1.0. Renaming breaks the ASO history and re-triggers Apple's name
uniqueness review. Owner decision, not a release task.

## Subtitle — two options

| option | value | limit |
|---|---|---|
| **keep** | `Privacy-first newborn tracking` | 30/30 |
| candidate | `Feeding, sleep & growth` | 23/30 |

The candidate names the third measurement axis (weight / height / temperature), missing from
every field since v1.1.0. ASC indexes the subtitle, so this is an ASO decision, not a copy
edit.

## Fields — paste from the source

| ASC field | file | limit | origin |
|---|---|---|---|
| Name | `store/source/en/apple-name.txt` | 30 | editorial |
| Subtitle | `store/source/en/apple-subtitle.txt` | 30 | editorial |
| Keywords | `store/source/en/apple-keywords.txt` | 100 | editorial — never machine-translated |
| Promotional text | `store/source/en/apple-promo.txt` | 170 | canonical prose |
| Description | `store/source/en/apple-description.txt` | 4 000 | canonical prose |
| What's New | `../release-notes/apple-whatsnew-en.txt` | 4 000 | `assets/patch_notes/en.json` |

`../fields/apple-en-*.txt` are byte-identical copies of the source files — paste either, they are
the same bytes. What's New renders from the app's own patch notes so the store page and the
in-app "What's New" dialog cannot say two different things.

Keywords stay unaccented and space-free in French and Spanish, and editorial everywhere: they
are the tokens users type, and the model's fluent equivalents are not what ASC matches on. Its
output is archived under `../machine/<locale>/apple-keywords.txt` for the record.

## Notes for the review team

- No demo account: the app works from first launch, terms accepted, nothing to connect.
- To see the encrypted measurements: Home → **Weight** button → save, then the **History** tab —
  the row appears there with its own unit (`6.18 kg`).
- "Breast milk" offers an ml / minutes toggle; the other feeding types have a fixed unit.
- No medical content, no diagnosis, no advice: the app stores what the parent enters.
  Breastfeeding content is parental, not sexual.

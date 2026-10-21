# App Store Connect — FR sheet (fr-FR)

Version **1.2.1** (build 11). Each field has **exactly one file** in
[`../fields/`](../fields/): paste that file, never a retyped copy. This guide does not
repeat the text — it says what to keep, what to change, and why.

## Name — keep `Mamadera Suivi Bébé`

Approved and in place since v1.1.0. Renaming it breaks the ASO history and reopens a
uniqueness check on Apple's side. An owner decision, not a release task.

## Subtitle — two options

| option | value | limit |
|---|---|---|
| **keep** | `Suivi nouveau-né 100% privé` | 27/30 |
| candidate | `Tétées, sommeil, croissance` | 27/30 |

The candidate names the third measurement axis (weight/height/temperature), absent from all
fields since v1.1.0. **Warning:** the app never writes « tétées » — its button
(`homeButtonMiam`) says **Nourriture**. A subtitle that names something the screen does not
show is a gap between the listing and the app, not an improvement. `make store-check`
flags it as WARN; it is a decision to make in review, not one to let slide.

## Long fields — paste from `../fields/`

| ASC field | file | limit | origin |
|---|---|---|---|
| `Mots-clés` | `../fields/apple-fr-keywords.txt` | 100 | editorial — never machine-translated |
| `Texte promotionnel` | `../fields/apple-fr-promo.txt` | 170 | TranslateGemma, aligned |
| `Description` | `../fields/apple-fr-description.txt` | 4 000 | TranslateGemma, aligned |
| `Nouveautés` | `../release-notes/apple-whatsnew-fr.txt` | 4 000 | `assets/patch_notes/fr.json` |

The French text is TranslateGemma's, aligned term by term against
`lib/l10n/app_fr.arb`; the raw output is under [`../machine/fr/`](../machine/fr/).
If a word is wrong, fix **`store/source/en/`** (or add an alignment rule cited in
`scripts/build_store_package.py`) and re-run
`python3 scripts/build_store_package.py --translate` — editing `../fields/` locally loses
the sentence at the next build, and the listing ends up carrying text nobody has
re-read.

## Notes for the review team

- No demo account: the app works from the first launch, terms accepted, nothing to connect.
- To see the encrypted measurements: Home → button **Poids** → Enregistrer, then the
  **Historique** tab — the row appears with its unit (`6,18 kg`, French comma).
- « Lait Maternel » offers an ml / minutes toggle; the other feeding types have a
  fixed unit.
- No medical content, no diagnosis, no advice: the app records what the parent enters.
  Breastfeeding is parental content there, not sexual.

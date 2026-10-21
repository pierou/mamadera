# App Store Connect — ES sheet (es-ES)

Version **1.2.1** (build 11). Each field has **exactly one file** in
[`../fields/`](../fields/): that is the one you paste, never a transcription.

## Name — keep `Mamadera Bebé`

Approved and live since v1.1.0. Renaming it breaks the ASO history and reopens Apple's
uniqueness check. Owner's decision, not a release task.

## Subtitle — two options

| option | value | limit |
|---|---|---|
| **keep** | `Recién nacido, 100 % privado` | 28/30 |
| candidate | `Tomas, sueño y crecimiento` | 26/30 |

The candidate names the third measurement axis (peso / estatura / temperatura — weight / height /
temperature), absent from every field since v1.1.0. **Careful:** the app never writes « tomas »
nor « pecho » (never "feeds" nor "breast") — its button (`homeButtonMiam`) says **Alimento**
(Food) and the subtype (`feedingSubtypeNatural`) says **Leche Materna** (Breast milk).
`make store-check` flags this as WARN: it is a review decision, not a detail.

## Long fields — paste from `../fields/`

| ASC field | file | limit | origin |
|---|---|---|---|
| Palabras clave (Keywords) | `../fields/apple-es-keywords.txt` | 100 | editorial — never machine-translated |
| Texto promocional (Promotional text) | `../fields/apple-es-promo.txt` | 170 | TranslateGemma, aligned |
| Descripción (Description) | `../fields/apple-es-description.txt` | 4 000 | TranslateGemma, aligned |
| Novedades (What's New) | `../release-notes/apple-whatsnew-es.txt` | 4 000 | `assets/patch_notes/es.json` |

The Spanish text was produced by TranslateGemma and aligned term by term against
`lib/l10n/app_es.arb`; the model's raw output is in [`../machine/es/`](../machine/es/).
If a word does not convince, shorten **`store/source/en/`** (or add an alignment rule cited in
`scripts/build_store_package.py`) and rerun `python3 scripts/build_store_package.py --translate`.
Editing `../fields/` by hand loses that sentence on the next build.

## Notes for the review team

- No demo account: it works from first launch, terms accepted, nothing to connect.
- To see the encrypted measurements: Inicio → botón **Peso** → Guardar (Home → **Weight** button →
  Save), then the **Historial** (History) tab — the row shows up with its unit (`6,18 kg`).
- « Leche Materna » offers an ml / minutes toggle; the other types have a fixed unit.
- No medical content, no diagnosis, no advice: the app stores what the father or the mother
  records. Breastfeeding is parental content, not sexual.

# Google Play Console — FR sheet (fr-FR)

Version **1.2.1** (`versionCode` 11). Play publishes **per language**: each localisation has its
own title, its short description, its full description and **its release notes**.

## Title — two options

| option | value | limit |
|---|---|---|
| **keep** | `Mamadera Suivi Bébé` | 19/30 |
| candidate | `Mamadera : poids & tétées` | 24/30 |

The title is the strongest ASO signal of a live listing: it changes by strategy, not per release.
The candidate contains « tétées » (the app never displays that word — its button says
**Nourriture** / Food): `make store-check` flags it, to be settled at review.

## Paste from `../fields/`

| Play field | file | limit | origin |
|---|---|---|---|
| Description courte (Short description) | `../fields/play-fr-short.txt` | 80 | TranslateGemma, aligned |
| `Description complète` (Full description) | `../fields/play-fr-description.txt` | 4 000 | TranslateGemma, aligned |
| Notes de version (Release notes) | `../release-notes/play-fr.txt` | 500 | TranslateGemma, aligned |

Raw model output under [`../machine/fr/`](../machine/fr/). The ceiling of 500 characters on the
notes is Play's own, and French lengthens by 20 to 50 %: if it overflows, shorten
`store/source/en/play-release-notes.txt` and rerun
`python3 scripts/build_store_package.py --translate` — never by trimming the French.

## Data safety — unchanged by 1.2.1

« Je ne collecte, ne partage et n'autorise l'accès à aucune donnée » (I collect, share and grant
access to no data). 1.2.1 adds an `unit` column to the local database: no network, no new
permission, so nothing new to declare. Free-text note to maintain:

```text
> Toutes les données de suivi du bébé sont stockées localement sur l'appareil dans une base
> SQLite ; les notes textuelles sensibles sont chiffrées champ par champ en AES-256-GCM (le
> fichier de base lui-même n'est pas chiffré). Aucune donnée ne quitte le téléphone sauf
> export JSON volontaire. Nous ne collectons, partageons ni transmettons aucune donnée.
```

Category: `Santé et forme` (Health and Fitness — recommendation; the category actually published
is not recorded in `docs/`, check it in the Console before touching it). Audience: parents of
newborns, declared « Enfants » (Children) — already in place.

## Release notes — where to paste them

In the **release** ("Notes de version" box, per language), not only in the listing: that is what
the parent reads when updating. `../release-notes/play-fr.txt`, 427/500.

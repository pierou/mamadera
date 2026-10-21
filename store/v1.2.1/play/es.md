# Google Play Console — ES sheet (es-ES)

Version **1.2.1** (`versionCode` 11). Play publishes **per language**: each localisation has its
own title, its short description, its full description and **its release notes**.

## Title — two options

| option | value | limit |
|---|---|---|
| **keep** | `Mamadera Seguimiento Bebé` | 25/30 |
| candidate | `Mamadera: Peso y tomas` | 22/30 |

The title is the strongest ASO signal of a published listing: it changes by strategy, not per
release. The candidate says « tomas » (feeds) — a word the app never shows: its button
(`homeButtonMiam`) says **Alimento** (Food). `make store-check` warns about it.

## Paste from `../fields/`

| Play field | file | limit | origin |
|---|---|---|---|
| Descripción corta (Short description) | `../fields/play-es-short.txt` | 80 | TranslateGemma, aligned |
| Descripción completa (Full description) | `../fields/play-es-description.txt` | 4 000 | TranslateGemma, aligned |
| Notas de versión (Release notes) | `../release-notes/play-es.txt` | 500 | TranslateGemma, aligned |

Raw model output in [`../machine/es/`](../machine/es/). If a description goes over 500, shorten
**`store/source/en/play-release-notes.txt`** and rerun
`python3 scripts/build_store_package.py --translate`; the Spanish is never trimmed by hand.

## Data safety — no change in 1.2.1

« No recopilo, comparto ni permito el acceso a ningún dato » (I collect, share and grant access to
no data). 1.2.1 adds a `unit` column to the local database: no network and no new permissions, so
there is nothing new to declare. Free-text note to maintain:

```text
> Todos los datos de seguimiento del bebé se guardan localmente en el dispositivo en una base
> SQLite; las notas de texto sensibles se cifran campo por campo con AES-256-GCM (el archivo
> de la base no está cifrado). Ningún dato sale del teléfono salvo que inicies tú la
> exportación JSON. No recopilamos, compartimos ni transmitimos datos de usuario.
```

Category: **Salud y forma física** (Health and Fitness — recommendation; the published category is
not recorded in `docs/`, verify it in the Console). Audience: parents of newborns, declared
« Niños » (Children).

## Release notes — where they go

In the **release** ("Notas de la versión" box, per language), not only in the listing: that is
what the parent reads when updating. `../release-notes/play-es.txt`, 367/500.

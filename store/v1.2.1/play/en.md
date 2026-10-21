# Google Play Console — listing EN (en-US)

Version **1.2.1** (`versionCode` 11). English is the canonical language: the text below lives
in `store/source/en/` and the build copies it. Edit the source, never the copies.

## Title — two options

| option | value | limit |
|---|---|---|
| **keep** | `Mamadera Baby Tracker` | 21/30 |
| candidate | `Mamadera: Baby Growth Log` | 24/30 |

Play's title carries the strongest ASO weight on a live listing: rename on strategy, not per
release. Owner decision.

## Fields — paste from the source

| Play field | file | limit | origin |
|---|---|---|---|
| Short description | `store/source/en/play-short.txt` | 80 | canonical prose |
| Full description | `store/source/en/play-description.txt` | 4 000 | canonical prose |
| Release notes | `../release-notes/play-en.txt` | 500 | canonical, Play's own cap |

The 500-character release-notes cap is Play's, and it is the reason the French and Spanish
notes are produced from a *deliberately short* English text: a faithful French translation of
the long version came back at 578 characters. Shortening English is the fix; trimming the
French would put unreviewed human wording back into a machine-made chain.

## Data safety — unchanged by 1.2.1

"I don't collect, share, or enable access to any data". 1.2.1 adds a `unit` column to the
local database: no network, no new permission, therefore nothing new to declare. Keep the
free-text note:

> All baby tracking data is stored locally on the device in a SQLite database; sensitive
> free-text notes are encrypted field-by-field with AES-256-GCM (the database file itself is
> not encrypted). Data never leaves your phone unless you start the JSON export yourself. We
> do not collect, share, or transmit any user data.

Category: **Health & Fitness** (recommendation — the category actually live on the listing is
not recorded in `docs/`, check it in Console before changing it). Audience: parents of
newborns, declared "Children" — already in place.

## Release notes — where they go

Into the **release** ("Release notes" box, per language), not only the store listing: that is
what a parent reads when the update lands.

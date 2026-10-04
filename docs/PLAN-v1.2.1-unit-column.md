# PLAN — v1.2.1: `unit` on every tracked quantity (schema v12) + coarse/fine sliders

Companion to [`PLAN-v1.2.0.md`](PLAN-v1.2.0.md) and [`BACKLOG.md`](BACKLOG.md) (B1, B2).
Branch off `develop` when v1.2.0 is merged. Owner decisions of 2026-10-03 are the contract here.

## Why now
v1.2.0 stores `quantity` in `tracking_events` with **no unit**: the meaning is inferred from the
row's type and subtype. v1.2.0 already made that inference carry three meanings (`ml` for bottle,
`min` for sleep, `g` for solids), and the owner's decision is that **breastfeeding selects its own
unit — `ml` or `min`** — because nursing counts minutes and pumping counts millilitres, and the same
parent does both the same day. Once one subtype can hold two units, inference is no longer sufficient.
The unit becomes data.

## Schema v12 — the migration
```sql
ALTER TABLE tracking_events ADD COLUMN unit TEXT NOT NULL DEFAULT 'ml';
```
Backfill, per row, **by what the UI showed the parent** — never by inference about intent:

| condition at migration | `unit` |
|---|---|
| `type = 'dodo'` | `'min'` |
| `type = 'miam'` AND `subtype = 'artificial'` | `'ml'` |
| `type = 'miam'` AND `subtype = 'solid'` | `'g'` |
| `type = 'miam'` AND `subtype = 'natural'` | **`'ml'`** — the UI said ml, so it means ml |
| `type = 'sante'`, `caca`, anything else | `'ml'` (unused; quantity is null there) |

**No arithmetic. No conversion. No guessing minutes.** A parent who typed 20 saw "20 ml"; the row
means 20 ml. Converting a historical `natural` value to minutes would invent a measurement that was
never taken, in an app whose promise is that the numbers it shows were actually entered.

Then: the column's `DEFAULT` stops mattering for correctness because every insert path must set
`unit` explicitly — make it so, so that no future code path can write a unit-less row by accident.

### Irreversibility
`ALTER TABLE … ADD COLUMN` with a `NOT NULL DEFAULT` is additive and safe on SQLite. It is still
**one irreversible migration** in the sense that the release cannot be downgraded without losing the
column. Therefore, per AGENTS.md: the emulator pass runs **on a device that already has v11 data**
before the PR, seeded from `test/data/local/fixtures/mamadera_v10.db` migrated forward, not a fresh
install.

## Unit rules in code
| subtype | unit | selectable? |
|---|---|---|
| `natural` | `ml` **or** `min` | **yes — toggle in the feeding dialog** |
| `artificial` | `ml` | fixed |
| `solid` | `g` | fixed |
| sleep (`dodo`) | `min` | fixed |
| measurements | `g` / `cm` / `degC` from `MeasureKind.unit` | fixed |

- The toggle appears **only** for `natural`. One control, two labelled segments (`Millilitres` /
  `Minutes`), default `min` (a breastfeed is timed; a bottle is measured) — flag if you want `ml`
  as default.
- Switching the toggle does **not** convert the entered number. 20 ml is not 20 minutes. Switching
  resets the quantity to 0 and says so inline; silently re-labelling a number is exactly the defect
  this release exists to remove.
- Range follows the unit: `ml` 0–300 step 10, `min` 0–120 step 1.
- History tile, edit dialog and home feedback render **from `event.unit`**, never from a literal. The
  hardcoded `'ml'` literals removed in v1.2.0 must not come back.
- Aggregates must filter on `unit`. Nothing sums feeding volume today (verified 2026-10-03); the day
  someone writes "milk today", adding minutes to millilitres is a category error, not a rounding.

## Backup format 3
- Export writes `unit` on every event row; `exportFormatVersion` → `3`; importer accepts **1, 2, 3**.
- Format 1 and 2 backups have no `unit` → backfill with the same table above at import time, i.e.
  a restored v1.0 backup's `natural` rows become `'ml'`, never `'min'`.
- `unit` becomes part of the row contract: a row whose unit contradicts its subtype (`solid` + `ml`)
  is rejected with the existing `ImportFormatException(invalidRow)`, not silently coerced.
- Extend the export→restore→export **stability test** to cover `unit`.

## B2 — coarse + fine slider pair (owner-approved)
One widget change in `QuantityPickerInline`, reused everywhere — not four per-screen copies.
- **Coarse slider**: full range, big step (weight 200 g, temperature 1 °C, height 5 cm, volume
  50 ml, duration 30 min) — for finding the neighbourhood fast.
- **Fine slider**: a narrow window centred on the current value (weight ±100 g by 10 g, temperature
  ±1 °C by 0,1, height ±5 cm by 1 cm, volume ±50 ml by 10 ml, duration ±30 min by 5 min),
  re-centring as the coarse slider moves.
- `±steppers` stay: they are the fastest single-quantum nudge and they survive both sliders.
- Never render both sliders when the range is already narrow enough for one (avoid a control pair
  doing nothing).
- Reverting the v1.2.0 steps is **not** an option: coarse selection and fine value are both required.

## Out of scope
Sync (BACKLOG B3 — blocked on a written privacy-mandate change from the owner), no network, no
analytics, no new dependencies, no `HistoryFilter` value for growth, `TrackButton` untouched.

## Required tests
1. Migration from a **real v11 file** (extend `fixtures/` with a migrated-forward copy): `unit`
   exists, all four backfill cases correct, pre-existing rows intact, ids preserved.
2. Every `natural` row in the fixture comes back `'ml'` — and a `natural` row written by v1.2.1
   with `min` comes back `'min'`. Both halves, or the test proves nothing.
3. Toggle switches unit without converting the number, and resets quantity with a visible message.
4. Tile/dialog render from `unit`; a fixture row with `unit='min'` displays minutes, `unit='ml'`
   displays ml.
5. Import accepts 1, 2 and 3; a format-2 `natural` row imports as `'ml'`; a `solid`+`ml` row is
   rejected.
6. Export stability with mixed units present.
7. Coarse/fine: fine slider window re-centres; both sliders clamp to the kind's absolute bounds.

## Gates
1. `flutter analyze --fatal-infos --fatal-warnings` → clean
2. `flutter test test/data/local/ test/features/home/ test/features/history/ test/features/export/ test/features/import/` → green, 0 skipped
3. `flutter test` → green, counts pasted
4. **Emulator pass, in this order** (AGENTS.md): old build installed and seeded → new build over it
   → screenshots on `Small_Phone` and one normal target, **viewed, not just captured** → manual entry
   of a ml feeding, a min feeding, a solid and a weight → export inspected. Simulator id and what was
   seen recorded in the PR description.

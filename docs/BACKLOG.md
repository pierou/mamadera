# BACKLOG — known debt, deliberately not paid

Things we know are wrong, cheap-ish to fix, and chose not to fix in the release at hand.
Each entry says **why it was deferred** and **what makes it urgent**, so the next person can
re-decide instead of re-discovering. Nothing here is hidden; nothing here is approved silently.

---

## B1 — `tracking_events.quantity` has no unit column

**Status:** open · **Severity:** medium · **Cost:** one migration (schema v12) + export format bump
**Found:** 2026-10-03, while adding the `solid` feeding subtype for v1.2.0
**Files:** `lib/data/local/app_db.dart:28`, `lib/features/history/presentation/widgets/history_tile.dart:134`,
`lib/features/home/presentation/widgets/feeding_tracking_dialog.dart:121`,
`lib/features/history/presentation/widgets/edit_event_dialog.dart:243`

### The debt
`tracking_events.quantity` is a `REAL` with no unit. Its meaning is **inferred from the row's
type and subtype**:

| type | subtype | quantity means |
|------|---------|----------------|
| `miam` | `natural` | millilitres (expressed milk) |
| `miam` | `artificial` | millilitres of formula |
| `miam` | `solid` ← new in v1.2.0 | **grams** |
| `dodo` | — | minutes |

`FeedingEvent` has **no duration field** — `quantity` is the only number, and it has always held
millilitres for both milk subtypes. Anyone tempted to relabel `natural` as "minutes at the breast"
is inventing a semantic the stored data never had, and would display every existing expressed-milk
record as a breastfeeding duration. `feeding_tracking_dialog_test.dart`'s *"natural keeps millilitres"*
test exists because a plan asserted minutes, an implementation obeyed, and nothing else checked.

Three call sites hardcode `'ml'` for feeding and derive nothing from the subtype
(`history_tile.dart:134` does `feeding: (_) => 'ml'`). The unit is a property of the *event*, but
it lives in the *code that renders the event*.

### Why it was accepted
This was already true before v1.2.0 — minutes vs ml was the same inference. Adding `solid` extends
existing debt rather than creating it, and the alternative was a schema migration landing days before
the v10→v11 re-key had been run on a single real device. Two irreversible migrations in one release,
both unverified on hardware, is how you lose a user's data.

### What makes it urgent
1. **The day a meal is logged in ml and g at once** — a bottle *and* a purée at one sitting — the
   model cannot express it. One row per event, one number, one inferred unit: the second food's
   quantity becomes ambiguous or the meal has to be split into two events with no link between them.
2. **Any future import of a foreign format** (another app's export, a spreadsheet restore) cannot be
   validated: an out-of-range value is only detectable if you know what unit you're checking against.
3. **Rendered output is wrong for `solid`** unless every display site was updated in lockstep. A missed
   site prints "40 ml" for 40 g of purée. That is a wrong health number on screen, in an app whose
   entire promise is correct health numbers. Four sites hardcoded `'ml'` for all feeding and had to be
   found and fixed in v1.2.0 — the fourth was not in the plan's list.
4. `measurements` (v1.2.0) *does* carry a `unit` column (`app_db.dart:102`). The schema now contradicts
   itself: one table states its unit, the other assumes it.

### Decision (owner, 2026-10-03): fix it in v1.2.1, and breastfeeding becomes MINUTES
Per-subtype units are now the product contract, not an accident of inference:

| subtype | quantity means | `unit` |
|---------|----------------|--------|
| `natural` | **minutes at the breast** | `min` |
| `artificial` | millilitres of formula | `ml` |
| `solid` | grams of solid food | `g` |
| `dodo` | minutes | `min` |

That makes the `unit` column a **prerequisite**, not a cleanup: without it, `quantity` would hold
minutes and millilitres under one subtype name with nothing distinguishing them.

### The backfill trap, stated before anyone writes the migration
Rows written before v1.2.1 under `natural` contain **millilitres** — entered through an `ml` picker,
labelled `ml`, on builds already shipped. There is no way to recover whether a given historical
`natural` row of `20` meant 20 ml or 20 minutes, so **do not convert them**. They backfill to `'ml'`
and stay `'ml'`, truthfully. Consequences, all of them intended:

- `natural` rows carry two units across time, distinguished only by `unit`. Any query, chart or
  "last fed" logic that ignores `unit` will mix volumes and durations. Verify there is no such query
  before shipping — today there is none, nothing sums feeding volume (checked 2026-10-03).
- **Expressed milk loses its input field.** Once breast means minutes, there is nowhere to record
  "30 ml at the pump". If that matters — and for a pumped-milk parent it will — it needs a fourth
  subtype (`pumped`) or a second optional field, decided before the migration, not after it.
- Duration of a feed becomes available per row, which is what a paediatrician asking "how long does
  she feed?" actually wants. That is the gain paying for all of the above.

### The fix
Schema v12: `ALTER TABLE tracking_events ADD COLUMN unit TEXT`. Backfill honestly, per row:
`sleep`→`min`; `miam`+`artificial`→`ml`; `miam`+`solid`→`g`; **`miam`+`natural`→`ml` for every row
that already exists** (that is what they mean), and `'min'` only for rows written by v1.2.1 and later.
Default for new rows comes from the subtype at insert time, so no code path can write a unit-less row.
Then make every read path render from `unit` and delete the hardcoded `'ml'` literals. Export format 3,
importer accepts 2 and 3, and a format-2 backup's feeding rows backfill to `'ml'` — never `'min'`.
Same discipline as v11: explicit column list in any `INSERT … SELECT`, export stability test extended
to cover `unit`, and an emulator migration pass with pre-existing v11 data before the PR (AGENTS.md).

**Ordering:** v1.2.0 (schema v11) ships and is verified on a device first. v1.2.1 carries v12. Two
unverified irreversible migrations in one release is how a re-key goes wrong with no rollback.

### Do not
Do not "fix" this by widening reminder matching to `type == miam`. Reminders match `subtype`
exactly (`reminders_repository_impl.dart:58`) — that is why a purée does **not** silence a milk
reminder. That exactness is behaviour, not oversight.

---

## B2 — Weight slider has 1980 stops → coarse + fine slider pair

**Status:** **approved for v1.2.1** (owner, 2026-10-03) · **Severity:** low · **Cost:** UI, ~2 h
**Found:** 2026-10-03, when the step moved from 200 g to 10 g

Half a pixel per stop on a phone. The slider is an aiming device, not an input device; the text
field and the ±steppers set the real value. Accepted deliberately because 10 g of granularity is
what the parent is looking at, and a coarse slider is a lesser sin than a coarse measurement.

**Decision:** two sliders, not one. A **coarse** slider spanning the whole range for rapid finding
(50 g, or 100 g below 3 kg) and a **fine** slider spanning a narrow window around the current value
for the exact one (±50 g, step 10 g), the window re-centring as the coarse slider moves. Same pattern
resolves temperature (coarse 33–42 by 0,5, fine ±1 °C by 0,1) and height. The ±steppers stay — they
are the fastest way to nudge one quantum, and the fine slider is the fastest way to see the neighbours.
Reused across all measurement kinds and the feeding picker, so this is one widget change, not four.
Reverting the step to 200 g is **not** an option: coarse selection and fine value are both required.

---

## B3 — v1.3.0 sync requires a written change to the privacy mandate

**Status:** blocked on the owner · **Severity:** structural
**Files:** `docs/ROADMAP-reminders-and-sync.md` §7 decision 5, `README.md` privacy promises

The app's core promise is *no network transport exists anywhere*. LAN peer sync contradicts that
sentence, so it is not a feature decision but a promise decision, and only the owner can rewrite the
promise. No code, no dependency, no spike until that sentence changes — see `AGENTS.md`
"Privacy-First Mandates (NON NEGOTIABLE)".

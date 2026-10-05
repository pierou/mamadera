# PLAN — solid food feeding subtype (`solid`), quantity in grams (v1.2.0)

Companion to [`PLAN-v1.2.0.md`](PLAN-v1.2.0.md) and [`BACKLOG.md`](BACKLOG.md) (read B1).
Branch: `feat/v1.2.0-growth-and-baby-scoped-reminders`. Do not branch, do not commit.

## Why
`FeedingSubtype` has exactly two values today — `natural` (minutes at the breast) and `artificial`
(millilitres of bottle). A baby starting solids has nowhere to write "40 g of purée". This adds the
third type with a gram selector.

**No schema migration.** `tracking_events.quantity` is already `REAL` nullable
(`lib/data/local/app_db.dart:28`) and already unit-inferred (minutes for sleep, ml for bottle).
Grams joins that inference. The debt this creates is written down in `BACKLOG.md` B1 — do not
"fix" it here by adding a `unit` column; that is schema v12, a separate release, for the reason
stated there (two unverified irreversible migrations in one release is how you lose someone's data).

## Verified current state (anchors, trust these)
- `lib/shared/domain/entities/tracking_enums.dart:17-46` — `enum FeedingSubtype { natural, artificial }`,
  `dbValue` is an **exhaustive `switch`** (the compiler will force you to handle the new case — good),
  `fromDbValue` ends with **`default: return null`** (silent, see tests below).
- `lib/features/home/presentation/widgets/feeding_tracking_dialog.dart:121` — `unit: 'ml'` hardcoded.
- `lib/features/history/presentation/widgets/edit_event_dialog.dart:243` — `unit: 'ml'` hardcoded.
- `lib/features/history/presentation/widgets/history_tile.dart:134` — `feeding: (_) => 'ml'` hardcoded.
- `lib/features/reminders/data/repositories/reminders_repository_impl.dart:58` — reminders match
  `t.subtype.equals(subtypeValue)`, i.e. **exact subtype**.
- `QuantityPickerInline` takes `unit`, `min`, `max`, `decimals`, `step` (the ±steppers exist already —
  reuse them, do not rebuild).

## Behaviour contract
| subtype | quantity means | unit label | picker range | step |
|---------|----------------|------------|--------------|------|
| `natural` | **millilitres** (expressed milk) | `ml` | unchanged | unchanged |
| `artificial` | millilitres | `ml` | unchanged | unchanged |
| `solid` | **grams** | `g` | 0 – 1000 | 5 |

> **Correction to this plan, same day.** An earlier revision of this table said `natural` meant
> "minutes at the breast". It was wrong, and it was checked against nothing: `FeedingEvent` has no
> duration field, and `quantity` has stored millilitres for both milk subtypes since the column
> existed. An implementation that obeyed the plan would have relabelled every existing expressed-milk
> record as a breastfeeding duration — a coherent, consistent, false health record. The contract above
> is now verified against `FeedingEvent` and pinned by a test that fails if `natural` is rendered in
> minutes. The error is kept in this file rather than quietly deleted, because the plan's authority is
> exactly what made the error dangerous.

### The rule that matters more than the UI
**A solid-food event must NOT satisfy a milk-feeding reminder.** Reminders match subtype exactly
(`reminders_repository_impl.dart:58`), so this works by construction — and it is *behaviour, not
accident*: a purée does not hydrate a hungry newborn. **Do not widen reminder matching.** Add a test
that proves it (below). If any code path you touch makes `miam` reminders match on `type` alone,
stop and report it rather than shipping it.

## Changes
1. **`tracking_enums.dart`** — add `solid` to `FeedingSubtype`, its `dbValue` case `'solid'`, and
   `fromDbValue` case `'solid'`. No legacy alias exists for it — do not invent one.
   Dartdoc in French, in the file's existing voice, saying quantity means grams for this subtype.
2. **`feeding_tracking_dialog.dart`** — third chip "Solide" with an icon, beside the existing two.
   Selecting it swaps the quantity picker to grams (0–1000, step 5, `unit: 'g'`); selecting breast
   milk swaps back to minutes and formula back to ml. The unit label must follow the selected chip —
   a dialog showing "40 ml" while "Solide" is selected is a wrong number on screen, and this app's
   whole promise is that its numbers are right.
3. **`edit_event_dialog.dart`** — same third chip and same unit swap, so an existing event can be
   retyped and re-quantified.
4. **`history_tile.dart:134`** — the `feeding:` branch must return `'g'` for a solid event and
   `'ml'` otherwise. Read the subtype from the event; do not leave `'ml'` as the feeding answer.
5. **l10n** — `feedingSolid` (`Solide` / `Solid` / `Sólido`) and any unit suffix you need
   (`gramSuffix`: `g` / `g` / `g`) in `app_fr.arb`, `app_en.arb`, `app_es.arb`, then `flutter gen-l10n`.
   Every user-visible string goes through l10n — three locales or it doesn't ship.
6. **Export/import** — `'solid'` must round-trip through the format-2 backup. Check
   `lib/features/import/` for any whitelist/validation of subtype strings; if one exists, add `'solid'`
   to it and say so in your report. Do not bump `exportFormatVersion`: the document shape is unchanged,
   only one more value in an existing free-text column.

## Out of scope (do not touch)
Schema, migrations, `exportFormatVersion`, `MeasureKind`, the ±stepper widget internals, `TrackButton`,
`HistoryFilter` (no new value — solid food is a feeding subtype, not a new tracking type), reminder
matching logic, `docs/PLAN-v1.2.0.md`. No new dependencies. No network. No analytics.

## Required tests (English names, French comments)
1. `dbValue` and `fromDbValue` round-trip `solid`.
2. **`fromDbValue` returns null for an unknown value** — the `default:` branch is silent today; pin
   its behaviour so a future edit cannot turn it into a fallback to `natural`. A baby's purée
   restored as "breast milk" is a fabricated health record.
3. Selecting "Solide" shows `g` and the 0–1000 range; selecting "Biberon" shows `ml` again.
4. Saving a solid event persists quantity as grams and subtype `solid`.
5. History tile renders `40 g` for a 40 g solid event and `120 ml` for a 120 ml bottle.
6. **A solid event does not complete a milk reminder**: seed a `miam`/`solid` event, assert
   `getLastCompleted` for a `natural` (or `artificial`) reminder still returns null.
7. Export → import → export stability with a solid event present, `unit` and subtype intact.
8. Editing an existing `artificial` event to `solid` converts the quantity field to grams and keeps
   the event's timestamp.

## Gates — run and paste verbatim
1. `flutter analyze --fatal-infos --fatal-warnings`
2. `flutter test test/shared/ test/features/home/ test/features/history/ test/features/reminders/ test/features/export/ test/features/import/`
3. `flutter test` (full suite, final counts, any skip)

Do not commit. Report: files changed, tests added, every `'ml'` literal you removed or left, whether
the importer whitelists subtypes, and any place this plan was wrong or impossible — say it explicitly
instead of deviating silently.

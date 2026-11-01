# PLAN — v1.2.1: `unit` on every tracked quantity (schema v12) + coarse/fine sliders

Status: **SHIPPED in v1.2.1 for the `unit` column** — `tracking_events.unit TEXT NULL`
(`lib/data/local/app_db.dart:44`), drift `schemaVersion` 12 (`app_db.dart:151`), export format 3
(`export_repository_impl.dart:49`, importer accepts ≤3 via `_supportedFormatVersion = 3`,
`import_repository_impl.dart:19`); commit `6133af9` is contained in tag `v1.2.1`. **The coarse/fine
slider half of this plan did NOT stay**: it shipped in v1.2.1 and was reverted 2026-10-13 by the owner
(ticket B2, now in [`BACKLOG-RESOLVED.md`](../BACKLOG-RESOLVED.md)) — one slider per picker stands.
Kept as implementation history.

Companion to [`PLAN-v1.2.0.md`](PLAN-v1.2.0.md) and [`BACKLOG.md`](../BACKLOG.md) (B1; B2 now in
[`BACKLOG-RESOLVED.md`](../BACKLOG-RESOLVED.md)).
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

> **Reverted 2026-10-13** (owner, after one week on a device): two sliders on one form answer no question
> the ±steppers and the text field did not already answer. One slider per picker now, at the same fine
> steps; the `SliderPair` parameter is gone from `QuantityPickerInline`. Full reasoning and what would
> re-open it: [`BACKLOG-RESOLVED.md`](../BACKLOG-RESOLVED.md) B2.

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
   *(moot since 2026-10-13 — replaced by "one `Slider` per picker, spanning `min`–`max`", asserted in
   `test/features/home/presentation/widgets/quantity_picker_inline_test.dart` and the temperature case of
   `measurement_sheet_test.dart`.)*

## Gates
1. `flutter analyze --fatal-infos --fatal-warnings` → clean
2. `flutter test test/data/local/ test/features/home/ test/features/history/ test/features/export/ test/features/import/` → green, 0 skipped
3. `flutter test` → green, counts pasted
4. **Emulator pass, in this order** (AGENTS.md): old build installed and seeded → new build over it
   → screenshots on `Small_Phone` and one normal target, **viewed, not just captured** → manual entry
   of a ml feeding, a min feeding, a solid and a weight → export inspected. Simulator id and what was
   seen recorded in the PR description.

## Decision — measurements must appear as events (owner, 2026-10-04)
Today `measurements` lives in its own table and **does not appear in the history**
(verified on the device: weight and temperature only show up on the home tiles).
The parent must be able to see « 37,4 °C à 20:26 » on the same timeline as the bottles and the naps.

**Chosen approach: unified read, NO duplication.**
- `measurements` stays the source of truth, **encrypted at rest** as today.
- The history builds a timeline merging `tracking_events` and `measurements`, sorted by
  timestamp, each row knowing how to render its unit from its own `unit` column.
- Modification and deletion addressed to the source table — never to both.

**Why not duplicate in `tracking_events`:** that would write a health number twice,
one of the copies into a `quantity` column **in the clear** (verified: `quantity` is in the clear at rest,
only the notes and the `measurements` value are encrypted). Duplicating is creating an unencrypted
copy of the app's most sensitive data. It is refused.

Real cost: a sorted read join + a history row type for measurements + an
edit route to the right table. Nothing in the storage schema changes — only the read.

## Decision — fate of the `''` rows at migration v12 (orchestrator, 2026-10-04)
The leak fix restricts the scope to the active baby; the existing `''` rows become
invisible to baby A. Decision:
- **if exactly one baby exists**: reassign `''` → that baby (`reminder_settings`,
  `reminder_dismissals`, `reminder_completions`, `custom_reminders`). One baby = the state belongs
  to it without ambiguity, and these are **contents** (custom reminders) as much as states:
  losing them would be a regression for the vast majority of installations.
- **if 0 or several babies**: **reassign nothing**. Choosing to which baby belongs a reminder
  `''` on a multi-baby device would be a guess; we leave the state « sans profil » (no profile),
  the semantics of the fix.
- No data destroyed in both cases; export/import keeps the round trip.

## Locale choice — the decimal comma is accepted everywhere (owner, 2026-10-04) — **DEVICE VERIFIED, OK**
Run on the Android device in the English locale (switch via the app menu, not via adb): the
character-by-character entry gives `3` `37` `37,` `37,4` — the comma entered as-is, **no
dot inserted before**. The header displays `37.4 °C` in English, `Enregistrer` (Save) active, no error.
No `InputFormatter` exists on this path: `keyboardType` is only a hint, and
`_onTextChanged` normalises via `replaceAll(',', '.')`, hence locale-neutral.
**My earlier observation `0.037,4` was an artefact of my own gesture**: I typed into a
field not emptied, cursor in the middle — `37.037,4` → `tryParse` null → ignored, same symptom « rien ne se
passe », zero defect. Lesson noted: before calling a bug a bug, empty the field and start over.

### Genuine detail spotted in passing (v1.2.1, cosmetic)
The **initial text of the field** is always formatted with a dot (`_textFor` → `toStringAsFixed`,
`quantity_picker_inline.dart:113`) whereas the **header** is formatted according to the locale. In fr/es, the
parent therefore sees `37,5` on top and `37.5` in the empty field. Genuine inconsistency, visible, no impact
on the data — to fix together with the pre-fill with the last measurement, which will touch the same code.

`37,4` must be accepted in `en` as in `fr`/`es`. The refusal observed on the English device
came from the keyboard/decimal key, not from the parsing — **to re-verify on the device in `en`**, because a
manual observation had given « 0.037,4 » out of range: if the field reformats the dot before the
comma, an `InputFormatter` is involved and the test in `en` does not necessarily see it.

## v1.2.1 — measurements as events, with edit/delete screen (owner, 2026-10-04)
Confirmed for v1.2.1 (and not v1.2.0): unified timeline **plus** a genuine screen to **modify** and
**delete** a measurement. Edit and delete address the source `measurements` table — never
a copy. `unit` follows the edited row: changing a measurement from 37,4 °C to 38,1 °C must not rewrite
the unit nor round.

## Default value = the last measurement of that type (owner, 2026-10-04)
The sheet pre-fills with the last measurement **of the same `kind`** (`ORDER BY recorded_at DESC LIMIT 1`,
encrypted at rest → decrypted for display). If there is none, we fall back to the current
defaults: 3500 g, 50 cm, 37 °C.

### The trap, and what we do about it (not to leave implicit)
A pre-filled field that the parent can validate without touching it records **yesterday's value as
today's measurement**. In a health app, that is not a convenience, it is an invented datum:
36,8 °C taken this morning and replayed this evening erases the fever that was not there, or fabricates one.

Proposed rule: the last measurement is displayed as a **hint** (`hintText`, soft tint, <!-- lang:fr: verbatim proposed hint text --> « dernière :
36,8 °C » <!-- lang:fr: verbatim proposed hint text -->), and not as an already-entered value; the field starts empty and **Enregistrer stays
disabled until something has been entered**. The parent keeps the reference under their eyes without being able to
validate it by accident. If the pre-fill with an active value is nevertheless wanted, then the
save without modification must be refused with a message — not silently accepted.

## Two bugs to fix in v1.2.1 (found in the v1.2.0 capture campaign, 2026-10-10)

Complete evidence, images included: [`BUG-en-date-format-and-growth-unit.md`](../BUG-en-date-format-and-growth-unit.md).
The two are **visible in the captures already generated** and in the tagged `v1.2.0` binary; they were
not fixed during the campaign, because the campaign must photograph what is shipped — touching
`lib/` after the tag would make the assets wrong on the binary. Testimony by eye, not guessing: no
unit test catches them.

### 1. `formatDate` loses the minutes in English — the whole app

`lib/core/l10n/date_localization.dart:21`

```dart
case 'en':
  return DateFormat('MM/dd/yyyy hh:aa', 'en_US').format(date);   // ← `aa` n'est pas une minute
```

In ICU the minute is `mm`, and `a` the AM/PM marker. `aa` therefore renders the marker, the minutes
disappear, and the colon that introduced them remains dangling.

| Screen | Rendered | Should be |
|---|---|---|
| Home → reminders | `Last done: 10/08/2026 07:PM` | `Last done: 10/08/2026 07:43 PM` |
| Growth (history) | `10/09/2026 01:AM` | `10/09/2026 01:43 AM` |

`fr` and `es` use `HH:mm` and are correct — that is exactly why it survived: all the
captures and all the fixtures written in French never touched the English branch. The doc comment
at L11 **restates the bug** (`MM/dd/yyyy hh:aa`): fixing it without fixing the comment
would leave the same error written in black and white for the next re-reader.

**Sites touched** (`formatDate` shared, 4 call sites): `event_date_time_field.dart`, `growth_screen.dart`,
`history_screen.dart`, `reminder_row.dart`. The `_formatDate` of `onboarding_dialog.dart:231` is an
ISO calendar without time — off subject, verified.

**Fix**: `DateFormat('MM/dd/yyyy hh:mm a', 'en_US')` + the L11 comment with it. **Test required**:
the three locales pinned on a fixed `DateTime`, so the pattern never rots again.

**Why it is not cosmetic**: in a fever tracking, `09:PM` does not distinguish 21:04 from
21:59. The timestamp is the only interest of the row.

### 2. The trailing unit of the growth history contradicts the displayed value

`lib/features/growth/presentation/screens/growth_screen.dart:95` — `trailing: Text(measurement.kind.displayUnit)`

`MeasureKind.displayUnit` (`measure_kind.dart:78`) returns the **storage** unit (`unitG` = `g`),
whereas `MeasureKind.format()` promotes weights > 1 000 g to kilograms. The tile displays the two,
and they contradict each other:

```
6.18 kg      ← titre, formaté (kg)
      g      ← traîne, unité de stockage
4.6 kg
      g
```

Only the weight is **wrong**: the trailing asserts a unit the value does not use, which a rushed parent
reads « 6,18 grammes ». Height and temperature are harmless duplicates.

**Fix**: remove the trailing when `format()` has already rendered the unit, or make it a hint
of the explicitly assumed storage unit. **Do not** « fix » it by making `displayUnit` return `kg`:
the getter also serves the sheet field (`measurement_sheet.dart:108` and `:132`),
where the storage unit (`g`, not 10 g) is the right hint — we would swap one defect for another.

### Consequence on the gate

These two fixes touch the rendering → **new capture campaign after the fix** (the 50 PNGs
currently show the two defects). The `Small_Phone` pass of the gate must look at `history_screen`
and `growth_screen` **in English**, since that is the locale where the bug lives — an emulator pass in
French would prove nothing on this ticket.


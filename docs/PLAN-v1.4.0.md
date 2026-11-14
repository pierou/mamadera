# PLAN — mamadera v1.4.0 (`1.4.0+17`, drift schema v14, export format 5)

Status: **proposed, pending owner sign-off on §2 decisions** · Written 2026-11-14 against
`develop` @ `3c58037` (1.3.2+16).
Executes the owner requests B6, B30, B33, B15, B22 and the schema-free small batch (B9, B13, B16,
B17, B26, B27, B29, B7-remainder) — scope agreed with the owner 2026-11-14.
Sequencing: **1.4.0 is the content release; Phase A sync is 1.5.0** (schema v15 / export v6,
`docs/PLAN-sync-phase-a.md` — the numbers are locked against this plan: this release takes v14/5).
A **1.3.3 exists only as the contingency** in §7 — it is not scheduled.

This file is the **release-level** plan: the shared decisions the individual tickets defer "to the
plan" (one schema step, one settings-row state machine, one export format, the milestone order),
plus the release gate. Per-ticket mechanics live in `docs/BACKLOG.md` (B6, B15, B22, B27, B30, B33)
and are cited, not re-derived. Do not re-derive what is asserted below.

---

## 0. How to use this file

Implement **one milestone at a time, in order** (M1 → M9). Each milestone ends green and is
committed separately (Conventional Commits: `feat(...)`, `fix(...)`). Never batch two milestones.

After every milestone, run and report verbatim:

```bash
flutter analyze --fatal-infos --fatal-warnings    # must be clean
flutter test test/<the directories you touched>/  # must be green
```

Run the **full** gate (`make ci`) only at M9. If a step's instruction contradicts the code you are
reading, **STOP and report the contradiction** — do not improvise a different design, and do not
"fix" an unrelated thing you noticed (note it in your report instead).

### Hard rules (from `AGENTS.md`, non-negotiable here)

- **No new dependency of any kind** — `pubspec.yaml` `dependencies:` and `dev_dependencies:` must
  not gain a single entry.
- **One schema step, one export format.** v13 → v14 and format 4 → 5 happen once, in this release.
  No intermediate migration, no column deferred to a "1.4.1".
- **The settings-row state machine has one implementation** (§3.2): the effective-item function
  lives in one place, consumed by the settings provider, the home reminders section **and** the
  scheduler. Two item lists that can disagree is the B31 defect class — the self-heal that fixed
  it ships in 1.3.2, do not regress it.
- **Preset ids are stable keys** (`vitamine_d`, `vitamine_k`, `eye_cleaning`, `face_cleaning`) —
  they index `reminder_settings`/`reminder_dismissals` and appear in users' backup files. Never
  rename, never delete from `reminderItemsFor`.
- Health numbers stay encrypted at rest (unchanged surface: this release adds no measurement
  columns).
- l10n: every new user-facing string ships **fr + en + es** in the same commit; fr/es patch-note
  items use the noun form ("Ajout d'une…", "Corrección de la…") — never infinitives.
- No clinical claims in patch notes or store copy: B6's "Do not" applies release-wide (no
  « l'app suit l'OMS » — the rest of the default list is care hygiene, not a WHO-derived list).

### Do NOT touch (explicitly out of release)

| Out of scope | Why / ticket |
|---|---|
| B8 growth tab + chart | Its own feature release; blocked on the CustomPainter-vs-dependency decision |
| Phase A sync (merge/uuids) | **1.5.0** — `docs/PLAN-sync-phase-a.md`; this release must not pre-empt its v15/v6 numbers |
| B3 Phase B (LAN) / Phase C | Gated on the written privacy-mandate change (B3); Phase C out of scope for now |
| B12 (due reminders at top of home) | Closed by owner decision 2026-11-03 — will not do |
| B19/B20/B21/B32 (maintenance quartet) | Separate maintenance PRs into `develop`, do not ride the release branch |
| B23, B25 (marked "v1.3.1 scope" in the backlog) | **Already in develop** — verified 2026-11-14: `track_button.dart:29` documents B23's pill removal; B25's line is localized end to end (`track_button.dart:44-67`). Status lines are stale; close them in a docs PR |
| B4, B11, B18, B24, B28 | Shipped in 1.3.1/1.3.2 |
| `HistoryFilter` / `TrackingType` enums | B7-remainder adds the **existing** `measurements` value to the History chip row only — no new enum value (the value already exists and is used by the merged timeline) |

---

## 1. Verified current state (do not re-derive)

| Fact | Evidence |
|---|---|
| `schemaVersion == 13` | `lib/data/local/app_db.dart:182` |
| `reminder_settings`: `(baby_id TEXT NOT NULL DEFAULT '', item_id TEXT NOT NULL, enabled BOOL)`, PK `(baby_id, item_id)` — **no time, no label, no frequency, no removal state** | `app_db.dart:60-68` |
| Effective-enabled filter is a **literal**: `settings[item.id] ?? true` — absent row means "on" for every item, no per-item default exists | `lib/features/reminders/presentation/providers/reminder_providers.dart:84` (B6) |
| Frequency codec: `({String code, int? intervalDays}) _encodeFrequency` with 4 codes from `db_constants.dart` (`daily`, `weekly`, `monthly`, `every_n_days`); tolerant decode maps unknown → daily (the "never disappear" rule) | `lib/features/reminders/data/repositories/reminders_repository_impl.dart:254-300` |
| `ReminderFrequency` is a sealed class with exactly 4 variants — **no `OneTime`, no end-date capability anywhere** | `lib/features/reminders/domain/entities/reminder_frequency.dart` (B33) |
| Vitamin K preset: `CustomInterval(days: 30)` static; `buildForBaby` → `Monthly(dayOfMonth: birthDate.day)` — monthly **for life**, no termination path | `lib/features/reminders/domain/entities/reminder_item.dart` (B33 Part 1) |
| The 365-day form-sheet cap is the documented boundary: « after one year, the parent wants a specific date. **Not a reminder.** » | `lib/features/reminders/presentation/widgets/custom_reminder_form_sheet.dart:36-38` (B33 Part 2) |
| Scheduler: `sync()` takes one `preferredHour`/`preferredMinute` for **all** items; `_PlanEntry` diff on `(at, title, body)`; the enabled-map read is already per-(baby, item) (`getEnabledByItemId`) | `lib/features/reminders/domain/services/reminder_scheduler.dart` (B30) |
| Global hour: `app_settings` key `notification_time_of_day`, default `09:00`, codec + validator in `notification_time.dart` (`isValidNotificationTime` / `parseNotificationTime`, read-lax / write-strict split documented) | `lib/features/reminders/domain/services/notification_time.dart` (B30) |
| Preset rows are bare `SwitchListTile` (no edit, no remove); custom rows have the switch **plus** `CustomReminderAction {edit, delete}` popup | `lib/features/reminders/presentation/screens/reminder_settings_screen.dart:107-115` (B33 Part 3) |
| Custom delete = hard delete of the `custom_reminders` row **and** its settings row, then `ref.invalidate(reminderSettingsProvider)` | `reminder_settings_screen.dart` / the custom notifier (B33 Part 3) |
| **No** notification response handler anywhere (zero hits for `onDidReceiveNotificationResponse`); scheduled notifications carry **no payload** (title/body only); Android `singleTop` + `taskAffinity=""` is why a tap restores the previous screen | `lib/features/reminders/data/services/flutter_local_notification_service.dart:43-71`, `lib/main.dart` (B22, B15) |
| `markDone` on a treatment-linked preset creates **no record** by design (D2: only the real health event settles it) | `lib/features/reminders/presentation/providers/reminder_notifier.dart:153-166` (B15) |
| Export: `_exportFormatVersion = 4`; the `reminderSettings` row is `{babyId, itemId, enabled}` | `lib/features/export/data/repositories/export_repository_impl.dart:56, 119-125` |
| Import: `_supportedFormatVersion = 4`; restore is replace-only (delete-all + insert, one transaction); formats 1–4 must keep restoring | `lib/features/import/data/repositories/import_repository_impl.dart:32, 570-586` |
| B27 fires **with and without** the onboarding fix and is currently *counted, not fixed* (tolerated in release, red in debug) | `integration_test/gate_v131_restore_onboarding.dart` (`[GATE] B27 recorded`) |
| B13: the sleep track passes `duration: selection.minutes` **and** `quantity: selection.minutes`; display fixed in rc.2, write path not | `lib/features/home/presentation/screens/home_screen.dart:204-208` |
| B26: `schema.sql` (the generated reference) ends the `measurements` column list with a trailing comma — not replayable | `lib/data/local/schema.sql` |

---

## 2. Release decisions (resolve before M1; owner sign-off on this file)

### D-R1 — B6 faithful reading: the "new default only" ships with a **seed-true** migration

B6's decision A (owner, 2026-10-06): existing installs keep the Vitamin D reminder **until manual
turning off**; new babies/installations start off. The naive implementation the ticket's cost line
describes (`enabledByDefault` field + `settings[id] ?? item.enabledByDefault`, no migration) does
**not** deliver A: for an existing install whose `vitamine_d` row is absent, "absent" currently
means *on*, and flipping the literal silently turns the reminder **off** for existing parents —
exactly the sin the decision rejects (« B silently removes a visible reminder without consent »).
The app cannot tell "never touched on an old install" from "never touched on a new install" without
recording the choice.

**Decision:** the v14 migration seeds, for every existing scope (`''` carry-over + every existing
`baby_profiles.id`), a `reminder_settings(baby_id, 'vitamine_d', enabled: TRUE)` row **if and only
if none exists**. Effects:

- existing installs: byte-identical behaviour (reminder still on), now with an explicit, visible,
  flippable row — "until manual turning off", literally;
- babies created after the upgrade: absent row → `?? enabledByDefault` → **off**, visible in the
  settings list (the switch is on-screen, that is the whole point of B6's "off but visible" state);
- the seed is **preservation, not B's flip** — the ticket's option B seeded `enabled: false` for
  all scopes; this seeds `true` only where a row is absent. The distinction is recorded here
  because it is the load-bearing detail.

The ticket's cost line ("one field + one filter fallback + tests") is **amended**: + the seed
statement in the v14 migration + one migration test (existing scope → row present `enabled=1`;
new scope → absent → effective off).

### D-R2 — The settings-row state machine (planned once for B6 + B33, as B33 Part 3 demands)

One row, per `(baby_id, item_id)`, five new states, one effective-item function:

| Row | `removed` | `enabled` | Visibility (settings list) | Effective on (home/scheduler) |
|---|---|---|---|---|
| absent | — | — | visible | `item.enabledByDefault` (B6: vitamine_d → **false**, other presets & customs → **true**) |
| present | 0 | 1 | visible | on |
| present | 0 | 0 | visible (switch off, re-enableable) | off, never due |
| present | 1 | *moot, kept as stored* | **hidden** (appears in the Removed section, D-R4) | off, never due, no OS notification |

- `enabledByDefault` is a **field on the `ReminderItem` entity** (code, `static const` values —
  never data): `vitamine_d: false`, `vitamine_k`/`eye_cleaning`/`face_cleaning`: `true`; customs:
  `true`. B30's "Do not" stands: the *hour* is not on the entity — but the *default* is, because a
  default is item identity, not per-(baby, item) data.
- **One function, three consumers.** `effectiveItemsForScope(babyId, items, settingsMap, profile)`
  (name at the plan; the ticket's "the override function must sit below both") returns the item
  list with overrides applied — label, frequency (**and the resolved `endsAt`**, D-R5 — which is
  why it takes the profile: `end_age_months` resolves against the birthdate there) — and removal
  filtered, in **one** domain function. Consumers: the settings screen provider, the home
  reminders section, the scheduler's `_itemsForScope`. The B31 invariant — provider and scheduler
  can never disagree — is structural, not a test's faith.
- The existing `enabled` column's read path (`settings[item.id] ?? true`) is replaced **only** by
  the `?? item.enabledByDefault` literal change — nothing else about the switch writes changes.

### D-R3 — Shared v14 columns: B30's hour + B33's overrides + B33's removal, one `ALTER` batch

Exact DDL (the §3 migration implements this; naming follows the tickets: B30 names its column
`time`, B33's frequency pair mirrors `custom_reminders`):

```sql
ALTER TABLE reminder_settings ADD COLUMN time TEXT NULL;            -- B30: 'HH:mm', NULL = inherit global
ALTER TABLE reminder_settings ADD COLUMN label TEXT NULL;           -- B33: preset label override, NULL = preset label
ALTER TABLE reminder_settings ADD COLUMN frequency TEXT NULL;       -- B33: override code (db_constants), NULL = preset frequency
ALTER TABLE reminder_settings ADD COLUMN interval_days INTEGER NULL;-- B33: paired with frequency (the every-n-days value)
ALTER TABLE reminder_settings ADD COLUMN frequency_date TEXT NULL;  -- D-R5: the one-shot's occurrence date ('yyyy-MM-dd') when frequency = 'one_time'
ALTER TABLE reminder_settings ADD COLUMN end_date TEXT NULL;        -- D-R5: 'until a date' — 'yyyy-MM-dd', inclusive end
ALTER TABLE reminder_settings ADD COLUMN end_age_months INTEGER NULL; -- D-R5: 'until an age' — canonical whole months 0–180
ALTER TABLE reminder_settings ADD COLUMN removed INTEGER NOT NULL DEFAULT 0;  -- B33: the third state (D-R2)
```

- All additive; `ALTER TABLE … ADD COLUMN` (the v12 precedent) — **no table rebuild, no rekey**
  (a rebuild would be B31-class irreversible; none of this needs it).
- `time` is validated by the existing `isValidNotificationTime` (write-strict at import, read-lax
  at the app read side — the split `notification_time.dart` documents).
- The new frequency code: `const String freqOneTime = 'one_time';` in `db_constants.dart` beside
  the four existing codes.
- `frequency_date` (the one-shot's occurrence) and `end_date`/`end_age_months` (the series end) are
  **different concepts with different columns** — D-R5's mutual exclusivity: a row carries at most
  one of {`one_time`+`frequency_date`, `end_date`, `end_age_months`}, enforced at write and at
  import, not by the schema.

### D-R4 — Removed presets are re-addable, from a Removed section

B33's open plan call ("how is a removed preset re-added? — a hidden section, or never"):
**a collapsed « Removed » section at the bottom of the settings screen**, one tap restores
(`removed = 0`). Rationale: removal is a state flag, not a delete — the preset cannot be lost, so
"never" buys nothing and a misclicked removal becomes unrecoverable; the section costs one
`ExpansionTile`-class widget and one l10n string. (Customs keep their existing hard-delete
semantics — D-R4 is about *presets* only.)

### D-R5 — "Program an end": three options — one time, until a date, until an age

**Owner decision, 2026-11-14** (supersedes this plan's initial D-R5, which offered the one-shot
only): every reminder can be given an end, in **three forms**, offered wherever a frequency is
chosen — the preset edit sheet (D-R6) and the custom form/edit sheets (the form sheet's 365-day
cap « not a reminder » dead end becomes the one-shot's entry point):

1. **One time** — a single occurrence on a date: frequency code `one_time` + `frequency_date`
   (the date *is* the occurrence, not an end). A passed date is due-now catch-up (D-R7); a
   completed one-shot never recurs.
2. **Until a date** — the frequency keeps its rhythm; the series stops after `end_date`
   (inclusive: the end date itself can still fire; no occurrence exists past it).
3. **Until an age** — the same, expressed in the baby's age: stored as canonical whole months
   (`end_age_months`, 0–180), resolved to a date **at read time** against the baby's birthdate
   with B18's clamped month arithmetic — so a corrected birthdate moves the end automatically.
   Available only where a birthdate is known (every per-scope row with a profile); on the legacy
   `''` profileless scope the option is **disabled with a hint** (D-R10's territory).

**Carrier: the end lives on the reminder, not inside the frequency.** The sealed
`ReminderFrequency` grows only `OneTime` (its `frequency_date`); the end is a derived field
`endsAt` resolved by the effective-item function (D-R2) from
`end_date ?? (end_age_months → clamped(birthdate + n months))`. Rationale: one cutoff code path
serves all five frequencies uniformly (no per-variant `isDue` branch), the export fields are
uniform, the picker's « end » section is independent of its « frequency » section, and any future
frequency variant inherits the end for free. The alternative carrier — `Daily(until:)`-style
embedding in each sealed variant — is rejected: it forks the frequency model five ways for what
is semantically one property of the reminder.

**Mutual exclusivity** (enforced at write **and** at import — write-strict): a row carries at most
one of {`one_time` frequency, `end_date`, `end_age_months`}. The picker makes it structural —
switching *to* the one-shot clears any stored end; switching *away* from it clears `frequency_date`.
An end set on a reminder whose frequency is changed to one-shot is dropped, not kept dormant.

**Semantics** (scheduling core, M3): `endsAt == null` → today's behaviour, unchanged.
`endsAt != null` → `isDue` is false once `now` is past the **end of the end date's day**
(inclusive end); `nextDueAt` returns the last occurrence on or before `endsAt`, else `null` — and
a `null` nextDueAt drops the item from the plan, so the **existing** `_PlanEntry` diff cancels the
OS notification: the same "can no longer be due" path as a completed one-shot or a removed row
(D-R2/D-R7) — one mechanism, three callers. An end in the past at write time is **accepted** (the
series is already over: the row simply stops being due and its OS entry drops at the next sync);
the picker warns but does not block.

### D-R6 — Preset edit: label + frequency (including one-shot); care subtype is **not** editable

Preset rows gain the custom-tile affordance (switch + `edit`/`remove` menu —
`custom_reminder_tile.dart` is the reference). The edit sheet reuses the form's label + frequency
fields; the **care-subtype field is out** (B33: re-pointing `vitamine_k` at another event would
decouple the reminder from the dose that settles it — D2's completion-by-event stands).

### D-R7 — The missed one-shot: catch-up, not expiry

B33's decision point (a vs b): **catch-up (a)**. A one-shot whose date has passed (or whose date
is null — D-R8) is **due now** and stays due until completed or dismissed; a completed one-shot is
**never due again** (it has no next occurrence). Expiry (b) is rejected: silently abandoning a
missed vitamin K dose in an app whose point is the care routine is the wrong default. Scheduler
consequence: the `_PlanEntry` diff must **remove** the OS notification when a one-shot is completed
(or its row removed, D-R2) — the removal half is the actual work (B33 Part 1.3).

### D-R8 — Tolerant decode of `one_time`

`_decodeFrequency` gains the `one_time` branch. A `one_time` row with a **null/invalid
`frequency_date`** decodes to a one-shot that is **due now** (D-R7's catch-up) — consistent with
the codec's "never disappear" rule (unknown code → daily, not gone), and with the read-lax /
write-strict split (the importer *refuses* a malformed date, so a broken row only exists via
hand-edited JSON, and there the safe read is "ask the parent", not "silently off").

### D-R9 — B15's D2 decision: tap **deep-links**, it never auto-creates

B15 To-do 3, resolved: for a **treatment-linked** item the notification tap opens the matching
health sub-type sheet **pre-filled**; the parent confirms through the existing care flow. A
**detached** custom tap = `markDone` (the existing `reminder_completions` semantics). An
auto-created health event would make the app author records the parent never entered — a mistap on
a 3 a.m. banner becomes a row in the paediatrician's export. A bare tap is attention, never
completion (B15 "Do not" 1). After validation the firing notification is settled until next due
(D3 discipline — no re-fire tonight).

### D-R10 — The profileless fallback keeps its behaviour

`buildForBaby` computes the Vitamin K `OneTime(date: birthDate + 1 month)` with **B18's clamped
anniversary rule** (`_addMonths`, `baby_profile_section.dart` — do not invent a second
month-addition). The profileless fallback (`reminderItemsFor`, the `''` sentinel path of legacy
installs) has no birthdate → no date → it **keeps the static `CustomInterval(days: 30)`**. That is
a deliberate no-change on the legacy path: the one-shot is a new-baby behaviour, and removing
Vitamin K from the fallback would drop a clinical reminder for the installs the B31 self-heal
still serves.

### D-R11 — The 1.4.0 patch-note voice

Patch notes (in-app, fr/en/es, noun form) carry: per-reminder hour; Vitamin K one-shot ("one month
after the birthdate, settled when recorded" — **without** re-deriving the clinical rationale, B6's
"Do not" applies); presets editable/removable; **the end trio** ("every reminder can be ended: on
a date, on a given date, or at a given age" — the D-R5 options as shipped, noun form in fr/es);
Vitamin D now off by default for **new** babies (existing keep it until turned off — say so, it
is the consent line decision A demands); notifications: tap lands on Home + tapping a reminder
performs its action. No "l'app suit l'OMS", no mortality or efficacy claim (research archive,
non-negotiable).

---

## 3. Target schema: drift v13 → v14 (one migration)

`AppDatabase.schemaVersion` → **14**. In `onUpgrade`, after the existing v13 step, one block:

```dart
// v13 → v14: per-(baby, item) overrides + hour + removal (B30/B33, PLAN-v1.4.0 D-R2/D-R3)
await customStatement('ALTER TABLE reminder_settings ADD COLUMN time TEXT NULL');
await customStatement('ALTER TABLE reminder_settings ADD COLUMN label TEXT NULL');
await customStatement('ALTER TABLE reminder_settings ADD COLUMN frequency TEXT NULL');
await customStatement('ALTER TABLE reminder_settings ADD COLUMN interval_days INTEGER NULL');
await customStatement('ALTER TABLE reminder_settings ADD COLUMN frequency_date TEXT NULL');
await customStatement('ALTER TABLE reminder_settings ADD COLUMN end_date TEXT NULL');
await customStatement('ALTER TABLE reminder_settings ADD COLUMN end_age_months INTEGER NULL');
await customStatement('ALTER TABLE reminder_settings ADD COLUMN removed INTEGER NOT NULL DEFAULT 0');
// B6 (D-R1): seed-true the vitamine_d row for every pre-existing scope that has none.
// INSERT the row only where absent — never UPDATE an existing row's `enabled`.
await customStatement('''
  INSERT INTO reminder_settings (baby_id, item_id, enabled)
  SELECT s.baby_id, 'vitamine_d', 1
  FROM (SELECT '' AS baby_id UNION ALL SELECT id FROM baby_profiles) s
  WHERE NOT EXISTS (
    SELECT 1 FROM reminder_settings r
    WHERE r.baby_id = s.baby_id AND r.item_id = 'vitamine_d'
  )
''');
```

Drift data classes update accordingly (`ReminderSettings` gains the eight fields; `?` / default as
per the DDL); `make codegen`; `schema.sql` regenerated — **and B26's trailing comma fixed in the
same regeneration** (the reference file must replay: `sqlite3 :memory: < schema.sql` exits 0 — add
that as the replay guard, B26's To-do).

Irreversibility: none beyond the standard additive-column policy (v12 precedent); the seed is
idempotent (the `NOT EXISTS` guard) and only ever inserts `enabled = 1`.

**Migration tests (write in M1, not after):**

1. v13 DB with one profile + one event + an existing explicit `vitamine_d` row `enabled=0`
   (a parent who turned it off) → v14: **row unchanged** (`enabled` still 0), the eight new columns
   null/0, app boots, the parent's off stays off.
2. v13 DB, no `vitamine_d` row → v14: `''` scope + profile scope each gain `enabled=1` rows.
3. Fresh install → v14 directly: schema present, no rows seeded (the seed runs in the migration,
   not at insert — a fresh DB is created at v14 and has no legacy scopes; verify no phantom rows).
4. The replay guard on the regenerated `schema.sql`.

---

## 4. Export / import: format 4 → 5

`_exportFormatVersion` → **5** (`export_repository_impl.dart:56`);
`_supportedFormatVersion` → **5** (`import_repository_impl.dart:32`). Same change, same commit
(AGENTS.md: the two features move together).

The `reminderSettings` row gains, after `enabled` (order irrelevant, presence is the format signal):

```dart
'timeOfDay': row.time,                    // 'HH:mm' | null
'label': row.label,                       // String?
'frequency': row.frequency,               // code | null
'intervalDays': row.intervalDays,         // int?
'frequencyDate': row.frequencyDate,       // 'yyyy-MM-dd' | null — the one-shot's occurrence
'endDate': row.endDate,                   // 'yyyy-MM-dd' | null — 'until a date' (D-R5)
'endAgeMonths': row.endAgeMonths,         // int 0–180 | null — 'until an age' (D-R5)
'removed': row.removed,                   // bool
```

- **Import of a format ≤4 file**: absent keys → the nullable fields default (`removed` → `false`) —
  the existing row contract, no new table, no new section. The `databaseSchemaVersion` guard is
  untouched (a v13 document is still a v13 document; the *format* is what moved).
- **Import of a format 5 file**: `timeOfDay` validated with `isValidNotificationTime` — a malformed
  hour **refuses the file** (B30 shape §2: write-strict, exactly like the global hour today); a
  malformed `frequencyDate`/`endDate` (present but not `yyyy-MM-dd`) likewise refuses; `endAgeMonths`
  present but outside 0–180 refuses; `frequency` present but an unknown code **refuses** (the app
  read side is tolerant, the importer is not — the same split the existing custom-reminder
  frequency validation uses). **D-R5's mutual exclusivity is also an import refusal**: a row with
  both an `endDate` and an `endAgeMonths`, or a `one_time` frequency with any end field, is
  ambiguous or contradictory — the file is refused, not repaired.
- `counts.reminderSettings` unchanged in meaning (row count; `removed` rows still count — they are
  rows, and a restore of a removed preset keeps it removed: D-R2's state travels with the backup).
- **Regression wall:** formats 1–4 keep restoring byte-for-byte on the existing test fixtures —
  the Phase A plan (§0.6 of that file) inherits this wall; do not break it here.

---

## 5. Milestones

One commit each; each ends with the §0 commands green.

### M1 — Schema v14 + B6 (the clinical fix)

The §3 migration + seed + drift codegen + `schema.sql` regeneration (B26 fixed inside) +
`ReminderItem.enabledByDefault` field (D-R2) + the filter literal change
(`settings[item.id] ?? item.enabledByDefault`, `reminder_providers.dart:84`) + the settings list
showing the off-by-default vitamine_d row **visible, switch off** (D-R2's "off but visible") +
the §3 migration tests + the existing B6 tests amended.
*Ticket: B6 (+B26 folded in by the D-R2/D-R3 decision to regenerate the reference file).*

### M2 — B30: the per-reminder hour

B30 "Shape" §1–6 as written in the ticket: the scheduler resolves the hour **per item inside the
loop** (the enabled-map read becomes the settings-map read, one query per scope); `nextDueAt`
unchanged; the `_PlanEntry` diff needs no new key (`at` already moves); UI: every preset row and
every `CustomReminderTile` shows the effective hour (own, or global marked inherited) →
`showTimePicker` → persist → `syncNow()`; "inherit" writes `NULL`; the global row stays as the
default. l10n fr/en/es: the subtitle's two states + the picker title. Tests: the per-item-hour
catch-up rows in `reminder_scheduling_test.dart` (a 08:00 item under a 09:00 global opens its
window an hour earlier), the scheduler diff re-submission on hour change, the export/import v5
`timeOfDay` round trip, the importer's malformed-hour refusal.
*Ticket: B30 (its "Shape" section is the spec).*

### M3 — B33 Part 1: `OneTime` + the end model (D-R5) + the Vitamin K cadence

`OneTime(DateTime? date)` variant (date nullable in the entity — D-R8's due-now path; the **stored**
row always has a date, the null case is the tolerant decode's invention); `isDue`: completed →
never again; not completed → `date == null || !date.isAfter(now)` (D-R7 catch-up: a passed date
stays due until settled); `nextDueAt`: a one-shot schedules **one** OS notification at the date's
hour (the item's own hour, M2's resolution — a one-shot with no date is due-now = the next hourly
check settles it, i.e. it fires on the next sync and then only completion/remove ends it); the
scheduler's `_PlanEntry` diff **removes** the entry on completion/removal (D-R7 — the regression
test this ticket most needs: completed one-shot → zero OS entries, both platforms); the frequency
label (fr/en/es) renders the date (« le 15 déc. »-class, existing date-localization helpers);
`buildForBaby` → `OneTime(birthDate + 1 month)` with B18's clamped rule; the profileless fallback
keeps `CustomInterval(days: 30)` (D-R10). The `db_constants` `freqOneTime` code + codec encode/decode
+ D-R8. **The end model (D-R5, semantics half):** the effective-item function (D-R2) resolves
`endsAt` = `end_date ?? clamped(birthdate + end_age_months)` (B18 arithmetic — the same
`_addMonths`, not a new one); `isDue` gains the cutoff — `endsAt != null && now` past the end of
the `endsAt` day → false (inclusive end date); `nextDueAt` returns the last occurrence on or before
`endsAt`, else `null` (a `null` nextDueAt drops the item from the plan → the **existing** diff
cancels the OS entry — the "can no longer be due" path now serves three callers: completed
one-shot, ended series, removed row). A changed birthdate moves an age-based end automatically
(read-time resolution — no stored date to go stale). Tests: `reminder_frequency_test.dart` (the
isDue suite incl. completed-forever, catch-up, **the end cutoff inclusive/exclusive boundary**,
**age-end resolution incl. a clamped anniversary** (Jan 31 baby + 6 months)),
`reminder_scheduling_test.dart` (nextDueAt past the end → null; last-occurrence-on-or-before),
`reminder_scheduler_test.dart` (plan removal: ended series → zero OS entries; birthdate edit
moves the plan), the codec's tolerant branches.
*Ticket: B33 Part 1 (+ D-R5's scheduling half — Part 2's scope is the owner's trio).*

### M4 — B33 Part 3: preset overrides + removal + UI parity

The effective-item function (D-R2) below the three consumers; the settings-row writes for
`label`/`frequency`/`interval_days`/`frequency_date`/`end_date`/`end_age_months`/`removed` (the
switch write path extends, does not fork); preset rows become the custom-tile pattern (switch +
`edit`/`remove` menu — `custom_reminder_tile.dart` reference); the preset edit sheet (label +
frequency incl. one-shot date picker, **no care-subtype field** — D-R6); **the end picker (D-R5,
UI half)** — an « end » section on the edit sheet (presets **and** customs, so the custom form
sheet gains it too, replacing its 365-day dead end): the three options *one time* (date) /
*until a date* (date) / *until an age* (a months-or-years stepper, stored as whole months 0–180),
plus the default *no end*; the exclusivity wiring (switching to one-shot clears the stored end and
vice versa, D-R5); *until an age* shows its **resolved date** next to the stepper (« until 18
months — 15 juin 2026 », recomputed per read, so a birthdate correction is visible) and is
disabled-with-hint on the profileless scope; a past end at write time warns but accepts (D-R5);
removal = `removed=1` + **OS plan drop** (the M3 removal mechanism, third caller alongside the
completed one-shot and the ended series); the « Removed » section with one-tap restore (D-R4);
the re-add is per-(baby, item) (a second baby sees the preset fresh — D6's per-baby scoping, no
change). l10n fr/en/es: the three option labels, the resolved-date line, the exclusivity, the
past-end warning, the disabled hint. Tests: the single-source invariant (provider and scheduler
return the same effective list — the B31 regression, asserted directly), override **and end**
round trip through export v5, removal hides from settings + home + scheduler, restore re-shows,
the second-baby fresh state, **the exclusivity write path** (one-shot ↔ ended-frequency switches
clear the right columns), the age stepper's month canonicalisation (2y6m → 30).

### M5 — B22 + B15: the notification tap pair

B22 first (it is B15's skeleton): the response handler exists (foreground
`onDidReceiveNotificationResponse` + the cold/background paths — verify `flutter_local_notifications`
22.x semantics per platform before wiring, B15 To-do 2's warning stands); a tap on a reminder
notification **navigates to Home** (the alive path; the cold path already lands on Home via the
splash redirect — `core/router.dart:64-84`, do not touch). Then B15's payload + action: schedule
time carries `babyId` + stable `item.id` (never the plan-index/OS id); the handler resolves the
item and performs D-R9's split (detached → `markDone`; treatment-linked → the matching health
sub-type sheet pre-filled); after validation the firing notification is settled (D3 — no re-fire
tonight); the `''` carry-over discipline (`await ref.read(activeBabyProvider.future)`, never a
transient `.value`). Tests: the payload contract (identity = `babyId`+`item.id`), the handler's
item-resolution both branches, the settle-until-next-due, the navigation to Home. **Device gate
note:** the tap pair is the one part no widget test executes — M9's pass covers it on both
platforms, alive and cold.
*Tickets: B22 + B15 (D-R9 resolves B15's To-do 3).*

### M6 — The small batch (schema-free, independent)

Each a standalone commit in this order (independence verified per ticket; B27 last within the
batch because it needs the device pass, not just the test suite):

1. **B9** — baby switcher: clickable AppBar title → the baby-picker sheet (one sheet + one
   `onTap`, the ticket's cost line).
2. **B13** — the sleep track stops passing `quantity: selection.minutes` (write path + entity +
   tests; **zero migration** — existing rows keep their duplicated value, the display already
   prefers `duration`, rc.2).
3. **B16** — the optional note field in `feeding_tracking_dialog` (storage/encryption/export
   already exist — `track()` already takes it; one field, one l10n string × 3).
4. **B17** — haptics on creation: the existing `show_feedback.dart` helper extended to the
   creation confirmations (the ticket's magnitude decision: one `selectionClick`-class magnitude,
   not a new one — record it in the commit).
5. **B29** — the history filter pills adopt the home track-button design (one style block, one
   screen).
6. **B7-remainder** — the `HistoryFilter.measurements` chip in the History pill row (the value
   already exists and feeds the merged timeline — this is chip + filter wiring only, the
   ticket's "small" cost line).
7. **B27** — the flush at the invalidation site (the ticket's fix: the post-restore Home mount
   schedules a provider refresh during build) + remove the `[GATE] B27 recorded` tolerance from
   `integration_test/gate_v131_restore_onboarding.dart` (the gate then asserts what it used to
   count) + the device pass in M9.

*Tickets: B9, B13, B16, B17, B29, B7, B27.*

### M7 — l10n + patch notes + version

The fr/en/es sweep of everything M1–M6 introduced (the arb files + `make codegen` + the
generated localizations); the `1.4.0` patch-note entries per D-R11 (noun form fr/es, no clinical
claims — B6's "Do not" is the check-list); `pubspec.yaml` → `1.4.0+17` (the build number
continues; the release PR may renumber within the gate); `make store-check` (no store surface
changes — the listing is untouched, the package is only re-verified for the version bump).

### M8 — The full test matrix + coverage

`make ci` (analyze + tests + coverage ≥ 80 % domain/data). The release-specific assertions that
must exist as named tests (not faith):

- **idempotent seed** (M1 test 2 re-run on an already-v14 DB — the `NOT EXISTS` guard);
- **B31 invariant**: provider and scheduler effective lists are equal (M4);
- **one-shot completed → zero OS entries** (M3, the plan-removal regression);
- **removed preset → zero OS entries + absent from home** (M4, the second caller);
- **hour change re-submits by id** (M2, B14's stale-schedule concern);
- **the end cutoff** (M3, D-R5): inclusive end date (fires on, stops after), age-end resolved at
  read time and moved by a birthdate edit, ended series → zero OS entries;
- **D-R5 exclusivity**: write path clears the right columns on one-shot ↔ ended-frequency
  switches; import refuses a file carrying both end fields or a `one_time` with an end (M3/M4,
  §4 — refused, not repaired);
- **formats 1–4 restore unchanged** (the §4 regression wall);
- **B6**: existing-off stays off, existing-absent gets the seed, new baby is off (M1);
- **B15 payload identity** is never the plan index (M5).

### M9 — Release gate (AGENTS.md, non-negotiable; the emulator pass BEFORE the PR)

1. **Migration on old data**: install 1.3.2 (v13) on the emulator, seed a profile + events + a
   manually-turned-off vitamine_d → install the 1.4.0 build → §3 test 1 observed on the device:
   the parent's off is still off, the seed rows exist, data visible.
2. **The Vitamin K one-shot, end to end, on the device**: a baby whose birthdate makes
   "birthdate + 1 month" = tomorrow → the OS notification is scheduled once; record the dose →
   **the notification disappears** (the M3 regression, seen on the lock screen / shade, not just
   in the test); a baby 5 months out with no record → the due-now catch-up shows on Home.
3. **The tap pair**: alive + cold, both platforms — tap lands on Home (B22); tap on a detached
   custom records it (D-R9 branch 1); tap on a treatment preset opens the pre-filled sheet, and
   the record made there settles the reminder (D-R9 branch 2); **a mistap test**: tap and
   background without confirming → nothing is recorded (B15 "Do not" 1, observed, not assumed).
4. **The per-reminder hour**: one item at 08:00 under a 09:00 global — the 08:00 catch-up window
   observed; the settings subtitle shows the inherited vs own state (screenshot, the two states).
5. **Removal + re-add**: remove a preset (row gone, OS entry gone, home gone) → the Removed
   section → restore → back on with its switch state kept.
6. **The end trio on the device** (D-R5): (a) set *until a date* = yesterday on a preset → sync →
   its OS entry is **gone** and it never shows due (the fast end-observation — no waiting for a
   real end); (b) set *until an age* on a reminder → the resolved date displays next to the
   stepper → edit the baby's birthdate → the resolved date **moves** (read-time resolution,
   observed, not just unit-tested); (c) the *one time* option in the same picker behaves as M3's
   one-shot (the trio shares one UI).
7. **Screenshots** of every touched screen (Small_Phone + normal): the settings list (preset rows
   with hour + menus), the edit sheet (frequency + the end trio), the Removed section, the
   switcher, the feeding note field, the history pills. `xcrun simctl io` / `adb exec-out
   screencap`, then **look at the files**.
8. **Export JSON inspection** (the manual entry path, as always): record a feeding with a note,
   a measurement, set an hour, set an end, remove a preset → export → the v5 fields present
   (`timeOfDay`, `label`, `frequency`, `intervalDays`, `frequencyDate`, `endDate`, `endAgeMonths`,
   `removed`) → the file restores on a fresh emulator with the removal, the hour **and** the end
   intact; a hand-broken file (both end fields set) is **refused** with the file-level error
   (§4's exclusivity refusal).
9. Record in the PR: which pass, which simulator/emulator, what was seen — an unrecorded pass is
   a pass that didn't happen.

---

## 6. The 1.3.3 contingency (NOT scheduled — the re-cut rule)

1.3.3 exists **only if** the core (M1–M4) overruns and the owner wants the fixes unblocked. The
re-cut is exact, so the decision is a one-liner at the slip:

- **1.3.3** = M5 (the tap pair) + M6 (the small batch) + their l10n/patch-notes — **everything
  schema-free**. No v14, no format 5. B6, B30, B33 do **not** move down: B6's urgency is for
  *new* installs (existing installs keep the reminder, which is today's behaviour — delaying costs
  no one their data or a fix), and splitting B6's seed from the v14 columns would either cascade
  the schema numbers (1.3.3=v14 → 1.4.0=v15 → Phase A=v16, breaking the locked PLAN-sync numbers)
  or ship B6 unfaithful (the naive flip-off, D-R1's rejected path).
- **1.4.0** then = M1–M4 (+ B15 stays with M5's surface? **No** — B15 rides 1.3.3 with M5;
  1.4.0 is the pure reminder cluster).
- If there is no slip: **no 1.3.3 exists**. The version numbers simply go 1.3.2 → 1.4.0 → 1.5.0.

## 7. Risks & rollback

| Risk | Mitigation (already in the plan) |
|---|---|
| The seed (D-R1) mis-inserts and flips a parent's off | The `NOT EXISTS` guard inserts only where absent, only `enabled=1`; M1 test 1 asserts an existing `enabled=0` row is byte-unchanged; the gate observes it on device |
| Two item lists disagree (B31 class) | The single effective-item function (D-R2) + the M4 invariant test + the M3/M4 plan-removal tests |
| The one-shot never reschedules / never stops | M3's isDue suite (completed → never) + the scheduler plan-removal regression + the gate step 2 on a real lock screen |
| Format-5 import breaks formats 1–4 restores | The §4 regression wall + the M8 named test |
| The tap handler's cold-start semantics differ per platform (B15's warning) | M5 verifies 22.x behaviour per platform *before* wiring; the gate step 3 covers cold on both |
| l10n drift (a string in en only) | M7 sweeps; the existing fr/es parity checks in `make ci` |
| Scope creep from the small batch | M6 is last of the code milestones; if M1–M4 overrun, §6's re-cut removes the batch from 1.4.0 without touching the core |

Rollback policy: none in-app (the additive v14 + the seed are forward-only, the app's standing
position — no downgrade support, no REKEY-class moves were made). A bad 1.4.0 is a 1.4.1, not a
revert.

## 8. Definition of done

- M1–M9 all green, in order, one commit each; `make ci` clean at M8 (≥ 80 % domain/data).
- The gate (§M9) recorded in the PR with device, build, and what was seen.
- `1.4.0` patch notes in fr/en/es, noun form, no clinical claims (D-R11 checked line by line).
- `pubspec.yaml` at `1.4.0+<build>`; `make store-check` green (no store surface change).
- The next numbers are free and locked for Phase A: **schema v15 + export format 6**
  (`docs/PLAN-sync-phase-a.md` §3/§4) — this release must not consume them.
- The backlog statuses updated in the release PR: B6/B30/B33/B15/B22/B9/B13/B16/B17/B26/B27/B29/
  B7 closed-or-shipped, B23/B25 status lines corrected (§0), B32/B19/B20/B21 untouched (maintenance).

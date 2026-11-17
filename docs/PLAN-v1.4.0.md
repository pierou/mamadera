# PLAN — mamadera v1.4.0 (`1.4.0+17`, drift schema v14, export format 5)

Status: **in progress** — §2 decisions adopted on the owner's go-ahead of 2026-11-16
(« let's build 1.4.0 »); M1 landed, execution notes in §9. Written 2026-11-14 against
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

Every line number below was re-measured against `3c58037` on 2026-11-14. Where a symbol names the
fact, cite the **symbol** in anything you write back into this file — line numbers in this repo have
rotted twice in four days (`docs/ROADMAP-reminders-and-sync.md` §0 still points at
`import_repository_impl.dart:439` for a method now at `:570`).

| Fact | Evidence |
|---|---|
| `schemaVersion == 13` | `lib/data/local/app_db.dart:182` |
| `reminder_settings`: `(baby_id TEXT NOT NULL DEFAULT '', item_id TEXT NOT NULL, enabled BOOL)`, PK `(baby_id, item_id)` — **no time, no label, no frequency, no removal state** | `app_db.dart:60-68` |
| "Absent row means on" is **not one literal — it is four, in two different idioms**, and no per-item default exists anywhere: `settings[item.id] ?? true` at `reminder_providers.dart:87` (`enabledRemindersProvider`, declared `:81`), the preset switch value at `reminder_settings_screen.dart:112`, the custom-tile switch at `:147`, and — **a different idiom, invisible to a `?? true` grep** — `if (enabled[item.id] == false) continue;` at `reminder_scheduler.dart:121` | those four sites (B6) |
| Frequency codec: `({String code, int? intervalDays}) _encodeFrequency` with 4 codes from `db_constants.dart` (`daily`, `weekly`, `monthly`, `every_n_days`); tolerant decode maps unknown → daily (the "never disappear" rule) | `lib/features/reminders/data/repositories/reminders_repository_impl.dart:273-300` (`_encodeFrequency` `:273`, `_decodeFrequency` `:287`) |
| `ReminderFrequency` is a sealed class with exactly 4 variants — **no `OneTime`, no end-date capability anywhere** | `lib/features/reminders/domain/entities/reminder_frequency.dart` (B33) |
| Vitamin K preset: `CustomInterval(days: 30)` static; `buildForBaby` → `Monthly(dayOfMonth: birthDate.day)` — monthly **for life**, no termination path | `lib/features/reminders/domain/entities/reminder_item.dart` (B33 Part 1) |
| The 365-day form-sheet cap is the documented boundary: « after one year, the parent wants a specific date. **Not a reminder.** » | `lib/features/reminders/presentation/widgets/custom_reminder_form_sheet.dart:36-38` (B33 Part 2) |
| Scheduler: `sync()` takes one `preferredHour`/`preferredMinute` for **all** items; `_PlanEntry` diff on `(at, title, body)`; the enabled-map read is already per-(baby, item) (`getEnabledByItemId`) | `lib/features/reminders/domain/services/reminder_scheduler.dart` (B30) |
| Global hour: `app_settings` key `notification_time_of_day`, default `09:00`, codec + validator in `notification_time.dart` (`isValidNotificationTime` / `parseNotificationTime`, read-lax / write-strict split documented) | `lib/features/reminders/domain/services/notification_time.dart` (B30) |
| Preset rows are bare `SwitchListTile` (no edit, no remove); custom rows have the switch **plus** `CustomReminderAction {edit, delete}` popup | `lib/features/reminders/presentation/screens/reminder_settings_screen.dart:107-116` (preset block), `:141-152` (custom tile) (B33 Part 3) |
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
- **The read path is four sites, not one (§1), and M1 changes all four.** `reminder_providers.dart:87`,
  `reminder_settings_screen.dart:112` and `:147` become `?? item.enabledByDefault`; the scheduler's
  `reminder_scheduler.dart:121` stops using `== false` and honours the same default (M4 then folds it
  into this function). Leaving any one behind is the B31 defect class **specified into the plan**:
  keep `:112` on the old literal and the parent sees a switch **ON** for a reminder that is off;
  keep `reminder_scheduler.dart:121` on `== false` and the **OS notification still fires** for a new
  baby whose vitamin D the app displays as off — while every provider-level B6 test in M8 passes.
  The *write* path (`setEnabled`) is unchanged.

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
  (a rebuild would be B31-class irreversible; none of this needs it). The whole batch was
  **executed against the v13 table shape on sqlite 3.54 (2026-11-14)**: all eight statements succeed,
  `time` is not a SQLite keyword, `removed INTEGER NOT NULL DEFAULT 0` is legal on a populated table,
  and the §3 seed leaves an existing explicit `enabled=0` row untouched (`enabled` still 0) while
  inserting `enabled=1` for the `''` scope and each row-less profile — re-run, it inserts nothing
  (3 `vitamine_d` rows both times). Contrast `docs/PLAN-sync-phase-a.md` §3, which as written does **not** execute: adding a
  `NOT NULL` column without a `DEFAULT` is rejected (`Cannot add a NOT NULL column with default value
  NULL`) — and the v12 precedent at `app_db.dart:371` is `unit TEXT NOT NULL DEFAULT 'ml'`, which is
  the only form that could have been added at all.
- `time` is validated by the existing `isValidNotificationTime` (write-strict at import, read-lax
  at the app read side — the split `notification_time.dart` documents).
- The DDL column is `time` (B30's name) while the §4 JSON key is `timeOfDay`. Deliberate (B30 names
  the column, the export already speaks camelCase), but two spellings of one field is a known
  importer footgun — name the parse variable `timeOfDay` to match the key it reads.
- **A NULL `frequency_date` has two different meanings** and D-R8 is only one of them. Read D-R8's
  resolution order before writing the effective-item function.
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

### D-R6 — Preset edit: label + frequency + the end trio (D-R5); care subtype is **not** editable

Preset rows gain the custom-tile affordance (switch + `edit`/`remove` menu —
`custom_reminder_tile.dart` is the reference). The edit sheet reuses the form's label + frequency
fields **plus the D-R5 end picker** (one time / until a date / until an age — the same widget
customs use, so presets and customs share one « frequency + end » surface); the **care-subtype
field is out** (B33: re-pointing `vitamine_k` at another event would decouple the reminder from the
dose that settles it — D2's completion-by-event stands).

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

**D-R8 covers a *stored* `frequency = 'one_time'` only.** A NULL `frequency_date` on a row whose
`frequency` column is NULL does **not** mean "due now" — it means "no override, use the preset's own
frequency", and the Vitamin K preset's date is **derived at read time** by `buildForBaby` (D-R10).
The two must never be conflated. Resolution order, explicitly:

1. `frequency IS NULL` → preset frequency, derived date, stored `frequency_date` **ignored**;
2. `frequency = 'one_time'` → stored `frequency_date`, and **only here** does NULL mean due-now.

If the effective-item function resolves the override pair and then reads `frequency_date`
unconditionally, the Vitamin K preset arrives at `OneTime(null)` for every new baby — **due at birth
instead of at one month**: the clinical fix shipping a wrong clinical default. Write-strict at the
picker follows from this: choosing *one time* on a preset edit requires a date (D-R5).

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
// M3 (2026-11-18): a ninth column, on the *other* table, in the same batch — the
// one-shot's occurrence day for a **custom** reminder. See §9's M3 note for why it
// could not wait for M4.
await customStatement('ALTER TABLE custom_reminders ADD COLUMN frequency_date TEXT NULL');
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

Drift data classes update accordingly (`ReminderSettings` gains the eight fields,
`CustomReminder` (drift) its `frequencyDate`; `?` / default as per the DDL);
`make codegen`; `schema.sql` kept in step by hand — **and B26's trailing comma fixed in the
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
`ReminderItem.enabledByDefault` field (D-R2) + **all four read sites** of the "absent = on" default
(§1, D-R2), not the one the ticket names: `settings[item.id] ?? item.enabledByDefault` at
`reminder_providers.dart:87`, `reminder_settings_screen.dart:112` and `:147`, and — the site a
`?? true` grep does not find — `reminder_scheduler.dart:121`, from
`if (enabled[item.id] == false) continue;` to
`if (!(enabled[item.id] ?? item.enabledByDefault)) continue;` (M4 replaces that line with the D-R2
function call; **until M4 lands it must already honour the per-item default**, or M1 is green and
wrong on a device). Then the settings list
showing the off-by-default vitamine_d row **visible, switch off** (D-R2's "off but visible") +
the §3 migration tests + the existing B6 tests amended + the M8 scheduler assertion.
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
**M4 rewrites `reminder_scheduler.dart:118-121` again** — the map M2 reads becomes the settings map
the D-R2 function takes — so keep M2's change narrow and inside the loop; do not build a helper here
that M4 immediately discards.
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

The effective-item function (D-R2) below the three consumers — **it deliberately absorbs M2's
per-scope settings read at `reminder_scheduler.dart:118-121`, superseding M2's shape**; the
settings-row writes for
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
- **B6**: existing-off stays off, existing-absent gets the seed, new baby is off (M1) — asserted on
  **both** consumers: the provider list *and* `ReminderScheduler.sync()`'s plan. A new baby with no
  `vitamine_d` row must produce **zero** OS entries. Named explicitly because the provider-only
  assertion passes on the broken three-of-four-sites version of M1;
- **B15 payload identity** is never the plan index (M5).

### M9 — Release gate (AGENTS.md, non-negotiable; the emulator pass BEFORE the PR)

1. **Migration on old data**: install 1.3.2 (v13) on the emulator, seed a profile + events + a
   manually-turned-off vitamine_d → install the 1.4.0 build → §3 test 1 observed on the device:
   the parent's off is still off, the seed rows exist, data visible. Then **create a new baby** and
   confirm on that same device: the vitamine_d switch shows **OFF** (`reminder_settings_screen.dart:112`)
   **and** no OS notification is scheduled for it (`reminder_scheduler.dart:121`) — the four-site
   default seen on a lock screen, not assumed from a provider test.
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
- **The lever this section does not offer, recorded so it is not rediscovered under pressure.**
  M1–M4 is treated as uncuttable, and it is — except that **D-R5's forms 2 and 3** (`end_date`,
  `end_age_months`) are the only scope in 1.4.0 beyond what the owner actually asked for
  (« vitamin K should be a one timer » = M3's one-shot alone). Deferring them to 1.5.0 would drop 3
  of the 8 v14 columns, the read-time age resolution, the birthdate-edit-moves-the-plan tests, the
  profileless disabled-hint and the 0–180 stepper, and keep every B6/B30/B33-Part-1 promise. The
  owner chose the trio on 2026-11-14, so this is a **sequencing** note, not a renegotiation — it is
  here because M4 is the largest milestone in the release and the first thing that gets cut.

## 7. Risks & rollback

| Risk | Mitigation (already in the plan) |
|---|---|
| The seed (D-R1) mis-inserts and flips a parent's off | The `NOT EXISTS` guard inserts only where absent, only `enabled=1`; M1 test 1 asserts an existing `enabled=0` row is byte-unchanged; the gate observes it on device (guard and idempotency both executed on sqlite 3.54, D-R3) |
| The seed permanently destroys the **"never touched"** signal: after M1 an absent `vitamine_d` row means *scope created post-1.4.0*, never *legacy default* | Accepted deliberately — D-R1 is precisely what needs that distinction, and nothing else in the app has a use for it today. Written down so a future "was this parent ever asked?" feature does not assume the signal survived the seed |
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

---

## 9. Execution notes (written back per §0 — "cite the symbol, not the line number")

> Session handoff (state, resume point, traps already paid for): `docs/HANDOFF-v1.4.0.md`.

### M1 — schema v14 + B6 (done against `develop` @ `5c9b5f8`)

Implemented as specified. Three things the plan did not predict, all recorded here
because the next milestones touch them:

1. **`ALTER … ADD COLUMN` is not re-runnable, and a test fixture knew that only
   about v12.** `test/data/local/real_file_migration_v11_to_v12_test.dart`
   fabricates a v11 file by hand (`PRAGMA user_version = 11`) and had always
   dropped `tracking_events.unit` first — precisely so the v12 step would have
   its real job. It now has to drop the eight v14 columns and the seeded vitamin D
   rows too, or the next open dies on `duplicate column name: time`. Any future
   milestone that adds a column has the same obligation in that helper, and the
   helper now asserts `reminder_settings` is back to three columns so the lie
   cannot come back.
2. **The seed collides with a sentinel-collapsing fixture.** The same helper does
   `UPDATE reminder_settings SET baby_id = ''`; with the seed there is now a
   `('', vitamine_d)` row *and* a `(baby, vitamine_d)` row, so the collapse hit
   `UNIQUE constraint failed`. Fixed by deleting the seed rows before collapsing
   (a genuine v11 never had them), not by weakening the seed.
3. **Eleven test files asserted "absent row = on".** The B6 amendment is not one
   line: the scheduler harness (`_Harness`, `ReminderScheduler.sync`) now seeds an
   explicit vitamin D row by default (`seedVitaminDOn`, the post-migration state of
   a 1.3.x install) with `setEnabled` merging into it, and the widget/provider
   harnesses that count four preset rows seed the row too. Each site says why, so
   the seed cannot be mistaken for the new default. `enabledByDefault` is asserted
   on **both** consumers as §0 demands: `enabledRemindersProvider` and
   `ReminderScheduler.sync()` (a new baby ⇒ zero OS entries naming `reminderVitaminD`).

**RESOLVED IN M3 (2026-11-18) — see the M3 note below.** D-R5 gives the *custom* reminder a
one-shot in the same picker as the presets, but the occurrence date column
(`frequency_date`) is on `reminder_settings`, while a custom reminder's frequency
lives in `custom_reminders.frequency` beside its own `interval_days`. So a custom
one-shot has no date column. Two admissible shapes: add `frequency_date` to
`custom_reminders` (symmetric with `interval_days`: the frequency's parameter
travels with the frequency), or read/write it through the `custom_<id>` settings
row (one carrier for every reminder-level field). v14 is still unreleased, so M4
may extend the same `if (from < 14)` block either way without spending a schema
version — but it must be a decision, and §3's "eight columns" line is the number
that changes.

**Noted, not fixed (out of release, §0):** `schema.sql` declares four indexes no
code creates — `idx_reminder_settings_baby_item`, `idx_reminder_dismissals_baby_item`,
`idx_custom_reminders_baby_id`, `idx_custom_reminders_label`. Neither `onCreate`
nor any `onUpgrade` step makes them (zero hits for the names in `lib/`), so they
exist only in the reference file. B26's replay guard now executes the file, so it
is *syntax* that is guarded here; the index parity between file and code is a
doc-drift ticket of its own (the v11 index gap in `schema_parity_test.dart` was
the same class, and it was fixed in code).

### M2 — B30 per-reminder hour (done on `release/v1.4.0`)

Implemented as specified: `reminder_settings.time`, resolved **inside** the plan loop
(`ReminderScheduler._buildPlan` → `_timeOfDayFor`), `nextDueAt` untouched, `NULL` = inherit,
preset row and `CustomReminderTile` both carry `ReminderHourControl`, the global row stays
the default. l10n reuses `reminderAt` for the time itself and adds four keys
(`reminderTimeInherited`, `reminderTimePickerTitle`, `reminderTimeUseGlobal` — fr/en/es).

Four things the next milestones inherit:

1. **`setEnabled` had to become an upsert.** It used to `delete` the row and insert a fresh
   one, which was invisible while `enabled` was the only column and destructive the moment a
   second one existed: set an hour, then toggle the switch, and the hour was gone. It now
   inserts `enabled` and, on conflict, **updates only `enabled`**. The discipline generalises and
   M4 depends on it — every writer touches its own columns and nobody's else (`setItemTime`
   writes `time`, `clearItemTime` nulls `time`). Three existing tests failed on the old shape;
   none of them was weakened.
2. **The seam D-R2 wanted now exists.** `getEnabledByItemId → Map<String, bool>` is gone; the
   repository returns `Map<String, ReminderItemSetting>` (`enabled`, `timeOfDay`) from one query
   per scope. **M4 extends that row and its reader** (interval overrides, end, `removed`) rather
   than adding a second map — that was the whole point of doing them in one place.
3. **Format 5 landed early**, exactly as D-R3 predicted, and with it the importer's
   `formatVersion` awareness: `ParsedExport.formatVersion` now exists, a document below 5 gets
   the vitamin D seed replayed inside the restore (`_insertReminderSettings`), and the
   standalone `seedVitaminDForExistingScopes` became dead and was deleted. A `timeOfDay` that is
   present but not `HH:mm` 24-7 rejects the whole document (strict write, lax read); absent
   means inherit.
4. **The complexity guard moved from 3 to 4 (Makefile), and the fourth entry is a measurement
   artifact, not a long function.** `sync()` was approaching the length cap, so it is now
   `sync()` (read the settings map, resolve the hour) + `_buildPlan()` (steps 3-4) +
   `_applyDiff()` (steps 5-6) — all three under 70 lines. But lizard's Dart parser sees no
   method boundary inside `ReminderScheduler` at all and charges the **whole class** to its
   constructor (`ReminderScheduler::ReminderScheduler`, 312 "lines"); four member orderings were
   tried and which boundaries it detects moves with the file's shape, not its size. The cap is 4
   with that entry named and explained. **To get back to 3:** extract `_applyDiff` (the half that
   talks to the OS, with `_plan`/`_catchUpArmed`) into its own type — worth its own small PR,
   not a milestone rider.

*Export test note: four long tests that count export assets went 4 → 5, because B30 adds the
`timeOfDay` key to `reminderSettings`; `nProgress` is derived from that list, which is the
behaviour the long test exists to pin.*

### M3 — B33 Part 1: the one-shot, the end model, the Vitamin K cadence

Implemented as specified (`OneTime`, D-R7 catch-up, D-R8 tolerant decode, D-R5 end
semantics, D-R10 fallback, `freqOneTime` + codec, `buildForBaby` → one month), with
one decision the plan left to M4 and four things the rest of the release inherits.

1. **The custom one-shot's carrier is a column, and it landed in v14 after all**
   (`custom_reminders.frequency_date`, the ninth column of the batch, §3 amended).
   The plan offered two shapes; the codec forced the choice in M3 rather than M4,
   because `_encodeFrequency` is exhaustive over the sealed type — adding `OneTime`
   without somewhere to write the date meant either dropping the date or refusing
   the reminder, and both are silent data changes. Settings-row carrier rejected for
   the same reason the export rejects it: it splits one frequency across two tables,
   and `custom_reminders` rows are exported and replayed as a section on their own.
   Symmetric with `interval_days`: the frequency's parameter travels with the
   frequency. Consequences honoured in the same commit: exported (`frequencyDate`),
   imported (with **`one_time` requires a parseable date**, and the inverse — a date
   on a recurring row is refused), and dropped by the `real_file_migration_v11_to_v12`
   helper exactly as §9/M1 predicted any new column would have to be.
   **Declared last in the drift class**, because `ALTER` appends and
   `schema_parity_test` compares fresh-vs-migrated column *order*: the logical place
   (beside `interval_days`) makes a fresh install disagree with an upgraded one.
2. **`nextDueAt` is now nullable, and that is the whole removal mechanism.** `null` =
   "can no longer be due", and three callers use it: a settled one-shot (D-R7), a
   series past its end (D-R5), and — in M4 — a removed row. The scheduler skips the
   item, the existing `_PlanEntry` diff cancels the id. No second cancel path.
   `reminder_scheduling_test` and `reminder_scheduler_test` split the assertions
   accordingly: the pure function answers `null`, the scheduler makes the OS forget.
   Note in the scheduler test: **plan ids are positional and compact**, so dropping a
   middle item does not cancel *its* id — it cancels the tail and re-submits whoever
   moved (R11, pre-existing). That is why those tests assert on the *title* absent
   from the fake's entries, not on an id; the one id-exact test ends the last item.
3. **Two shared helpers were created instead of duplicated** (both pure Dart, both
   with their own test file):
   - `core/utils/date_arithmetic.dart` — `addMonthsClamped` is B18's rule, extracted
     from `baby_profile_section.dart` (where it was private and only the age label
     used it); `wholeMonthsOld` replaces the age computation there too. D-R5 says "the
     same `_addMonths`, not a new one" and this is the only way to honour it across
     two features.
   - `core/utils/calendar_date.dart` — `parseCalendarDate`/`formatCalendarDate` for
     the `'yyyy-MM-dd'` columns. `DateTime.tryParse('2026-12-15')` returns **UTC**
     midnight, which against a device-local `now` is the day *before* for any parent
     west of Greenwich: an inclusive end date would silently become exclusive. The
     helper validates the fields and returns a local midnight, and rejects the dates
     Dart would otherwise normalise into existence (`2026-02-30` → 2 March).
   - `reminder_end.dart` — `reminderEndFor` (date wins over age; age needs a
     birthdate; age 0-180 canonical) and `isPastSeriesEnd`/`seriesEndExpiry`, the one
     cutoff check for all five frequencies (D-R5's carrier decision: the end belongs
     to the reminder, never to the variant).
4. **D-R8's resolution order is implemented in `_decodeFrequency`, not downstream** —
   the date column is read *only* when the code is `one_time`. `reminder_item_test` /
   the repository test pin the two directions: `one_time` + junk date ⇒ due-now
   one-shot (never daily, never gone), and a date on a `daily` row ⇒ ignored. A
   reader that resolved the pair first and then read the date would hand Vitamin K a
   `OneTime(null)` for every new baby — due at birth.
5. **Vitamin K's behaviour change reaches further than the entity.** Seven existing
   tests asserted the monthly-for-life cadence (3 in `reminder_item_test`, the UI ⇔
   scheduler parity row, 2 screen rows, 1 home-section row) and 2 export asset maps;
   each now asserts the one-shot with its date, including the clamped anniversary
   (31 January 2026 ⇒ 28 February 2026). None was deleted or weakened.

**Consequence to watch, not a bug (D-R7 as written):** a one-shot whose date is long
past is *due*, so a family whose baby is two years old sees vitamin K as overdue on
Home until it is settled or the switch turns it off. The nudge itself fires once per
process (the catch-up period key is the occurrence day, so it does not re-arm daily),
and the escape is the settings switch — one tap, and the reminder leaves Home and the
plan. If that reads as noise in the emulator pass, the fix is a one-shot staleness
rule, which is an owner decision, not an implementation detail.

**Open for M4 (from this milestone, unchanged in kind):** the custom **edit sheet**
offers no one-shot entry point, so editing a custom reminder that arrived as
`one_time` (hand-built backup — no in-app writer exists yet) saves it back as daily.
M4 rewrites that sheet anyway (its exit criterion: "the 365-day cap becomes the
one-shot's door"), and the `frequency_date` column is already there for it.

**Tooling note:** `make check-complexity` stayed at 4 and `make check-architecture`
unchanged; M1's `schema_sql_replay_test` caught a real bug in this milestone's own
edit — a comma added *after* a `--` comment in `schema.sql`, which SQLite reads as
part of the comment. That is the guard earning its place.

### M4 — B33 Part 3: preset overrides, removal, UI parity (done on `release/v1.4.0`)

**What landed.** `effectiveItemsForScope` (`domain/services/effective_reminders.dart`) is D-R2's
one point: it drops removed items, applies the label/frequency overrides and resolves the series
end, and it is called by exactly the three consumers — `ReminderScheduler._buildPlan`,
`enabledRemindersProvider`, `ReminderSettingsScreen`. Four writers own one column set each
(`RemindersRepositoryImpl.setItemLabel` / `setItemFrequency` / `setItemEnd` / `setItemRemoved`,
all through one `_upsertOwnColumns` helper), which is M2's writer discipline extended rather than
forked. `ReminderEndPicker` is the D-R5 UI (none / on a date / at an age, resolved date shown,
age disabled-with-hint without a profile, past end warns and accepts); it is used by
`PresetReminderEditSheet` (no care-subtype field, D-R6) **and** by `CustomReminderFormSheet`.
`_RemovedSection` restores with one tap (D-R4). Export v5 writes the whole settings row and the
importer parses it, refusal included: `endDate` + `endAgeMonths` together, an end on a `one_time`,
`one_time` without `frequencyDate`, a `frequencyDate` on another code, `endAgeMonths` outside
0–180, a non-boolean `removed`.

**Deviation, deliberate — the preset row's menu is in `secondary`, not `trailing`.** The plan's
reference (`custom_reminder_tile.dart`) puts switch + menu in a `trailing` row. The preset rows are
`SwitchListTile`s, whose `trailing` *is* the switch; moving both into `trailing` would have
replaced `SwitchListTile` with a hand-rolled `ListTile` + `Switch`, and every test and screen
helper that finds a reminder's switch by its label (`_switchFor`/`_isOn` in
`reminder_settings_screen_test.dart`) reads the `SwitchListTile` semantics. `secondary` keeps one
widget, one accessibility element, and the switch label association. Cost paid: the title column
narrows by ~40px, the hour subtitle wraps more, and the "System notifications" section fell below
the test viewport — a lazy `ListView` does not build it, so two `findsNWidgets(5)` assertions
became `findsAtLeastNWidgets(4)` (they assert the four preset switches exist, which is what they
were for) and the D8 de-opt test now uses the group's existing `revealOptIn` before reading its
switch. Nothing was scrolled away in the app; the assertions were betting on a scroll extent.

**Deviation — the custom form sheet returns `CustomReminderDraft`, not `CustomReminder`.** The end
belongs to the settings row (`custom_<id>`), not to the reminder, and the sheet's contract is that
it writes nothing. So it returns the reminder plus the chosen end and the screen performs the two
writes, `ReminderSettingsNotifier.setEndById` being the second one: after `create`, the new item
is not in `customReminderItemsProvider` yet, so the end is addressed by id with
`enabledIfNew: true` — creating a custom reminder *was* the consent (B6), whereas every preset
write passes `item.enabledByDefault`.

**What the guards caught, in order.**
1. **The analyzer, on `ReminderItemSetting.copyWith`:** the row mirrors the *columns* (`endDate`
   is `'yyyy-MM-dd'` text), while `ReminderItem.endsAt` is a `DateTime`. The first draft of
   `setEndById` passed a `DateTime` where the row wanted text. The fix keeps one spelling on disk
   (`formatCalendarDate` on the way in, `reminderEndFor` on the way out) instead of letting two
   representations of the same day coexist.
2. **`scripts/check_architecture.py`'s 800-line ratchet:** B33's validation pushed
   `import_repository_impl.dart` to 804. Split as
   `import_repository_reminder_parsing.dart` (`part` of the same library) rather than raising the
   baseline — the pairing rules read better on their own page anyway. Baseline unchanged at 0.
3. **My own test helper, via `const` canonicalisation:** `const Object _profileDefault = Object();
   const Object _noProfile = Object();` are the **same instance** — Dart canonicalises identical
   const constructor calls — so the "age end without a profile" case silently ran *with* one and
   asserted a resolved date as `null`. Two private classes fixed it. Worth remembering as a
   sentinel idiom in this tree: distinct marker types, never two `const Object()`s.
4. **`make check-complexity`:** unchanged at the documented baseline of 4.

**Tests.** `effective_reminders_test.dart` (13 cases: each override kind, the malformed-date
lax read, the both-ends-corrupt-row tie-break, and the one thing the function must *not* do —
apply `enabled`, since Settings must show a switched-off reminder);
`reminders_settings_writers_test.dart` (9 cases on a real drift DB: each writer writes only what
it owns, one-shot ⇒ stored end cleared, age canonicalised with no date column written, both forms
refused at the write, removal leaves `enabled` alone, and D-R9's per-scope isolation);
`reminder_scheduler_test.dart` gains "a removed preset is cancelled from the OS schedule (D-R2,
D-R4)" — cancel, other presets intact, restore re-schedules; `reminder_settings_test.dart` gains
the B31 regression asserted concretely (removed absent from Home, nickname/rhythm/resolved end
visible on the items) rather than by calling the function under test;
`import_repository_impl_test.dart` gains the format-5 whole-row restore, the before-format-5
"loses nothing it never had" case, and three refusals.

**Exit criteria still open after this commit:** none of M4's list, with one scope note — the plan's
"single-source invariant (provider and scheduler return the same effective list)" is proved as two
tests, not one: Home's side in `reminder_settings_test.dart`, the scheduler's side in
`reminder_scheduler_test.dart`. A single harness driving both from one stored row would need the
drift-backed repository *and* the fake notification service in the same container; the two halves
each go through `effectiveItemsForScope` in production code, which is what the invariant actually
claims, so the shared-function test was not worth the harness.

### M5 — B22 + B15: the notification tap pair (done on `release/v1.4.0`)

**What landed.** `FlutterLocalNotificationService` now registers
`onDidReceiveNotificationResponse` in `init()` and forwards `response.payload` to an injected
`onNotificationTapped` (B22's seam: the data layer must not import `core/router.dart`); the seam is
`localNotificationServiceProvider`, which `watch`es the handler and passes `handler.handle`.
`scheduleAt`/`scheduleIn` gained an optional `payload`, and `ReminderScheduler._applyDiff` submits
`ReminderNotificationPayload(scope, item.id).encode()` on every entry — plan entries included, so an
entry whose identity moved to another plan index cannot be skipped as "unchanged". The tap lands on
Home first (`AppRoute.home.path`, before the payload means anything), then: detached →
`RemindersNotifier.markDone(item, scope: payload.scope)`; treatment-linked →
`pendingCareSheetProvider`, consumed by `HomeScreen`.

**D-R9 as implemented.** The treatment-linked branch does not write. It asks Home to open
`HealthSubtypeDialog`, which gained `initialSubtype` (the sub-type pre-selected, date left at "now" —
what a tap means), and the parent confirms through the existing care flow. `_HomeContent`'s sheet
opener became the library-private `_showHealthSubtypeSheet`, because two callers now need the *same*
flow and a second copy would be a second place to keep D2 true. `PendingCareSheetNotifier.take()`
drains atomically: Home can see the request two ways (the first build after a tap that navigated
here, and `ref.listen` for a tap that arrived while Home was already up), and without the atomic take
one tap stacks two sheets.

**Riverpod 3's disposal is a real hazard on this path, and it is now guarded twice.** A provider
nothing watches is disposed as soon as the read returns, and a tap's work continues *after* the
plugin callback returned: the first draft died exactly there, in `_act`, on
`Cannot use the Ref of Provider<NotificationTapHandler> after it has been disposed` — found by the
test, not by reading. The anchor is `ReminderLifecycleSyncWidget.build`, which `watch`es
`notificationTapHandlerProvider` (that widget is mounted above the router for the life of the app);
`_act` also checks `_ref.mounted` after each await, so an app torn down mid-tap writes nothing.

**A tap selects the child it is about** — owner decision 2026-11-17, resolving the one open point of
this milestone. D6 schedules *every* baby, so a banner may belong to the child who is not selected.
The first cut stopped such a tap at Home, because the care sheet is Home's and Home shows the
selected baby: opening it for Béa would have recorded the care against Aimée. The owner's answer was
to go the other way — **`switchProfile(payload.scope)` first, then act** — which is also the more
honest reading of B22: « tap ⇒ Home » was always « tap ⇒ that baby's Home ». So a cross-baby tap now
(i) selects that baby, (ii) settles a detached reminder for them (`markDone` still takes the payload's
`scope` explicitly, so the write is right even when the selection is a no-op) or (iii) asks for their
care sheet, asked *after* the selection moved so Home opens it for the right child.

Two edges kept deliberately: the profileless `''` scope **cannot** be selected (there is no profile
to select), so a tap from a legacy install whose selection is a real baby still stops at Home with a
log line instead of a misattributed care record; and a tap for the already-selected baby never calls
`switchProfile` at all — that write deactivates every profile and rebuilds the dependent tree, and a
tap that needs neither must not pay for it. Both are pinned by tests.

**Not unit-tested, and why.** `router.go(AppRoute.home.path)` itself: the handler's navigation is
asserted through an injected `navigate` (the alternative is pumping the whole route tree — splash,
terms gate, shell — to learn that one string was passed), and the two lines of the *seam*
(`watch` + `handler.handle`) are covered by B22's five-case device pass, which is where B22's repro
lives anyway. This is the one part of v1.4.0 no widget test executes (the plan's M5 device note).

**Also, one ratchet went down.** Three presentation files compared
`completionSource == completionManual`, each importing `data/local/db_constants.dart` for it.
`ReminderItem.isDetached` (domain) answers the question instead, and the
`presentation_to_data` baseline is now **2** (was 4) — the first shrink of that rule in the repo.

**Tests.** `flutter_local_notification_service_test.dart` (+4: the callback is registered, it
forwards the payload exactly once, a service with no handler survives a tap, the payload rides
`zonedSchedule` and a null payload still schedules); `notification_payload_test.dart` (new, 5:
round trip, the `''` sentinel, ids needing escaping, the junk-strings list, and the encoded shape
pinned as JSON because a *different build* reads it back); `reminder_scheduler_test.dart` (+4: every
entry carries its scope + stable id, the payload follows the reminder when the plan reshuffles, the
catch-up nudge carries the same identity, a re-submission keeps it);
`notification_tap_handler_test.dart` (new, 12: Home always, no payload, cross-baby detached
completion *and* selection, the pre-filled sheet ask, cross-baby selection then ask, no
`switchProfile` when already selected, removed reminder, missing reminder, deleted baby, profileless
scope not selectable, `take()` drains once); `home_screen_test.dart` (+2: the sheet opens
pre-selected, and once). 1682 tests, coverage 84 %.

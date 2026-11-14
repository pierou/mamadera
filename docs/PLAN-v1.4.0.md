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
- **One function, three consumers.** `effectiveItemsForScope(babyId, items, settingsMap)` (name at
  the plan; the ticket's "the override function must sit below both") returns the item list with
  overrides applied (label/frequency, D-R3) and removal filtered, in **one** domain function.
  Consumers: the settings screen provider, the home reminders section, the scheduler's
  `_itemsForScope`. The B31 invariant — provider and scheduler can never disagree — is structural,
  not a test's faith.
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
ALTER TABLE reminder_settings ADD COLUMN frequency_date TEXT NULL;  -- B33: ISO 8601 'yyyy-MM-dd' when frequency = 'one_time'
ALTER TABLE reminder_settings ADD COLUMN removed INTEGER NOT NULL DEFAULT 0;  -- B33: the third state (D-R2)
```

- All additive; `ALTER TABLE … ADD COLUMN` (the v12 precedent) — **no table rebuild, no rekey**
  (a rebuild would be B31-class irreversible; none of this needs it).
- `time` is validated by the existing `isValidNotificationTime` (write-strict at import, read-lax
  at the app read side — the split `notification_time.dart` documents).
- The new frequency code: `const String freqOneTime = 'one_time';` in `db_constants.dart` beside
  the four existing codes.

### D-R4 — Removed presets are re-addable, from a Removed section

B33's open plan call ("how is a removed preset re-added? — a hidden section, or never"):
**a collapsed « Removed » section at the bottom of the settings screen**, one tap restores
(`removed = 0`). Rationale: removal is a state flag, not a delete — the preset cannot be lost, so
"never" buys nothing and a misclicked removal becomes unrecoverable; the section costs one
`ExpansionTile`-class widget and one l10n string. (Customs keep their existing hard-delete
semantics — D-R4 is about *presets* only.)

### D-R5 — B33 Part 2 scope: `OneTime` is the generic "end"; no `untilDate` modifier

The owner's « program an end to a reminder » is delivered by `OneTime` being available **everywhere
a frequency is chosen**: the custom form sheet (which removes its 365-day cap's « not a reminder »
dead end — a date *is* the answer the cap pointed at) and the preset edit sheet (D-R6). A general
`untilDate` on all four existing rhythms is **rejected**: no ticket asks for "monthly *until* X",
the model cost is real (every `isDue` variant grows a branch), and `OneTime` covers the expressed
need. The storage (D-R3) precludes neither — `frequency_date` is there if a future ticket wants it.

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
"Do not" applies); presets editable/removable; Vitamin D now off by default for **new** babies
(existing keep it until turned off — say so, it is the consent line decision A demands);
notifications: tap lands on Home + tapping a reminder performs its action. No "l'app suit l'OMS",
no mortality or efficacy claim (research archive, non-negotiable).

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

Drift data classes update accordingly (`ReminderSettings` gains the six fields; `?` / default as
per the DDL); `make codegen`; `schema.sql` regenerated — **and B26's trailing comma fixed in the
same regeneration** (the reference file must replay: `sqlite3 :memory: < schema.sql` exits 0 — add
that as the replay guard, B26's To-do).

Irreversibility: none beyond the standard additive-column policy (v12 precedent); the seed is
idempotent (the `NOT EXISTS` guard) and only ever inserts `enabled = 1`.

**Migration tests (write in M1, not after):**

1. v13 DB with one profile + one event + an existing explicit `vitamine_d` row `enabled=0`
   (a parent who turned it off) → v14: **row unchanged** (`enabled` still 0), six new columns
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
'frequencyDate': row.frequencyDate,       // 'yyyy-MM-dd' | null
'removed': row.removed,                   // bool
```

- **Import of a format ≤4 file**: absent keys → the nullable fields default (`removed` → `false`) —
  the existing row contract, no new table, no new section. The `databaseSchemaVersion` guard is
  untouched (a v13 document is still a v13 document; the *format* is what moved).
- **Import of a format 5 file**: `timeOfDay` validated with `isValidNotificationTime` — a malformed
  hour **refuses the file** (B30 shape §2: write-strict, exactly like the global hour today); a
  malformed `frequencyDate` (present but not `yyyy-MM-dd`) likewise refuses; `frequency` present but
  an unknown code **refuses** (the app read side is tolerant, the importer is not — the same split
  the existing custom-reminder frequency validation uses).
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

### M3 — B33 Part 1: `OneTime` + the Vitamin K cadence

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
+ D-R8. Tests: `reminder_frequency_test.dart` (the isDue suite incl. completed-forever and
catch-up), `reminder_scheduling_test.dart`, `reminder_scheduler_test.dart` (plan removal), the
codec's tolerant branches.
*Ticket: B33 Part 1.*

### M4 — B33 Part 3: preset overrides + removal + UI parity

The effective-item function (D-R2) below the three consumers; the settings-row writes for
`label`/`frequency`/`interval_days`/`frequency_date`/`removed` (the switch write path extends,
does not fork); preset rows become the custom-tile pattern (switch + `edit`/`remove` menu —
`custom_reminder_tile.dart` reference); the preset edit sheet (label + frequency incl. one-shot
date picker, **no care-subtype field** — D-R6); removal = `removed=1` + **OS plan drop** (the M3
removal mechanism, second caller); the « Removed » section with one-tap restore (D-R4); the
re-add is per-(baby, item) (a second baby sees the preset fresh — D6's per-baby scoping, no
change). l10n fr/en/es. Tests: the single-source invariant (provider and scheduler return the same
effective list — the B31 regression, asserted directly), override round trip through export v5,
removal hides from settings + home + scheduler, restore re-shows, the second-baby fresh state.
*Ticket: B33 Part 3 (+ Part 2's scope: the custom form sheet gains the one-shot option per D-R5,
replacing the 365-day dead end — the cap comment becomes the one-shot's entry point).*

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
6. **Screenshots** of every touched screen (Small_Phone + normal): the settings list (preset rows
   with hour + menus), the edit sheet, the Removed section, the switcher, the feeding note field,
   the history pills. `xcrun simctl io` / `adb exec-out screencap`, then **look at the files**.
7. **Export JSON inspection** (the manual entry path, as always): record a feeding with a note,
   a measurement, set an hour, remove a preset → export → the v5 fields present (`timeOfDay`,
   `label`, `frequency`, `intervalDays`, `frequencyDate`, `removed`) → the file restores on a
   fresh emulator with the removal **and** the hour intact.
8. Record in the PR: which pass, which simulator/emulator, what was seen — an unrecorded pass is
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

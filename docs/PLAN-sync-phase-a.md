# PLAN — Phase A: two-phone merge over the share sheet (manual sync)

Status: **proposed — §12 decision points resolved by the owner, 2026-11-14** · Opened 2026-11-14 against
`develop` @ `3c58037` (1.3.2+16).
Mandate: owner decision 2026-11-14 (ROADMAP §6 status block + §7 decision 5, RESOLVED) — Phase A
*approved for a future release, version unassigned*; Phase B (LAN) under serious consideration,
gated on the written privacy-mandate change (B3); Phase C out of scope for now.
Upstream design: [`docs/ROADMAP-reminders-and-sync.md`](ROADMAP-reminders-and-sync.md) §6 — this
plan is the implementation document for its Phase A paragraph ("Stable UUID per event + per-row
`updated_at`/`deleted_at`; merge = union by UUID, latest write wins; still fully manual through the
existing share sheet. **No network, no new permission, no server.**").

---

## 0. Verified state (develop, 2026-11-14)

The facts the design rests on, all checked this day:

1. **Restore is replace-only.** `ImportRepositoryImpl.restore()`
   (`lib/features/import/data/repositories/import_repository_impl.dart:570`) deletes all eight
   tables (`:577-586`) and re-inserts inside one transaction — "All or nothing". A merge cannot
   reuse this path; it is a sibling of it.
2. **Row identity is the local autoincrement int, exported verbatim.** The importer writes file
   rowids straight into the autoincrement column (`id: Value(event.id)` `:601`, reminder `:628`,
   measurement `:677`). Two phones both tracking have event id 47, id 48, … on each side — the
   reason restore deletes first. There is **no stable cross-device row identity anywhere**.
3. **Profiles have no cross-device identity either.** `baby_profiles.id` is a TEXT pk, created as
   `DateTime.now().millisecondsSinceEpoch.toString()` at both creation sites
   (`lib/features/home/presentation/widgets/onboarding_dialog.dart:210`,
   `lib/features/menu/presentation/widgets/baby_profile_section.dart:278`). Two phones create the
   same baby under two different ids. The only stable cross-device signal is the *data* —
   (name, birthDate) — which is evidence for a suggestion, not a key.
4. **No timestamp columns at all.** No `created_at`/`updated_at`/`deleted_at` anywhere
   (`lib/data/local/app_db.dart`, schema v13 `:182`). Deletions are hard deletes
   (`deleteEvent`, `deleteBabyProfile` + the B31 cascade statements).
5. **No `uuid` dependency** in `pubspec.yaml`; no UUID generation anywhere in `lib/`.
6. **The importer is a strict write-boundary** (house style documented at its top): pure parser on
   an isolate, closed validation, one transaction, format wall `_supportedFormatVersion = 4`
   (`:32`) + `databaseSchemaVersion` guard. Formats 1–4 must keep restoring.
7. **`reminder_settings` / `reminder_dismissals` already have identity in their primary key**
   `(baby_id, item_id)` — no autoincrement, so they need only `updated_at`, not a uuid.
8. **`reminder_completions` is an append-only journal** (`app_db.dart:136`, read by
   `MAX(completed_at)`) — and the document carries **no row id for it**
   (`_parseCompletion`, `import_repository_impl.dart:458`). Re-inserted on every restore today; in
   a merge world, re-imported on *every merge* with no way to skip → unbounded journal growth. It
   needs a uuid for idempotency, or merges are not re-runnable.
9. **The active-profile invariant lives in two places** and a merge must keep it: the B31
   read-boundary self-heal (`AppDatabase.healActiveProfileIfLost`) and the import repair
   (`_promoteActiveProfile`, `:724`). A merge can hand a device profiles without an active one
   (file exported mid-choice, or the local active profile mapped away) — the same repair must run
   after a merge, by the same code, not a copy.
10. **`app_settings` is device-level** (notification opt-in + time of day, schema v13) —
    installation preferences, not baby data.
11. **B30/B33 already claim the next numbers**: per-reminder hour + Vitamin K one-shot/preset
    overrides plan schema **v14** + export format **v5** (1.4.0 content release). Phase A must take
    the next free step after them.
12. **The import UI is one dialog + one AsyncNotifier**
    (`lib/features/import/presentation/widgets/import_data_dialog.dart`,
    `lib/features/import/presentation/providers/import_providers.dart`) — small enough to grow a
    mode choice, a mapping step and a result screen around it.

---

## 1. Scope

**In:** a *merge* mode beside the existing *replace* mode in the same import flow (Menu → import →
file); stable per-row UUID identity; latest-write-wins conflict rule; delete propagation by
tombstone; baby-profile mapping (the two-phone identity problem); export/import format step;
migration with backfill; l10n fr/en/es; the full test + gate matrix below.

**Out (Phase A, by decision):**

- network of any kind, new OS permission, server, dependency (charter — this is *why* Phase A
  needed no mandate change);
- semantic dedup — a feeding recorded on *both* phones is two rows with two UUIDs and stays two
  rows; the app is not a duplicate detector;
- profile-deletion propagation (§2 D6);
- merging `app_settings` (§2 D5);
- automatic/periodic merging — it stays a deliberate act behind the share sheet;
- changes to replace mode — the existing restore path is untouched and keeps its tests green.

The working model for parents: **each event is recorded once, on the phone that was in the hand;
the other phone picks it up at the next manual merge, in either direction.** The plan optimises
for that loop being *safe to repeat* (idempotent), *safe to interleave* (lww) and *safe to
abandon* (transactional).

---

## 2. Decisions

### D1 — Row identity: random v4 UUID, generated on-device at row creation

Every row that can exist on two phones gets a `uuid` column (v4, random). Generated where the row
is born (insert path) — never derived from content.

- **Not derived** (e.g. hash of name+birthDate for profiles): a rename or a corrected birthdate
  would silently break identity, and a deterministic id is a fingerprint of personal data. Random
  ids leak nothing and cannot collide meaningfully (122 bits of `Random.secure()` entropy).
- Backfill at migration for existing rows (§3) and at import for legacy files (§4, D9).
- The local autoincrement `id` stays the **local** primary key (Drift/SQLite machinery, B31's
  cascade statements all reference it); the uuid is the **cross-device** identity. The uuid gets a
  UNIQUE index per table. Nothing external ever sees the local id again — the export keeps writing
  it for backward compatibility of format ≤4 consumers, but the merge never reads it as identity.

### D2 — Profile identity: manual mapping at import time, stored in an alias table

Two phones' rows for "the same baby" are united by **mapping the file's profile id to the
local profile id**, done by the parent at import time:

- new table `profile_aliases(source_id TEXT PRIMARY KEY, local_id TEXT NOT NULL, mapped_at INTEGER NOT NULL)`;
- for each profile in the file: alias hit → auto (shown, not asked); else suggestion = local
  profile with exact (name, birthDate) match (one tap); else the parent picks an existing local
  profile or "import as new baby";
- mapped file profiles are **not inserted** — their rows are re-parented to the local profile id;
- an unmapped file profile is inserted with its file id (a timestamp string; if it ever equals a
  local id, it *is* that baby and the mapping step has already treated it as such).

**Rejected: deterministic profile ids.** Re-keying the pk would migrate every referencing table
(baby scoping is the B11 saga), breaks on rename, and is exactly the class of irreversible move
the v12 lesson quarantines to its own verified release.

**Rejected: auto-merge on (name, birthDate) without confirmation.** Same name+date for two
different babies (twins named alike, corrected data) is rare but the cost is merging two
children's histories together — the one merge error that is not recoverable by re-doing. The
suggestion makes the correct answer a single tap; the confirmation makes the wrong answer
impossible by accident.

Aliases are **importer-local knowledge and are not exported** (a file's "my id X means baby Y" is
true only for the device that did the mapping; a third phone re-confirms in one tap). Revisiting
this is a Phase A+ option, not a blocker.

### D3 — Conflict rule: latest write wins on `updated_at`; tie → local wins, counted

Every mergeable row carries `updated_at` (epoch ms). For a file row whose uuid exists locally:
the newer `updated_at` wins, whole row (no field-level merge — a field-level merge would need a
per-field history the app has never kept). **Tie (equal ms) → the local row wins**, the file row
is counted as a conflict in the result screen. Rationale: the device in the hand is the one the
parent is looking at; losing their just-edited row to a file would be the worse surprise. The rule
is deterministic and unit-tested both ways.

### D4 — Deletion: tombstones on UUID rows; reads filter at the repository boundary

A user-facing delete of a UUID row (event, measurement, custom reminder, completion) writes
`deleted_at` instead of removing the row. Consequences, stated once:

- the merge applies file tombstones to local rows by uuid (and the symmetric "file row alive and
  newer than the local tombstone" **restores** the row — that is lww; an un-delete-by-merge is
  documented behaviour, and the only way a deletion loses);
- **every read path that serves UI or reminder logic filters `deleted_at IS NULL`** — the audit
  list in §6.2 is the work item; the dangerous ones are the scheduling/D2 reads
  (`getLastEventTimestamp` and friends) because a deleted event that still settles a reminder is a
  B31-class silent invariant break;
- **the database reset (full deletion) stays a hard wipe** and is the only hard-delete path left.
  Documented consequence: a reset device holds no tombstones, so the next merge re-imports the
  partner's rows for "deleted" babies/events. A reset is a device act, not a merge signal —
  propagating "delete everything" is out of Phase A scope (it would need a per-dataset
  tombstone the reset would have to survive its own wipe, which is contradictory).

### D5 — `app_settings` is not merged

Notification opt-in and time-of-day are installation habits (the opt-in is tied to the OS
permission of *this* phone). Merge mode skips the section; replace mode keeps today's replace
behaviour unchanged. The importer's closed key set (`_knownSettingKeys`) is untouched.

### D6 — Profile deletion is not propagated (Phase A)

Deleting a baby on one phone does not delete it on the other. The local B31 cascade runs as
today; the partner's rows for that baby reappear at the next merge (the baby "resurrects", mapped
by the existing alias). Acceptable: the failure mode is *visible and non-destructive* (the parent
sees the baby and re-deletes locally), whereas propagating a destructive cascade through a
hand-carried file is the kind of blast radius the B31 saga exists to avoid. Propagation with an
explicit confirmation UI is a named follow-up, not a Phase A scope.

### D7 — UUID generation in-house; no new dependency

`Random.secure()` (dart:math, platform CSPRNG) → 122 random bits → v4 string format, one private
function in `lib/core/services/` (suggested: `uuid.dart` beside `encryption_service.dart`), with a
test for format (RFC 4122 v4 shape), version/variant bits and collision at test volume. Adding the
pub `uuid` package would be defensible (pure Dart, no network) but the charter's dep-audit rule
means any addition is a review surface for a job of twelve lines; in-house costs zero.

### D8 — Release placement: its own feature release after the 1.4.0 content release

B30/B33 take schema **v14** + export **v5**. Phase A takes the **next free step: schema v15 +
export format 6** (the numbers are "next free", not sacred — if 1.4.0 slips, Phase A inherits
v14/5 and the content items shift). One big schema step per release, verified in the field
between — the v12 → v1.2.0 → v1.2.1 lesson, quoted in `app_db.dart`'s v12 migration. Recommended
target: **1.5.0**, after 1.4.0 is published and the v14 migration has field time.

### D9 — Legacy files (format ≤4, no uuids) import with fresh ids, and say so

A pre-Phase-A backup has no uuids. Import (either mode) generates a uuid per row at insert time.
Consequence: a household whose two phones both hold *legacy* data must exchange **once in each
direction** after upgrading (each direction backfills the ids the other side lacks) — the merge
result screen and the patch notes carry that one sentence. After both phones run the new build
once, all rows have stable ids and merges are idempotent for good.

---

## 3. Schema step (v13 → v15; v14 = B30/B33, assumed to precede)

Additive except where noted; no table rebuild, no rekey of any existing pk.

| Table | New columns |
|---|---|
| `tracking_events` | `uuid TEXT NOT NULL` + UNIQUE index, `updated_at INTEGER NOT NULL` (epoch ms), `deleted_at INTEGER` (NULL = alive) |
| `measurements` | same three |
| `custom_reminders` | same three |
| `reminder_completions` | `uuid TEXT NOT NULL` + UNIQUE index (append-only: no `updated_at`/`deleted_at` — there is no edit or delete UI for a completion today; if one appears, it takes D4) |
| `reminder_settings` | `updated_at INTEGER NOT NULL` (identity already in pk) |
| `reminder_dismissals` | `updated_at INTEGER NOT NULL` (identity already in pk) |
| `baby_profiles` | `updated_at INTEGER NOT NULL` (rename/birthdate edits) |

New table: `profile_aliases` (D2).

Migration `from < 15` (after the v14 step, in the same `onUpgrade`):

1. `ALTER TABLE … ADD COLUMN` for each (the v12 precedent — legal on populated tables).
2. **Backfill**, per UUID table: a Dart loop over existing rowids generating one uuid each and
   stamping `updated_at` = migration instant, same for `baby_profiles`/settings/dismissals.
   (Row counts are phone-lifetime small — thousands at most; a loop is fine and keeps uuid
   generation in the tested D7 function.)
3. `CREATE TABLE profile_aliases`; UNIQUE indexes on the uuid columns.

**Irreversible** (backfilled uuids cannot be un-generated) — same class as v12, same gate: the
emulator pass on a device that has v13 data (§9). Downgrade policy: none (existing app position).

---

## 4. Export format (→ 6) and importer acceptance

`ExportRepositoryImpl._exportFormatVersion` → **6** (bump rule: same change as
`ImportRepositoryImpl._supportedFormatVersion`; importer still refuses >6).

Per-row additions (absent ⇒ legacy, D9):

- `trackingEvents`, `measurements`, `customReminders`: `uuid`, `updatedAtEpochMillis`,
  `deletedAtEpochMillis` (nullable);
- `reminderCompletions`: `uuid` (the section finally carries a row identity);
- `reminderSettings`, `reminderDismissals`, `babyProfiles`: `updatedAtEpochMillis`;
- `profileAliases`: **not a section** (D2 — importer-local, not exported).

Tombstoned rows **are exported** (with `deletedAtEpochMillis` set) — they are the delete
propagation, and `counts` keeps counting them (the counts validator sees rows, not liveness).

Importer: accepts 1…6. For rows lacking uuids (any format ≤5): generate at insert (D9). The
strict-validation stance is unchanged — a malformed `uuid` (wrong shape) rejects the file; a
*missing* one is the legacy path. The `databaseSchemaVersion` guard is untouched.

**Version-allocation note (B30/B33):** if the 1.4.0 content release lands as planned, Phase A's
export v6 adds its fields on top of v5's (per-reminder hour, preset override columns) — the
sections are disjoint, the importer's per-row field set is the union. If it does not, the numbers
shift; the rule (next free) does not.

---

## 5. Merge core: pure plan + one transaction

**Pure function** (domain layer, zero Flutter — unit-testable without a DB):

```
MergePlan computeMerge({
  required LocalRows local,      // all mergeable tables, read once
  required FileRows file,        // parsed document
  required Map<String,String> profileAliases,  // file profile id → local id (confirmed)
})
```

→ `({upserts, tombstoneApplications, profileInserts, conflictsLocalWins, conflictsFileWins,
skippedDuplicates, countsByTable})`.

Rules, in one place:

1. **Profiles** (pre-step, from the confirmed mapping): file id with alias → rows re-parented to
   the local id; file id absent from local profiles and not mapped-as-existing → `profileInserts`
   (file id kept); never insert a mapped profile.
2. **UUID rows**: file row alive, local absent → insert (re-parent baby id, re-encrypt
   notes/`value` with the local key — the existing restore pipeline, not a new one); local present
   → lww (D3), whole row; file row tombstoned, local alive → apply tombstone (respecting lww: a
   *newer local alive* row survives a *older file tombstone* — the delete loses); file row
   tombstoned, local tombstoned → skip.
3. **Composite-pk rows** (settings/dismissals): upsert by `(baby, item)`, lww on the row's
   `updated_at`.
4. **Completions**: insert iff uuid absent (idempotent union).
5. After application: **run the existing active-profile repair** (the B31 `healActiveProfileIfLost`
   logic, called — not copied — from the merge transaction) so a merge can never leave a device
   without an active baby.

The transaction applies the plan in dependency-free order (as `restore()` does today), all-or-nothing.
A second run of the same plan produces zero writes — **idempotency is a test, not a hope** (§8).

Result screen numbers come from the plan's counters (same rule as the repositories' logging:
counts only, never content).

---

## 6. Write-path and read-path audit (the long pole)

### 6.1 Stamp + tombstone at every write site

| Site (call sites to enumerate in the work item, grep-driven) | Change |
|---|---|
| Event insert (home quick-add + any future entry point) | + uuid + updated_at |
| `updateNotesForEvent` / event update | + updated_at |
| `deleteEvent` | hard delete → tombstone |
| Measurement insert/delete | same pair |
| Custom reminder insert/update/delete | same triple (delete = tombstone; the B31 orphan cleanup of its `custom_<id>` settings/dismissals/completions rows **stays a local hard delete** — with the item gone those rows are inert, and propagating a three-table cascade through a file is D6-class blast radius) |
| Completion insert | + uuid |
| Dismissal insert / clear | + updated_at |
| Settings upsert | + updated_at |
| Profile rename / birthdate edit | + updated_at |
| **Database reset** | **unchanged hard wipe — the only hard-delete path left (D4)** |

The work item is a grep checklist (`delete(`, `update(`, `.insert(` across the data layer) with a
"touched" column per site — the B31 lesson: the audit list is committed to the PR, not to memory.

### 6.2 Filter `deleted_at IS NULL` at every read site that serves UI or logic

Enumerated in the same checklist; the dangerous ones named: `getLastEventTimestamp`
(scheduling + home grid), the D2 completion-derivation reads (a deleted event must not settle a
reminder), `getEventsByBabyId`/`getEventsByType` (history UI), measurements reads (growth chart
when B8 lands — B8 builds on *this* filter, a side benefit), custom-reminder lists. Reads inside
the merge itself see all rows (it must read tombstones to apply lww) — that is the one read path
deliberately unfiltered, and it lives inside the merge transaction only.

---

## 7. UI (fr/en/es, product strings)

Around the existing dialog/notifier, three additions:

1. **Mode choice** — after a successful parse, *only when the local database is non-empty*:
   "Merge with this phone's data" (default) / "Replace everything" (today's behaviour, same
   confirm screen). Local DB empty → no choice, it is a plain restore.
2. **Profile mapping step** — one screen, only when the file contains profiles not already
   aliased: each file profile row with its suggested local match pre-selected (exact
   name+birthDate), "other local baby…" / "import as new baby" as the alternatives. Known aliases
   are shown, not re-asked.
3. **Result screen** — counters (added / updated / deletions applied / conflicts kept-local /
   conflicts taken-from-file / profiles mapped / profiles imported), and, when the file carried
   legacy rows (D9), the one line: *the other phone should receive one export of this one, once.*

Replace mode, its confirm copy and its behaviour: untouched.

---

## 8. Test matrix

| Layer | Tests (new; existing stay green) |
|---|---|
| domain (pure) | merge plan: union both directions; lww newer-file, newer-local, **tie → local**; tombstone applied; tombstone loses to newer alive row (the un-delete); idempotent re-run = 0 writes; profile: alias hit / suggested / new / file-id-equals-local-id; completions dedup by uuid; composite-pk upsert |
| data (in-memory drift) | two-DB round trip (seed A, export, merge into B, verify invariants: no duplicate uuids, tombstones respected, active-profile guarantee after merge, counters match plan); replace-mode regression (existing restore tests untouched); D7 uuid function (v4 shape, version/variant bits, collision at 10k) |
| migration | v13-seeded DB → v15: every row has uuid + updated_at, app boots, data visible; v14→v15 alone (the expected field path) |
| importer | format 4 file → import → uuids generated (D9); format 6 file merges; format 7 refused; counts-with-tombstones validator; strict uuid-shape rejection; schema guard unchanged |
| coverage | ≥80 % domain/data as usual (`make ci`) |

---

## 9. Release gate (AGENTS.md, non-negotiable)

1. **Migration on old data**: emulator with a v13 database that has real rows (seed via the app,
   not fixtures) → install the new build → migration + backfill ran, data visible and correct.
2. **The merge loop, recorded**: emulator A with data → export → file onto host → emulator B
   (fresh) imports (restore) → B adds one event → export B → A merges → **screenshots of the
   mapping step and the result screen** (Small_Phone + normal) → A exports again → B merges →
   **A re-imports the very same file a third time: result screen must show zero changes**
   (idempotency on real screens, the test that matters). Record device, build, what was seen.
3. The manual entry path + export JSON inspection (as always): a merged JSON carries uuids,
   updated_at, and a tombstoned row after a delete.
4. `make store-check` (the listing does not change — Phase A adds no store surface; the package
   is rebuilt for the version bump).

---

## 10. Do not

- No network, no permission, no server, no new dependency (D7, charter) — this is the phase that
  needed no mandate change; a PR that adds one has left Phase A.
- No content-based dedup: union by uuid only.
- No profile-deletion propagation (D6) and no `app_settings` merging (D5) in this release.
- No changes to replace mode or to its copy — the existing restore keeps its tests green as-is.
- No deterministic profile ids; no re-keying of `baby_profiles.id`.
- No hard delete left standing after the §6.1 audit (except the reset).
- Not in the same release as B30/B33 (D8): one schema step per release, verified between.
- Do not copy the active-profile repair into the merge: call the existing logic (B31 single source).

## 11. Work breakdown (sizing)

1. D7 uuid function + tests — S
2. Schema v15 migration + backfill + migration tests — M
3. Write-path audit: stamping + tombstoning (§6.1) — M
4. Read-path audit: `deleted_at IS NULL` filters (§6.2, incl. scheduling/D2) — **L (long pole)**
5. Export v6 + importer extension (accept 1…6, D9 backfill) — M
6. Pure merge core + plan tests — M
7. Merge transaction + `profile_aliases` + repair call — M
8. UI: mode choice + mapping + result + l10n fr/en/es — M
9. Gate pass (§9) — M wall-clock, the emulator loop is the bulk

Release: its own feature release, **1.5.0** (owner-confirmed 2026-11-14) after 1.4.0
(B30/B33/B6) has field time.

## 12. Owner decisions (resolved 2026-11-14)

1. **D6 confirmed** — profile deletion stays local in Phase A. The resurrection-at-next-merge
   cost is documented and accepted; propagation with a confirmation UI remains the named follow-up.
2. **Mode default confirmed** — when local data exists, **Merge is the pre-selected mode**
   (Replace stays one tap away, behaviour unchanged).
3. **Release target confirmed** — **1.5.0**, after the 1.4.0 content release (B6/B30/B33 cluster,
   schema v14 + export v5). Phase A takes schema v15 + export v6.

(D1–D9 above are implementation decisions made with rationale in this plan; the owner may veto any
of them before work starts — after that, changes cost a migration.)

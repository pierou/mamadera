# Plan: Database Import (restore from export)

Status: **implemented** (uncommitted) — see §10 for the deviations from this plan.

> **Review record.** Every claim about this repo was re-checked against the sources: the export
> document shape, the storage precisions, `schemaVersion` 10, the `_performReset` provider list,
> `getActiveBabyProfile`'s ordering, the `withLength(min: 1, max: 60)` constraint, `db_const.allTypeValues`
> and the fr l10n template all check out. Four items did not and are corrected in place: the
> `file_picker` major and call API (§2, §6.1 — `FilePicker.platform.pickFiles` / `readBytes()` no
> longer exist), "raw SQL is required to insert explicit ids" (§2/§4 — Drift companions already
> accept an explicit `Value(id)`), the `sqlite_sequence` test (§7 — `DELETE FROM` does not reset
> the counter), and the post-restore invalidation list (§2 — invalidating `databaseProvider`
> without closing anything leaks a connection and an isolate per restore). Two contract gaps were
> added: the `databaseSchemaVersion` guard (§3) and the zero-profile / invisible-orphan case
> (§3, §5).

## 1. Context

The export (`lib/features/export/`) serialises **all 5 tables** (`baby_profiles`, `tracking_events`, `reminder_settings`, `reminder_dismissals`, `custom_reminders`) into a versioned JSON document (`exportFormatVersion: 1`, `generator: "mamadera"`), with notes **decrypted** to plaintext, timestamps dual-encoded (epoch int + ISO string), `counts` cross-checked with the payloads, and unfiltered rows (orphans included). The export document shape (as written today by `ExportRepositoryImpl.buildExportJson`):

```json
{
  "exportFormatVersion": 1,
  "generator": "mamadera",
  "appVersion": "1.1.0",
  "databaseSchemaVersion": 10,
  "exportedAt": "<ISO8601 UTC>",
  "counts": { "babyProfiles": 0, "trackingEvents": 0, "customReminders": 0, "reminderSettings": 0, "reminderDismissals": 0 },
  "babyProfiles":      [ { "id", "name", "birthDateEpochMs", "birthDateUtc", "isActive" } ],
  "trackingEvents":    [ { "id", "type", "timestampEpochSeconds", "timestampUtc", "durationMinutes", "subtype", "notes", "wasteType", "color", "texture", "babyId", "quantity", "notesUndecryptable"? } ],
  "customReminders":   [ { "id", "label", "subtypeValue", "frequency", "intervalDays" } ],
  "reminderSettings":  [ { "itemId", "enabled" } ],
  "reminderDismissals":[ { "itemId", "dismissedAtEpochSeconds", "dismissedAtUtc" } ]
}
```

Import must be its exact inverse.

## 2. Key decisions (with rationale)

| Decision | Choice | Rationale |
|---|---|---|
| **Import semantics** | **Full restore (replace)** — clear all 5 tables, insert the file's contents in one transaction | The export is a *complete* backup, so the inverse is a full restore. A merge would duplicate events (history is chronological; duplicates are confusing) and can't preserve event IDs cleanly. Merge = explicitly out of scope (YAGNI). |
| **File selection** | New dependency `file_picker` (**13.x** — 13.1.0 at review time), picker restricted to `.json`, read via `FilePicker.pickFile() → PlatformFile.readAsBytes()` | No file-picking mechanism exists in the app today. `file_picker` is local-only (OS picker = the consent step, matching the "minimal permissions" mandate). **API facts, verified against the 13.1.0 package sources, not from memory of the old API:** the class is `abstract final class FilePicker` with **static** methods (`FilePicker.platform` was removed by the 12.0.0 federated rewrite); `pickFile({type, allowedExtensions, …})` returns `PlatformFile?` (`null` = cancelled) and replaces the removed `pickFiles(allowMultiple:)`; data is read with `readAsBytes()` / `readAsByteStream()` — **`readBytes()` does not exist**; `withData` / `withReadStream` were removed in 13.0.0; size comes from `lengthSync()` or `length()` (`Future<int?>`). `PlatformFile.path` is `uri.scheme == 'file' ? uri.toFilePath() : null`, so on Android `content://` picks have `path == null` — `readAsBytes()` is the only portable read path. License MIT, publisher `victorcarreras.dev` (repo transferred to `vicajilau/flutter_file_picker`), requires Dart ≥ 3.10 / Flutter ≥ 3.38 (this project already requires Flutter ≥ 3.44). |
| **Picker alternative considered** | `file_selector` (official `flutter/packages`, Flutter Favorite) was **not** chosen | `file_selector`'s Android implementation **copies** the picked `content://` document into `context.getCacheDir()/<uuid>/<fileName>` before handing back a path (`file_selector_android/android/src/main/java/…/FileUtils.java:112-153`, verified in the published package); `file_picker.pickFile() + readAsBytes()` reads the URI directly, which is what the "no plaintext copy on disk" mandate in §9 asks for. Recorded here so the choice is not re-litigated. |
| **Strictness** | Strict, fail-atomic: any structural error rejects the **whole file** with a specific reason | A backup that restores half is worse than none. Mirrors the export's "honest counts" philosophy. |
| **Notes** | Plaintext in file → **re-encrypted** with fresh IV on insert | Export decrypted them; the DB invariant is "ciphertext at rest" (encrypted at the repository layer, per AGENTS.md). |
| **IDs** | Preserved as stored in the file (baby `id` TEXT, event `id` INT, custom reminder `id` INT) | A restore on a new phone should keep the same identifiers. **No raw SQL needed**: the generated companions already expose the autoincrement column as `Value<int> id` defaulting to `Value.absent()` (`app_db.g.dart:656` for `TrackingEventsCompanion`, `:1436` for `CustomRemindersCompanion`), so `Value(id)` inserts an explicit rowid through the typed path. SQLite raises `sqlite_sequence` to any explicitly inserted rowid above it, so no manual sequence fix (see §7 for the exact — and narrower — guarantee). |
| **Destructive UX** | Two-step confirmation: warning dialog → pick file → **summary dialog** ("X profiles, Y events — will erase everything on this device") → restore | The operation wipes current data; informed consent needs the file's actual contents, not just a generic warning. |
| **Placement** | Menu → Danger zone, between *Export* and *Reset*, danger-styled like the reset tile | It's destructive, like reset. |
| **Post-restore** | Invalidate the **state holders only**: `babyProfileProvider`, `babyProfileListProvider`, `activeBabyProvider`, `anyBabyExistsProvider`, `historyNotifierProvider`, `reminderNotifierProvider`, `menuRepositoryProvider`. Explicitly **not** `databaseProvider`, and not the repository providers. | Keep-alive notifiers (history, active baby, reminders…) would otherwise serve pre-import data. But `_performReset` invalidates `databaseProvider` for a reason import does not have: `MenuRepositoryImpl.resetDatabase()` *closes the connection and deletes the file*. Import does neither — same file, same open connection. `databaseProvider` has **no `ref.onDispose`**, and `createAppDatabase()` returns `LazyDatabase(() => NativeDatabase.createInBackground(file))`, so invalidating it builds a second `AppDatabase` **and a second background isolate** while the first is never closed: one leaked connection + isolate per restore, with `importRepositoryProvider` still holding the stale instance. The repository providers are then redundant — they `ref.watch(databaseProvider.future)` and rebuild on their own if it ever does change. |
| **No temp file** | Read bytes directly into memory; never copy the user's file into app storage | Export already deletes its plaintext temp file; import can do better — no second plaintext copy on disk at all. Plaintext notes live in memory during the transaction; the DB immediately holds ciphertext. |
| **No schema change** | None — no migration, no new table | Import reuses the exact current schema (v10). |

## 3. Data contract (what the importer accepts)

**Document level** (reject with specific reason if violated):
- Size ≤ 5 MB, checked **before reading**: `PlatformFile.lengthSync()` (the native picker usually reports it) then `length()`, both nullable → read and check only when the size is unknown, and reject a known-oversized file without loading it. A full backup is well under 1 MB; the cap guards against picking the wrong file.
- Valid UTF-8 JSON object
- `generator == "mamadera"`, `exportFormatVersion == 1`. Version **> 1** → distinct "file created by a newer app version" message. (We own the format; never guess at unknown versions.)
- **`databaseSchemaVersion ≤ AppDatabase.schemaVersion`** — the export writes this field deliberately and the check is the only thing that catches a *newer schema* whose JSON still says `exportFormatVersion: 1`. Without it, a v11 backup carrying a column that does not exist yet would be accepted, restored, and the rows for that column **silently dropped from the device** — data loss caused by a restore. Greater → reject with its **own** reason (`importDataErrorNewerSchema` — distinct from "newer format version", because the fix for the user differs: update the app vs. re-export). This only covers the *silent* case; the invariant it depends on must be written down next to the export: **any field added to the export document must bump `exportFormatVersion`, not just `schemaVersion`** (add it to the AGENTS.md export row and to the §6.8 docs step).
- All five table keys present and arrays
- `counts` section matches the five array lengths (export guarantees they come from the same read; a mismatch = untrustworthy file)
- Not empty in the export's sense: `babyProfiles == 0 && trackingEvents == 0` → "file contains no restorable data" (importing an empty file would just wipe the current DB)

**Row level** (any violation → whole-file rejection):
- *babyProfiles*: non-empty `id` (unique within file), non-empty `name`, `birthDateEpochMs` int (fallback: parse `birthDateUtc` ISO), `isActive` bool default true
- *trackingEvents*: `type` ∈ `db_const.allTypeValues` (the existing single source of truth — do not re-literal the four strings) (strict — structural); `id` int unique; `timestampEpochSeconds` int (fallback ISO), sanity range 1990–2100; `durationMinutes`/`quantity` null or finite number; `subtype`/`wasteType`/`color`/`texture`/`babyId` null or string (pass-through — the domain mapper `mapToEntity` already falls back on unknown enum values, so we don't over-validate and risk breaking on future enum additions); `notes` null or string (`notesUndecryptable: true` tolerated — it means notes is null); orphans (`babyId` not in the file's profiles) **kept** — symmetric with export: no FK to violate, nothing is lost. ⚠️ **But they are not *visible*.** `HistoryNotifier` filters on `activeBabyProvider.value?.id`, and `HistoryRepositoryImpl.getAllEventsOrdered(babyId:)` routes to `getEventsByBabyId` → `baby_id = ?`, which also hides `babyId IS NULL` rows. A restore that contains orphans therefore reports more events than the history screen shows. Nothing to fix in the importer — but the UI must not promise "you'll see everything" (see §5)
- *customReminders*: `label` 1–60 chars (table constraint `withLength(min: 1, max: 60)`), `subtypeValue` ∈ `HealthSubtype.values` (validated with `HealthSubtype.byValue` — an unknown care produces a reminder that can *never* be completed and gives the parent no clue why; strict here matches the strict `type` check above), `frequency` ∈ the four exported codes, `intervalDays` ≥ 1 when present; `id` int unique. **The four frequency codes must not be hardcoded a third time**: they are private consts (`_freqDaily` …) in `reminders/data/repositories/reminders_repository_impl.dart:155-158`; expose them (or move them next to `ReminderFrequency`) and import them. Note the divergence to justify in the PR: that same file's `_decodeFrequency` is deliberately *tolerant* (unknown code → `daily`, bad `intervalDays` → 7, "un rappel qu'on ne voit plus ne peut plus être corrigé"). Reading tolerantly while writing strictly is defensible — a backup is a trust boundary the DB read is not — but it is a decision, not an accident, so say so in the validator dartdoc.
- *reminderSettings*: non-empty `itemId` (unique), `enabled` bool
- *reminderDismissals*: non-empty `itemId` (unique), `dismissedAtEpochSeconds` int (fallback ISO)

**Post-restore invariants** (applied inside the same transaction):
- If profiles were restored but none has `isActive: true` → activate the first by `(birthDate, id)` ascending (the same deterministic ordering `AppDatabase.getActiveBabyProfile` uses), so the app never lands without an active baby
- **`profiles == 0 && events > 0` is legal input** (the export's own `ExportCounts.isEmpty` only rejects `babyProfiles == 0 && trackingEvents == 0`), and it restores into an app with no active baby — `anyBabyExistsProvider` false → onboarding/add-baby, while "restored 500 events" is technically true and completely invisible. Do not silently accept and do not invent a profile: the summary dialog must state it explicitly ("this backup contains events but no baby profile — you will be asked to create one") so the user can cancel instead of thinking the restore failed. See §5 step 5.

**Storage format reminders** — using companions (§4) means Drift owns all four conversions, which is the whole reason not to hand-write the INSERTs:
- `tracking_events.timestamp` — Drift `dateTime()` → epoch **seconds** (asserted by `export_repository_impl_test.dart:220`); a hand-written `INSERT` must reproduce that ÷1000 exactly, or every timestamp lands in 1970 with no error raised
- `reminder_dismissals.dismissed_at` — epoch **seconds**
- `baby_profiles.birth_date` — app-level convention: epoch **milliseconds**, in a plain `integer()` column (not a `dateTime()`), so Drift does **not** convert it: pass the file's `birthDateEpochMs` int straight to `BabyProfilesCompanion.insert(birthDate: …)`
- booleans — Drift writes 0/1 for `boolean()`
- column naming — `waste_type`, `baby_id`, `subtype`, `duration`… are Drift-derived snake_case; a hand-written statement re-derives them by hand and silently drops any column a v11 adds. That is the concrete cost the raw-SQL approach would have paid.
- input timestamps arrive as `timestampEpochSeconds` (int) → `DateTime.fromMillisecondsSinceEpoch(sec * 1000)`; ISO fallback → `DateTime.parse(iso).millisecondsSinceEpoch` (never hand-rolled field math, which is where a timezone bug would live)

## 4. Architecture & files

New feature module mirroring `export/` (Clean Architecture, feature-first, per AGENTS.md):

```
lib/features/import/
├── domain/repositories/import_repository.dart
│     abstract class ImportRepository
│       Future<ParsedExport> parseExport(String json)   // pure, no DB → throws typed errors
│       Future<ImportCounts> restore(ParsedExport)     // transactional, DB + encryption
│     ParsedExport — domain DTO with the 5 typed row lists (pure Dart, no Drift/Flutter deps)
│     ImportCounts — row counts (for the summary + success messages)
│     sealed import errors: InvalidExportFile(reason), UnsupportedExportVersion(int),
│                           UnsupportedSchemaVersion(int)   // §3 newer-schema guard
│     ImportFailureReason — closed enum, one value per ARB key (§4 "No raw error text")
├── data/repositories/import_repository_impl.dart
│     parseExport(): parse + validate (the §3 contract) → ParsedExport
│     restore(): one db.transaction {
│       DELETE all rows × 5 tables (delete(table).go(), or customStatement for the two
│         UNIQUE-item_id tables, matching the existing upsert style in reminders_impl)
│       INSERT all 5 tables via drift companions — including the autoincrement ones:
│         babyProfiles, reminderSettings, reminderDismissals,
│         trackingEvents (TrackingEventsCompanion(id: Value(row.id), …)),
│         customReminders (CustomRemindersCompanion(id: Value(row.id), …))
│       no hand-written INSERT: see §3 storage-format reminders
│       notes: encryption.encrypt() each non-null before insert
│       active-profile promotion invariant
│     }
└── presentation/
    ├── providers/import_providers.dart
    │     importRepositoryProvider (FutureProvider, like exportRepositoryProvider —
    │       injects databaseProvider + encryptionServiceProvider, exposes the domain interface)
    │     ParsedExport is HELD in the controller between summary and apply (not re-parsed), so
    │       it survives the round trip; importRepositoryProvider must therefore NOT be in the
    │       post-restore invalidation list (§2) or the pending restore would be discarded
    │       underneath itself. Non-autoDispose AsyncNotifierProvider, exactly like
    │       exportControllerProvider.
    │     parse/validate runs in compute() — up to 5 MB of utf8 + jsonDecode on the UI isolate
    │       is a visible jank; only restore() stays on the caller isolate (AES-GCM on a few
    │       thousand short notes is milliseconds, the SQL is already off-isolate)
    │     ImportController extends AsyncNotifier<ImportOutcome>
    │       sealed ImportOutcome:
    │         ImportIdle
    │         ImportInvalidFile(reason)
    │         ImportUnsupportedVersion(version)
    │         ImportSummaryReady(counts)        // parsed OK, awaiting 2nd confirm
    │         ImportSuccess(ImportCounts)
    │         ImportFailure(reason: ImportFailureReason)   // CLOSED ENUM, never a String
    │       restoreFromJson(String) — parse/validate → state = summary → (2nd confirm) → apply → done
    │       applyRestore() — the destructive step after summary confirm
    └── widgets/import_data_dialog.dart
          3 phases (same shape as ExportDataDialog: initial → loading → outcome, built with
          DialogActionButtons / DialogConfirmButton from core/widgets/dialog_buttons.dart):
          warning → (file picked) summary w/ counts → result
          file_picker call lives HERE (widget), so the controller needs no plugin at all:
            final file = await FilePicker.pickFile(          // STATIC — no .platform in 12+/13+
              type: FileType.custom, allowedExtensions: ['json']);
            if (file == null) return;                       // null == cancelled
            final bytes = await file.readAsBytes();          // NOT readBytes(); path is null for
                                                            // content:// on Android
          → utf8.decode → controller.restoreFromJson(json)
          Note: FileType.custom is a *hint*, not a filter. android_file_picker maps extensions to
          MIME and, when none maps, logs and falls back to */* — the user can always reach a wrong
          file, so the §3 validator is the only real guard.
```

Modified files:

```
lib/features/menu/presentation/screens/menu_screen.dart   # + import tile in danger zone (danger styling)
lib/features/reminders/data/repositories/reminders_repository_impl.dart  # un-privatise the frequency codes (§3)
lib/l10n/app_fr.arb / app_en.arb / app_es.arb             # ~12 new keys (fr is the template)
pubspec.yaml                                              # + file_picker (alphabetical — sort_pub_dependencies is on; comment it like the riverpod entry)
```

**l10n keys** (fr, en, es): `importDataTitle`, `importDataDescription`, `importDataConfirm`, `importDataWarning` (will erase current data), `importDataSummary` (params {profiles}/{events}/{reminders}), `importDataNoProfile` (events but no baby profile — see §3), `importDataProceed`, `importDataSuccess`, `importDataErrorInvalidFile`, `importDataErrorUnsupportedVersion`, `importDataErrorNewerSchema`, `importDataErrorEmpty`, `importDataErrorFailed` (generic, **no `{error}` placeholder**).

**No raw error text in the UI.** `resetDatabaseError` interpolates `{error}`; do not copy that here. A filesystem path, a content URI or a MIME string must never reach an `AlertDialog` (it is visible on screen, in screenshots, and in anything the user shares). `ImportFailureReason` is a closed enum mapped to the ARB keys above; the enum name is what gets logged (counts and reasons only, never file names or note text — same rule as the export repository).

**Controller testability**: the plugin call stays in the widget (same shape as `SharePlus` usage in the export controller — faked at platform level in tests, or simply not reached because the controller receives a JSON string). Controller tests then need no plugin at all.

**Analyzer constraints to expect** (`analysis_options.yaml` sets `strict-casts`, `strict-raw-types`, `strict-inference`, and `make lint` is `--fatal-infos --fatal-warnings`): every read of a `dynamic` JSON value needs an explicit typed helper (`String? _str(Object? v)`, `int? _int(Object? v)`, `Map<String, Object?> _obj(Object? v)` …) — an `as String` on a `dynamic` map access is an implicit downcast and will fail the build. Write the extractor helpers once in the parser, they are also what makes the §3 contract readable.

## 5. UI flow

1. Menu → Danger zone → **"Restore from backup"** tile (error styling, like reset)
2. Dialog: privacy/destructive warning ("This will **erase all data currently on this device** and replace it with the file's contents. Choose the file you exported.") → *Cancel* / *Choose file…*
3. OS file picker (`.json` where the platform honours the filter hint — it is cosmetic, §8.7). Nothing picked → dialog stays, nothing changed.
4. File read + parsed (in `compute()`) + validated. Failure → dialog shows the specific reason from the closed enum (invalid JSON / not a mamadera backup / newer app version / newer schema / no data / malformed row), DB untouched. If the picker returned a file the platform could not read, that too is one enum case, not an exception dump.
5. Success → **summary dialog**: "This backup contains **N** baby profiles, **M** tracking events, **K** reminders. Restoring will erase all current data." → *Cancel* / *Restore*. Two conditional additions: (a) if `profiles == 0 && events > 0`, add the `importDataNoProfile` line ("…but no baby profile: you will be asked to create one, and these events will not be attached to any baby") so the user can cancel; (b) if the file contains orphan or `babyId`-null rows, do **not** claim they will appear in history — they are restored but hidden while a baby is active (§3). Keep the wording count-based ("N events restored"), never visibility-based ("you'll see all N events").
6. Restore runs (spinner), transactional. Success → "Restore finished: N profiles, M events" + the §2 invalidation list (state holders only — **not** `databaseProvider`) so home/history/menu/baby switcher all refresh. Failure → error dialog; because the transaction rolled back, the pre-import DB is intact — say exactly that.

## 6. Implementation steps

1. **`file_picker` dependency** — `flutter pub add file_picker` (resolves to 13.x; it is **not** `^10.x` — three majors newer, and the API changed in each of them, so code against the 13.x signatures verified in §2/§4, not against blog posts: static `FilePicker.pickFile()`, `PlatformFile.readAsBytes()`, no `withData`). `sort_pub_dependencies` is on → insert alphabetically. Then, because this adds **8 packages** (`file_picker_platform_interface`, `android_file_picker`, `file_picker_darwin`, `file_picker_linux`, `windows_file_picker`, `file_picker_web`, `cross_file`, `path`), the privacy audit is a **manifest/API review, not a `make audit-trivy` run** (trivy finds CVEs, not data paths): read each platform package's `AndroidManifest.xml` / `*.podspec` / entitlements and confirm (i) no network permission anywhere, (ii) the only Android manifest addition is the `<queries><intent GET_CONTENT>` block — verified against `android_file_picker 2.0.0`, (iii) we only ever call the read path (`readAsBytes`/`readAsByteStream`); the plugin's `saveFile()` / `clearTemporaryFiles()` write into `cacheDir/file_picker/` and must stay unused, (iv) iOS needs no Info.plist key. Check the F-Droid metadata implications of a new Kotlin plugin while at it (`docs/fdroiddata`).
2. **Domain** — `import_repository.dart` (interface, `ParsedExport` DTO, typed errors, `ImportCounts`).
3. **Data** — `import_repository_impl.dart`: parser/validator first (pure, no DB → unit-testable in isolation, runs in `compute()`), then `restore()` — **all five tables through drift companions**, including the two autoincrement ones via `Value(id)`; no raw `INSERT` (see §2/§3).
4. **Providers + controller** — `import_providers.dart`.
5. **Widget + menu tile** — `import_data_dialog.dart`, wire the tile in `menu_screen.dart` (danger zone, between export and reset).
6. **l10n** — 3 ARB files, regenerate (`make codegen` / `flutter gen-l10n`), no missing-translation analyzer warnings (`make lint` is `--fatal-infos --fatal-warnings`).
7. **Tests** (see §7).
8. **Docs** — README (features table row, Data Lifecycle "Import" bullet, Privacy section: import is the sanctioned *entry* path, user-selected file, no network, the file is never copied to app storage), **and fix the stale wording on the export row: README line 22 still says "all four tables" — it has been five since v10**, plus the export-format invariant next to the export docs and in `AGENTS.md` (*any field added to the export document must bump `exportFormatVersion`* — the §3 `databaseSchemaVersion` guard depends on it). Patch notes for the next version (`en` natural phrasing; fr/es bullet items in **noun form** per AGENTS.md).
9. **`make ci`** green (lint, tests, ≥80% coverage on the new domain/data files).

## 7. Test plan

**Data layer** — `test/features/import/data/repositories/import_repository_impl_test.dart`
(real in-memory Drift DB — `LazyDatabase(NativeDatabase.memory)` — + the `_FakeEncryption` pattern from `export_repository_impl_test.dart`, same style; **reuse `ExportRepositoryImpl` in the same test to generate the fixture**, proving true round-trip):

- Full round-trip: seed rich DB → export JSON → restore into empty DB → all 5 tables row-identical (ids, values, timestamps to the second, notes **decrypt** to the originals — never compare raw `notes` bytes: the real `encrypt()` uses a random IV, so ciphertext legitimately differs every run)
- Replace semantics: restore into a *non-empty* DB → old rows gone, only file rows present
- Notes re-encrypted: imported rows store ciphertext (`isEncrypted` true) that decrypts to the file's plaintext
- **Double round-trip equality**: export → restore → export again → `JsonDecoder`-normalised documents are equal except `exportedAt` / `appVersion` / `databaseSchemaVersion`. Cheaper to write and stronger than five per-table comparisons; it catches any field the importer forgets to carry.
- Autoincrement safety — **narrow, verified-scoped claim, not "N+1"**: SQLite raises `sqlite_sequence` to an explicitly inserted rowid above it, but `DELETE FROM` does **not** reset it (only `DROP TABLE` does). So on a *fresh* DB, restoring ids up to N means the next `insertEvent` gets N+1; on a device that previously held a higher id, the next id is `max(previous sequence, N) + 1` — never a collision, never a reuse. Assert exactly that ("never collides, always > max(existing)"), and keep the strict N+1 assertion on an empty DB only, or the test will fail for a reason that has nothing to do with the importer.
- Active-profile promotion: file with profiles but none active → oldest `(birthDate, id)` becomes active; file with an active one → unchanged
- Custom reminders: all 4 frequency codes round-trip, `custom_<id>` settings keys stay attached, `intervalDays` null for monthly
- Dismissals round-trip (epoch-seconds path and ISO-fallback path both parse)
- Rejection matrix (DB must be **unchanged** — assert counts identical before/after): invalid JSON, missing table key, `counts` mismatch, `generator` ≠ mamadera, version 2 (→ distinct `UnsupportedExportVersion`), **`databaseSchemaVersion` > `AppDatabase.schemaVersion` (→ the newer-schema reason — the regression test for the §3 data-loss hole)**, empty file (0 profiles/0 events), unknown event type, **unknown `subtypeValue`**, duplicate event id, duplicate baby id, duplicate reminder `itemId`, label > 60 chars, `every_n_days` with `intervalDays: 0`, timestamp outside 1990–2100
- Zero-profile file (`profiles == 0 && events > 0`) is **accepted**, no profile invented, and the summary surfaces `importDataNoProfile`
- Size pre-check is **not** a repository concern (the repository receives a JSON string): keep the gate pure and next to the read path — `(int? length, int cap) → accept | reject-without-reading` — and test it directly (`null` → read anyway; over cap → reject without invoking the reader). See the presentation list below.
- Orphan `babyId` kept, not nulled
- Notes are **not** byte-stable across a round trip: an empty-string note encrypts to `''` and decrypts to `null` (`EncryptionService.encrypt('')` / `decrypt('')`). Do not write an assertion that `""` survives. (Adjacent pre-existing bug, out of scope here but worth its own issue: the export flags such a row `notesUndecryptable: true`, which mislabels an empty note as lost-key.)

**Presentation** — `test/features/import/presentation/`:

- `providers/import_controller_test.dart` — controller with in-memory DB + real `ImportRepositoryImpl`: invalid JSON → `ImportInvalidFile`; valid → `ImportSummaryReady` with correct counts; `applyRestore()` → `ImportSuccess` + DB actually replaced; failure path leaves pre-state intact; the `ParsedExport` held between `restoreFromJson` and `applyRestore` survives the gap (provider not autoDisposed); every `ImportFailure` carries an enum reason, never interpolated error text (assert the reason set is closed)
- **Connection-leak guard** — after a successful restore, `ref.read(databaseProvider.future)` returns the *identical* `AppDatabase` instance as before the restore. One assertion that pins the §2 decision and would catch a future copy-paste of `_performReset`'s invalidation list (which would silently open a second isolate per restore).
- `widgets/import_data_dialog_test.dart` — the 3 phases; cancel-at-each-step changes nothing (mirror of `export_data_dialog_test.dart`); the size gate rejects an oversized `lengthSync()` **without** calling `readAsBytes()` (the read is the thing under test — use a fake `PlatformFile` that counts reads, since the plugin itself is not faked at data level)
- `menu_screen` test — import tile present in danger zone, opens the dialog

**Integration**: **not added to `ci_smoke_suite.dart`** — `file_picker` opens a real OS dialog that can't be driven reliably on a headless CI emulator; the destructive logic is fully covered at data + widget level. (Optional follow-up: an integration test that bypasses the picker by driving the controller with a fixture file.)

## 8. Risks / open questions

1. **Android permissions: none, at any API level** — verified in `android_file_picker 2.0.0`, not assumed: the manifest declares **no `<uses-permission>` at all**, and a custom-type pick goes through `Intent.ACTION_OPEN_DOCUMENT` (SAF). The old "plugin asks for storage permission on Android ≤9" concern is gone with the 12/13 rewrite. The persistable-URI-grant code path exists in Kotlin but is unreachable in 13.x (`AndroidOptions` is an empty class; `androidSafOptions` was removed in 13.0.0) — keep it that way: never pass a `grant: lifetime` option, a persistable URI grant outlives the restore and is a standing grant the user is never shown again.
2. **Explicit-rowid insert** is now low-risk: it goes through `TrackingEventsCompanion(id: Value(row.id), …)` / `CustomRemindersCompanion(id: Value(row.id), …)`, so Drift still owns column naming and type conversion. Revisit only if a future drift version stops exposing the autoincrement column in the companion (it does today: `Value<int> id = const Value.absent()`, `app_db.g.dart:669` and `:1443`) — in that case fall back to a strictly parameterised `customInsert`, never string interpolation.
3. **`sqlite_sequence` is monotonic, not restored.** A device that had 500 events and restores a 10-event backup keeps sequence 500; the next event is id 501. Harmless (no FK on id, no id shown to the user, no reuse) but it means ids are *not* a faithful copy of the source device's future ids — worth one line in the docs so it is not later reported as a bug.
4. **Open question**: should re-importing a backup from the *same* device be deduplicated? **Recommendation: no** — full-restore semantics are predictable, and the summary step makes "I'm about to replace my data with this file" explicit.
5. **5 MB size cap** is a heuristic (real exports are ≪ 1 MB), now enforced *before* reading via `lengthSync()`/`length()`. Revisit if multi-year, multi-baby exports with long notes ever approach it — the cap is a single const in the controller.
6. **New dependency surface.** `file_picker` 13.x is a thin facade over **six** platform packages plus `cross_file` and `path`, MIT, publisher `victorcarreras.dev`, repo transferred to `vicajilau/flutter_file_picker`. For a privacy-first app that is a review obligation per §6.1, and a maintenance one: the API moved twice in three majors (`FilePicker.platform` gone in 12.0.0, `withData`/`readBytes` gone in 13.0.0), so pin `^13.1.0` and expect a breaking change on the next major. Re-verify the platform manifests on every upgrade.
7. **The picker's extension filter is cosmetic.** `android_file_picker` maps `allowedExtensions` to MIME types and falls back to `*/*` when nothing maps (and logs it), so a user can always select a wrong file — and `json` filtering may silently not filter on some devices. The §3 validator is the guard; the filter is UX. Verify on-device rather than assuming the filter protects anything.
8. **System dialog over Flutter `AlertDialog`.** The OS picker is presented on top of the open warning dialog; confirm on both platforms that cancelling the picker leaves the dialog mounted as §5 step 3 promises (Android process-death while the picker is foregrounded is the known edge — the correct behaviour there is simply "nothing changed", which the no-write-until-apply design already guarantees).

## 9. Privacy compliance checklist (AGENTS.md mandates)

- [ ] No network transport anywhere in the import path (picker + local read + local DB write only)
- [ ] `file_picker` 13.x: every platform package's manifest/entitlements reviewed by hand (§6.1) — trivy covers CVEs, not data paths — plus `make audit-trivy` and `make audit-gitleaks` green
- [ ] No new permission. Verified against `android_file_picker 2.0.0`: the only manifest addition is a `<queries><intent GET_CONTENT></intent></queries>` block — that is still a **merged-manifest change**, so write "no new permission", never "no manifest change". iOS: no Info.plist key. The OS picker is the consent step.
- [ ] Plaintext notes never written to disk by the app (memory only, re-encrypted before commit). This holds **only** because the import path calls nothing but `readAsBytes`/`readAsByteStream` — the plugin's `saveFile()` and `clearTemporaryFiles()` write into `cacheDir/file_picker/` and must stay unused; say so in the dartdoc so nobody "just uses `path`" later.
- [ ] Logs contain counts/reasons only — never file contents, names, or note text (same rule as the export repository); UI errors come from the closed enum, not from `e.toString()`
- [ ] The user's original file is never modified, moved, or copied into app storage

---

Estimated footprint: ~6 new files, ~5 modified (`menu_screen.dart`, `reminders_repository_impl.dart` to un-private the frequency codes, 3× ARB, `pubspec.yaml`), ~2 new test files + 1 menu test update. No schema change, no migration. Permission manifests untouched, but the plugin adds a `<queries>` block to the merged Android manifest (no permission).

---

## 10. What was actually built

Implemented and green: `make ci` passes (analyze `--fatal-infos --fatal-warnings`, full suite,
coverage 86 % ≥ 80 %). New-code coverage: data 93.6 %, domain 95.5 %, controller 94.6 %, dialog
76 % (the uncovered lines are the real `_readPickedBackup` picker path, unreachable headless).

Files: `lib/features/import/{domain,data,presentation}` (4 new), `db_constants.dart`,
`menu_screen.dart`, `reminders_repository_impl.dart`, 3 ARBs (+15 keys) + regenerated
localizations, `pubspec.yaml` (`file_picker: ^13.1.0`), README (features/privacy/data-lifecycle,
including the stale "all four tables" fix), `AGENTS.md` (export ⇄ import invariant). Tests: 29
data, 8 controller, 13 dialog, 2 new menu-screen — no `skip:`.

Where the build departs from this document, and why:

1. **Outcome classes collapsed.** `ImportInvalidFile` / `ImportUnsupportedVersion` became one
   `ImportRejected(reason)` over the closed `ImportRejectionReason` enum, and `ImportFailure(message)`
   became `ImportFailed()` with no text — a value that *cannot* carry a message is a stronger
   guarantee than a value that promises not to.
2. **The invalidation list changed twice over** (this is the document's biggest error, found while
   building): `databaseProvider` is excluded (leaks a connection + background isolate per restore —
   `import_controller_test.dart` asserts the `AppDatabase` instance stays `identical` across a
   restore), and the list *gained* the repository providers, because their absence would have made
   things stale rather than safe: `customRemindersProvider` and `reminderSettingsProvider` refresh
   only through the cascade from `remindersRepositoryProvider`. Follow-up worth its own change:
   `menu_screen._performReset` relies on the same cascade today, so deleting
   `invalidate(databaseProvider)` there would silently stale the reminder switches.
3. **Frequency codes went to `db_constants.dart`** (`allFrequencyValues`), not to un-privatised
   consts in `reminders_repository_impl.dart`: an importer in `import/data` must not import another
   feature's data layer. `reminders_repository_impl` now aliases the shared consts.
4. **Size gate moved into the domain** as `maxBackupBytes` + `enforceBackupSizeLimit(...)` (plus a
   `fileTooLarge` reason), so the gate is unit-tested without any plugin.
5. **`ImportDataDialog` gained a `readBackup` seam** (`BackupReader`, optional; production passes
   nothing and gets the OS picker). That is what let the dialog be tested headlessly at all — the
   §7 "integration test excluded" reasoning stands, but the three phases and every rejection path
   are now covered at widget level.
6. **`compute()` lives in the data layer** (`ImportRepositoryImpl.parseExport`), so presentation
   never mentions isolates. Verified to work under `flutter test`.
7. **Patch notes not added**: they are generated at release time (`make patch-notes VERSION=…
   DATE=…`) and inventing a version/date for an unreleased build would put a fake entry in the
   upgrade dialog.

Verified on-device-adjacent facts (were assumptions in §8/§9):
- Merged Android debug manifest after adding file_picker 13.1.0: **no new permission** (only the
  debug-only `INTERNET` and AGP's own `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`), and
  file_picker's whole contribution is one `<queries><intent GET_CONTENT></intent></queries>` entry.
- `compute()`-based parsing, the explicit-rowid companion insert, and the monotonic
  `sqlite_sequence` behaviour (next id after restoring low ids on a device that had id 900 is >900,
  never a collision) are now pinned by tests rather than by SQLite folklore.

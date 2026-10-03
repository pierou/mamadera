# PLAN — mamadera v1.2.0 (`1.2.0+1`, drift schema v11, export format v2)

Status: **ready to implement.** Written 2026-10-02 against `1.1.1+8` @ `894042a`.
Supersedes nothing; it executes `docs/ROADMAP-reminders-and-sync.md` §4 (items M, 3, 4, 8).

This file is the **only** input an implementer gets. Everything needed is here: verified
current state, target schema with exact DDL, exact file paths, exact signatures, verification
commands. Do not re-derive what is already asserted below; do not invent what is not asked.

---

## 0. How to use this file

Implement **one milestone at a time, in order** (M1 → M7). Each milestone ends green and is
committed separately. Never batch two milestones into one commit.

After every milestone, run and report verbatim:

```bash
flutter analyze --fatal-infos --fatal-warnings    # must be clean
flutter test test/<the directory you touched>/     # must be green
```

Run the **full** gate (`make ci`) only when M7 tells you to. If a step's instruction contradicts
the code you are reading, **STOP and report the contradiction** — do not improvise a different
design, and do not "fix" an unrelated thing you noticed (note it in your report instead).

Report per milestone: files created, files modified (with the diff of each non-new file), the
exact commands you ran and their output tail, and anything you could not do.

### Hard rules (from `AGENTS.md`, non-negotiable here)

- **No network, no analytics, no telemetry, no crash reporting.** No new dependency of any kind
  in this plan — `pubspec.yaml` `dependencies:` must not gain a single entry. Dev dependencies
  may not change either.
- Health numbers (weight, height, temperature) are **encrypted at rest**. `measurements.value` is
  AES-GCM ciphertext produced by the existing `EncryptionService`, stored in a `TEXT` column.
  A `REAL` column storing plaintext weight violates the privacy charter and will be rejected.
- Comments in `lib/` are in **French**; new test names in **English** (that is the split the
  codebase already uses).
- Conventional Commits: `feat(...)`, `fix(...)`, `chore(...)`, `security(...)`.

### Do NOT touch (explicitly out of scope)

| Out of scope | Why |
|---|---|
| `HistoryFilter` (`lib/shared/domain/entities/tracking_enums.dart:313-378`) | Growth gets its own screen (`/growth`), not a 6th filter chip. A 6th value ripples through `label`, `labelKey`, `trackingType`, `dbKey`, `fromString` and 23 tests for no user benefit. |
| `TrackingType` (`lib/shared/domain/entities/tracking_type.dart`) | Not a free label: `HistoryFilter` mirrors it 1:1, pills and icons key on it. Growth is not a care event. |
| `TrackButton` (`lib/features/home/presentation/widgets/track_button.dart`) | Height is hardcoded 230/200 (L164) and `_maxVisiblePills = 3` (L132) is reminder-owned. Measurement buttons are a **new** widget so the existing 2×2 tap targets cannot shrink. |
| `ReminderPill` (display-only, no tap) | The reminders list uses a new row widget with real actions. |
| Growth curves / WHO percentiles | Later release. The table shape already supports it. |
| `°F` / unit toggle | Metric only in v1.2.0. |
| Two-phone sync, merge, LAN, cloud | v1.3.0, and it needs a written privacy decision first. |
| `test_driver/`, screenshots, store assets | Not part of this feature work. |
| Renaming any existing DB value, enum value, or `item_id` | They are on-disk and inside users' backup files. |

---

## 1. Verified current state (do not re-derive)

| Fact | Evidence |
|---|---|
| `schemaVersion == 10`, 5 tables | `lib/data/local/app_db.dart:67-73`; DDL reference `lib/data/local/schema.sql` |
| `reminder_dismissals(item_id PK, dismissed_at)`, `reminder_settings(item_id PK, enabled)` — **no baby column** | `app_db.dart:31-41`, `schema.sql` |
| `custom_reminders(id AI, label 1..60, subtype_value NOT NULL, frequency, interval_days?)` — no baby column, care always required | `app_db.dart:43-66` |
| Export writes `'exportFormatVersion': 1` as a **literal** | `export_repository_impl.dart:58` |
| Import supports exactly 1: `const int _supportedFormatVersion = 1;` | `import_repository_impl.dart:18`; ladder at L115-135 (`newerFormatVersion` then `newerSchemaVersion` at L130-133) |
| Restore is replace-only, one transaction, delete order profiles→events→customReminders→settings→dismissals | `import_repository_impl.dart:436-526` (L439 `database.transaction`) |
| `deleteProfile` cleans **only** `tracking_events` + `baby_profiles` | `baby_profile_repository_impl.dart:83-93` |
| `getLastCompleted(item, {String? babyId})` is the only baby-aware reminder path | `reminders_repository.dart:15`, impl L22-51 |
| `setEnabled` is a raw DELETE + INSERT, **not** in a transaction | `reminders_repository_impl.dart:73-98` (L81-90) |
| `ReminderItem` = `{id, labelKey, frequency, trackingType, subtypeValue?}`; 4 presets `vitamine_d`, `vitamine_k`, `eye_cleaning`, `face_cleaning`; custom ids are `custom_<id>` | `reminder_item.dart:12-83`, `custom_reminder.dart:43` |
| Completion is always derived from `tracking_events`; no manual "done" exists anywhere | `reminders_service.dart:26`, `custom_reminder.dart` dartdoc L8-15 |
| Home body = `Container > SingleChildScrollView > GridView.count(2)` — the GridView is the **only** child | `home_screen.dart:299-344` (GridView L303, children L308-342) |
| `QuantityPickerInline` is the numeric+unit widget actually used; `QuantityPickerDialog` is unreferenced dead code | `feeding_tracking_dialog.dart:120`, `edit_event_dialog.dart:220,240`; grep of `QuantityPickerDialog` in `lib/` → declaration only |
| `EventDateTimeField({required value, required onChanged, title?, firstDate?, lastDate?})` | `lib/core/widgets/event_date_time_field.dart:15-30` |
| Menu: reminders section ends L95, terms section starts L97 → "Mesures" slots between | `menu_screen.dart:84-111` |
| Router: `/reminder-settings` is a top-level `GoRoute` (L131-135); menu navigates by **path string** `context.push('/x')` | `router.dart:85-163` |
| l10n: 3 ARBs × 234 identical keys; `app_localizations*.dart` are generated **and committed**; **no `make l10n` target exists** — regenerate manually with `flutter gen-l10n` | `l10n.yaml`, `git ls-files lib/l10n/`, Makefile |
| Patch notes screen renders **the last key** of the asset map | `patch_notes_screen.dart:48-49` |
| Version is hard-checked only in CI (`pubspec.yaml` vs `AppConfig.version`) | `.github/workflows/ci.yml:97-106` |
| Migration test harness template: `_RawSqlDatabase extends GeneratedDatabase` + on-disk temp `.db` + raw v-N DDL seed, then open `AppDatabase` | `test/data/local/migration_v9_to_v10_test.dart:10-91` |
| `make test` runs `test/shared/ test/data/ test/presentation/ test/features/ test/core/ --coverage`; coverage gate ≥80 % excluding `lib/l10n/*`, `*.g.dart`, `*_freezed.dart` | `Makefile:19-21`, `Makefile:41-55` |

### 1.1 Two traps, already paid for — respect them

1. **SQLite lets `NULL` live in a table-level composite PRIMARY KEY, and lets it repeat.**
   Verified on this machine (sqlite 3.51.0):
   `CREATE TABLE t (a TEXT, b TEXT, PRIMARY KEY(a,b)); INSERT … (NULL,'x')` twice → **2 rows stored**,
   both `NULL`. `NOT NULL` on the column is what fixes it. Therefore every new composite key in
   this plan declares `baby_id TEXT NOT NULL` and the app uses the **empty-string sentinel**
   `db_const.sharedBabyId = ''` meaning "applies to every baby". Never `NULL` in a key.
2. **Adding a nullable column to `custom_reminders` cannot drop `NOT NULL` via `ALTER TABLE`.**
   The table must be rebuilt (create-new → copy with explicit ids → drop → rename). Same for the
   two re-keyed reminder tables. `DROP TABLE` inside drift's `onUpgrade` is fine: drift runs the
   migration in a transaction, and this schema declares **no foreign keys** (so no
   `PRAGMA foreign_keys` dance is needed).

---

## 2. Product decisions (resolved — implement as written)

The roadmap left #3 and #4 open. They are resolved here so implementation is not blocked; the
chosen default is the one that cannot damage data or the existing UI. If the owner overrides one,
only the milestone named changes.

| # | Decision | Resolved as | Roadmap ref |
|---|---|---|---|
| D1 | Multi-baby home list | **Active baby only.** No merged list, no per-baby sections. The list is already baby-reactive (`activeBabyProvider`), which matches today's pill behaviour and cannot show a wrong baby's number. A cross-baby "N pending for Léa" badge is **deferred** to v1.2.x — it multiplies `checkDue` queries and is not the reported need. | §7.3 |
| D2 | Detached custom reminder completion | **One mechanism per reminder**, chosen at creation by `completion_source`: `from_events` (a care is bound → derived from `tracking_events`, unchanged semantics) XOR `manual` (detached → a "Done" tap writes `reminder_completions`). Presets stay `from_events`. No latching of both. | §7.4 |
| D3 | Dismiss (new affordance on list rows) | Suppress that reminder until **`dismissalWindow = Duration(hours: 24)`** (one named constant). Simpler and kinder than a per-frequency rule; does not reintroduce the deleted 4 h cooldown constant of v1.1.0. | §4.1 UI |
| D4 | History placement | Dedicated `/growth` screen from the Menu. `HistoryFilter` untouched. | §4.2 |

---

## 2.5 M1 — DONE (schema v11 in the tree, full suite green: 1179 pass / 3 skip)

M1 is implemented, reviewed and verified. **The sections below are the amendments M1 forced.
They override §3 where they disagree.** Read §2.5 before touching anything from §3 onward.

| Amendment | What changed from §3 | Why |
|---|---|---|
| **A1 — drift defaults on every new NOT NULL column** | `babyId` on `ReminderSettings` / `ReminderDismissals` / `CustomReminders` / `ReminderCompletions` is `text().withDefault(const Constant(db_const.sharedBabyId))()`; `completionSource` is `.withDefault(const Constant(db_const.completionFromEvents))()` | Without a drift-level default the generated companion demands the argument, and **the tree stops compiling** in `reminders_repository_impl.dart`, `import_repository_impl.dart` and 17 test call sites — files §3 scheduled for M2/M4. A milestone that does not compile is not a milestone. The default also makes `onCreate` emit the same `DEFAULT ''` as the migration, so fresh and migrated schemas agree. |
| **A2 — `onCreate` creates the two v11 indexes** | They were only in `onUpgrade` | Fresh installs would have shipped without them: invisible to every migration test (which only ever looks at a migrated DB) and visible on a parent's phone. Locked by `test/data/local/schema_parity_test.dart` (new, 3 tests, verified red-when-removed). |
| **A3 — the D2 invariant is enforced at the write boundary, today** | `insertCustomReminder` and `updateCustomReminder` derive `completionSource` from `subtypeValue == null`; `CustomReminder.subtypeValue` is already `String?` | A detached reminder left at `from_events` matches **any** `sante` event and would read as done. The hazard had to be closed when the column became nullable, not two milestones later. |
| **A4 — `ImportedCustomReminder.subtypeValue` stays non-null until M4** | The import path writes `const Value(db_const.completionFromEvents)` | Deriving from a field the holder declares non-nullable is dead code and the lint says so. M4 makes the holder nullable and the derivation real. |
| **A5 — plan SQL uses single quotes** | `'...'` inside customStatement blocks | `prefer_single_quotes` is enabled; §3.3's double quotes fail lint. |
| **A6 — the migration test asserts the AUTOINCREMENT trap** | `expect(newId, greaterThan(7))` on a post-migration insert | It passes: the explicit-id copy advances `sqlite_sequence`. The `UPDATE sqlite_sequence` guard is confirmed a no-op on every tested path — kept as the belt. |

**New permanent guard:** `test/data/local/schema_parity_test.dart` compares a **fresh install** to a
**v10-migrated** database (columns, nullability, PK, defaults, indexes) for the five tables v11
creates or rebuilds. Any later milestone that touches DDL must keep it green. It compares SQLite
*storage affinity*, not declared type names (`TIMESTAMP` legacy vs drift's `INTEGER` are the same
column — comparing names raises an alarm about grammar, and alarms about grammar train people to
ignore alarms).

**Known pre-existing state, not caused by this work:** `test/features/home/presentation/screens/home_screen_test.dart`
has 3 tests with `skip: true` (L126, L131, L136) although the ROADMAP claims they were enabled. M6 touches
that file — resolve them there, deliberately, one by one.

---

## 3. Target schema: drift v11 (one migration, all tables at once)

Why once: v1.2.0 already takes the `exportFormatVersion` 1→2 bump, so every table this release
needs must land in v11. A second migration in the same release would force format 3 for nothing.

### 3.1 New tables (exact drift definitions to add to `lib/data/local/app_db.dart`)

```dart
/// Mesures de croissance (poids, taille, température) — v11.
///
/// `value` est du **chiffré AES-GCM** (`iv:ciphertext` base64), pas un REAL :
/// le mandat de confidentialité (`AGENTS.md`) classe le poids comme donnée
/// sensible ; la température et la taille sont de la même famille (données de
/// santé RGPD). Le en-clair n'existe qu'au moment de l'export JSON, qui est
/// en clair par conception — comme les `notes`.
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nullable, comme `tracking_events.baby_id` : un suivi sans profil reste lisible.
  TextColumn get babyId => text().nullable()();
  TextColumn get kind => text()();          // 'poids' | 'taille' | 'temperature'
  TextColumn get value => text()();        // chiffré
  TextColumn get unit => text()();         // 'g' | 'cm' | 'degC'
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get notes => text().nullable()(); // chiffré, même pipeline que events
}

/// Achèvement **manuel** d'un rappel (`completion_source = 'manual'`, D2).
///
/// Journal append-only : une ligne par tap « Fait ». La lecture est
/// `MAX(completed_at)`, ce qui rend la forme identique à `getLastCompleted`
/// côté événements.
class ReminderCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get babyId => text()();       // '' = tous les bébés (sentinelle)
  TextColumn get itemId => text()();
  DateTimeColumn get completedAt => dateTime()();
}
```

### 3.2 Re-keyed / widened tables

```dart
class ReminderDismissals extends Table {
  TextColumn get babyId => text()();       // NOT NULL, '' = partagé
  TextColumn get itemId => text()();
  DateTimeColumn get dismissedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {babyId, itemId};
}

class ReminderSettings extends Table {
  TextColumn get babyId => text()();       // NOT NULL, '' = partagé
  TextColumn get itemId => text()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column> get primaryKey => {babyId, itemId};
}

class CustomReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get babyId => text()();                     // '' = tous les bébés
  TextColumn get label => text().withLength(min: 1, max: 60)();

  /// Null = rappel **détaché** : aucun soin lié, achèvement manuel (D2).
  TextColumn get subtypeValue => text().nullable()();
  TextColumn get frequency => text()();
  IntColumn get intervalDays => integer().nullable()();

  /// `'from_events'` | `'manual'` — qui décide que le rappel est fait.
  TextColumn get completionSource => text()();
}
```

Declare the columns `text()` (not `.nullable()`) wherever the DDL below says `NOT NULL DEFAULT ''`
— drift will emit `NOT NULL`, and the `DEFAULT ''` in the raw migration DDL keeps copied rows valid.

### 3.3 `onUpgrade` block to append at `app_db.dart:149` (after the `from < 10` block)

```dart
// v10 → v11 : trois mouvements, un seul passage.
//  (a) `reminder_settings` et `reminder_dismissals` sont re-clés par bébé :
//      un rappel éteint pour l'un ne l'est plus pour l'autre (item M).
//  (b) `custom_reminders` gagne `baby_id` + `completion_source` et surtout
//      `subtype_value` NULLABLE, ce qu'`ALTER TABLE` ne sait pas faire : la
//      table est reconstruite.
//  (c) deux tables neuves : `measurements` et `reminder_completions`.
// Les PRIMARY KEY composites déclarent `baby_id NOT NULL` : SQLite autorise
// NULL dans une clé composite et l'autorise en double (vérifié, sqlite 3.51),
// ce qui ferait deux lignes « partagées » pour un même rappel. La sentinelle
// `''` signifie « tous les bébés ».
// Les ids de `custom_reminders` sont recopiés explicitement : la clé
// d'extinction `custom_<id>` de `reminder_settings` s'y rapporte, changer un id
// éteindrait un rappel au hasard.
if (from < 11) {
  // (a) settings
  await m.database.customStatement('''
    CREATE TABLE reminder_settings_new (
      baby_id TEXT    NOT NULL DEFAULT '',
      item_id TEXT    NOT NULL,
      enabled BOOLEAN NOT NULL,
      PRIMARY KEY (baby_id, item_id)
    )''');
  await m.database.customStatement(
    "INSERT INTO reminder_settings_new (baby_id, item_id, enabled) "
    "SELECT '', item_id, enabled FROM reminder_settings");
  await m.database.customStatement('DROP TABLE reminder_settings');
  await m.database.customStatement('ALTER TABLE reminder_settings_new RENAME TO reminder_settings');

  // (a) dismissals
  await m.database.customStatement('''
    CREATE TABLE reminder_dismissals_new (
      baby_id      TEXT    NOT NULL DEFAULT '',
      item_id      TEXT    NOT NULL,
      dismissed_at TIMESTAMP NOT NULL,
      PRIMARY KEY (baby_id, item_id)
    )''');
  await m.database.customStatement(
    "INSERT INTO reminder_dismissals_new (baby_id, item_id, dismissed_at) "
    "SELECT '', item_id, dismissed_at FROM reminder_dismissals");
  await m.database.customStatement('DROP TABLE reminder_dismissals');
  await m.database.customStatement('ALTER TABLE reminder_dismissals_new RENAME TO reminder_dismissals');

  // (b) custom reminders — rebuilt for the nullable subtype_value
  await m.database.customStatement('''
    CREATE TABLE custom_reminders_new (
      id               INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      baby_id          TEXT    NOT NULL DEFAULT '',
      label            TEXT    NOT NULL,
      subtype_value    TEXT,
      frequency        TEXT    NOT NULL,
      interval_days    INTEGER,
      completion_source TEXT   NOT NULL DEFAULT 'from_events'
    )''');
  await m.database.customStatement(
    "INSERT INTO custom_reminders_new (id, baby_id, label, subtype_value, frequency, interval_days) "
    "SELECT id, '', label, subtype_value, frequency, interval_days FROM custom_reminders");
  await m.database.customStatement('DROP TABLE custom_reminders');
  await m.database.customStatement('ALTER TABLE custom_reminders_new RENAME TO custom_reminders');
  // Safety net : un AUTOINCREMENT renommé peut repartir de 1 et entrer en collision
  // avec un id recopié. Le test de migration l'attrape ; la ligne l'empêche.
  await m.database.customStatement(
    "UPDATE sqlite_sequence SET seq = (SELECT COALESCE(MAX(id), 0) FROM custom_reminders) "
    "WHERE name = 'custom_reminders'");

  // (c) new tables (drift emits the DDL from the classes above)
  await m.createTable(measurements);
  await m.createTable(reminderCompletions);

  await m.database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_measurements_baby_kind_recorded '
    'ON measurements(baby_id, kind, recorded_at DESC)');
  await m.database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_reminder_completions_baby_item '
    'ON reminder_completions(baby_id, item_id, completed_at DESC)');
}
```

Also: `schemaVersion` → `11` (`app_db.dart:73`), and add `Measurements, ReminderCompletions` to
the `@DriftDatabase(tables: […])` list (`app_db.dart:67`). `onCreate` needs no change — `createAll()`
picks up the new classes. **`reminder_completions` gets no composite PK on purpose** (append-only log,
§3.1) — do not add one.

> Before writing the migration: run `make codegen` **after** editing the table classes and confirm
> the generated DDL matches §3.3 column-for-column. Then hand-copy §3.3's column order into
> `lib/data/local/schema.sql` (header version → 11, changelog lines for v11) — `schema.sql` is a
> committed reference and every migration test seeds from it.

### 3.4 New constants — `lib/data/local/db_constants.dart`

```dart
// ── Growth measurement kinds (`measurements.kind`) ─────────────────────
const String kindPoids = 'poids';
const String kindTaille = 'taille';
const String kindTemperature = 'temperature';
const Set<String> allMeasureKindValues = {kindPoids, kindTaille, kindTemperature};

// Units — metric only in v1.2.0, no °F.
const String unitG = 'g';
const String unitCm = 'cm';
const String unitDegC = 'degC';

// ── Reminder completion source (`custom_reminders.completion_source`) ──
const String completionFromEvents = 'from_events'; // a `sante` event of subtype settles it
const String completionManual = 'manual';          // a tap on reminder_completions settles it
const Set<String> allCompletionSourceValues = {completionFromEvents, completionManual};

/// Sentinelle « tous les bébés » des clés composites (baby_id, item_id).
/// NULL n'est **pas** utilisé : SQLite l'autorise dans une PRIMARY KEY composite,
/// et l'autorise en double.
const String sharedBabyId = '';
```

The kind codes are French like `miam`/`sante`/`caca`/`dodo`: they are on-disk and inside backup
files written by users. Renaming them is a data-format break, not a refactor.

---

## 4. Export / import: format 1 → 2

One bump carries both the re-keyed reminder rows and the new tables (`AGENTS.md` rule).

### 4.1 Export — `lib/features/export/data/repositories/export_repository_impl.dart`

- L58 `'exportFormatVersion': 2` (literal stays a literal, matching the file's style).
- `counts` gains `'measurements'` and `'reminderCompletions'`; `ExportCounts`
  (`export_repository.dart:11-43`) gains two `required int` fields and `isEmpty` accounts for them.
- Two new payload sections, appended **after** `reminderDismissals`:
  ```dart
  'measurements': measurements.map((row) => <String, Object?>{
    'id': row.id,
    'babyId': row.babyId,
    'kind': row.kind,
    'value': _decryptedValue(row.value),  // decrypt; 'valueUndecryptable': true on failure
    'unit': row.unit,
    'recordedAtEpochSeconds': …, 'recordedAtUtc': …,
    'notes': …, // decrypted, same helper as events
  }),
  'reminderCompletions': completions.map((row) => <String, Object?>{
    'babyId': row.babyId, 'itemId': row.itemId,
    'completedAtEpochSeconds': …, 'completedAtUtc': …,
  }),
  ```
- `reminderSettings` / `reminderDismissals` rows each gain `'babyId': row.babyId`.
- `customReminders` rows gain `'babyId'`, `'completionSource'`, and `subtypeValue` may now be `null`.
- Unfiltered reads only (no baby filter): a backup that omits a table is a broken backup.

> `_decryptedValue` mirrors `_decryptedNotes` (L180-185). Export of health numbers in clear text is
> a deliberate continuation of the existing plaintext-JSON design, and is the one sanctioned data exit
> (Menu → confirm → OS share sheet). Flag it in the commit message body; do not "improve" it here.

### 4.2 Import — `lib/features/import/`

- `import_repository_impl.dart:18` → `_supportedFormatVersion = 2`. The ladder at L115-135 already
  rejects `> _supportedFormatVersion` with `newerFormatVersion` — **do not touch it**, it becomes correct
  by the constant change.
- `import_repository.dart`: three new row holders `ImportedMeasurement`, `ImportedReminderCompletion`,
  and `babyId` + `completionSource` fields on `ImportedReminderSetting`, `ImportedReminderDismissal`,
  `ImportedCustomReminder`; `ImportCounts` gains `measurements` + `reminderCompletions`; `ParsedExport`
  gains the two lists.
- Two new row parsers next to `_parseDismissal` (L258): `_parseMeasurement` (kind ∈ `allMeasureKindValues`,
  unit ∈ {`g`,`cm`,`degC`}, value a non-empty numeric string after decrypt, `recorded_at` in the
  1990-2100 `_checkRange` window), `_parseCompletion`.
- `_section` doc (L134-135) says "one of the five table sections" → update to seven, and `_parseAndValidate`
  (L72-86) must read the two new sections; `_validateCounts` covers them for free.
- `restore()` (L436-526): delete order gains `measurements` + `reminderCompletions`
  (**before** `babyProfiles`, to keep the documented dependency-free order meaningful), inserts after
  `reminderDismissals`, with explicit ids for `measurements` and `baby_id`/`item_id`/`enabled` on the
  re-keyed tables. Notes and values are re-encrypted on insert, exactly as events' notes are today.
- **Backward compatibility, mandatory:** a **format-1** backup must still restore. Accept
  `exportFormatVersion == 1` by filling absent sections with empty lists and absent `babyId` with
  `sharedBabyId`. Reject only `> 2`. A parent's old backup is the one file that must never fail to open.
  Tests must prove both directions.
- `ImportFormatException.reason` values: reuse `missingTable` / `invalidRow` / `countsMismatch`.
  **No new enum value** — the 10 existing reasons cover it, and the UI maps them
  (`import_data_dialog.dart`).

### 4.3 Baby deletion — `lib/features/baby/data/repositories/baby_profile_repository_impl.dart:83-93`

Inside the existing transaction, before `deleteBabyProfile(id)`:
`deleteMeasurementsByBabyId`, `deleteReminderCompletionsByBabyId`,
`deleteReminderSettingsByBabyId`, `deleteReminderDismissalsByBabyId`, `deleteCustomRemindersByBabyId`
(new queries in `app_db.dart`, all `WHERE baby_id = ?` — rows holding the `''` sentinel belong to
every baby and must **survive** a single baby's deletion). Rows of `custom_reminders` deleted this way
also remove their `reminder_settings` key `custom_<id>`; do it in the same transaction.

---

## 5. UI

### 5.1 Home (`lib/features/home/presentation/screens/home_screen.dart`)

Convert the GridView's sole-child slot (L299-344) into a Column, keeping the 2×2 grid byte-identical:

```
SingleChildScrollView(padding: spacingXl)
  └ Column
      ├ GridView.count(crossAxisCount: 2, shrinkWrap: true,
      │                physics: NeverScrollableScrollPhysics())   ← add physics, it was missing
      ├ const SizedBox(height: spacingXl)
      ├ const MeasurementButtonRow()      ← 3 × Expanded, new widget (§5.2)
      └ const HomeRemindersSection()     ← below the buttons, §5.3
```

Sequence rule from the roadmap: the reminders list is **last**, so the measurement row (which the user
asked for as buttons on the home screen) never displaces the scroll position of the reminder list, and
neither can push the 2×2 grid off-screen.

### 5.2 New `lib/features/growth/presentation/widgets/measurement_button.dart`

`MeasurementButton({required String label, required MeasureKind kind, String? latestValue,
required VoidCallback onTap})` — card, `CircleAvatar(radius: 24)` + icon, label in
`Expanded > FittedBox(fit: BoxFit.scaleDown)` with `maxLines: 1` (this is why `TrackButton` was not
reused: its height and pill budget are reminder-owned), and a **separate** `bodySmall` subtitle line
for `latestValue` (e.g. `3,4 kg`). `latestValue == null` renders an em-dash `—`, never an error state,
never a pill. Row wrapper `MeasurementButtonRow` = `Row` of three `Expanded` (equal width,
`spacingMd` gaps) inside the Column of §5.1.

### 5.3 Reminders list (item 3)

`lib/features/reminders/presentation/widgets/home_reminders_section.dart` + `reminder_row.dart`:
section title + flat ordered list (presets first, then custom, creation order) of the **active baby's**
due reminders (D1). Row: icon + label + frequency label (`reminderFrequencyLabel`) +
"last done `X`" (`lastEventAt`, or the manual completion date) + a **Done** `Icons.check_circle_outline`
action and a **Dismiss** `Icons.close` action (D3). Done → `remindersNotifier` →
`recordCompletion` (§5.4). Dismiss → `dismissReminder` → `reminder_dismissals` upsert on
`(baby_id, item_id)`.

### 5.4 Notifier / service changes

- `RemindersService.checkDue` resolves `lastCompleted` as: `from_events` →
  `repository.getLastCompleted(item, babyId:)`; `manual` →
  `repository.getLastManualCompletion(itemId, babyId:)`. Add `Duration dismissalWindow = const
  Duration(hours: 24)` (D3) and skip an item whose dismissal for `(babyId ?? sharedBabyId, itemId)` is
  newer than `now - dismissalWindow`.
- `RemindersNotifier` gains `Future<void> markDone(ReminderItem)` and `Future<void> snooze(ReminderItem)`,
  each writing then `_checkDue()` (no `ref.invalidate` nudge — v1.1.1's reactive `build()` chain already
  re-evaluates; do **not** re-add one-shot invalidations, they raced and were deleted for it).
- All repository reads/writes take `{String? babyId}` and normalise `null → sharedBabyId` at the
  repository boundary, in exactly one place (`reminders_repository_impl.dart`).

### 5.5 Growth feature module (Clean Architecture, `AGENTS.md` shape)

```
lib/features/growth/
├── domain/
│   ├── entities/growth_measurement.dart      # freezed GrowthMeasurement — NOT `Measurement`:
│   │                                         # drift already generates `Measurement`, and a name
│   │                                         # clash would force `hide` clauses everywhere
│   ├── entities/measure_kind.dart            # enum MeasureKind {poids, taille, temperature}
│   │                                         # value/labelKey/unit/icon/min/max/decimals
│   └── repositories/measurement_repository.dart   # pure Dart interface
├── data/repositories/measurement_repository_impl.dart  # injects AppDatabase + EncryptionService
└── presentation/
    ├── providers/measurement_providers.dart       # repository provider + AsyncNotifier(s)
    ├── screens/growth_screen.dart                   # latest per kind + descending history
    └── widgets/{measurement_button.dart, measurement_sheet.dart}
```

`MeasureKind` carries its own validation range (roadmap §8, locked in tests):

| kind | db value | unit | min | max | decimals | display |
|---|---|---|---|---|---|---|
| `poids` | `poids` | `g` | 200 | 20 000 | 0 (grams) | kg, 3 decimals above 1 000 g |
| `taille` | `taille` | `cm` | 30 | 110 | 1 | `42,5 cm` |
| `temperature` | `temperature` | `degC` | 33 | 42 | 1 | `37,2 °C` |

- Stored `value` = the canonical number in the table's base unit, **encrypted** (`encryption.encrypt(
  value.toString())`), decrypted in the repository only. Out-of-range input is rejected **in the sheet**
  with an inline `validationError` — never stored and then explained in history.
- `MeasurementSheet`: `QuantityPickerInline` (min/max/divisions from `MeasureKind`) +
  `EventDateTimeField` + optional note + `DialogActionButtons`. Add one optional
  `Color accentColor = AppTheme.miam` param to `QuantityPickerInline` so the sheet is not stuck in
  feeding-green — that is the **only** permitted edit to an existing widget in this plan.
- `GrowthScreen`: newest value per kind across the top, then the list (date, kind, value, note),
  empty state text, and delete via the existing pattern? **No** — no edit/delete in v1.2.0. Read-only
  screen. (A wrong measurement is corrected by recording the right one; adding delete here would demand
  the whole `edit_event_dialog` machinery again.)
- Router: top-level `GoRoute(path: '/growth', builder: GrowthScreen)` next to `/reminder-settings`
  (`router.dart:131-135`). Menu: new section between `menu_screen.dart:95` and `:97`, tile icon
  `Icons.straighten`, `context.push('/growth')`. Do **not** add a 4th bottom-nav tab.

---

## 6. l10n

New keys, all three ARBs, same key sets (234 → ~258). Names follow the existing `homeButton*` /
`reminder*` / `feedback*` convention:

`homeButtonPoids`, `homeButtonTaille`, `homeButtonTemperature`, `growthSectionTitle`,
`growthMenuTile`, `growthScreenTitle`, `growthEmptyState`, `growthLatestWeight`,
`growthLatestHeight`, `growthLatestTemperature`, `growthSheetTitleWeight|Height|Temperature`,
`growthSheetNoteField`, `growthSheetSave`, `growthValueOutOfRange` (`{min}`,`{max}`,`{unit}`),
`growthFeedbackSaved` (`{value}`), `growthValueUndecryptable`,
`reminderListTitle`, `reminderListEmpty`, `reminderMarkDone`, `reminderDismiss`,
`reminderLastDone` (`{date}`), `reminderNeverDone`, `reminderCustomCareNone`,
`reminderCustomCareNoneHint`.

- ARB format: `"key": "value"` plus `"@key": {"placeholders": {…}}` when it has placeholders —
  mirror `"@feedbackFeedingWithQuantity"` exactly.
- `fr` is the template; `en`/`es` must gain the identical key set (CI does not check it — a missing key
  is a runtime `MissingPluginException`-class crash in the other locales).
- Regenerate **manually**: `flutter gen-l10n`, then `git add lib/l10n/`. Also add the missing target to
  the Makefile (this is a real trap the repo already documents wrongly at
  `docs/import-database-plan.md:184`):
  ```makefile
  l10n:  ## Regenerate lib/l10n/app_localizations*.dart from the ARB files
  	flutter gen-l10n
  ```

---

## 7. Milestones

| M | Content | New / modified files | Gate |
|---|---|---|---|
| **M1** | Schema v11: 2 new tables, 2 re-keyed tables, `custom_reminders` rebuilt, `schemaVersion` 11, constants, `schema.sql` v11, `make codegen` | `app_db.dart`, `db_constants.dart`, `schema.sql` | `make codegen && flutter analyze`; `flutter test test/data/local/` — **must include the new `migration_v10_to_v11_test.dart`** (§8) |
| **M2** | Baby-scoped reminder persistence: repository interface + impl signatures take `babyId`, `getLastManualCompletion`, `recordCompletion`, `dismissReminder`, one `null → sharedBabyId` boundary, `setEnabled` wrapped in `database.transaction` (roadmap §8) | `reminders_repository.dart`, `reminders_repository_impl.dart`, `reminders_service.dart`, `reminder_item.dart` (+`babyId`, `completionSource`), `custom_reminder.dart` (nullable `subtypeValue`, `completionSource`) | `flutter test test/features/reminders/ test/data/` |
| **M3** | Detached custom reminders (D2): care dropdown gains a "Aucun soin" option, form writes `completionSource`, `forCustom` honours it, settings screen shows detached reminders distinctly | `custom_reminder_form_sheet.dart` (dropdown L199-217 — the hardcoded coupling point), `custom_reminder_tile.dart`, `reminder_providers.dart`, `custom_reminders_notifier.dart`, `reminder_settings_screen.dart` | `flutter test test/features/reminders/` |
| **M4** | Export/import format 2 (§4): sections, counts, parsers, restore, **format-1 backward compatibility**, baby-scoped `deleteProfile` | `export_repository{,_impl}.dart`, `import_repository{,_impl}.dart`, `baby_profile_repository{,_impl}.dart`, `app_db.dart` queries | `flutter test test/features/export/ test/features/import/ test/features/baby/` |
| **M5** | Growth module end-to-end (§5.2, §5.5): entities, repo+encryption, providers, sheet, screen, 3 home buttons, router, menu tile | `lib/features/growth/**`, `home_screen.dart`, `router.dart`, `menu_screen.dart`, `quantity_picker_inline.dart` (one param) | `flutter test test/features/growth/ test/features/home/ test/core/router_test.dart test/features/menu/` |
| **M6** | Reminders list on home (§5.3, §5.4) | `home_reminders_section.dart`, `reminder_row.dart`, `home_screen.dart`, `reminder_notifier.dart` | `flutter test test/features/reminders/ test/features/home/` |
| **M7** | l10n sweep (§6) + patch notes `1.2.0` in en/es/fr (noun form) + `pubspec.yaml version: 1.2.0+1` + `AppConfig.version = '1.2.0'` + ROADMAP status update + `make ci` | ARBs + generated files, `assets/patch_notes/{en,es,fr}.json`, `pubspec.yaml`, `app_config.dart`, `Makefile`, `docs/ROADMAP-…md` | **`make ci`** full gate, green |

**Order is load-bearing:** M4 before M5/M6 (a new table whose rows cannot be backed up is a data-loss
bug waiting to ship); M5 before M6 (both edit `home_screen.dart` §5.1 — sequencing them means neither
reverts the other's layout); M7 last (version bump gates the release notes).

---

## 8. Tests that must exist (write them with the milestone, not after)

**`test/data/local/migration_v10_to_v11_test.dart`** — copy the harness of
`migration_v9_to_v10_test.dart` verbatim (`_RawSqlDatabase` with `allTables => const []`,
`schemaVersion => 10`; on-disk temp `.db`; raw v10 DDL from `schema.sql`). It must assert, in order:

1. `db.schemaVersion == 11`, and `measurements` + `reminder_completions` exist and accept a write.
2. **A preset switched off before the upgrade is still off after it** (`vitamine_k`, `enabled: 0`) —
   the load-bearing assertion of every migration in this repo, and the reason the re-key is a
   copy-and-rename and not a `createAll`.
3. `custom_reminders` ids survive, **and a reminder inserted after the migration does not collide**
   (insert → `id > max(migrated ids)`). This is what catches the `AUTOINCREMENT`-after-`RENAME` trap.
4. `reminder_settings` legacy rows carry `baby_id = ''`, and the composite PK now rejects a duplicate
   `('', 'vitamine_k')` while accepting `('baby_2', 'vitamine_k')` — i.e. the whole point of item M.
5. Two babies, one row each: switching one off does not switch the other off.
6. Dismissals survive with `baby_id = ''`.
7. A **format-1** backup restores on schema v11 (§4.2 backward compatibility) — assert empty new
   sections and `''`-sentinel settings.

Then: repository unit tests for every new query (`NativeDatabase.memory()`, the existing pattern);
`MeasureKind` range validation (each bound, inclusive, ±1 outside); encrypted-at-rest test proving the
raw column is ciphertext and round-trips; `MeasurementSheet` widget tests (in-range saves, out-of-range
blocked with the inline error, unit shown, note optional); `MeasurementButton` tests (subtitle present
when a value exists, em-dash and no error styling when absent); `home_screen_test` additions for the
7 buttons and the reminders list; `track_button_test` must stay **green untouched** (the tap-target
regression guard); import round-trip tests for format 2 **and** format-1 acceptance; `deleteProfile`
test proving a second baby's settings/dismissals/completions/custom reminders and the `''` sentinel rows
all survive.

---

## 9. Risks & rollback

| Risk | Mitigation baked in |
|---|---|
| Migration loses the parent's switches | §8.2 assertion; the re-key is copy→drop→rename, never `createAll`; migration runs in drift's transaction |
| `AUTOINCREMENT` restarts after rename → UNIQUE collision on insert | explicit-id copy + `sqlite_sequence` reset (§3.3) + §8.3 |
| `NULL` in composite PK silently duplicating "shared" rows | `NOT NULL` + `sharedBabyId = ''` sentinel (§1.1) |
| Format-2 export breaks a parent's old backup | §4.2: format 1 still restores; §8.7 proves it |
| Health numbers stored in clear text | `value TEXT` encrypted + a test asserting the column is ciphertext (§8) |
| The 2×2 tap targets shrink | New `MeasurementButton`; `track_button.dart` untouched; `track_button_test` unmodified and green |
| Home screen overflow on small phones (7 buttons + list) | `shrinkWrap` + `NeverScrollableScrollPhysics` in a `SingleChildScrollView` (§5.1); widget test on a 320×568 viewport |
| A new table ships without export/import | M4 precedes M5/M6; counts verified in the importer |
| Regressions in `reminder_dismissals` semantics (feature deleted in v1.1.1, reborn here) | D3 is one named constant, tested; nothing else reads the table |

**Rollback:** revert the milestone's commit. For a released v1.2.0 on a device, the schema is a
forward migration only — there is no downgrade path (drift cannot reverse a re-key), so M1 must be
green on a real device before M7 tags. That is the one irreversible step in this plan; it is why the
migration test runs on a **file-backed** DB, not in memory.

---

## 10. Definition of done

- `make ci` green: lint `--fatal-infos --fatal-warnings`, 1179+ tests, coverage ≥80 % on `domain/`+`data/`.
- `pubspec.yaml version: 1.2.0+1` == `AppConfig.version` (`.github/workflows/ci.yml:97-106`).
- Patch notes `1.2.0` present in **all three** assets (the screen renders the *last* key,
  `patch_notes_screen.dart:48`) — note that **1.1.1 never got an entry**, so do not repeat that miss.
- Export→import round-trip verified on a device or emulator with all 7 tables populated.
- Privacy: `git diff main..HEAD -- pubspec.yaml` shows **zero** new dependencies; `grep -rn "http\|dio\|socket" lib/`
  still returns nothing.
- ROADMAP §3/§4/§7 updated to mark M, 3, 4, 8 shipped and D1–D4 recorded.

# ROADMAP — Reminders, multi-baby scoping, onboarding, two-phone sync, growth measurements

Status: **§2 shipped in v1.1.0+4 (2026-09-21); §4.2 (measurements) added 2026-09-29, decisions resolved the same day; §5 (v1.1.1) implemented and `make ci`-green 2026-09-29. §4 (items M, 3, 4, 8) implemented in full on branch `feat/v1.2.0-growth-and-baby-scoped-reminders` on 2026-10-03, executed from [`docs/PLAN-v1.2.0.md`](PLAN-v1.2.0.md) — drift v11, export format v2, `make ci`-green (1305 scoped / 1311 full, 0 skipped, 88 % lines). §10 (backlog, items 11–19) recorded 2026-10-02; §9 (items 9 + 10, slider colour) recorded 2026-10-05; §1 remains withdrawn; §6 (v1.3.0 sync) is still proposal; decisions 1, 2, 6 and 7–9 in §7 are resolved, and **3, 4, 5 are now resolved too — 3 → D1 and 4 → D2 as decided in PLAN §2, 5 still awaits you** (sync needs a written privacy mandate change from the owner before any code).
Opened 2026-09-20, while v1.1.0 was mid-flight (Phase 2B, Xcode Cloud).

Five requests came in together:

1. Synchronisation between two phones
2. "Vit. K reminder displaying every 14 in settings" → **withdrawn, see §1**
3. Show a list of reminders below the tracking buttons
4. Custom reminder detached of the health type
5. Refresh of reminders when reminders shown are modified in Settings
6. *(added later)* After wiping the DB and re-importing, the baby-creation popup is shown even though the backup contains a baby → **§2.1, v1.1.0**
7. *(added later)* Patch notes screen prints raw markdown (`### Nouvelles fonctionnalités`, `- bullet`) → **§2.2, v1.1.0** — and it has been printing since 1.0.0, see below
8. *(added later, 2026-09-29)* Temperature, weight and size tracking, with dedicated home buttons → **§4.2, planned for v1.2.0 (decisions 7–9 resolved 2026-09-29)**

---

## 0. Verified state of the code (read this, do not re-derive)

| Fact | Evidence |
|---|---|
| Reminders are in-app banners only — no system notification exists | `RemindersService.checkDue` + `TrackButton` pills; no `flutter_local_notifications` in `pubspec.yaml` |
| Completion of every reminder today is **derived from `tracking_events`** | `reminders_repository_impl.dart:22-45` (`getLastCompleted`), `custom_reminder.dart:66` (`trackingType: TrackingType.sante` hardcoded) |
| Presets are 4 hardcoded items; only `vitamine_k`'s *frequency* is derived from the baby | `reminder_item.dart:26-84`, `buildForBaby` → `monthly(dayOfMonth: profile.birthDate.day)` |
| `dynamicRemindersProvider` falls back to Vit. D + rolling 30-day Vit. K with no profile | `reminder_providers.dart:43-52` |
| Custom reminders are stored, but `subtype_value` is **NOT NULL** and the care dropdown lists only the 6 `HealthSubtype`s | `app_db.dart:52-66`, `custom_reminder_form_sheet.dart:196-210` |
| Settings/create/edit **no longer** invalidate the home notifier — the notifier reactively awaits `remindersServiceProvider` in `build()`, so the settings→enabled→service chain settling *is* the re-evaluation (§5, v1.1.1) | `reminder_notifier.dart` `build()`, `reminder_settings_notifier.dart`, `custom_reminders_notifier.dart`; the bulk-reset invalidation stays at `menu_screen.dart` and `import_providers.dart` |
| Due reminders re-evaluate on a **5-minute poll**, on active-baby change, **and on any change to the reminder chain** (toggle, custom-reminder write) via the reactive dependency | `reminder_notifier.dart` `build()` watches `activeBabyProvider` and `remindersServiceProvider.future` |
| **No `WidgetsBindingObserver` / `AppLifecycleListener` anywhere in `lib/`** | `grep -rn "AppLifecycle\|didChangeAppLifecycleState\|WidgetsBindingObserver" lib/` → 0 hits |
| ~~`RemindersService.dismiss()` had zero callers~~ — **dead dismiss/cooldown code deleted in v1.1.1**; the `reminder_dismissals` table stays (imported backups carry rows; v1.2.0 re-purposes it) | §5; deleted surface: `dismiss()`, `cooldownPeriod`, `save/getDismissalTime`, `ReminderStatus.lastDismissedAt`; kept: table, `getAllReminderDismissals()` (export), cleanup-on-delete |
| Pills on a track button are capped at **3 + "+N"** | `track_button.dart:128-146` |
| `HomeScreen` is **disposed and recreated on every tab switch** — plain `ShellRoute` + `MaterialPage`, no indexed stack / keep-alive | `router.dart:136-160` |
| Restore is **replace-only**, in one transaction | `import_repository_impl.dart:439` |
| Event ids are **autoincrement ints, exported verbatim** | `export_repository_impl.dart:159` (`'id': row.id`) |
| `exportFormatVersion: 1`, `databaseSchemaVersion: 10`, `pubspec 1.1.0+4` | `export_repository_impl.dart:58`, `app_db.dart:73`, `pubspec.yaml` |
| Notes are AES-GCM under a **per-device** Keychain/Keystore master key; the export decrypts them to **plaintext JSON** | `encryption_service.dart:17`, `export_repository_impl.dart:150-176` |
| No sync code, no networking dependency, no `uuid` dependency today | `grep -i sync lib/` → only `dart:async`/`toIso8601`; `pubspec.yaml` |
| Patch notes printed every `items[]` string verbatim — **fixed in 1.1.0+4** | `_PatchNotesItem` now branches: heading → `_SectionHeader` (no check icon), bullet → `_CheckedItem`, `""` → `SizedBox.shrink()`; `patch_notes_screen.dart` |
| The screen also rebuilt its `Future` from `build()` (spinner flash + asset re-read on every ancestor rebuild) — **fixed in 1.1.0+4** | replaced by `patchNotesProvider`, a `FutureProvider.autoDispose.family<Map<String, dynamic>, String>` keyed on language code |
| The patch notes assets are **authored in markdown** — `### Heading` and `- bullet` inside the strings, all three languages | `assets/patch_notes/{fr,en,es}.json` (verified by reading the files 2026-09-20) |
| ⇒ the raw-markdown rendering shipped with **1.0.0**, not 1.1.0: the 1.0.0/1.0.1 items carry the same `### `/`- ` prefixes, and Play is live with 1.0.1 | same assets, keys `1.0.0`/`1.0.1`; `RELEASE-PLAN-v1.1.0.md` "Google Play is live with v1.0.1" |
| A markdown renderer **already exists** in the app; the patch notes list now shares it | `core/utils/markdown_parser.dart`: `parseMarkdownToTextSpans` (`#`/`##`/`###`, `- `/`* `, `**bold**`, `*italic*`, `[text](url)`, `---`) serves `features/onboarding/.../terms_screen.dart`; `parseInlineMarkdown` (plain-text strip) serves the patch notes bullets |
| Every `items[]` array ends with a `""` entry — rendered as nothing since 1.1.0+4, and left in the assets | same assets; locked by `patch_notes_screen_test.dart` “an empty entry renders no row at all” |
| `markdown: ^7.2.2` was declared but never imported — **dropped in 1.1.0+4** | `grep -rn "package:markdown"` across the repo → 0 hits; `flutter pub deps --style=compact` → gone from the lockfile, and `flutter analyze` stays clean |
| **No table exists for weight/height/temperature** — 5 tables total, schema v10 | `app_db.dart:7-66` (`BabyProfiles`, `TrackingEvents`, `ReminderDismissals`, `ReminderSettings`, `CustomReminders`) |
| The home grid is a **2×2 `GridView.count` with exactly 4 `TrackButton`s**, scrollable, no sectioning | `home_screen.dart:303-338` |
| `TrackingType` has exactly 4 values and is **not just a label**: `HistoryFilter` mirrors it 1:1, reminder pills key on it, icons key on it | `tracking_type.dart:1-24`, `tracking_enums.dart:310-346` |
| `tracking_events.quantity` is already **overloaded without units** (ml for feedings, minutes for sleep); no unit-carrying numeric column exists | `app_db.dart:28-29` |
| The privacy charter **already names weight as a sensitive field** to encrypt at rest | `AGENTS.md` "Encryption at rest" row (notes, weight, allergies) |

---

## 1. Item 2 — Vit. K "every 14": **not a bug** (withdrawn)

`Le 14 de chaque mois` is `dayOfMonth = activeBaby.birthDate.day` (`reminder_item.dart:78`,
`reminder_providers.dart:52`), asserted by `test/features/reminders/domain/reminder_item_test.dart:122`
("anchors Vitamin K on the birth day of month"). Withdrawn as reported.

**But the follow-up concern — "with several babies things could get complicated" — is valid and is the
largest real defect found.** Tracked below as item **M**.

### M. Multi-baby scoping (real, structural)

Baby-scoped ✅ : completion lookups use `tracking_events.baby_id` (`reminders_repository_impl.dart:31-38`).

**Not** baby-scoped ❌:

| Table / behaviour | Consequence with 2 babies | Where |
|---|---|---|
| `reminder_dismissals(item_id)` is the PK | Dismissing Vit. D for twin A mutes twin B for 4 h | `app_db.dart:31-35`; already documented as accepted-at-v1 in `reminders_repository.dart:22-30` |
| `reminder_settings(item_id)` is the PK | Switching off Vit. K for one baby switches it off for both | `app_db.dart:37-40` |
| `custom_reminders` has no `baby_id` | "Crème eczéma, tous les 2 jours" created for the newborn also nags the 18-month-old | `app_db.dart:52-66` |
| Monthly due-day is read from the **active** baby | One row id (`vitamine_k`) means "day 14" and "day 3" depending on the selected profile, while its `enabled`/dismissal rows stay shared | `reminder_providers.dart:52-68` |
| `deleteProfile` has nothing to clean for reminders | Fine today; becomes a leak the moment these tables gain `baby_id` | `baby_profile_repository.dart` |

**One item id carrying two meanings per baby is the root of the whole family.** Fix = key reminder
state by `(baby_id, item_id)` and give custom reminders a `baby_id`. That is schema **v11**, and it is the
same migration item 4 needs (§4). Do it once.

---

## 2. v1.1.0 — two UI defects (both fixed, shipped in `1.1.0+4`)

### 2.1 Item 6 — Onboarding popup after wipe + re-import ✅ fixed

#### Reproduction (traced, not yet executed)

1. Menu → wipe (`menu_screen.dart:316` `_performReset`): DB closed, file deleted, all providers
   invalidated → `anyBabyExistsProvider` resolves `false`. Correct.
2. `HomeScreen` rebuilds with a **fresh** `_HomeScreenState` (`router.dart:136-160` recreates it on every
   return to the Home tab) → `_onboardingShown = false` (`home_screen.dart:35`) → watches `false`
   (`:41`) → schedules the onboarding sheet in `addPostFrameCallback` (`:61-70`).
3. Parent picks the file → confirms → restore commits → `_invalidateRestoredState()`
   (`import_providers.dart:173-186`) correctly invalidates `anyBabyExistsProvider`… **but an already-open
   modal bottom sheet is a Navigator route, not provider state. Nothing pops it.**
4. If the parent types into that sheet, `onboarding_dialog.dart:172` runs `insertProfile` →
   **duplicate baby profile on top of the restored ones.** Data damage, not cosmetics.

Aggravating: the import summary already carries `counts.babyProfiles` (`import_repository.dart:16-24`), so
the app provably knows a baby is arriving; and because `_onboardingShown` resets on every tab switch,
"just re-check the bool" is not a fix.

#### Why it is proposed **for** v1.1.0 rather than after

* It is a defect in **the headline feature of this release** ("full DB restore from an exported backup").
* It fires on the exact flow a reviewer, an F-Droid tester, or a parent migrating phones will run.
* The fix is **presentation-only**: no schema change, no `exportFormatVersion` bump, no new permission,
  no new dependency.
* Cost: ~half a day including the regression test.

#### Known test gap — now closed

`test/features/home/presentation/screens/home_screen_test.dart` used to carry only the *negative* case, the
positive one being skipped because `showModalBottomSheet` overflowed the 600×900 test viewport. Both cases
now run: the sheet test pumps a 1200×3200 viewport so a layout constraint is not what fails the test
(`“shown when no profile exists”`, `“closed as soon as a profile exists while it is open”`).

#### Fix as shipped

The trigger stayed in `HomeScreen.build()` (where Riverpod requires listeners to live); what changed is that
the sheet now **stops being able to outlive the state that opened it**:

1. `home_screen.dart` — `_scheduleOnboardingSheet()` re-reads `anyBabyExistsProvider` *inside* the
   post-frame callback and returns unless it reads an explicit `false`: an unresolved provider
   (`AsyncLoading`, which is what an invalidation leaves behind) is **not** an observed absence, so the
   sheet does not open on it.
2. `onboarding_dialog.dart` — the dialog listens to `anyBabyExistsProvider` and **dismisses itself** once a
   profile exists. This is the load-bearing half: `ref.listen` fires on *change*, so a restore landing after
   the sheet route was pushed but before the dialog's listener registered would otherwise never be noticed.
3. `onboarding_dialog.dart` — `_saveProfile()` refuses to insert into a database that is no longer empty
   (the query it already runs for the duplicate-name check), so the duplicate cannot be written even in the
   window before dismissal paints.
4. Two latches, deliberately separate: `_closed` (a `pop` was emitted — a second one would pop a *different*
   route) and `_saving` (a save is in flight — the listener must not close the sheet before the success
   message). An earlier single-latch version set the flag at the top of `_saveProfile` and thereby blocked
   its own dismissals; the tests caught it.

Verified red-before-green: with the fix reverted, the restore test inserts the duplicate profile
(`Expected: empty / Actual: [BabyProfile…]`) and the sheet stays open.

---

### 2.2 Item 7 — Patch notes print raw markdown ✅ fixed

Screenshot `Screenshot_20260920_134348` (Android, fr): the 1.1.0 overlay shows `### Nouvelles
fonctionnalités` and `- Ajout de rappels personnalisés liés à un soin` **literally**, each line on its own
check-marked row, so section headers and their items are indistinguishable.

**Root cause.** The assets are authored in markdown; the renderer is not. `patch_notes_screen.dart:74` maps
every `items[]` entry straight to `_PatchNotesItem` (`:134-160`), which is a `check_circle_outline` icon plus
`Text(item)` — it has no notion of a heading, a bullet, or inline formatting. Nothing strips or styles the
markup, so the markup *is* the UI.

**This shipped with 1.0.0.** `assets/patch_notes/*.json` keys `1.0.0` and `1.0.1` carry the identical
`### ` / `- ` prefixes, and Google Play is live with v1.0.1 — so live users have been reading raw markdown
for two releases. It is not a 1.1.0 regression; 1.1.0 is simply the release where upgrading users see the
notes again, at scale, for the first time in months. That is the argument for fixing it here rather than
adding a third release: the cosmetic defect rides along with the release that re-exposes it.

**Fix shape (presentation + data hygiene, no schema, no dependency).**

1. `_PatchNotesItem` branches on the line instead of printing it — heading (`### `/`## `/`# `) renders as a
   section title, **without** the check icon; a bullet (`- `/`* `) renders the check icon + the text with
   `parseInlineMarkdown()` applied (already in `core/utils/markdown_parser.dart`, so `**bold**` and
   `[text](url)` stop leaking too); empty string renders nothing.
2. Do **not** strip the markdown out of the assets to "fix" it — the assets are markdown by convention
   (same convention as the terms assets), and a renderer that only works if nobody ever writes markdown is
   the bug, not the fix.
3. Keep the existing `patchNotesWhatChanged` l10n header ("Ce qui a changé") — it is a different level from
   the asset's own `### ` section titles; don't merge them.
4. Reuse `core/utils/markdown_parser.dart`; add **no** dependency. If full-span rendering is wanted later,
   `parseMarkdownToTextSpans` is already there and already proven by the terms screens.

**Tests — written, and they are what proves the bug.** `test/features/patchnotes/presentation/screens/patch_notes_screen_test.dart`
did not exist when this was written (only `patch_notes_dialog_test.dart` did, which is why the defect shipped
unnoticed for two releases). It now holds 11 tests, and they were confirmed **red against the old renderer**
before the fix went in.

Two harness constraints found the shape of this file, both observed rather than assumed:

* `rootBundle` stops answering after the third instantiation of `PatchNotesScreen` inside one test file (the
  `flutter/assets` channel handler is reset between tests) → the shipped-asset tests read the JSON from disk
  with `dart:io` and serve it through a fake repository. The content under test is still the published file, so
  the regression lock holds; only the asset *load* is stubbed. Wrapping the wait in `tester.runAsync` does not
  work here — it fights the `CircularProgressIndicator` ticker.
* `pumpAndSettle()` never returns while the loading banner is on screen (it animates forever) → settle is a
  bounded wait on the positive condition instead.

Assertions that carry the lock: no rendered `Text` contains `###` or starts with `- `; icon count equals bullet
count (a heading gets no check); `""` produces no row; `- **X**` renders `X`. Content is read from the shipped
files, so editing an asset moves the assertions instead of silently passing.

**Dead dependency — dropped in the same change.** `markdown: ^7.2.2` was declared and never imported once
(`grep -rn "package:markdown"` across the whole repo, `lib/`, `test/`, `scripts/`, `ci_scripts/` → 0 hits), it
is pure Dart, and its AST could not render into Flutter `Text` widgets without a custom span visitor. Removing
it shrinks the privacy-audited dep list and the F-Droid manifest, and `flutter pub get` + `make ci` stay clean
without it. The rebuild was happening anyway for `+4`, so the lockfile change cost nothing it did not already
cost.

---

## 3. Release buckets (proposal)

| Release | Content | Schema / format | Gate cost |
|---|---|---|---|
| **v1.1.0** (shipped `1.1.0+4`) | **§2.1** onboarding after restore **+ §2.2** patch notes raw markdown, + dead `markdown` dep dropped | none | done: `make ci` green — 1174 tests, lint clean, 86.9 % lines |
| **v1.1.1** | Item 5 (stale reminders) — reactive fix, red→green verified; dead dismiss cooldown deleted; time-axis lifecycle refresh deferred to v1.2.0 | none | implemented 2026-09-29, `make ci` green — 1174 tests, lint clean, 87.0 % lines; patch notes en/es/fr to write with the tag |
| **v1.1.2** (optional quick patch once 1.1.1 is approved) | Items 9 + 10 — slider colour consistency (§9) | none | light gate: `make ci` green + patch notes en/es/fr + store copy (cosmetic only) |
| **v1.2.0** | Item M (baby scoping) + item 4 (detached custom reminders) + item 3 (home reminders list) **+ item 8 (measurements: weight/height/temperature, 3 home buttons — §4.2)** | drift **v11**, `exportFormatVersion` **2** (one bump carries both the reminder keying change and the new table) | full gate + migration test + patch notes en/es/fr + store copy |
| **v1.3.0** | Item 1 (two-phone sync), phase A (merge, manual transport) | drift **v12**, format **3** | full gate + privacy decision (§7.5) |

Rules inherited from `AGENTS.md`, applying to every row above:
* a new/changed export field bumps `exportFormatVersion` in `ExportRepositoryImpl` **and** the supported
  version in `ImportRepositoryImpl`;
* a new table joins the export **and** the import (replace transaction) in the same commit;
* patch notes en/es/fr use the **noun form** (`Mise à jour de…`, `Actualización de…`), en natural — the
  1.1.0 entries already obey this; §2.2 changes the *renderer*, not the wording, so no new entry is needed
  (a build-number bump stays under the same `1.1.0` key);
* `AppConfig.version` stays in sync with `pubspec.yaml` (CI hard-checks it).

---

## 4. v1.2.0 scope

### 4.1 The reminder model

Answering one question once: **what does a reminder belong to, and who says it is done?**

* **Schema v11**
  * `reminder_settings` → PK `(baby_id, item_id)`; backfill existing rows from the active baby, and
    **never guess per-row** — an ambiguous backfill silently changes a parent's switches.
  * `reminder_dismissals` → PK `(baby_id, item_id)`.
  * `custom_reminders` → `baby_id TEXT NULL` (null = "every baby", the honest reading of legacy rows).
  * `reminder_completions(baby_id, item_id, completed_at)` — the manual "done" record for a reminder not
    bound to a tracked care.
  * `custom_reminders.subtype_value` → nullable, plus a `completion_source` discriminator
    (`from_events` | `manual`). Completing stays a strategy, not a hardcoded `TrackingType.sante`.
* **Domain**: `ReminderItem` gains `babyId` + `completionSource`; `RemindersService.checkDue` resolves
  `lastCompleted` from events *or* from `reminder_completions`. `isDue`
  (`reminder_frequency.dart:66-88`) is untouched — its semantics are already documented per variant.
* **UI**: reminders list below the 2×2 grid — flat ordered list (presets then custom, creation order),
  per-baby sections when >1 profile, each row: care/label + frequency label + "last done" + a done/dismiss
  action. Pills stay on the buttons for the glance; the list is where the `+N` actually gets read.
* **New l10n keys** en/es/fr; **export + import + counts** updated in the same commit;
  `deleteProfile` cleans the new rows.

### 4.2 Item 8 — growth measurements: weight, height, temperature (new, proposed v1.2.0)

**Model — a new table, not `tracking_events`.**

`tracking_events.quantity` is already an untyped, overloaded numeric (ml for feedings, minutes for
sleep — `app_db.dart:29`); a measurement is a *recorded value with a unit and a sane range*, not an
event quantity. And `TrackingType` is not a free label — a fifth value ripples through `HistoryFilter`,
the reminder pills and the icon table for data that is not a care event. So:

```
measurements(
  id          INTEGER PK AUTOINCREMENT,
  baby_id     TEXT NULL REFERENCES baby_profiles(id),  -- same nullability as tracking_events (item M)
  kind        TEXT NOT NULL,   -- 'poids' | 'taille' | 'temperature'
  value       TEXT NOT NULL,   -- AES-GCM ciphertext, NOT REAL (see encryption below)
  unit        TEXT NOT NULL,   -- 'g' | 'cm' | 'degC'
  recorded_at DATETIME NOT NULL,
  notes       TEXT NULL        -- encrypted, same pipeline as tracking_events.notes
)
```

* **Values are encrypted at rest.** The privacy charter in `AGENTS.md` already lists *weight* as a
  sensitive field; temperature and length are the same class (health data under GDPR). The numeric is
  AES-GCM ciphertext through the existing `EncryptionService` (a TEXT column), decrypted in the
  repository — the exact pattern `notes` already uses. `REAL` would leave plaintext health data in
  SQLite and contradict the mandate.
* **Feature module**: `features/growth/` — domain `MeasurementRepository` (pure Dart), data impl
  injecting `AppDatabase` + `EncryptionService`, presentation with the input sheet and the history
  screen. `MeasureKind` enum (`poids`/`taille`/`temperature`) carries unit, label key, icon and
  validation range.
* **Home — three dedicated buttons** (the user's request, not a single "Mesures" button). The grid is
  today a 2×2 of 4 `TrackButton`s (`home_screen.dart:303-338`); 4+3 = 7 cells. **Layout A, resolved
  §7.8:** keep the 2×2 care grid untouched, add a row of 3 equal-width measurement buttons below —
  the only option that cannot regress the existing tap targets (`track_button.dart:128`). The rejected
  alternative (*B*, one 2×4 grid) shrinks every existing target.
  Each button opens a quick-input sheet (numeric + unit fixed per kind + optional note + date/time,
  reusing the event date/time picker) and shows the **latest value as a subtitle** — not a pill, pills
  are reminder-driven and capped at 3+"+N" (`track_button.dart:128-146`).
* **History** — a dedicated "Mesures" screen (menu entry), scoped to the active baby: latest value per
  kind + descending list (date, kind, value, note). **Growth curves are out of scope for v1.2.0** —
  WHO percentiles are their own feature (local computation vs. a chart dependency, its own privacy
  review) and belong in a later bucket; the table shape already supports it (one value per
  `(baby, kind, recorded_at)`).
* **Schema + export (same-commit rule, §3).** Rides the drift **v11** + `exportFormatVersion` **2**
  bump v1.2.0 already takes: one migration adding one table, the format-2 document gains one section
  (unfiltered read, values decrypted on export like notes — the export is plaintext JSON by design).
  Import validates the section (kind/unit contract, decryptable value) and inserts inside the replace
  transaction; summary counts stay in sync. `deleteProfile` cleans the rows — baby-scoped from day
  one, so item M's backfill never touches this table.
* **Carve-out to v1.2.1 rejected** (§7.7) — but for the record: had it been taken, the whole bucket
  chain would shift (v1.2.1 at v12/format 3, and **v1.3.0 sync at v13/format 4**).
* **l10n + tests**: keys en/es/fr (buttons, sheet, screen, feedback, errors); widget tests for the 3
  buttons + input sheet incl. range validation; repository unit tests with mocked DB + encryption;
  export/import round-trip incl. rejection of a malformed `measurements` section.

## 5. v1.1.1 scope — **implemented, verified 2026-09-29**

### 5.1 Item 5 — stale reminders (settings axis) ✅ fixed

Reproduced per decision #2 **right after a toggle** (settings axis, not the time axis). Root cause,
confirmed by a red→green regression test, not by inspection: `setEnabled()` wrote the repo and pushed its
own state, then fired a one-shot `ref.invalidate(reminderNotifierProvider)`. That nudge rebuilt the
notifier while the `remindersServiceProvider` was **still resolving its `enabledRemindersProvider` read
from the pre-toggle settings** — `build()` then committed the stale due list, and nothing re-evaluated
until the next 5-minute tick, because one-shot invalidations do not survive the chain settling.

**Fix** — the nudge became a real dependency: `RemindersNotifier.build()` now awaits
`ref.watch(remindersServiceProvider.future)` before computing the due list, so the toggle's
settings→enabled→service settling *is* the re-evaluation, deterministically, whatever the timing.
The one-shot invalidations in the settings and custom-reminder write paths were **removed** (they only
could race — and did race; the custom-reminder one additionally triggered an orphan re-evaluation that
read a transient empty list). The bulk invalidations in `menu_screen.dart` (wipe/restore) and
`import_providers.dart` (import commit) stay: they are ceremonies that invalidate everything and
explicitly document intent.

**Verified red before green.** `test/features/reminders/presentation/providers/reminder_toggle_reactivity_test.dart`
(2 tests, plain `test()` — see the harness note below):
* *toggling off a reminder removes its pill without waiting for the tick* — **RED against the old code**
  (stale `eye_cleaning` pill survives after the chain settles, exactly the reported symptom), green after
  the fix;
* *the 5-minute poll survives an invalidation-triggered rebuild* — green on **both** old and new code:
  the timer lifecycle (`_pollTimer == null` guard + `ref.onDispose(_stopPolling)`) was never the bug, and
  this test locks that fact.

**Deferred to v1.2.0** (time axis): the old suspect #1 stands as a polish item, not a bug — midnight
rollover and month boundaries re-evaluate on the next poll (≤ 5 min after app resume, since timers are
the only clock). An `AppLifecycleListener` → `refresh()` on resume makes that instant; it ships with the
v1.2.0 reminder rework (item M), which touches the same providers.

### 5.2 Dismiss affordance — resolved by **deletion** ✅

`RemindersService.dismiss()` had zero callers: v1.1.0 shipped reminders with the 4 h cooldown in the
model but no UI surface to trigger it (§5's "wire it or delete it" — wiring an affordance for a
cooldown nobody asked for was the worse option). Deleted in v1.1.1:

* `RemindersService.dismiss()` + `cooldownPeriod` + the per-item cooldown read in `checkDue()`;
* `RemindersRepository.saveDismissalTime` / `getDismissalTime` (interface, impl, mock);
* `ReminderStatus.lastDismissedAt` (freezed regen done);
* the corresponding service/repo/provider tests (9 tests removed, 2 added = 151 in the suite).

**Kept, deliberately:** the `reminder_dismissals` table (schema v10), `getAllReminderDismissals()` in
the export, and the `DELETE FROM reminder_dismissals` cleanup in `deleteCustomReminder` — imported
backups contain dismissal rows (a wipe-then-restore must not lose them), and §4.1's v1.2.0 migration
re-purposes the table with a `(baby_id, item_id)` key. An export that omits a table is a broken backup
(`AGENTS.md`); the table therefore survives the death of its only reader.

### 5.3 Test-harness finding (kept for the next person)

The new regression tests run under **plain `test()` with a real event loop**, not `testWidgets`. Under
`testWidgets`' FakeAsync, `tester.pump()` does **not** progress this suite's real-future provider chain
(verified empirically: 200 pumped frames left `reminderSettingsProvider` and friends stuck in
`AsyncLoading` while a stubbed `activeBabyProvider` reached `AsyncData`). `reminder_settings_test.dart`
already used plain `test()` for exactly this shape. `RemindersNotifier` gained an injectable
`pollInterval` (constructor param, default unchanged 5 min) so the timer-survival test runs at 200 ms
instead of `runAsync`-sleeping.

## 6. v1.3.0 scope — two phones, privacy-first

Today the plumbing points the wrong way: restore is **replace-only** (`import_repository_impl.dart:439`) and
event ids are **autoincrement ints exported verbatim** (`export_repository_impl.dart:159`) → two phones both
tracking means either overwriting one device's history or colliding ids on merge.

* **Phase A — merge instead of replace (recommended v1.3.0).** Stable UUID per event + per-row
  `updated_at`/`deleted_at`; merge = union by UUID, latest write wins; still fully manual through the
  existing share sheet. **No network, no new permission, no server.** For most parents this *is* the feature.
* **Phase B — LAN peer-to-peer, opt-in.** Bonjour discovery + local-network permission + pairing that
  exchanges a shared key. This is a **deliberate amendment** to the mandate in `AGENTS.md`
  ("no network transport exists anywhere in the app") and needs a consent screen a parent cannot miss, plus
  a re-check of the F-Droid build story.
* **Phase C — cloud/Drive/WebDAV. Recommended: no.** It trades the app's entire positioning (offline,
  zero telemetry, F-Droid) for a problem Phase A already solves.

**Encryption constraint for any transport:** notes are AES-GCM under a **per-device** master key
(`encryption_service.dart:17`) and today's export **decrypts them to plaintext JSON**. A sync payload
therefore either carries plaintext on the LAN or needs a pairing step exchanging a shared key. Decide it
explicitly; do not let it happen by accident.

---

## 7. Decisions needed

1. **v1.1.0**: take §2.1 + §2.2 pre-freeze (needs re-gate + versionCode `+4`), or hold either for 1.1.1?
   *Recommendation: take both — §2.1 is a defect in this release's headline feature and can duplicate a
   baby profile; §2.2 is one bump for a defect already live since 1.0.0 that this release re-exposes.*
2. **Item 5 — RESOLVED 2026-09-29: reproduced right after a toggle** (settings axis). Fixed reactively,
   red→green verified (§5.1); the time axis is deferred to v1.2.0 as polish.
3. **Multi-baby semantics**: one merged list showing both babies (twins → two "Vit. D" lines), or the
   active baby only with a badge "1 reminder pending for Léa"?
4. **Detached custom reminder**: manual "done" only, or manual-with-event-latching (an event, when present,
   also completes it)?
5. **Sync**: is manual merge over the share sheet acceptable for v1.3.0, or do you want LAN — in which case
   the privacy mandate change must come from you, in writing, before any code.
6. **Dead `markdown` dep**: drop `markdown: ^7.2.2` in this release with §2.2 (after verifying nothing pulls
   it transitively), or defer to 1.1.1 to keep the in-flight lockfile untouched?
7. **Measurements placement — RESOLVED 2026-09-29: v1.2.0.** Rides the already-paid v11/format-2
   bump; the table is purely additive and the feature is independent of sync. *Fallback if v1.2.0's
   reminder scope overruns: carve out to v1.2.1 (§4.2 records the bucket-chain shift).*
8. **Measurements layout — RESOLVED 2026-09-29: A** (2×2 care grid untouched + row of 3 measurement
   buttons below). The only option that cannot regress the existing tap targets
   (`track_button.dart:128`).
9. **Measurements model — RESOLVED 2026-09-29: dedicated `measurements` table** (§4.2). A fifth
   `TrackingType` on top of `tracking_events.quantity` was rejected: it overloads an already-ambiguous
   column, ripples into `HistoryFilter`/pills/icons, and would store health numbers unencrypted by
   default.

---

## 8. Open questions / risks to re-check when implementing

* Backfilling `(baby_id, item_id)` keys from a single-baby history is unambiguous; from a multi-baby
  history it is **not**. Decide the tie-break and say so in the migration comment.
* `reminder_settings` writes are delete+insert **without a transaction** (`reminders_repository_impl.dart:139-155`);
  a composite PK makes a torn write more visible. Wrap it while in there.
* The v1.2.0 `(baby_id, item_id)` dismissal key must not make a dismissal of a *preset* apply to a
  newborn added later (the 4 h cooldown that motivated per-row scoping was deleted in v1.1.1, §5.2 —
  define the per-baby dismissal semantics in the migration either way).
* The home list must not become the new place where a 2×2 grid loses its tap target — `track_button.dart:128`
  exists because that already happened once.
* `anyBabyExistsProvider` is read by Home, Menu and onboarding; if §2 introduces a settled-state provider,
  keep one source of truth rather than a second boolean.
* **Measurements input ranges** — fix and lock in tests: weight 200–20 000 g, height 30–110 cm,
  temperature 33–42 °C (newborn → toddler). Out-of-range input must be rejected in the sheet, not
  stored and then explained in history. Weight is entered in grams (displayed in kg to 3 decimals
  above 1 000 g); height in cm to 1 decimal; temperature in °C to 1 decimal — **metric only, no °F**
  (three locales, two metric markets plus one optional; a unit toggle is a later feature, not v1.2.0).
* The latest-value subtitle on a measurement button must not reuse the reminder-pill mechanism
  (`track_button.dart:128-146` is capped at 3+"+N" and is reminder-owned); it is a distinct, smaller
  text line, and its absence (no measurement yet) must not read as an error state.
* The "Mesures" history screen and the v1.2.0 home reminders list (§4.1) both want the area below the
  grid — sequence them so one does not displace the other's scroll position (the home screen is
  already `SingleChildScrollView`-wrapped for exactly this reason).

---

## 9. Open UI defects (cosmetic) — items 9 + 10

Reported by Pierre-Vincent 2026-10-05 while reviewing build 1.1.1 on a physical device.

### 9.1 Item 9 — sleep slider: edit colour ≠ creation colour

* Creation: `DurationPickerDialog` themes the value text **and** the slider with `AppTheme.dodo`
  (blue) — `duration_picker_dialog.dart:80-93`.
* Edit: `EditEventDialog._buildDurationSection` embeds `QuantityPickerInline`, which hardcodes
  `AppTheme.miam` (yellow) — `edit_event_dialog.dart:218-234`,
  `quantity_picker_inline.dart:78,83-91`.
  → the same sleep duration is blue when created, yellow when edited.
* Fix direction: give `QuantityPickerInline` an `accent` parameter (default `AppTheme.miam`) and
  pass `AppTheme.dodo` from `_buildDurationSection`; value text and slider stay on the same accent.

### 9.2 Item 10 — feeding quantity slider vs the edit box

* Observation: the feeding quantity slider is not consistent with the edit box.
* On current main both creation (`FeedingTrackingDialog` → `QuantityPickerInline`,
  `feeding_tracking_dialog.dart:120`) and edit (`EditEventDialog._buildQuantitySection` →
  `QuantityPickerInline`, `edit_event_dialog.dart:236-253`) use the same widget, so the slider and
  big value already share the miam yellow on both sides. The visible clash is *inside* the edit
  section: the miam-yellow slider/value sitting above a `TextField` with the default grey
  `OutlineInputBorder` (`quantity_picker_inline.dart:99-108`).
* Before coding: reproduce on the submitted 1.1.1 build and pin down exactly which two elements
  clash (screenshot). Candidate fixes: theme the `TextField` border/focus colour with the section
  accent, or align the edit-section styling with the creation dialog.

---

## 10. Backlog — **unbucketed**, recorded 2026-10-02 from Pierre-Vincent's backlog list

Items 11–19, reported 2026-10-02. None is bucketed yet; each carries a **proposed bucket**
(recommendation only — the decision stays with Pierre-Vincent, as for §7). Items 1–10 and M are
unchanged; item 1 (sync) and item 8 (measurements) from the original backlog are already bucketed
in §3/§4.2.

### 10.1 Item 11 — age-conditioned reminders

* Reminders whose existence or frequency depends on the baby's age (e.g. a Vit. D stop date,
  new presets that appear only after a given age).
* Extends the §4.1 preset model; today only `vitamine_k`'s *frequency* is derived from the baby
  (`reminder_item.dart:26-84`).
* Directional overlap with the **withdrawn** item 2 — item 2 was a misread of the same mechanism;
  this one is a real feature. Needs a decision: which presets are age-bounded and by what rule
  (hardcoded cutoffs vs user-adjustable dates — the latter touches the custom-reminder model, item 4).
* Proposed bucket: **v1.2.0** (rides the reminder-model work of items 3+4) — or v1.3.0 if the
  rule turns out to need user-adjustable dates.

### 10.2 Item 12 — reminder notifications

* System notifications for due reminders. §0 verified: in-app banners only, **no**
  `flutter_local_notifications` in `pubspec.yaml`.
* Cost: one new local-only dependency (privacy-neutral — no network, no payload), a permission
  consent flow (iOS + Android, per AGENTS.md minimal-permissions: explicit, on first opt-in, not
  on launch), and a scheduling model aligned with the 5-minute poll (§0) or per-due-time local
  schedules.
* Proposed bucket: **v1.2.0 or v1.3.0** — the permission flow adds a store-review surface, so
  keep it out of a cosmetic v1.1.2.

### 10.3 Item 13 — add "bain" to hygiene

* New `HealthSubtype` `bain` alongside the existing six (4 nettoyages + vitD + vitK,
  `tracking_enums.dart:265-295`).
* `subtype_value` is a free string in the DB → **no migration**; the work is the enum constant,
  l10n ×3, an icon (`tracking_icons.dart:70` lists the cleaning set), and the health-form dropdown
  entry.
* Proposed bucket: **v1.2.0** (small, but it changes the settings UI — not v1.1.2 material).

### 10.4 Item 14 — +/− step buttons on sliders

* Explicit +/− buttons next to the duration/quantity sliders (`QuantityPickerInline`,
  `duration_picker_dialog.dart`) for precise input without dragging.
* UI-only, no schema change. Note: it shares surface with the §9 colour-consistency fixes — sequence
  them in the same release to avoid touching the same widgets twice.
* Proposed bucket: **v1.1.2 candidate** (UX, light gate) or **v1.2.0** if the slider surface churns
  there anyway.

### 10.5 Item 15 — add a brown caca colour

* New `CacaColor` `marron`. Today: exactly 4 (mécônium, vert olive, jaune moutarde, jaune clair —
  `tracking_enums.dart:160-185`).
* DB value is a string → new value is **backward-compatible, no migration**; work is the enum
  constant + hex, l10n ×3, position in the picker row, history swatch. Decide the hue (single
  `marron`, or two shades).
* Proposed bucket: **v1.1.2 or v1.2.0**.

### 10.6 Item 16 — pvj.io credit

* Add a "pvj.io" credit mention (Menu → à propos / credits area).
* Open: exact wording and placement (plain text vs tappable link — a link is still local-only, it
  just opens the OS browser).
* Proposed bucket: **trivial, any** — piggyback on the next release's store copy.

### 10.7 Item 17 — no scroll in landscape + half-screen box in portrait

* Reported wording: *« Pas de scroll en paysage + box moitié d'écran en portrait ».*
* **Not yet pinned to a screen.** Before coding: reproduce on the submitted 1.1.1 build and identify
  the affected surface (same procedure as item 10, §9.2). Prime suspects: a dialog/sheet that caps
  its height (half-screen box) and a list that stops scrolling when rotated.
* Proposed bucket: after reproduction — likely **v1.1.2** if cosmetic, **v1.2.0** if structural.

### 10.8 Item 18 — baby age not localized

* `baby_profile_section.dart:478-492` (`_formatBirthdate`) hardcodes **English** strings —
  `'$days days old'`, `'$months months old'`, `'$age years old'` — ignoring the active locale.
* Fix: l10n keys with count parameters for the three branches (en/es/fr); no schema change.
* Proposed bucket: **v1.1.2 candidate** (small l10n fix, light gate) or **v1.2.0**.

### 10.9 Item 19 — « littérature »: in-app reference guide

* Clarified 2026-10-02: static reference documentation for parents (first topic: **baby car seat**,
  « and all » — the article list is open).
* Fully local content (privacy: no network — bundled markdown assets), rendered with the existing
  `core/utils/markdown_parser.dart`, l10n ×3.
* Open questions before any bucket: scope of the initial article set, who authors/maintains the
  content, placement (Menu → « Guide »?), and the legal framing (informational, not medical advice —
  a disclaimer line, and it belongs in the in-app privacy/terms surface too).
* Proposed bucket: **its own feature** — v1.2.0 if the article set is small, v1.3.0 if it grows;
  content authoring, not code, is the critical path.

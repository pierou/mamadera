# ROADMAP — Reminders, multi-baby scoping, onboarding, two-phone sync

Status: **§2 shipped in v1.1.0+4 (2026-09-21) — the 5 decisions in §7 still await you.** Everything in §2 is implemented, tested and `make ci`-green; §1 is withdrawn; §3 onward is still proposal.
Opened 2026-09-20, while v1.1.0 was mid-flight (Phase 2B, Xcode Cloud).

Five requests came in together:

1. Synchronisation between two phones
2. "Vit. K reminder displaying every 14 in settings" → **withdrawn, see §1**
3. Show a list of reminders below the tracking buttons
4. Custom reminder detached of the health type
5. Refresh of reminders when reminders shown are modified in Settings
6. *(added later)* After wiping the DB and re-importing, the baby-creation popup is shown even though the backup contains a baby → **§2.1, v1.1.0**
7. *(added later)* Patch notes screen prints raw markdown (`### Nouvelles fonctionnalités`, `- bullet`) → **§2.2, v1.1.0** — and it has been printing since 1.0.0, see below

---

## 0. Verified state of the code (read this, do not re-derive)

| Fact | Evidence |
|---|---|
| Reminders are in-app banners only — no system notification exists | `RemindersService.checkDue` + `TrackButton` pills; no `flutter_local_notifications` in `pubspec.yaml` |
| Completion of every reminder today is **derived from `tracking_events`** | `reminders_repository_impl.dart:22-45` (`getLastCompleted`), `custom_reminder.dart:66` (`trackingType: TrackingType.sante` hardcoded) |
| Presets are 4 hardcoded items; only `vitamine_k`'s *frequency* is derived from the baby | `reminder_item.dart:26-84`, `buildForBaby` → `monthly(dayOfMonth: profile.birthDate.day)` |
| `dynamicRemindersProvider` falls back to Vit. D + rolling 30-day Vit. K with no profile | `reminder_providers.dart:43-52` |
| Custom reminders are stored, but `subtype_value` is **NOT NULL** and the care dropdown lists only the 6 `HealthSubtype`s | `app_db.dart:52-66`, `custom_reminder_form_sheet.dart:196-210` |
| Settings/create/edit/delete **do** invalidate the home notifier | `reminder_settings_notifier.dart:36`, `custom_reminders_notifier.dart:63-70`, `menu_screen.dart:334-341`, `import_providers.dart:173-186` |
| Due reminders re-evaluate on a **5-minute poll** and on active-baby change only | `reminder_notifier.dart:8`, `build()` watches `activeBabyProvider` |
| **No `WidgetsBindingObserver` / `AppLifecycleListener` anywhere in `lib/`** | `grep -rn "AppLifecycle\|didChangeAppLifecycleState\|WidgetsBindingObserver" lib/` → 0 hits |
| `RemindersService.dismiss()` has **zero callers in `lib/`** — the 4 h cooldown is dead code today | `reminders_service.dart:48`; the only `saveDismissalTime` caller is the service itself |
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
| **v1.1.1** | Item 5 (stale reminders), missing dismiss affordance | none | full patch gate |
| **v1.2.0** | Item M (baby scoping) + item 4 (detached custom reminders) + item 3 (home reminders list) | drift **v11**, `exportFormatVersion` **2** | full gate + migration test + patch notes en/es/fr + store copy |
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

## 4. v1.2.0 scope — the reminder model

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

## 5. v1.1.1 scope

* **Item 5 — stale reminders.** Reproduce before touching: the invalidation chain is correct on paper
  (§0). Suspect #1 is the *time* axis, not the settings axis: **no lifecycle observer exists**, so
  midnight rollover, the 4 h cooldown expiry and the month boundary only re-evaluate on the 5-min poll.
  Fix shape: an `AppLifecycleListener` calling `reminderNotifierProvider.notifier.refresh()` on resume.
  Suspect #2: whichever surface the new home list becomes, it must refresh live when Réglages changes —
  same pattern as §2: **no widget-local bool caching a provider fact.**
* **Dismiss affordance** — `RemindersService.dismiss()` is currently unreachable (§0). Wire it to the list,
  or delete the cooldown. Shipping dead code that promises a 4 h mute nobody can trigger is the worse option.

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
2. **Item 5**: can you reproduce it right after a toggle, or does it show up after the day/month rolls
   over? (Decides whether 1.1.1 is a lifecycle fix or a tree/invalidation fix.)
3. **Multi-baby semantics**: one merged list showing both babies (twins → two "Vit. D" lines), or the
   active baby only with a badge "1 reminder pending for Léa"?
4. **Detached custom reminder**: manual "done" only, or manual-with-event-latching (an event, when present,
   also completes it)?
5. **Sync**: is manual merge over the share sheet acceptable for v1.3.0, or do you want LAN — in which case
   the privacy mandate change must come from you, in writing, before any code.
6. **Dead `markdown` dep**: drop `markdown: ^7.2.2` in this release with §2.2 (after verifying nothing pulls
   it transitively), or defer to 1.1.1 to keep the in-flight lockfile untouched?

---

## 8. Open questions / risks to re-check when implementing

* Backfilling `(baby_id, item_id)` keys from a single-baby history is unambiguous; from a multi-baby
  history it is **not**. Decide the tie-break and say so in the migration comment.
* `reminder_settings` writes are delete+insert **without a transaction** (`reminders_repository_impl.dart:139-155`);
  a composite PK makes a torn write more visible. Wrap it while in there.
* Adding `baby_id` to dismissed reminders interacts with the 4 h cooldown: define whether a dismissal of a
  *preset* applies to a newborn added later (it must not).
* The home list must not become the new place where a 2×2 grid loses its tap target — `track_button.dart:128`
  exists because that already happened once.
* `anyBabyExistsProvider` is read by Home, Menu and onboarding; if §2 introduces a settled-state provider,
  keep one source of truth rather than a second boolean.

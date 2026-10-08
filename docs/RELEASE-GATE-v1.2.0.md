# Release gate pass — v1.2.0 (2026-10-07/08)

Emulator release-gate per `AGENTS.md`, run on branch `feat/v1.2.0-growth-and-baby-scoped-reminders`
at `dd79a4f` (pubspec `1.2.0+9`). Debug APKs both sides (release signing lives in CI).

## 1. Migration path v10 → v11, on a device that had old data

**Small_Phone (emulator-5554, Android 17 / API 37, 720×1280):**

1. Fresh `adb install` of **v1.1.1** (`v1.1.1` tag worktree, debug) → onboarding (baby **Luna**).
2. Seeded via the v1.1.1 UI: feeding (breast milk 130 ml), sleep (30 min), diaper (poop),
   health care (eye cleaning — which cleared the Eyes pill), custom reminder **NailCare**
   (linked care Nose Cleaning), and disabled presets **Vit. D + Vit. K**.
3. DB pulled via `run-as` and verified a genuine v10 baseline: `PRAGMA user_version = 10`,
   `reminder_settings(item_id, enabled)` 2 rows, `custom_reminders(id, label, subtype_value NOT
   NULL, frequency, interval_days)` 1 row, no `measurements`, no `reminder_completions`.
   One `reminder_dismissals` row inserted directly (v1.1.1 has no UI write path for it) — app
   relaunched clean over it before upgrading.
4. `adb install -r` of **v1.2.0** (`1.2.0+9` debug) over it. App launched; patch-notes dialog
   showed **1.2.0** (not the stale 1.1.0 seen on earlier reinstalls).

Post-migration DB (pulled, `/tmp/pass/m11-final.db`):

| Check | Result |
|---|---|
| `PRAGMA user_version` | **11** |
| `measurements`, `reminder_completions` | created |
| `reminder_settings` re-keyed `(baby_id, item_id)` | `vitamine_d=0`, `vitamine_k=0` preserved under `baby_id=''` |
| `reminder_dismissals` re-keyed | `nettoyage_yeux` row preserved under `''` |
| `custom_reminders` rebuilt (nullable `subtype_value`, `completion_source`) | `NailCare` preserved **with `id=1`** — kill-switch key `custom_1` intact |
| `tracking_events` | all 4 seeded rows intact |

History on the upgraded app showed all old events (Eye Cleaning, Poop, Feeding 130 ml,
Sleep 30 min).

**Pixel_10_Pro (emulator-5556, 1280×2856)** — same path independently: fresh v1.1.1 → onboarding
(baby **Nino**) → feeding 120 ml + diaper + sleep via UI → `install -r` v1.2.0 → patch notes
1.2.0 → all three events visible in History. Weight 3500 g recorded post-migration (tile shows
"3.5 kg").

## 2. Manual entry + export on v1.2.0 (Small_Phone)

- Weight **3510 g** via `+` stepper (10 g step confirmed) → `measurements` row (encrypted at rest,
  decrypted on export), tile shows 3.51 kg.
- Feeding **120 ml**, sleep **35 min** (5-min step) — both appear in History (6 events total).
- Detached custom reminder **Bath** ("No care" option → `completion_source='manual'`,
  `subtype_value=NULL`) → appears on Home with **Mark as done** (D2: presets linked to a care
  deliberately have no check button) → tap writes `reminder_completions(baby_id=Luna,
  custom_2)` and clears the row.
- Export → confirm dialog ("nothing is sent automatically") → OS share sheet with
  `mamadera-export-20261007-232806.json`. Pulled and inspected: `exportFormatVersion: 2`,
  `databaseSchemaVersion: 11`, counts `{babyProfiles:1, trackingEvents:6, customReminders:2,
  reminderSettings:2, reminderDismissals:1, measurements:1, reminderCompletions:1}` — every
  section present and correct.

## 3. Screenshots

Small_Phone: `60` home, `61` history, `62` weight sheet, `67` reminder list, `77` growth,
`78` reminder settings, `65/66` share sheet. Pixel_10_Pro: `70` v1.1.1 home (the old **+2**
pill, pre-upgrade), `71` v1.1.1 history, `72` patch notes 1.2.0, `73` v1.2.0 home (reminder
list replaces "+2"), `74` history, `75` after weight, `76` growth.
Committed subset: `70`, `73`, `72`, `67` + final export JSON in `docs/release-evidence/v1.2.0/`.

## 4. Findings worth recording (all by-design, none blocking)

1. **Upgraded installs reset reminder state to defaults.** v1.1.1 was global-keyed; v1.2.0 reads
   strictly per baby (`_visibleScopes`: "la ligne du bébé, rien d'autre"). Old rows survive under
   `baby_id=''` and still export, but are not surfaced to a real baby's Home/settings — so a user
   who had Vit. D off in v1.1.1 sees it due again after upgrading, and old custom reminders leave
   Home. Documented in `reminders_repository_impl.dart` and in the patch notes ("Keep reminders
   independent per baby"). Owner may want a dedicated "starting fresh with baby profiles" note.
2. Patch-notes `releaseDate` says `2026-10-03`; update at actual ship date if desired.
3. v1.1.1 reinstall shows patch notes "1.1.0" (its asset shows the last-authored older entry);
   v1.2.0 upgrade correctly showed 1.2.0. Cosmetic, reinstall-only path.
4. Downgrade install (older build over newer schema) leaves the newer schema with a stamped-down
   `user_version` — test artifact, store blocks downgrades; no release action.
5. CI before this pass: analyzer clean, **1346 tests green**, coverage 88 %
   (`/tmp/mamadera-ci-v120.log`).

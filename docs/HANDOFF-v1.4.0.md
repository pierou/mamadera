# HANDOFF — v1.4.0 execution state (written 2026-11-17)

Resume document for a fresh session. `docs/PLAN-v1.4.0.md` remains the **release source of
truth** (D-R1…D-R11 decisions, M1…M9 milestones); this file records *where the work physically
is*, what was decided beyond the plan, and the traps already paid for. §9 of the plan holds the
per-milestone narrative; this file is the short version plus the resume instructions.

## 1. Where we are

| | |
|---|---|
| Branch | `release/v1.4.0`, cut from `origin/develop` — **8 feature commits + this handoff, working tree clean, nothing pushed** |
| Range | `git diff --stat origin/develop..HEAD` → 113 files, +10 958 / −735 |
| Milestones | **M1 ✅ M2 ✅ M3 ✅ M4 ✅ M5 ✅** · **M6 in progress (3 of 7 tickets: B9, B13, B16)** · M7 M8 M9 not started |
| Schema | `AppDatabase.schemaVersion = 14` (`lib/data/local/app_db.dart`) — the one and only v1.4.0 bump |
| Export | `_exportFormatVersion = 5` / importer `_supportedFormatVersion = 5` — the one and only bump |
| pubspec | still `1.3.2+16` on purpose — **M7** bumps to `1.4.0+17` |
| Pushed | **yes** — `origin/release/v1.4.0` exists, no PR opened, `develop` untouched |
| Gates at HEAD | `flutter analyze --fatal-infos --fatal-warnings` clean · `flutter test` **1695 passed** · coverage **84 %** · `make check-architecture` ✅ (`presentation_to_data` 2, `oversized_files` 0) · `make check-complexity` ✅ (3 over cap, baseline 4) |

```
270af3f fix(sleep): a nap carries its minutes once (B13)              <- M6 item 2
67c9963 feat(baby): the home title opens the baby switcher (B9)       <- M6 item 1
c656514 feat(notifications): a cross-baby tap selects that baby       <- owner decision on B15
2481548 feat(notifications): the tap lands on Home and means … (M5)
c1303cd feat(reminders): preset overrides, removal and the end picker (M4)
2b844f1 feat(reminders): one-shot frequency + the end model (M3)
8a824f7 feat(reminders): per-reminder notification hour (B30, M2)
fe8f774 feat(reminders): schema v14 + per-item enabled default (B6, M1)
```

## 2. Resume here — M6, three-and-a-half tickets left

M6 is **schema-free and independent**; the plan (section "M6 — The small batch") fixes the order
and each item is **its own commit**. Done: B9, B13, B16, B17. Remaining, in order:

3. ~~**B16**~~ ✅ done — one optional `TextField` at the foot of the feeding sheet
   (`ValueKey('feeding-note-field')`), `null` when empty so the row stores an absence, reusing
   `editNotesLabel`/`editNotesHint` so **no new l10n key** was needed. Its ticket item 2
   (Small_Phone screenshots, keyboard up) joins the M9 device-pass list.
4. ~~**B17**~~ ✅ done — one magnitude (`selectionClick`) in `show_feedback.dart` for every
   committed insert, plus `showFeedback` on the custom-reminder create/edit path with
   `reminderCustomAdded`/`reminderCustomUpdated` in three locales. **Done/Snooze and TrackButton
   press-feedback were deliberately left out** — the ticket requires feeling them on a handset,
   and its "Do not" forbids bundling press feedback. New keys need **`make l10n`** (not
   `make codegen`): build_runner does not regenerate `app_localizations*.dart`.
5. **B29 — history filter pills adopt the home track-button design.** One style block, one screen
   (`lib/features/history/presentation/screens/history_screen.dart`).
6. **B7-remainder — the `HistoryFilter.measurements` chip.** The enum value already exists and
   already feeds the merged timeline; this is chip + filter wiring only.
7. **B27 — the flush at the invalidation site** (post-restore Home mount schedules a provider
   refresh during build) **+ remove the `[GATE] B27 recorded` tolerance** from
   `integration_test/gate_v131_restore_onboarding.dart` so the gate asserts what it used to count,
   **+ the device pass in M9**. B27 is last in the batch precisely because it needs the device.

Then **M7** (l10n sweep of everything M1–M6 introduced, `make codegen`, patch notes per D-R11 in
the noun form for fr/es with **no clinical claims**, `pubspec.yaml` → `1.4.0+17`,
`make store-check`), **M8** (`make ci` + the named release assertions the plan lists — most
already exist as tests, see §9 of the plan), **M9** (the emulator release gate, before the PR).

## 3. Owner decisions taken outside the plan (do not re-litigate, do not re-ask)

1. **B15 cross-baby tap ⇒ switch to that baby** (`c656514`, 2026-11-17). The first cut of M5
   stopped a treatment-linked tap from a non-selected baby at Home. The owner chose the other
   branch: `NotificationTapHandler._act` calls `activeBabyProvider.notifier.switchProfile(scope)`
   **before** settling or asking for the care sheet. Two edges are deliberate and tested: the
   profileless `''` scope **cannot** be selected (there is no profile to select), so that one case
   still stops at Home with a log line; and a tap for the already-selected baby never calls
   `switchProfile` (that write deactivates every profile and rebuilds the dependent tree).
2. Nothing else. Everything else in M1–M5 followed `PLAN-v1.4.0.md`.

## 4. What each milestone actually put where (orientation, not a changelog)

* **M1** — v14 adds eight nullable `reminder_settings` columns (`time`, `label`, `frequency`,
  `interval_days`, `frequency_date`, `end_date`, `end_age_months`, `removed`) and the Vitamin D
  seed. **M3** added one more to v14 while it was still unreleased:
  `custom_reminders.frequency_date` (appended last, for trap 5). B6 rule: "no row" ⇒ `ReminderItem.enabledByDefault`, never "enabled".
  `test/data/local/schema_sql_replay_test.dart` guards `schema.sql` against `app_db.dart`.
* **M2** — B30 hour in `reminder_settings.time` (strict `HH:mm`, `NULL` = inherit).
  `ReminderScheduler.sync` is split into `sync` / `_buildPlan` / `_applyDiff`;
  `_timeOfDayFor` resolves the effective hour. `setEnabled` became a **column-scoped upsert** —
  it used to delete-and-reinsert and erased a stored hour.
* **M3** — `OneTime` frequency + `one_time` code, `lib/core/utils/date_arithmetic.dart`
  (`addMonthsClamped`, `wholeMonthsOld`), `lib/core/utils/calendar_date.dart`
  (`parseCalendarDate` = local midnight, `formatCalendarDate`), `reminder_end.dart`
  (`reminderEndFor`, `isPastSeriesEnd`, `seriesEndExpiry`, `maxReminderEndAgeMonths = 180`).
  Vitamin K is `OneTime(birth + 1 month, clamped)`; the profileless fallback keeps
  `CustomInterval(days: 30)` (D-R10). `nextDueAt` returning **null** is the only removal
  mechanism — the plan diff cancels the OS entry.
* **M4** — `effectiveItemsForScope` (`domain/services/effective_reminders.dart`) is the **single**
  place overrides/removal/end-resolution happen; its three callers are
  `ReminderScheduler._buildPlan`, `enabledRemindersProvider`, `ReminderSettingsScreen`. It
  deliberately does **not** apply `enabled` (Settings must show a switched-off reminder).
  Writers: `setItemLabel` / `setItemFrequency` / `setItemEnd` / `setItemRemoved`, all through
  `_upsertOwnColumns`. UI: `_PresetMenu`, `PresetReminderEditSheet`, `ReminderEndPicker`,
  `_RemovedSection`, `reminder_display_name.dart`. Importer split:
  `import_repository_reminder_parsing.dart` (a `part` of the importer) because of the 800-line
  ratchet.
* **M5** — `notification_payload.dart` (`ReminderNotificationPayload`, JSON `{"b":scope,"i":id}`),
  payload on every `scheduleAt`/`scheduleIn` and part of the plan-diff equality;
  `FlutterLocalNotificationService({onNotificationTapped})` registered in `init()`;
  seam at `localNotificationServiceProvider` (`watch` + `handler.handle`);
  `NotificationTapHandler` (Home first, then settle or ask);
  `pending_care_sheet.dart` (`take()` drains atomically); `HomeScreen` consumes it via
  `_showHealthSubtypeSheet` (extracted so the "+" button and the tap share one flow) and
  `HealthSubtypeDialog(initialSubtype:)`.
* **M6.1 B9** — `lib/features/baby/presentation/widgets/baby_picker_sheet.dart`
  (`showBabyPickerSheet`, `BabyPickerSheet`) opened from the Home `AppBar` title;
  `add_baby_dialog.dart` (`showAddBabyDialog`) extracted out of `baby_profile_section.dart`.
* **M6.3 B16** — the note is now asked at creation; `_notesOrNull()` in
  `feeding_tracking_dialog.dart` owns the empty ⇒ `null` rule, and the UI never encrypts.
* **M6.2 B13** — `SleepEvent` has **no** `quantity` field; insert leaves the column absent, the
  history update **clears it** (`Value(null)`), the edit dialog's duration picker writes
  `duration` only. Zero migration; legacy mirrors stay, unread.

## 5. Traps already paid for (each of these cost a cycle)

1. **Riverpod 3 disposes an unwatched provider.** A notification tap does its work *after* the
   plugin callback returned; the first draft died on
   `Cannot use the Ref of Provider<NotificationTapHandler> … after it has been disposed`.
   The anchor is `ReminderLifecycleSyncWidget.build`, which `ref.watch`es
   `notificationTapHandlerProvider` (it is mounted above the router for the life of the app),
   and `_act` checks `_ref.mounted` after every await. **Any future fire-and-forget provider work
   needs the same anchor.** In tests, `container.listen(provider, (_, __) {})` is the equivalent.
2. **`const Object()` sentinels are canonicalised.** Two `const Object()` markers are the **same
   instance**; a "no profile" case silently ran *with* one. Use distinct private marker classes.
3. **`ReminderItemSetting` mirrors the columns** (`endDate` is `'yyyy-MM-dd'` text,
   `endAgeMonths` an int) while `ReminderItem.endsAt` is a `DateTime`. One spelling on disk
   (`formatCalendarDate` in, `reminderEndFor` out); `effectiveItemsForScope` is the resolution
   point. It is a **freezed** class — `copyWith` takes the raw column types.
4. **End inclusivity lives in the scheduler, not the resolution**: `reminderEndFor` returns the
   end **day at midnight**; `isPastSeriesEnd` / `seriesEndExpiry` in `reminder_end.dart` let the
   whole end day through. Do not "fix" the midnight.
5. **`schema.sql`**: a comma after a `--` comment is inside the comment (SQLite).
   `make codegen` + `schema_sql_replay_test` catch it; new columns must be **appended**
   (`ALTER TABLE` appends, and the parity test compares column order).
6. **Lizard's Dart parser** misattributes `ReminderScheduler`'s methods to its constructor, which
   is why `Makefile`'s complexity baseline is 4 with a documented artifact note. Real fix if you
   touch it: extract `_applyDiff` into its own type and drop the baseline to 3 (M6 B13 already
   brought the count to 3 over cap without touching that entry).
7. **Lazy `ListView` in widget tests**: a section below the fold is simply not built. The
   reminder settings screen asserts `findsAtLeastNWidgets(4)` rather than an exact count, and the
   opt-in group has a `revealOptIn(tester)` helper — use it before touching a below-the-fold row.
8. **`ProviderScope.overrides` element type (`Override`) is not exported** by
   `package:riverpod/riverpod.dart` in 3.x, so a test helper cannot take an extra-override
   parameter. This file's idiom is a per-group pump (see `pumpHomeWithCareRequest` in
   `home_screen_test.dart`).
9. **Architecture ratchet** (`scripts/check_architecture.py`, baseline
   `scripts/architecture_baseline.json`, `--update` to re-lock): `domain/` must not import a
   framework package — which is why `ReminderNotificationPayload` has **no** `==`/`@immutable`
   (the lint would need `meta`/`foundation`). `presentation_to_data` was **lowered 4 → 2** in M5
   via `ReminderItem.isDetached`; prefer shrinking it over raising it.
10. Doc-comment `[references]` to a record-typedef field or to a type not imported raise
    `comment_references` under `--fatal-infos`. Use backticks.

## 6. Commands

```bash
flutter analyze --fatal-infos --fatal-warnings   # gate 1 (must be clean, infos included)
flutter test                                     # 1690 at HEAD
make check-architecture                          # ratchet, may only shrink
make check-complexity                            # baseline 4 (see trap 6)
flutter test --coverage && make check-coverage   # ≥ 80 %
make codegen                                     # after any freezed/drift edit (M6 B13 needed it)
```

## 7. Outstanding obligations, stated plainly

* **The emulator pass has not been run for M1–M6.** AGENTS.md makes it a pre-PR gate; the
  M9 checklist in the plan is the script. It must cover at least: the v13→v14 upgrade on a device
  that holds old data; every touched screen on `Small_Phone` (M4 changed row layouts — the hour
  subtitle now wraps); the manual entry → export → inspect-JSON path (format 5 carries the whole
  settings row); **B22's five tap cases** (alive / recents / killed / icon-launch / autoCancel),
  which no widget test executes; B27's post-restore gate; and the D-R7 known-noise case — a
  one-shot Vitamin K on a two-year-old's Home reads as overdue until settled or switched off,
  which is the behaviour the owner approved, not a bug.
* Branch is pushed to `origin` as of 2026-11-17 (no PR). Re-push after each new commit if a
  session boundary is near — the branch is the only copy of the release.
* Deliberate non-work, recorded rather than forgotten: the store listing is untouched (M7 only
  re-verifies `make store-check`); Phase A sync stays v1.5.0 and its schema/export numbers were
  **not** pre-empted here.

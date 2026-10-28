# PLAN — Item 12: background-capable reminder notifications (`1.3.0+12`, drift schema v13, export format v4)

Status: **OPEN — v1.3.0 candidate**. Owner decisions recorded 2026-10-25:
1. **Background-capable** scheduling (local OS notifications via `flutter_local_notifications` +
   `timezone`), not poll-only.
2. **Bucket: v1.3.0** — "quite big" (two new dependencies, a permission flow, a migration, an
   export-format bump). Not v1.2.2.
3. **Scope: all babies** (D6) — every baby profile gets its own notifications, not only the
   active baby.

Executes `docs/ROADMAP-reminders-and-sync.md` §10.2 (item 12). Written 2026-10-25 against
`1.2.1+11` @ `origin/develop` (post F-Droid work, `409fa65`).

This file is the **only** input an implementer gets. Everything needed is here: verified current
state, target signatures, exact scheduling semantics, verification commands. Do not re-derive what
is already asserted below; do not invent what is not asked.

---

## 0. How to use this file

Implement **one milestone at a time, in order** (M1 → M8). Each milestone ends green and is
committed separately. Never batch two milestones into one commit.

After every milestone, run and report verbatim:

```bash
flutter analyze --fatal-infos --fatal-warnings    # must be clean
flutter test <the directories you touched>/       # must be green
```

Run the **full** gate (`make ci`) only at M8. If a step's instruction contradicts the code you are
reading, **STOP and report the contradiction** — do not improvise a different design, and do not
"fix" an unrelated thing you noticed (note it in your report instead).

Report per milestone: files created, files modified (with the diff of each non-new file), the exact
commands you ran and their output tail, and anything you could not do.

### Hard rules (from `AGENTS.md`, non-negotiable here)

- **No analytics, no telemetry, no crash reporting, no network transport of any kind.** The two
  new dependencies in M1 (`flutter_local_notifications`, `timezone`) are the **only** exception to
  "no new dependency" in this repo's release cycle, and they are privacy-neutral: local-only
  scheduling, no network, no payload leaves the device. Do not add anything else.
- **Minimal permissions**: the notification permission is requested **only** when the user flips
  the opt-in switch. Never at launch, never implicitly, never as a side effect of creating a
  reminder.
- **Encryption at rest** is untouched: notifications carry label + baby name only (both already
  plaintext in the DB — `custom_reminders.label`, `baby_profiles.name` — and nothing encrypted is
  read on the scheduling path).
- Comments in `lib/` are in **English**; new test names in **English**.
- Conventional Commits: `feat(...)`, `fix(...)`, `chore(...)`, `security(...)`.
- **Corrupted docstrings**: the blocked fr→en pass
  (`docs/PLAN-fr-comments-to-english.md`, stage 1) left broken docstrings in several reminder files
  — mixed French/English fragments and nonsense sentences (e.g.
  `reminder_notifier.dart` ~L49: *"Wait for the five-minute scan to complete. Do not press any
  buttons."*). Where this plan edits a file, **rewrite the corrupted docstrings in that file** as
  accurate English describing what the code actually does. Do not extend the cleanup to any other
  file.

### Do NOT touch (explicitly out of scope)

| Out of scope | Why |
|---|---|
| Per-reminder notification times | One app-level time (D1). Per-item times multiply UI surface for no user benefit in v1.3.0. |
| Repeating / escalating notifications, "still due?" nudges | One notification per due window (D7). KISS. |
| Sound / channel / badge customization UI | Single fixed channel, default sound, **no badge** (D7). |
| Deep links from the notification | Tap opens the app at the root (Home). No router wiring in v1.3.0. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Not requested; exact alarms are Doze-exempt. Asking for battery-optimization exemption is a store-review surface we do not need. |
| Two-phone sync (roadmap §6) | Still blocked on the written privacy-mandate change. Notifications share **no** state with sync. |
| Rewriting corrupted docstrings outside the files this plan edits | Tracked in `PLAN-fr-comments-to-english.md`. |
| `reminder_dismissals` / `reminder_completions` semantics, `isDue` | `nextDueAt` **reuses** `isDue`'s invariants; it never changes them. |
| `HistoryFilter` / `TrackingType` / growth | B7/B8, separate tickets. |

---

## 1. Verified current state (do not re-derive)

| Fact | Evidence |
|---|---|
| `pubspec.yaml` `version: 1.2.1+11`, `sdk: ">=3.4.0 <4.0.0"`, `flutter: ">=3.44.0"` | `pubspec.yaml:17,21-23` |
| `AppConfig.version = '1.2.1'`, CI hard-checks it against `pubspec.yaml` | `lib/core/config/app_config.dart:10`, `.github/workflows/ci.yml` version-sync job |
| `schemaVersion => 12`; tables: `BabyProfiles`, `TrackingEvents`, `ReminderDismissals`, `ReminderSettings`, `CustomReminders`, `Measurements`, `ReminderCompletions` | `lib/data/local/app_db.dart:47-136,151`; DDL reference `lib/data/local/schema.sql` |
| **No `app_settings` table exists** — there is nowhere to persist the opt-in today | grep of `app_db.dart` |
| Every reminder table keys on `baby_id TEXT NOT NULL` with the `''` sentinel `db_const.sharedBabyId` | `app_db.dart:47-136`, `db_constants.dart` |
| Export writes `exportFormatVersion: 3` (literal), sections `babyProfiles`, `trackingEvents`, `customReminders`, `reminderSettings`, `reminderDismissals`, `measurements`, `reminderCompletions` + counts | `export_repository_impl.dart:49,76,84-128` — *baseline at plan time; M7 moved this to 4 with an `appSettings` section* |
| Import supports exactly `_supportedFormatVersion = 3`; strict per-section row validation; replace-only restore in one transaction with a fixed delete order | `import_repository_impl.dart:19,83-116,641-642` |
| Presets: `vitamine_d` (Daily), `vitamine_k` (Monthly(birth day) via `buildForBaby`, CustomInterval(30) fallback without profile), `eye_cleaning` (Daily), `face_cleaning` (Daily) | `reminder_item.dart` (`ReminderItemPresets`) |
| Custom reminder ids: `'custom_<autoIncrement id>'`; weekly is **hardwired `dayOfWeek: 1`** (Monday) by the current form | `custom_reminder.dart:61,114`, `reminders_repository_impl.dart:277-290` |
| `isDue` semantics: Daily = any calendar day other than lastCompleted's day; Weekly = ISO week strictly after lastCompleted's week (`_weekIndex`); Monthly = calendar month strictly after lastCompleted's month, gated on `now.day >= clamped dayOfMonth`; CustomInterval = ≥ n whole days elapsed | `reminder_frequency.dart:50-98` |
| In-app delivery: `Timer.periodic` 5-minute poll in `RemindersNotifier`, `RemindersService.checkDue` with 24 h dismissal window (`snooze`); completion via events or `reminder_completions` | `reminder_notifier.dart:13,63`, `reminders_service.dart:13-56` |
| Reminder state is **already per-baby** in the DB: `custom_reminders.baby_id` NOT NULL, default `''` (sentinel = created without a profile, *visible only without a profile*); `reminder_settings` / `reminder_dismissals` / `reminder_completions` keyed by `(baby_id, item_id)`; every read takes a `{String? babyId}` scope and the impl maps `null` ⇒ `''` (`_scope` / `_visibleScopes`) | `app_db.dart:79-106`, `reminders_repository_impl.dart:25-35` |
| No-profile item set: `dynamicRemindersProvider` ⇒ profile exists ⇒ `buildForBaby(profile)` (vitamin K's monthly day = **that baby's** birth day); no profile ⇒ base `[vitamineD, vitamineK]` (vitamin K = 30-day interval); customs map through `CustomReminderPresets.forCustom(reminder, monthlyDay: activeProfile?.birthDate.day)` | `reminder_providers.dart` (`dynamicRemindersProvider`, `customReminderItemsProvider`) |
| `BabyProfileRepository.getAllProfiles()` exists; the drift query orders by **name ascending** | `baby_profile_repository.dart:10`, `app_db.dart:432-435` |
| Profile add/remove happens in exactly three presentation places — `onboarding_dialog.dart:213`, `baby_profile_section.dart:281` (insert), `:449` (delete); **no profile-list Riverpod provider exists** (`baby_profile_providers.dart` holds only the repository `FutureProvider`) | grep 2026-10-25 |
| **No system notification exists anywhere** — no `flutter_local_notifications` in `pubspec.yaml`, zero `displayNotification`/`zonedSchedule` hits in `lib/` | grep 2026-10-25; roadmap §0 line 23 |
| **The shipped UI copy promises the absence of this feature**: `reminderSettingsDescription` = "…No system notifications are sent: everything stays on this device." | `lib/l10n/app_en.arb:153` (fr/es carry the same claim) |
| **No `WidgetsBindingObserver` / `AppLifecycleListener` anywhere in `lib/`** — a resume hook must be added, it does not exist | roadmap §0 line 30 |
| `main.dart`: splash preserve → `runApp(ProviderScope)` → `MyApp` (ConsumerWidget), splash removed in a post-frame callback; no lifecycle handling | `lib/main.dart` |
| Android: `minSdk = flutter.minSdkVersion`, `compileSdk = flutter.compileSdkVersion` (no pinned numbers) | `android/app/build.gradle.kts:30,40-41` |
| Dependencies available (pub.dev, checked 2026-10-25): `flutter_local_notifications` **22.3.2** stable (23.x is dev-only), `timezone` **0.11.2** | `https://pub.dev/api/packages/{flutter_local_notifications,timezone}` |
| Store source makes **no** notification claim: zero hits for "notification" in `store/source/en/` → nothing to retract in the listing; the only retraction is the in-app string | grep 2026-10-25 |
| l10n: 3 ARBs (en/fr/es, 472 lines each, identical key sets), generated `app_localizations*.dart` **committed**, **no `make l10n` target** — regenerate with `flutter gen-l10n` | `l10n.yaml`, `Makefile` |
| Migration test harness template: `_RawSqlDatabase extends GeneratedDatabase` + on-disk temp `.db` + raw v-N DDL seed, then open `AppDatabase` | `test/data/local/migration_v9_to_v10_test.dart` |
| Patch notes: `assets/patch_notes/{en,fr,es}.json`, map keyed by version string; **fr/es items in noun form** ("Mise à jour de…", "Ajout d'une…", "Correction de la…" / "Actualización de…", "Adición de…", "Corrección de…") | `assets/patch_notes/en.json`, `AGENTS.md` |
| F-Droid: MR [!53740](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/53740) pending — the 2026-10-24 review round was addressed and the pipeline is green on the pinned commit; `Builds:` is currently single-entry `1.2.1 / 11` | `docs/fdroiddata/README.md` |
| `make test` runs `test/shared/ test/data/ test/presentation/ test/features/ test/core/ --coverage`; coverage gate ≥ 80 % excluding `lib/l10n/*`, `*.g.dart`, `*_freezed.dart` | `Makefile` |

### 1.1 Traps, already paid for — respect them

1. **`NULL` in composite keys**: SQLite lets `NULL` live in a table-level composite PRIMARY KEY and
   repeat it. Every new table column that participates in a key is `NOT NULL`; the `''` sentinel
   means "applies to every baby" (see §1 fact table). `app_settings` has no baby dimension, so no
   sentinel is involved — but the key column is still `NOT NULL`.
2. **String `hashCode` is not stable across runs/platforms** — it must never be used as a
   notification id (it would silently change the id and break the diff). D5's plan-index ids are
   pure enumeration — no hashing anywhere; see the D5 rationale for why per-baby arithmetic
   schemes were rejected.
3. **A new exported table without a version bump is a broken backup**: adding `appSettings` to the
   export bumps `_exportFormatVersion` **and** `_supportedFormatVersion` to 4 in the same commit,
   or old apps importing a new export (and vice versa) mis-parse the document. `AGENTS.md`
   states this rule; M7 enforces it.
4. **The in-app string promises the opposite of this feature** (`app_en.arb:153`). Shipping M1–M6
   without the M6 rewrite would make the settings screen lie. The rewrite is inside M6, not after.

---

## 2. Decisions

Owner-confirmed (2026-10-25): **D0** background-capable; **D0'** bucket v1.3.0; **D6** all babies.
The rest are
recorded here so the next person can re-decide instead of re-discover; change one only by editing
this section and the affected milestones.

| # | Decision | Rationale |
|---|---|---|
| D1 | **One app-level preferred time** (`notification_time_of_day`, default `09:00`), user-settable via a plain `showTimePicker` row. A midnight fire for "Vitamin D" is bad UX; a per-reminder time is UI surface we don't need. | §10.2 said "scheduling model aligned with the poll or per-due-time local schedules" — per-due-time with a preferred time-of-day is the only variant that fires at a humane hour. |
| D2 | **Reconciliation model: the DB is the source of truth; OS schedules are a derived cache.** One `ReminderScheduler.sync()` = diff the new plan against the previous plan: cancel dropped ids, (re)schedule changed ones, **skip unchanged ones** (steady-state 5-min poll with many babies ⇒ zero plugin calls). Called: on app start, on app resume, on every 5-min poll tick, and after every mutation (toggle, create/edit/delete custom, `markDone`, `snooze`, **add/delete a baby profile** — baby *switch* is no longer a trigger, D6). | Scheduled local notifications are lost or stale across app updates (iOS), OS-level permission revocations, and clock changes. Re-deriving from the DB on every resume is cheap (bounded number of ids) and makes all of those non-bugs. |
| D3 | **Catch-up, once per process.** If an item is already due at sync time (due window open, not suppressed), schedule a short 60 s notification instead of waiting for the next day's preferred time. Guarded by an in-memory `Map<String, int>` keyed `'$scope::$itemKey::$periodDay'` in the scheduler, where `$periodDay` is the day returned by `duePeriodStart` (§3.4) — **the period, not the day of the nudge**: a daily item that stays overdue keeps returning "now" from `nextDueAt`, so a key without the period would either re-nudge every 5-minute tick or, once forgotten, never nudge again; keyed on the period it nudges once today and again tomorrow. No escalation. | A parent who closed the app all morning must hear about the missed vitamin D — but one nudge, not a barrage. Several *distinct* items due at once each fire once (information, not a barrage — no staggering); what is banned is repeating the *same* item. Cost of the guard: an app restart within the same due window can nudge once more — bounded, documented (R12). |
| D4 | **Storage: new `app_settings(key TEXT NOT NULL, value TEXT NOT NULL)` table**, schema v13 (pure `CREATE TABLE`, additive, no rebuild/rekey). Keys: `notifications_opt_in` (`'0'`/`'1'`), `notification_time_of_day` (`'HH:mm'`, missing ⇒ `09:00`). | There is no general settings table today (verified §1). A two-row key/value table is the smallest surface; it is future-proof for the next preference without another migration. |
| D5 | **Notification ids are plan indices: `1..N`** over the enumeration in §3.5 **for the scheduled entries** (profiles in `getAllProfiles()` name order; per profile: preset slots in fixed order, then customs by dbId ascending; sentinel scope when profileless). Catch-up nudges take ids from a separate band (`catchUpIdBase = 10000`, allocated monotonically and held in `_catchUpArmed`) — see §3.2 for why sharing the index space was unsound. With D2's diff, ids only need to be **deterministic within the current state** — a baby rename shifts the order once and triggers one harmless reschedule burst (R11). | Trap 2 still applies: no `hashCode`. A per-baby arithmetic scheme (`100 × babyOrdinal + slot`) collides with the custom range (`1000 + dbId`) as soon as there are ≥ 10 babies — enumeration removes the arithmetic, and the catch-up band sits above all of it. |
| D6 | **All babies (owner decision 2026-10-25).** `sync()` covers **every** baby profile, each with its own item set: presets built for **that** profile (vitamin K's monthly day = its own birth day), its own custom reminders, its own settings/completions/dismissals — all reads scoped per baby exactly like `RemindersService.checkDue` does today. The profileless `''` scope is scheduled **only when no profile exists** (mirroring the in-app visibility rule). Baby switching is no longer a sync trigger; **adding or deleting a profile is**. | The reminder state is already per-baby in the DB (v11 re-key, §1); scoping notifications to the active baby would silently miss siblings. The body carries the baby's name (§5), so any baby's notification is unambiguous. |
| D7 | **One fixed channel** `reminders` (default importance, sound on, no badge), default tap = open app at root. No sound/channel UI, no deep link. | KISS; store-review surface is the constraint, not capability. |
| D8 | **Opt-in semantics.** Switch defaults OFF. ON ⇒ `ensurePermission()` (runtime request on Android 13+ / iOS; no-op grant below Android 13) ⇒ persist `notifications_opt_in='1'` ⇒ `sync()`. Denied ⇒ switch stays OFF, inline hint shown, nothing persisted as ON. OFF ⇒ persist `'0'` + `cancelAll()`. On start/resume: if app-opt-in is ON but the OS permission is now denied (user revoked in system settings) ⇒ `cancelAll()` + persist `'0'` (the switch silently reflects reality). | AGENTS.md: explicit consent, never at launch. |

---

## 3. Target architecture

### 3.1 New files

```
lib/features/reminders/domain/services/reminder_scheduling.dart        # M3 — pure nextDueAt
lib/features/reminders/domain/services/reminder_scheduler.dart         # M5 — sync() orchestration (pure Dart, interfaces only)
lib/features/reminders/domain/services/local_notification_service.dart # M4 — interface (pure Dart)
lib/features/reminders/domain/repositories/app_settings_repository.dart# M2 — interface (pure Dart)
lib/features/reminders/data/repositories/app_settings_repository_impl.dart # M2
lib/features/reminders/data/services/flutter_local_notification_service.dart # M4 — plugin impl
lib/features/reminders/presentation/providers/reminder_sync_notifier.dart  # M5 — provider + sync hooks (no baby-switch listen, D6)
lib/core/widgets/lifecycle_sync.dart                                   # M5 — the app's single WidgetsBindingObserver
test/features/reminders/domain/reminder_scheduling_test.dart           # M3 (the big one)
test/features/reminders/domain/reminder_scheduler_test.dart            # M5
test/features/reminders/data/app_settings_repository_test.dart         # M2
test/features/reminders/data/flutter_local_notification_service_test.dart # M4 (fake plugin)
test/data/local/migration_v12_to_v13_test.dart                         # M2
```

### 3.2 Exact signatures (new code)

```dart
// domain/services/local_notification_service.dart (M4)
abstract class LocalNotificationService {
  Future<void> init();                                  // plugin init + tz.initializeTimeZones() + channel
  Future<bool> ensurePermission();                      // D8 request; true if granted
  Future<bool> get permissionGranted;                   // query only, never prompts
  Future<bool> get exactAlarmsAllowed;                  // Android 33+: canScheduleExactNotifications(); true elsewhere
  bool get ready;                                       // init succeeded; false ⇒ schedule/cancel are silent no-ops (R13)
  Future<void> scheduleAt({required int id, required String title, required String body, required DateTime at});
  Future<void> scheduleIn({required int id, required String title, required String body, required Duration delay}); // catch-up (D3); near-future scheduleAt — the plugin has no zonedTimer (§3.6)
  Future<void> cancel(int id);
  Future<void> cancelAll();
}
```

```dart
// domain/services/reminder_scheduling.dart (M3) — pure, no Flutter, no IO
/// Wall-clock instant (device-local) at which a notification for [item] should fire,
/// assuming no state change before then. Contract:
///   result <= now  ⇒ the item is due RIGHT NOW (caller converts to the D3 60 s catch-up);
///   result  > now  ⇒ wait until [result].
/// [preferredHour]/[preferredMinute] are the D1 time of day (0-23 / 0-59).
/// [lastDismissal] suppression = lastDismissal + [dismissalWindow] (24 h default, mirroring checkDue).
DateTime nextDueAt(
  ReminderItem item, {
  required DateTime now,
  DateTime? lastCompleted,
  DateTime? lastDismissal,
  required Duration dismissalWindow,
  required int preferredHour,
  required int preferredMinute,
});
```

```dart
// domain/services/reminder_scheduler.dart (M5) — orchestration; pure Dart
// (imports features/baby/domain/... — the same cross-feature domain import the
// presentation layer already does in reminder_providers.dart)
class ReminderScheduler {
  ReminderScheduler({
    required RemindersRepository repository,
    required LocalNotificationService notifications,
    // (no AppSettingsRepository — opt-in/time are read by the notifier, which owns the D8
    // de-opt persistence, and passed in as values on each sync call)
  });

  // D2/D3 private state: what the OS currently has scheduled, and which
  // catch-up nudges this process already armed (D3).
  final Map<int, _PlanEntry> _plan = {};   // plan index → entry submitted last sync
  final Map<String, int> _catchUpArmed = {}; // '$scope::$item::$periodDay' → os id
  int _catchUpSeq = catchUpIdBase;          // monotonic, never recycled in-process

  /// Catch-up nudges take ids from a band above every plan index the notifier
  /// can produce (`catchUpIdBase = 10000`). Implemented this way because the
  /// first draft shared one id space and that was **unsound**: a rename or an
  /// added baby reshuffles the indices, so a nudge that had already fired (or
  /// was 60 s out) landed on an id a different baby's schedule then took over
  /// — either cancelled out of the shade or silently replaced. In its own
  /// band a nudge is fire-and-forget: never re-armed (D3), never displaced,
  /// cancelled only when its own due period closes.
  static const int _catchUpIdBase = catchUpIdBase;

  /// The diff key is (at, title, body) at a plan index — **content is part of
  /// the identity**: a plan-index reshuffle (baby rename/add/delete, R11) can
  /// put different title/body at an id, and a diff on (id, at) alone would
  /// skip it and leave a stale name in the OS notification center.
  typedef _PlanEntry = ({DateTime at, String title, String body});

  /// Reconciles the OS schedule with the DB for **every** baby (D6). Returns the
  /// number of notifications left pending.
  /// [babies] = `getAllProfiles()` (name asc); empty ⇒ the profileless `''` scope is
  /// scheduled instead. [title]/[body] are content closures supplied by the
  /// presentation layer (l10n + baby name are UI concerns; the domain stays pure);
  /// the `BabyProfile?` argument is `null` for the profileless scope.
  /// Internally per D2/D3/D5: build the plan (scheduled entries take indices
  /// 1..N, catch-ups take sticky ids from the `catchUpIdBase` band), diff
  /// against the previous plan, cancel dropped ids, reschedule changed ones,
  /// skip unchanged; a catch-up is armed at most once per
  /// (scope, item, **due period**) per process.
  Future<int> sync({
    required List<BabyProfile> babies,
    required bool notificationsOptIn,
    required int preferredHour,
    required int preferredMinute,
    required String Function(ReminderItem, BabyProfile?) title,
    required String Function(ReminderItem, BabyProfile?) body,
    DateTime? now,                              // injectable for tests; default DateTime.now()
  });
}

// reminder_item.dart (M3) — shared item-set helper, single-sourced with the UI.
/// The item set for one scope: with [profile] ⇒ `ReminderItemPresets.buildForBaby(profile)`;
/// without ⇒ the profileless fallback (`[ReminderItemPresets.vitamineD, .vitamineK]` base,
/// vitamin K = 30-day interval). `dynamicRemindersProvider` and `ReminderScheduler` both
/// call this so the UI and the OS schedule can never disagree about which items exist.
List<ReminderItem> reminderItemsFor(BabyProfile? profile);
```

```dart
// domain/repositories/app_settings_repository.dart (M2)
abstract class AppSettingsRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);   // upsert
  Future<void> deleteAll();                     // restore only
  Future<Map<String, String>> getAll();         // export
}
// data/repositories/app_settings_repository_impl.dart — drift impl; upsert = insert(..., onConflict: DoUpdate(...))
```

```dart
// presentation/providers/reminder_sync_notifier.dart (M5)
final reminderSyncNotifierProvider =
    NotifierProvider<ReminderSyncNotifier, void>(ReminderSyncNotifier.new);

class ReminderSyncNotifier extends Notifier<void> {
  @override
  void build() {
    // No baby-switch listen (D6: every baby is scheduled; switching is a no-op).
    // First sync happens from the lifecycle widget (on first frame + each resume).
  }

  /// The single entry point. Reads opt-in/time from app_settings (defaults '09:00'),
  /// the profile list from `babyProfilesProvider`, and builds title/body closures
  /// from AppLocalizations (active locale) + baby name (absent ⇒ the no-profile body
  /// key). Enabled/disabled state, completions and dismissals are read **inside the
  /// scheduler**, per scope — the notifier passes no item-level state. If opt-in is
  /// ON but OS permission is denied (D8) ⇒ persist '0', then sync (whose step 1
  /// does the cancelAll).
  /// In-flight guard: concurrent triggers (resume + 5-min tick + a mutation in the same
  /// second) must never run two `sync()`s at once — coalesce onto the in-flight future
  /// (`Future<void>? _inFlight`); a coalesced call loses nothing, the next tick reconciles.
  /// Awaits `service.init()` (idempotent, §3.6) **before** `scheduler.sync()` — tz data
  /// and the channel must exist before any schedule/cancel reaches the plugin.
  ///
  /// **Never throws.** A background reconciliation must not break the tap that
  /// triggered it: recording a feeding, dismissing a reminder and deleting a baby
  /// always succeed; a failed sync is logged and the next tick retries. This also
  /// keeps the plugin and the database out of the tests that exercise only the
  /// mutation (`reminder_notifier_test` would otherwise drag in `path_provider`
  /// through `appSettingsRepositoryProvider` → `databaseProvider`).
  ///
  /// The stored `HH:mm` is parsed **strictly** (`_parseTimeOfDay`): 2 parts, hour
  /// 0..23, minute 0..59, else `defaultNotificationTime`. `'0830'` parses as the
  /// integer 830 and an hour of 830 does not fail — it silently schedules a
  /// wall-clock time that does not exist. The settings UI cannot write that; a
  /// hand-edited or corrupted row can, and the schedule must not inherit it.
  Future<void> syncNow();
}
```

### 3.3 Modified files (per milestone)

| File | Change | Milestone |
|---|---|---|
| `pubspec.yaml` | + `flutter_local_notifications: ^22.3.2`, + `timezone: ^0.11.2` (with a comment: local-only, no network — the §10.2 privacy note); version bump to `1.3.0+12` at M8 (build number is the global monotonic counter — last release was `1.2.1+11`, so the next is `+12`, **not** `+1`; a reset fails the on-device upgrade and the store) | M1 / M8 |
| `android/app/src/main/AndroidManifest.xml` | `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` + `<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>` (reminder-class exemption, API 33+; comment: no `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, out of scope) | M1 |
| `lib/data/local/app_db.dart` | + `AppSettings` table; `schemaVersion` 12 → 13; `onUpgrade` additive `CREATE TABLE` branch; schema.sql regenerated to match | M2 |
| `lib/data/local/db_constants.dart` | + key constants `settingsKeyNotificationsOptIn = 'notifications_opt_in'`, `settingsKeyNotificationTime = 'notification_time_of_day'`, `defaultNotificationTime = '09:00'` (rewrite the corrupted docstrings in this file — see §0) | M2 |
| `lib/features/reminders/presentation/providers/reminder_settings_notifier.dart` | `setEnabled` ⇒ after the write, `ref.read(reminderSyncNotifierProvider.notifier).syncNow()`; fix corrupted docstrings | M5 |
| `lib/features/reminders/presentation/providers/custom_reminders_notifier.dart` | `create`/`edit`/`remove` ⇒ `syncNow()` inside `_refreshAfterWrite`; fix corrupted docstrings | M5 |
| `lib/features/reminders/presentation/providers/reminder_notifier.dart` | `_tick` (the 5-min poll) ⇒ `syncNow()` after the state update; `markDone`/`snooze` ⇒ `syncNow()` after `refresh()`; fix corrupted docstrings | M5 |
| — (no new baby-feature provider) | the sync notifier reads the **existing** `babyProfileListProvider` in `lib/core/providers/active_baby_provider.dart` (a `FutureProvider<List<BabyProfile>>` on `getAllProfiles()`); this row originally proposed a duplicate `babyProfilesProvider`, which the M5 step 5 supersedes | M5 |
| `lib/features/home/presentation/widgets/onboarding_dialog.dart` | after `insertProfile` (L213) ⇒ `syncNow()` (D6: a new baby starts scheduling immediately) | M5 |
| `lib/features/menu/presentation/widgets/baby_profile_section.dart` | after `insertProfile` (L281) and `deleteProfile` (L449) ⇒ `syncNow()` | M5 |
| `lib/main.dart` (`MyApp`) | Wrap the routed child in `LifecycleSyncWidget` (the single `WidgetsBindingObserver`; on `resumed` + first frame ⇒ `syncNow()`) | M5 |
| `lib/features/reminders/presentation/screens/reminder_settings_screen.dart` | New "System notifications" section: opt-in `SwitchListTile` (D8 flow) + time-of-day row (disabled unless opt-in) + denied hint; rewrite the corrupted screen dartdoc (it currently documents the absence of notifications); `reminderSettingsDescription` usage unchanged (the string itself is rewritten in M6) | M6 |
| `lib/features/export/data/repositories/export_repository_impl.dart` | + `appSettings` section (unfiltered `getAll()`, both rows), + count in summary, `_exportFormatVersion = 4` | M7 |
| `lib/features/export/domain/repositories/export_repository.dart` | + parsed type for the new section (mirror the existing section DTOs) | M7 |
| `lib/features/import/data/repositories/import_repository_impl.dart` | `_supportedFormatVersion = 4`; `appSettings` section parse (both fields non-empty strings); delete-all + insert inside the restore transaction (append to the existing delete/insert order) | M7 |
| `lib/features/import/domain/repositories/import_repository.dart` | + `ImportedAppSetting` row type + field on the parsed document | M7 |
| `lib/features/reminders/domain/entities/reminder_item.dart` | + `reminderItemsFor(BabyProfile?)` helper (§3.2) | M3 |
| `lib/features/reminders/presentation/providers/reminder_providers.dart` | `dynamicRemindersProvider` refactored onto `reminderItemsFor` (zero behavior change — existing provider tests must stay green) | M3 |
| `lib/l10n/app_{en,fr,es}.arb` + generated `app_localizations*.dart` | §6 key table; regenerate with `flutter gen-l10n` | M6 |
| `lib/core/config/app_config.dart` | `version = '1.3.0'` (CI enforces sync with pubspec) | M8 |
| `assets/patch_notes/{en,fr,es}.json` | + `1.3.0` entry (fr/es **noun form**) | M8 |

### 3.4 The scheduling algorithm (`nextDueAt`) — exact semantics

Let **T** = `preferredHour:preferredMinute` as a local time-of-day. `at(day, T)` = that
time-of-day on calendar day [day]. All comparisons are device-local wall clock. `suppressedUntil`
= `max(lastCompleted is today ? end-of-today : epoch, lastDismissal != null ? lastDismissal +
dismissalWindow : epoch)`. The dismissal window mirrors `RemindersService.dismissalWindow` (24 h) and
applies to **every** variant exactly as `checkDue` applies it — a snoozed item is silent in the OS
as in the app.

The algorithm is two steps, uniform across variants:

1. **Natural candidate** — the next moment the item would fire if nothing were suppressed
   (per-variant table below). "Advance one period" = a day (Daily), the same target in the next
   week (Weekly), the next eligible month (Monthly), the next n-day boundary (CustomInterval).
2. **Universal resolution**, in order:
   - while `candidate < suppressedUntil`: advance one period and recompute the natural
     candidate. Bounded (24 h window + end-of-today ⇒ ≤ 3 iterations) — write the loop, not
     hand-unrolled cases.
   - `candidate <= now` ⇒ return **`now`** (D3 catch-up — the due window is open and the fire
     moment passed while the app was closed).
   - else return `candidate`.

| Variant | Natural candidate |
|---|---|
| `Daily` | `at(today, T)`. "Completed today" is suppression, not a different candidate: `suppressedUntil` = end-of-today pushes the candidate to tomorrow. |
| `Weekly(dayOfWeek)` (1=Mon…7=Sun, matching `DateTime.weekday`; the current UI only produces 1) | `dueWeek` = the ISO week (by `_weekIndex`) strictly after `lastCompleted`'s week, or the current week if never completed; candidate = `at(dayOfWeek, T)` within `dueWeek`. |
| `Monthly(dayOfMonth)` | `eligibleMonth` = the current month if never completed, else the calendar month strictly after `lastCompleted`'s month; candidate = `at(clampedDay(eligibleMonth, dayOfMonth), T)` (same `_clampedDayOfMonth` as `isDue` — day 31 fires on the 28th/30th/31st of shorter months). |
| `CustomInterval(days: n)` | Never completed ⇒ `now` if not suppressed, else `suppressedUntil` (fires as soon as the snooze window closes — exactly like the pill). Else `at(lastCompleted + n days, T)` (calendar-day arithmetic, like `isDue`'s `.inDays >= n`). |

Reuse the private helpers from `reminder_frequency.dart` (`_isSameDay`, `_weekIndex`,
`_monthIndex`, `_clampedDayOfMonth`) — **do not copy them**: promote them to public
(`isSameDay`, `weekIndex`, `monthIndex`, `clampedDayOfMonth`) in the same file and update the one
internal use-site; the weekly/monthly index math must stay single-sourced, or the scheduler and
`isDue` will drift.

`duePeriodStart(item, {now, lastCompleted})` (public, same file) returns the **calendar day** of
the natural candidate, time-of-day stripped. It exists for D3: the catch-up guard needs the
identity of the *due period*, and only the natural candidate carries it — `nextDueAt` collapses an
overdue item to `now`, which is the same value for every item at every tick. Day granularity is
what makes it right for all four variants: a daily item has a period per day, a weekly item one
per target weekday, a monthly item one per birth day, a custom interval one per n-day boundary.

**Test matrix for M3** (every row is a test; use fixed instants, round numbers, DST pairs where
marked): daily — never done (fires at T today; T already passed ⇒ catch-up); done today (fires
tomorrow T); snoozed yesterday (window still open ⇒ tomorrow T); snoozed 25 h ago (window closed
⇒ today T or catch-up); weekly — never done, target weekday not yet reached; never done, target
weekday T already passed (catch-up); done this week (fires next week target); month boundary
(Monday epoch semantics — a completion on Sunday belongs to that week's Monday index); monthly —
never done, clamped day (31 in February ⇒ 28); done this month (fires next month clamped day);
done on the 31st with dayOfMonth 15 (fires next month the 15th, not "as soon as the month
changes"); custom interval — never done (catch-up now); done n−1 days ago (fires today T or
tomorrow T per T vs now); done n days ago at a later time than T (catch-up now); **DST**: a daily
T in a zone where the clock springs forward (T in the skipped hour ⇒ next valid instant, no
crash, drift ≤ 1 h) and falls back (T fires once, at the first occurrence).

### 3.5 `ReminderScheduler.sync()` — exact steps (M5)

0. If `!notifications.ready` ⇒ return 0, **touching nothing** (R13): `init()` failed in this
   process, so the OS holds no schedules we know about; clearing `_plan` here would make the
   next healthy sync see a clean slate and resubmit everything (fine), but skipping is simpler
   and the notifier retries `init()` before every sync, so the next tick picks up.
1. If `!notificationsOptIn` ⇒ `cancelAll()`, clear `_plan` and `_catchUpDone`, return 0.
   (The D8 de-opt path lands here too: the notifier persists `'0'` *before* calling sync,
   so step 1 does the cancelling.)
2. `now` = injected or `DateTime.now()`.
3. **Scopes** (D6): if `babies` is empty ⇒ a single scope, the `''` sentinel, item set =
   `reminderItemsFor(null)` + `repository.getCustomReminders(babyId: null)`. Otherwise one
   scope per baby in the given order (name asc — the `getAllProfiles()` order), item set =
   `reminderItemsFor(baby)` + `repository.getCustomReminders(babyId: baby.id)`. Every
   repository read below passes the same scope (the impl's `_scope`/`_visibleScopes`
   already map `null` ⇒ sentinel). Customs map through
   `CustomReminderPresets.forCustom(reminder, monthlyDay: scopeBirthDay)` — `null` in the
   profileless scope — the same mapping the UI uses.
4. **Build the plan.** For each scope, for each item in enumeration order (preset slot
   order — vitamine_d, vitamine_k, eye_cleaning, face_cleaning — then customs by dbId
   ascending; the preset slot order is pinned to the item **ids** in exactly that literal
   order, not to list positions, so a future reordering of `buildForBaby`'s list cannot
   move an id): if `getEnabledByItemId(babyId: scope)[item.id] ?? true` is false ⇒ skip.
   Else read `lastCompleted` (the existing `getLastCompleted(item, babyId: scope)` /
   `getLastManualCompletion` split, mirroring `RemindersService._checkDue`) and
   `lastDismissal` (`getLastDismissal(item.id, babyId: scope)`); compute `nextDueAt` (§3.4);
   entry = `(planIndex, kind: at | catchUp, at: …, title: title(item, profile), body: body(item, profile))`.
   `planIndex` increments from 1 over the **kept** entries (D5) — `catchUp` when
   `nextDueAt <= now`.
5. **Diff against `_plan`** (the scheduled entries actually submitted at the last sync).
   *Scheduled* entries only — a catch-up nudge is not in `_plan`, it is in
   `_catchUpArmed` keyed `'$scope::$itemKey::$periodDay'` with its own id:
   - id in `_plan` but not in the new plan ⇒ `cancel(id)`;
   - id in both, same `at`, **same title, same body** ⇒ skip (steady-state tick costs
     zero plugin calls — D2); same id with at/title/body changed ⇒ re-submit with the
     new content (the plugin replaces the pending entry **by id** on both platforms —
     no explicit cancel needed; a content change at an unchanged time is exactly the
     R11 rename case); new id ⇒ `scheduleAt(at)`;
   - catchUp, key ∉ `_catchUpArmed` ⇒ take a fresh id from the band, `scheduleIn(60 s)`,
     record `key → id`;
   - catchUp, key ∈ `_catchUpArmed` ⇒ **touch nothing**: no re-arm (D3) *and no
     cancel* — cancelling would wipe a notification the user has not tapped yet on the
     next 5-minute tick. This is the half the first draft got wrong.
6. Cancel the nudges whose key has disappeared (completed, dismissed, disabled, or gone
   with its baby) and forget those keys, so a **later** period of the same item can
   nudge again — without the forget, one nudge would silence that item for the life of
   the process. Store the newly submitted entries in `_plan` and the live nudges in
   `_catchUpArmed`; return `_plan.length + _catchUpArmed.length`.

The 60 s delay is a near-future `scheduleAt` (`scheduleIn`) — inexact is fine for catch-up, it is already late.
`_catchUpArmed` is per-process (D3): an app restart within the same due window can nudge
once more — bounded (R12). The key uses `(scope, itemKey)`, **not** the plan index, so a
baby rename (which reshuffles indices) cannot re-arm a catch-up.

### 3.6 `FlutterLocalNotificationService` (M4) — platform notes

- `init()`: `initialize(IOSInitializationSettings(requestAlertPermission: false, …) merged with
  AndroidInitializationSettings('@mipmap/ic_launcher'))` + `tz.initializeTimeZones()` +
  Android `NotificationChannel('reminders', 'Reminders', importance: Importance.defaultImportance,
  playSound: true)` (no badge anywhere — D7).
- `init()` failure (e.g. `tz.initializeTimeZones()` throws): log **one** line and mark the
  service unhealthy — `schedule*`/`cancel*` no-op until the next successful `init()` (the sync
  cycle simply returns 0; the next tick/resume retries `init()` first). The app never crashes
  over the reminder channel, and never leaves a half-scheduled plan (R13).
- `ensurePermission()`: Android 13+ ⇒ `requestNotificationsPermission()`; Android < 13 ⇒
  `areNotificationsEnabled()` (no prompt exists below 13); iOS ⇒
  `requestPermissions(alert: true, sound: true, badge: false)`.
- `exactAlarmsAllowed` (Android 33+): `canScheduleExactNotifications()`; other platforms/versions
  ⇒ `true`. `scheduleAt` uses
  `AndroidScheduleMode.exactAllowWhileIdle` when allowed, else `inexactAllowWhileIdle` (log **one** line
  via `logger`, D7-adjacent: inexact can drift tens of minutes — acceptable, and start/resume
  reconciliation repairs it).
- `scheduleAt`: `zonedSchedule(id, title, body, tz.TZDateTime.from(at, tz.getLocation('UTC')), details: …)` — the
  channel carries *wall-clock + zone name* (Android: `ZonedDateTime.parse` +
  `ZoneId.of`; iOS: `dateFormatter` + `NSTimeZone timeZoneWithName:`), so the instant is preserved by
  expressing it in UTC: the device's IANA zone is never discoverable from pure Dart (no
  `tz.setLocalLocation` needed, no offset-matching guess). Verified 2026-10-26 against 22.3.3 +
  timezone 0.11.2 (`toMap()` sends `location.name`);
  `scheduleIn`: **`zonedTimer` does not exist in `flutter_local_notifications` 22.x** (verified
  2026-10-26 against 22.3.3) — the D3 catch-up is implemented as
  `scheduleAt(at: now + 60s)`, the same one-shot primitive. Tap: default launch (no payload —
  nothing to pass, D7).
- Constructor-inject the `FlutterLocalNotificationsPlugin` instance (default `FlutterLocalNotificationsPlugin()`)
  so M4 tests drive a **fake** that records calls — no method-channel mocking.

---

## 4. Milestones

### M1 — Dependencies + Android manifest (no logic)

1. `pubspec.yaml`: add the two dependencies at the §1 versions, comment per §0 hard rules. `flutter pub get`.
2. `AndroidManifest.xml`: the two `<uses-permission>` lines (§3.3), with the comment.
3. No iOS change is required (local notifications need no Info.plist key; authorization is
   runtime). Verify by reading `flutter_local_notifications`'s iOS setup docs and record the
   version checked in the commit message.

**Verify:** `flutter analyze --fatal-infos --fatal-warnings`; `flutter test` (existing suite,
must be green — nothing references the plugin yet); `cd android && ./gradlew :app:processDebugMainManifest`
(manifest parses). Commit: `chore: add local-notification dependencies for v1.3.0 (item 12)`.

### M2 — Storage: `app_settings` table, schema v13

1. `app_db.dart`: `AppSettings` table (`key` TEXT NOT NULL unique/PK, `value` TEXT NOT NULL);
   `schemaVersion` ⇒ 13; additive `CREATE TABLE` in `onUpgrade` (no rebuild — trap 1 does not
   apply, no composite key, no rekey); update `schema.sql` to the generated DDL.
2. `db_constants.dart`: the three key/default constants (§3.3) + rewrite the file's corrupted
   docstrings (§0).
3. `AppSettingsRepository` interface + drift impl (`getAll`, `get`, upsert `set`, `deleteAll`).
4. `test/features/reminders/data/app_settings_repository_test.dart`: round-trips, upsert-overwrite,
   missing-key ⇒ null.
5. `test/data/local/migration_v12_to_v13_test.dart` on the §1 harness template: seed a v12 DDL
   database with real rows in all seven v12 tables, open v13, assert the table exists, all v12
   rows intact, `app_settings` empty.
6. Codegen (`make codegen`) — the drift `*.g.dart` regenerates; run `flutter analyze` afterwards.

**Verify:** analyze + `flutter test test/features/reminders/data/ test/data/`. Commit:
`feat(reminders): app_settings table (schema v13) for notification preferences`.

### M3 — Pure scheduling: `nextDueAt` + shared item-set helper

1. Promote the four private helpers in `reminder_frequency.dart` to public (single-sourced, §3.4)
   and update the internal use-sites.
2. `lib/features/reminders/domain/services/reminder_scheduling.dart`: `nextDueAt` (§3.2/§3.4).
3. `reminder_item.dart`: the `reminderItemsFor(BabyProfile?)` helper (§3.2) + refactor
   `dynamicRemindersProvider` onto it — zero behavior change, the existing provider tests must
   stay green (they are the proof).
4. `reminder_scheduling_test.dart`: the full §3.4 matrix, DST included. Use injected fixed
   `now` instants (e.g. `2026-10-25 08:00`); no `DateTime.now()` in tests. Plus a small
   `reminderItemsFor` table test (profile ⇒ 4 items with the profile's birth day; null ⇒ the two
   base items).

**Verify:** analyze + `flutter test test/features/reminders/domain/`. Commit:
`feat(reminders): pure next-due computation for notification scheduling`.

### M4 — `LocalNotificationService` interface + plugin impl

1. Interface (§3.2) in domain; impl (§3.6) in data with constructor-injected plugin.
2. `flutter_local_notification_service_test.dart`: fake plugin records
   `initialize`/`request*`/`zonedSchedule`/`cancel`/`cancelAll` calls; assert the
   exact-vs-inexact mode switch on `exactAlarmsAllowed`, the permission paths (Android 13+ vs < 13
   vs iOS), that `init()` is idempotent, and that a failing `init()` ⇒ logged no-ops until
   re-init (R13).
3. Wire nothing else yet (no provider) — M5 does that.

**Verify:** analyze + `flutter test test/features/reminders/data/`. Commit:
`feat(reminders): local notification service wrapping flutter_local_notifications`.

### M5 — Orchestrator + sync hooks + lifecycle

1. `ReminderScheduler` (§3.2/§3.5) in domain, with fake repository + fake notification service in
   `reminder_scheduler_test.dart`. The matrix is per-scope (D6): two babies with **different
   birth days** (distinct vitamin K monthly targets) + one profileless run; per-baby disablement
   (one baby's toggle must not touch the other's plan); opt-in off ⇒ cancelAll + 0; stale ids
   cancelled on mutation; **unchanged state ⇒ zero plugin calls** (D2 steady state, asserted via
   the fake's call counter); catch-up uses `scheduleIn(60 s)` and is **not re-armed** by a second
   sync in the same process (D3 — the fake records that the id stays absent); a baby *rename*
   reshuffles plan indices ⇒ the content-aware diff re-submits every entry whose
   title/body moved — **stale-name regression test: assert the fake received the NEW
   title, not the old one, for a surviving id** (Flash-Next review blocker) — no orphans
   (R11); adding a baby schedules its items, deleting one cancels them; two `syncNow()`
   in flight at once ⇒ a single `scheduler.sync()` (the in-flight guard).
2. `reminder_sync_notifier.dart` (§3.2): `syncNow()` reading app_settings + the **existing**
   `babyProfileListProvider` (`lib/core/providers/active_baby_provider.dart` — no new provider is
   created; the plan's `babyProfilesProvider` name is satisfied by it); title/body closures from
   `AppLocalizations` (active locale via `localeProvider`) + the scope's profile (`{baby}` +
   `{care}` placeholders, §5; `null` profile ⇒ `reminderNotificationBodyNoProfile`); the D8 de-opt
   check (opt-in ON + `permissionGranted` false ⇒ persist `'0'`, then sync — step 1 cancels).
   M5 also adds the three notification-content l10n keys (§5, marked M5) because the closures need
   them before any UI exists.
3. Hooks (§3.3): `setEnabled`, `create`/`edit`/`remove`, `markDone`/`snooze`, the poll `_tick`,
   onboarding `insertProfile`, menu `insertProfile` + `deleteProfile`. No baby-switch hook (D6).
4. `lifecycle_sync.dart` + `MyApp` wiring: first-frame + `AppLifecycleState.resumed` ⇒ `syncNow()`.
   This is the app's only `WidgetsBindingObserver` — the class dartdoc must say so (roadmap §0
   verified there were none).
5. Providers: `reminderSyncNotifierProvider`, `localNotificationServiceProvider` (a
   `FutureProvider` for the process-lived `FlutterLocalNotificationService`),
   `reminderSchedulerProvider` (a `FutureProvider` composing repository + service), and the
   `appSettingsRepositoryProvider` (the M2 impl needed its wiring; the notifier is the first
   consumer). `babyProfilesProvider` is the existing `babyProfileListProvider` (step 2).

**Verify:** analyze + `flutter test test/features/reminders/`. Commit:
`feat(reminders): reconciliation scheduler wiring OS notifications to reminder state`.

### M6 — Settings UI + l10n

1. `reminder_settings_screen.dart`: the "System notifications" section (§3.3, D8 flow):
   - opt-in `SwitchListTile`; ON ⇒ `ensurePermission()`; granted ⇒ persist `'1'` + `syncNow()`;
     denied ⇒ hint text (`reminderNotificationsPermissionDenied`), switch stays OFF;
   - time row (`showTimePicker`, initial = stored or `09:00`), enabled only when opt-in ON;
     save ⇒ persist `HH:mm` + `syncNow()`;
   - the screen-level dartdoc is rewritten (it currently documents the *absence* of notifications).
2. l10n (§6): all three ARBs, `flutter gen-l10n`, generated files committed.
3. Widget tests (`test/features/reminders/presentation/`): opt-in granted/denied paths (override
   the notification-service provider with a fake), OFF ⇒ `cancelAll`, time change ⇒ reschedule,
   denied hint shown/hidden.

**M6 implementation notes (deliberate deviations).**

- The section **trails** the two reminder lists. `ListView` builds lazily, so a block inserted near the
  top pushes the preset rows out of the build tree — and twenty existing widget tests assert those rows
  by text. Both placements were run: leading passes the new tests and breaks the old ones.
- `notificationSettingsProvider`, `NotificationPreferences` and `NotificationSettingsNotifier` live **in
  `reminder_sync_notifier.dart`**, not in a file of their own. The de-opt inside `_run()` must
  `ref.invalidate(notificationSettingsProvider)` — otherwise a parent who revokes the permission in
  system settings and comes straight back to the open settings screen sees a switch that is a lie, which
  is exactly what D8 forbids — and two files importing each other for that one call is a cycle for
  nothing.
- The `HH:mm` codec is its own domain file, `domain/services/notification_time.dart`:
  `parseNotificationTime` (strict, falls back to the default), `formatNotificationTime` (zero-padded —
  never `8:7`) and `notificationTimeDefaults()` **derived from** `defaultNotificationTime`, so there is
  no second hard-coded 09:00 to drift.
- Widget tests that assert scheduling or the de-opt **mount `LifecycleSyncWidget`**: `syncNow()` runs
  there, not in the screen, so without it a stored `'1'` schedules nothing and a `cancelAll()` assertion
  proves nothing. Assertions run on the **fake OS through the real scheduler**.
- Those tests assert notification **content and count, never ids**: past the preferred hour every item is
  a catch-up and lands in the sticky `catchUpIdBase` band (D5), so `scheduled[1]` depends on the wall
  clock the test happens to run at. The same four titles either way.

**Verify:** analyze + `flutter test test/features/reminders/presentation/`. Commit:
`feat(reminders): notification opt-in and time-of-day in settings (+ l10n en/fr/es)`.

### M7 — Export/import v4

1. Export: `appSettings` section + count, `_exportFormatVersion = 4` (§3.3).
2. Import: `_supportedFormatVersion = 4`, section parse + row contract (both fields non-empty
   strings), delete-all + insert inside the restore transaction.
3. Update the existing export/import test fixtures (a v3 fixture gains an `appSettings` section;
   the format-version ladder tests gain the v3 ⇒ "older app" and v4 ⇒ accepted branches).

**M7 implementation notes (deliberate deviations, and one defect found).**

- `AppDatabase.getAllAppSettings()` **orders by key**. The other export getters keep table order;
  this one sorts, because `app_settings` rows are updated in place, so table order changes after an
  `UPDATE` and two exports of an unchanged database would not be byte-identical.
- The importer keeps a **closed set of keys** (`_knownSettingKeys`) and rejects an unknown key with
  `invalidRow`. `app_settings` is a generic key/value table, so a hand-edited file can name anything;
  a key this build does not know has no value format to check, which makes it unverifiable rather than
  harmless. A future format adds its key and its validator in the same change that bumps the version.
- `appSettings` is **`optional: true`** on import: a pre-1.3.0 backup carries no such section, and
  refusing it because it predates the feature would brick every restore taken before it. Absent means
  empty, and the app then falls back to `notifications_opt_in` off / 09:00 — exactly the pre-item-12
  behaviour.
- The opt-in is restored **as written**, even onto a phone where the OS permission is missing: the
  backup is the owner's stated intent. The next sync runs the D8 de-opt and the switch stops lying.
  `ExportCounts.appSettings` and `ImportCounts.appSettings` are **required**, not defaulted to 0 —
  the compiler is the thing that remembers the next table.
- **Defect found by the test, not by the author.** The importer first owned
  `RegExp(r'^[0-2][0-9]:[0-5][0-9]$')` and that pattern accepts `24:00`: the digit class behind
  `[0-2]` allows `4`. Validation moved to one domain predicate, `isValidNotificationTime`
  (`domain/services/notification_time.dart`), used by the importer for the refusal and by
  `parseNotificationTime` for the fallback — one definition of a valid time, three callers. The test
  asserting `['8:00', '0830', '24:00', '09:5', '']` are all rejected is what caught it.
- The import fixture takes an `appSettings` parameter and `_seedRichDatabase` seeds both rows, so the
  existing **byte-for-byte round-trip** test now covers the preferences without being edited.

**Verify:** analyze + `flutter test test/features/export/ test/features/import/`. Commit:
`feat(export): appSettings section, export format v4`.

### M8 — Version, notes, full gate, release evidence

1. `pubspec.yaml` ⇒ `1.3.0+12` (build number continues the global counter from `1.2.1+11`); `AppConfig.version` ⇒ `'1.3.0'`.
2. Patch notes `1.3.0` entries in the three JSONs (fr/es **noun form**); one item per user-visible
   change (notifications opt-in, time of day, everything-stays-on-device sentence).
3. `make ci` (full pipeline: lint, tests, coverage ≥ 80, store-check).
4. **Release gate (AGENTS.md, non-negotiable)** — record in the PR description:
   - install the `1.2.1+11` build on `Small_Phone` (Android) and a standard iPhone (iOS
     simulator), seed **two** baby profiles (different birth days ⇒ different vitamin K monthly
     targets, D6) + sante events + one custom reminder per baby;
   - install the `1.3.0+12` build over it: migration v12→v13 ran, old data visible, `app_settings`
     empty;
   - flip the opt-in ON (grant permission), set the time to now+3 min, **force-stop the app**
     (Android: `adb shell am force-stop com.pvjio.mamadera`; iOS: terminate), wait, screenshot
     (`xcrun simctl io <udid> screenshot` / `adb exec-out screencap -p`), save under
     `docs/release-evidence/` with the date — the screenshot set must show **one notification per
     baby** (names in the bodies, D6);
   - delete one baby ⇒ the scheduler log records the cancels for its entries (R11);
   - export ⇒ inspect JSON (the `appSettings` section present, both keys); delete-all/reset path
     still works.
5. Store: `make store-package` for v1.3.0 (no prose retraction needed — §1: zero notification
   claims in `store/source/en/`).
6. F-Droid: append the `1.3.0` `Builds:` entry (**versionCode = the pubspec build number at tag
   time** — `12` if v1.3.0 is the next release, one higher if v1.2.2 ships first) to the fork; if
   [!53740](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/53740) has merged by then, push it
   as a follow-up MR, otherwise it rides the same MR.
7. Commit: `chore: v1.3.0 version bump, patch notes, release evidence`.

---

## 5. l10n key table (en is canonical; fr/es aligned to existing terminology, produced via `tg-translate` per the store-prose discipline and checked against `app_<locale>.arb` for the existing `reminder*` terms. Milestone: the three `reminderNotification*` content keys are added in **M5** — the scheduler's title/body closures need them before any UI exists; the UI keys + the `reminderSettingsDescription` rewrite are **M6**)

| Key | en | fr | es | Notes |
|---|---|---|---|---|
| `reminderSettingsDescription` (**rewrite** — trap 4) | "Banners shown on the home screen until the care has been logged. Optionally, Mamadera can also show a system notification at the reminder time — even when the app is closed. Notifications are generated on this device and never sent to a server." | « Bandeau affiché sur l'écran d'accueil jusqu'à ce que le soin soit consigné. Facultativement, Mamadera peut aussi afficher une notification système à l'heure du rappel — même quand l'application est fermée. Les notifications sont générées sur cet appareil et ne sont jamais envoyées à un serveur. » | « Bandea mostrado en la pantalla de inicio hasta que el cuidado se registre. Opcionalmente, Mamadera también puede mostrar una notificación del sistema a la hora del recordatorio, aunque la aplicación esté cerrada. Las notificaciones se generan en este dispositivo y nunca se envían a un servidor. » | The fr/es above are **starting points to be term-aligned** (notification vs notification système, etc.) — the en rewrite is the contract. |
| `reminderNotificationsSectionTitle` | "System notifications" | « Notifications système » | « Notificaciones del sistema » | |
| `reminderNotificationsOptIn` | "Notify me when a reminder is due" | « Me notifier quand un rappel est dû » | « Avisarme cuando un recordatorio esté pendiente » | |
| `reminderNotificationsTimeLabel` | "Notification time" | « Heure de notification » | « Hora de la notificación » | |
| `reminderNotificationsPermissionDenied` | "Notifications are currently disabled in the system settings. Turn them on there to receive reminder notifications." | « Les notifications sont désactivées dans les réglages du système. Activez-les là-bas pour recevoir les notifications de rappel. » | « Las notificaciones están desactivadas en la configuración del sistema. Actívalas allí para recibir las notificaciones de recordatorio. » | |
| `reminderNotificationTitle` | "{care}" | « {care} » | « {care} » | The scheduled-notification title = the care label (preset display label or the parent's custom label). |
| `reminderNotificationBody` | "{baby}: time for {care}." | « {baby} : c'est l'heure de {care}. » | « {baby}: hora de {care}. » | Per-baby scopes (D6): `{baby}` = the scope's name — the name is now **load-bearing**, not cosmetic. `care` is the care label (preset display label via `resolveHealthLabel` as the settings screen already does; custom labels pass through untouched). |
| `reminderNotificationBodyNoProfile` | "Time for {care}." | « C'est l'heure de {care}. » | « Hora de {care}. » | Only the profileless `''` scope (D6) — no name to carry. |

## 6. Risks, edge cases, accepted behaviors

| # | Risk / edge | Handling |
|---|---|---|
| R1 | DST spring-forward: T falls in the skipped hour | `tz` normalizes to the next valid instant; ≤ 1 h drift; M3 test asserts no crash and bounded drift. Start/resume reconciliation repairs persistent drift. |
| R2 | iOS clears pending scheduled notifications on app update | D2 reconciliation on start — the schedules are a derived cache, never state. |
| R3 | Android 33+ user revokes exact alarms in system settings | `exactAlarmsAllowed` false ⇒ inexact fallback (`allowWhileIdle`), one logged line; notification may drift tens of minutes — accepted. |
| R4 | User revokes the notification permission in system settings | D8 de-opt on start/resume: `cancelAll` + persisted `'0'` + switch reflects it. No prompt is re-shown (it would nag). |
| R5 | Device clock moved backwards | `nextDueAt` catch-up (D3) fires one notification; the reminder is genuinely due — correct behavior, not a bug. |
| R6 | App foreground when a catch-up fires | The pill **and** the notification are both visible — accepted (D7); suppressing foreground notifications is complexity we don't need. |
| R7 | iOS 64-pending-notification cap | Scheduled set = enabled items per baby (4 presets + customs, bounded by what a parent creates; realistically < 20). Cap is not a practical constraint; the diff-based reschedule keeps it fresh. |
| R8 | Multiple babies | D6: **all** babies — each scope's settings/completions/dismissals are independent (the DB has been per-baby since v11); the body carries the name (§5), so any baby's notification is unambiguous; disabling a preset for one baby does not touch the others. |
| R9 | `timezone` data vs device tz on iOS/Android | Schedules are submitted as the exact instant expressed in the **UTC** zone (`tz.getLocation('UTC')`, M4) — the channel carries wall-clock + zone name, so UTC preserves the instant without ever discovering the device IANA zone (the device zone is unreachable from pure Dart). `tz.initializeTimeZones()` still runs in `init()`. No user-facing tz picker (out of scope). |
| R10 | Corrupted docstrings copied into new files by habit | §0 hard rule: rewritten in the touched files; M5/M6 diffs are the check point. |
| R11 | Baby added / renamed / deleted | Add/delete ⇒ the M5 `syncNow()` hooks re-schedule immediately; rename ⇒ a one-time plan-index shuffle (D5) ⇒ the content-aware diff (§3.5 step 5) re-submits every entry whose title/body moved — no orphans, **no stale name** (content is part of the diff key, `_PlanEntry`). A live catch-up nudge is not reshuffled at all: its id is sticky in its own band (D3/D5), so its text can never be overwritten by another baby's schedule. A nudge *already shown* keeps the name it was posted with until the user dismisses it — the OS gives no way to rewrite a delivered notification, and re-posting one would violate D3. |
| R12 | Restart within the same due window | `_catchUpArmed` is in-memory: at most **one** duplicate catch-up nudge per restart, per item. Bounded; deliberately not persisted (persisting it would need a new table — rejected). |
| R13 | `tz.initializeTimeZones()` throws (time-zone asset failure) | Service goes unhealthy: logged no-ops, sync returns 0, next tick/resume retries `init()` (M4). No crash, no half-scheduled plan (§3.6). |

## 7. What this plan is **not**

- Not v1.2.2 material (owner decision D0'). If v1.2.2 ships first (audit housekeeping, B7), this
  plan lands on v1.3.0 unchanged; the M8 version bump runs at the start of the v1.3.0 cycle.
- Not sync (roadmap §6) — no state crosses devices; the notification path reads only the local DB
  and writes only the local schedule cache.
- Not the F-Droid pipeline (M8.6 is a two-line follow-up to the existing runbook in
  `docs/fdroiddata/README.md`).
- Not a fix for the blocked fr→en comment pass — only the bounded rewrite in touched files (§0).

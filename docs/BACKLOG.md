# BACKLOG — known debt, deliberately not paid

Things we know are wrong, cheap-ish to fix, and chose not to fix in the release at hand.
Each entry says **why it was deferred** and **what makes it urgent**, so the next person can
re-decide instead of re-discovering. Nothing here is hidden; nothing here is approved silently.

> **Resolved, shipped and decided items are archived in [`BACKLOG-RESOLVED.md`](BACKLOG-RESOLVED.md)**
> (append-only history). **MOVED 2026-10-20:** **B2** (coarse + fine slider pair — shipped v1.2.1,
> reverted 2026-10-13) and **B5** (out-of-range input swallowed without a message — resolved v1.2.1), bodies
> moved verbatim, numbers preserved. **B1** and **B7** stay here: B1 keeps its full evidence under a
> corrected status line, and B7 still carries open work (the `HistoryFilter.measurements` chip,
> re-requested by the owner 2026-10-17).

---

## B1 — `tracking_events.quantity` has no unit column

**Status:** ~~open~~ **resolved in v1.2.1** — the `unit` column landed (`tracking_events.unit TEXT NULL`,
`lib/data/local/app_db.dart:44`; `measurements.unit` at `:119`), schema v12 (`app_db.dart:151`), commit
`6133af9` tagged `v1.2.1` — see [`docs/release-notes/v1.2.1.md`](release-notes/v1.2.1.md). Body kept as
the decision record · **Severity:** medium · **Cost:** one migration (schema v12) + export format bump
**Found:** 2026-10-03, while adding the `solid` feeding subtype for v1.2.0
**Files:** `lib/data/local/app_db.dart:28`, `lib/features/history/presentation/widgets/history_tile.dart:134`,
`lib/features/home/presentation/widgets/feeding_tracking_dialog.dart:121`,
`lib/features/history/presentation/widgets/edit_event_dialog.dart:243`

### The debt
`tracking_events.quantity` is a `REAL` with no unit. Its meaning is **inferred from the row's
type and subtype**:

| type | subtype | quantity means |
|------|---------|----------------|
| `miam` | `natural` | millilitres (expressed milk) |
| `miam` | `artificial` | millilitres of formula |
| `miam` | `solid` ← new in v1.2.0 | **grams** |
| `dodo` | — | minutes |

`FeedingEvent` has **no duration field** — `quantity` is the only number, and it has always held
millilitres for both milk subtypes. Anyone tempted to relabel `natural` as "minutes at the breast"
is inventing a semantic the stored data never had, and would display every existing expressed-milk
record as a breastfeeding duration. `feeding_tracking_dialog_test.dart`'s *"natural keeps millilitres"*
test exists because a plan asserted minutes, an implementation obeyed, and nothing else checked.

Three call sites hardcode `'ml'` for feeding and derive nothing from the subtype
(`history_tile.dart:134` does `feeding: (_) => 'ml'`). The unit is a property of the *event*, but
it lives in the *code that renders the event*.

### Why it was accepted
This was already true before v1.2.0 — minutes vs ml was the same inference. Adding `solid` extends
existing debt rather than creating it, and the alternative was a schema migration landing days before
the v10→v11 re-key had been run on a single real device. Two irreversible migrations in one release,
both unverified on hardware, is how you lose a user's data.

### What makes it urgent
1. **The day a meal is logged in ml and g at once** — a bottle *and* pureed food at one sitting — the
   model cannot express it. One row per event, one number, one inferred unit: the second food's
   quantity becomes ambiguous or the meal has to be split into two events with no link between them.
2. **Any future import of a foreign format** (another app's export, a spreadsheet restore) cannot be
   validated: an out-of-range value is only detectable if you know what unit you're checking against.
3. **Rendered output is wrong for `solid`** unless every display site was updated in lockstep. A missed
   site prints "40 ml" for 40 g of pureed food. That is a wrong health number on screen, in an app whose
   entire promise is correct health numbers. Four sites hardcoded `'ml'` for all feeding and had to be
   found and fixed in v1.2.0 — the fourth was not in the plan's list.
4. `measurements` (v1.2.0) *does* carry a `unit` column (`app_db.dart:102`). The schema now contradicts
   itself: one table states its unit, the other assumes it.

### Decision (owner, 2026-10-03): fix it in v1.2.1, and breastfeeding becomes MINUTES
Per-subtype units are now the product contract, not an accident of inference:

| subtype | unit | who chooses |
|---------|------|-------------|
| `natural` | **`ml` or `min` — chosen by the parent** | the parent, at input time (toggle) |
| `artificial` | `ml` | fixed |
| `solid` | `g` | fixed |
| `dodo` | `min` | fixed |

Amendment owner 2026-10-03 (second): the breast is fixed **neither** to minutes **nor** to ml. The parent
chooses. Nursing counts in minutes, pumping counts in ml, and the same mother does both
the same day — freezing the subtype would have removed one of the two usages, which is no small thing for
a pumping parent. The toggle only shows for `natural`; the other subtypes stay frozen,
because only one unit has meaning there.

### Backfill at migration v12 — explicit rule
**All existing `natural` rows get `'ml'`**, because that is what the interface
was showing: a parent who entered 20 saw « 20 ml », so the data *meant* to be 20 ml. No
arithmetic conversion, no inference: we name the unit the user saw. A row whose
unit was guessed as minutes would be fabrication.

Accepted consequence: at the breast, `ml` and `min` coexist in the same column and the same subtype.
Any aggregate must filter on `unit` — adding minutes to millilitres is not an
approximation, it is nonsense. Verified: nothing sums feeding volume today.

That makes the `unit` column a **prerequisite**, not a cleanup: without it, `quantity` would hold
minutes and millilitres under one subtype name with nothing distinguishing them.

### The backfill trap, stated before anyone writes the migration
Rows written before v1.2.1 under `natural` contain **millilitres** — entered through an `ml` picker,
labelled `ml`, on builds already shipped. There is no way to recover whether a given historical
`natural` row of `20` meant 20 ml or 20 minutes, so **do not convert them**. They backfill to `'ml'`
and stay `'ml'`, truthfully. Consequences, all of them intended:

- `natural` rows carry two units across time, distinguished only by `unit`. Any query, chart or
  "last fed" logic that ignores `unit` will mix volumes and durations. Verify there is no such query
  before shipping — today there is none, nothing sums feeding volume (checked 2026-10-03).
- ~~Expressed milk loses its input field~~ — **resolved** by the ml/min toggle on `natural`
  (amendment above): no fourth subtype, the breast accepts both units.
- Duration of a feed becomes available per row, which is what a paediatrician asking "how long does
  she feed?" actually wants. That is the gain paying for all of the above.

### The fix
Schema v12: `ALTER TABLE tracking_events ADD COLUMN unit TEXT`. Backfill honestly, per row:
`sleep`→`min`; `miam`+`artificial`→`ml`; `miam`+`solid`→`g`; **`miam`+`natural`→`ml` for every row
that already exists** (that is what they mean), and `'min'` only for rows written by v1.2.1 and later.
Default for new rows comes from the subtype at insert time, so no code path can write a unit-less row.
Then make every read path render from `unit` and delete the hardcoded `'ml'` literals. Export format 3,
importer accepts 2 and 3, and a format-2 backup's feeding rows backfill to `'ml'` — never `'min'`.
Same discipline as v11: explicit column list in any `INSERT … SELECT`, export stability test extended
to cover `unit`, and an emulator migration pass with pre-existing v11 data before the PR (AGENTS.md).

**Ordering:** v1.2.0 (schema v11) ships and is verified on a device first. v1.2.1 carries v12. Two
unverified irreversible migrations in one release is how a re-key goes wrong with no rollback.

### Do not
Do not "fix" this by widening reminder matching to `type == miam`. Reminders match `subtype`
exactly (`reminders_repository_impl.dart:58`) — that is why `Solide` (pureed food) does **not** silence a milk
reminder. That exactness is behaviour, not oversight.

---

## B3 — v1.3.0 sync requires a written change to the privacy mandate

**Status:** blocked on the owner · **Severity:** structural
**Files:** `docs/ROADMAP-reminders-and-sync.md` §7 decision 5, `README.md` privacy promises

The app's core promise is *no network transport exists anywhere*. LAN peer sync contradicts that
sentence, so it is not a feature decision but a promise decision, and only the owner can rewrite the
promise. No code, no dependency, no spike until that sentence changes — see `AGENTS.md`
"Privacy-First Mandates (NON NEGOTIABLE)".

---

## B4 — Insufficient contrast: the yellow (day) and the brown (night)

**Status:** open, v1.2.1 candidate · **Priority:** real accessibility · **Cost:** colour choice + verification pass
**Found:** 2026-10-04, by eye on Android (light) and iOS (dark) captures

### The problem, seen and not guessed
- **Light mode:** the « Feeding » button is pale yellow on a pale yellow background — barely
readable.
- **Dark mode:** the « Couche » button is dark brown on a dark background — barely readable.
Both are **already in production** (the theme did not change on this branch). This is not a matter
of taste, it is a parent reading the screen one-handed, half asleep, at 3 h, on a dimmed screen.

### Candidates, with the ratio to measure — not to guess
WCAG AA rule: **4,5:1** for normal text, **3:1** for large text (≥ 24 px / bold ≥ 18,7 px).
Button titles are large, but the pills (« Vit. D ») and the values (« 3 510 g ») are not
— so it is 4,5:1 that must be targeted on the labels of these buttons.

| role | problem | candidate to test |
|---|---|---|
| `miam` (yellow, light) | too pale on a light background | dark amber `#B26A00`, or saturated yellow `#E0A400` **with dark brown text** on top |
| `couche` (brown, dark) | too dark on a dark background | terracotta `#C97B5A`, or clay `#D08B6A` |
| structural alternative | — | keep the tints, but make the **label** a guaranteed-contrast text colour (dark on light background, light on dark background), and reserve the tint for the background and the icon |

The structural alternative is probably the right one: it keeps the visual identity (the four
colours that distinguish care/feeding/nappy/sleep) without asking a pastel tint to carry
the readability of the text.

### To do before touching the colours
1. Measure the real ratio of the current pairs (capture excerpt + WCAG calculator) and note the
   numbers — a colour sheet without ratios is an opinion.
2. Choose one pair per theme, verify 4,5:1 on the labels and the pills in **both**
   themes, on the smallest device.
3. Do not change an identity colour lightly: these four tints are the app's
   wayfinding system, and an unmeasured colour change can break two others.

---

## B6 — The Vitamin D reminder is on by default; WHO 2022 (Rec 36): research only

**Status:** open, high priority (clinical) — **decision A made** (owner, 2026-10-06: no
migration, new default only) · **Cost:** small — one field + one filter fallback + tests
**Found:** 2026-10-05, research archive (`docs/research/2026-10-05-clinical-evidence.md`, Rec 36);
removal request to the backlog by the owner, 2026-10-06.
**Files:** `lib/features/reminders/domain/entities/reminder_item.dart:51` (preset `vitamine_d`),
`lib/features/reminders/presentation/providers/reminder_providers.dart:84` (`settings[item.id] ?? true`),
`lib/features/reminders/presentation/providers/reminder_settings_notifier.dart` (the doc comment
documents « clé absente = activé » ),
`lib/features/reminders/presentation/screens/reminder_settings_screen.dart` ,
`lib/features/reminders/presentation/widgets/reminder_row.dart`.

### The fact
The default reminder list includes a daily Vit. D pill (`ReminderItemPresets.vitaminD`,
`Daily()`, triggered by a health event of subtype `vitamine_d`). All presets are **enabled by
default**: the filter is `settings[item.id] ?? true`, and the notifier's doc comment says it explicitly <!-- lang:fr: verbatim doc comment, quoted below -->:
« Une clé absente signifie *jamais touché*, donc **activé** : » <!-- lang:fr: verbatim doc
comment -->
« l'extinction est une option de retrait, pas une adhésion. » <!-- lang:fr: verbatim doc comment
-->
« Un parent qui n'ouvre jamais cet écran continue de recevoir Vit. D, Vit. K, Yeux et Visage. »
<!-- lang:fr: verbatim doc comment -->

WHO 2022 *Caring for the newborn*, Rec 36: vitamin D supplementation of the newborn is
**research only** — not a recommendation (Rec 35 shows the model for vitamin A: context thresholds,
never a systematic supplement). The app therefore sends, every day, by default, a reminder for a
practice the reference guideline does not recommend — in an app whose reason for being is the
neonatal mortality areas (`docs/PLAN-francophone-neonatal.md`). It is the open clinical discrepancy documented in
the research archive: « This is a live clinical discrepancy in the current build, in the app's
own default
reminder list. »

### The fix (mechanics)
1. Add `enabledByDefault` (bool, default `true`) to `ReminderItem`; set it to `false` on `vitamine_d`.
2. The filter becomes `settings[item.id] ?? item.enabledByDefault` . The
« clé absente = activé » invariant
   stays intact for all the other items — the opt-out model is preserved, only the Vit. D becomes opt-in.
3. `reminder_settings_screen.dart` / `reminder_row.dart` must render the switch's initial state from the same
   fallback — verify that no « activé par défaut » is re-coded in the widget.
4. Tracking stays: `HealthSubtype.vitamineD` (`tracking_enums.dart:290`) remains in
   `health_subtype_dialog.dart`. A parent with a prescription keeps logging vitamin D, and the reminder stays
    re-enableable in « Réglages » → « Rappels » (Settings → Reminders). We change the
    **default**, not the **function**.
5. l10n: add a short justification on the settings row (« Non recommandé en routine — OMS 2022, Rec 36 ») in fr/en/es, so that the off-by-default state does not look like a bug.

### Decision point (owner) — existing installations
A parent installed before this change has « Vit. D = jamais touché » = **on**. Two options:
- **A. New default only** (no migration): existing ones keep receiving the reminder until
  manual turning off; new babies/installations start off.
- **B. Migration** seeding `reminder_settings(baby_id, 'vitamine_d', enabled: false)` for all existing
  scopes (profiles + carry-over `''`): all installations flip at upgrade.

Recommendation: **A** + a patch note explaining the change. B silently removes a visible reminder
without consent — exactly the sin that B1's backfill rule refuses for data (« on nomme l'unité que l'utilisateur a vue »).

**Decision (owner, 2026-10-06): A.** New default only, no migration. Existing installations
keep the reminder until manual turning off; new babies/installations start off.
Patch note explaining the change (without marketing it as « l'app suit l'OMS » — see « Do not »
).

### Do not
- Do not **remove** the vitamin D reminder or the `vitamine_d` health subtype.
« Recherche uniquement » is
   not « interdit » : in part of the target market (US practice, AAP: 400 IU/day) it is the
   standard. The
  removal is a different, much noisier decision.
- Do not invert the **global default** « clé absente » to « désactivé » : the opt-out carries
the Vit. K
  presets (after the first month), Yeux, Visage — all would become opt-in and a new parent's home screen
  would be empty of reminders.
- Do not present this change in store/patch notes as
« l'app suit désormais l'OMS sur les suppléments » : the rest of the default list (eyes, face,
Vit. K) is care hygiene,
  not a WHO-derived list. An over-generalisation is a clinical promise that the research
  archive forbids making.

---

## B7 — The History tab does not have *all* event types: measurements are absent from it

**Status:** the timeline part is **shipped in v1.2.1** (verified in the code, 2026-10-17:
   `measurement_history_tile` in `history_screen`, `tracking_events` + `measurements` merge in
   `history_notifier`); what remains on this ticket, re-requested by the owner on 2026-10-17
    (« filtrer les événements de l'historique par mesures »): the dedicated
    `HistoryFilter.measurements` chip,
   explicitly **out of v1.2.1 scope** (the plan's « Out of scope » section: « no `HistoryFilter`
   value for growth ») → v1.3.0 candidate. · **Cost of the remaining part:** small
**Found:** owner request, 2026-10-06 (« l'onglet historique devrait avoir tous les types d'événements »),
   verified in the code — and cross-checked against the v1.2.1 plan on 2026-10-06; the
   chip filter request was re-opened on 2026-10-17, exact scope below.
**Files:** `lib/features/history/presentation/screens/history_screen.dart:20` (`_filters`:
all/miam/dodo/caca/sante), `lib/features/history/presentation/providers/history_notifier.dart:28-50` (only
consults `tracking_events`), `lib/features/history/data/repositories/history_repository_impl.dart`
(`getAllEventsOrdered`, `getEventsByType`), `lib/shared/domain/entities/tracking_enums.dart:320`
(`HistoryFilter`), `lib/data/local/app_db.dart:96` (table `measurements`, separate, encrypted values),
`lib/features/history/presentation/widgets/history_tile.dart`.

### The fact
« Historique » (History) promises all events; it only shows `tracking_events` (miam, dodo, caca,
sante).
Since v1.2.0, weight/height/temperature live in the **`measurements`** table — a separate table, encrypted
values, unit in its own column, its own repository (`MeasurementRepository.allForBaby`, scoped to the baby, already
sorted newest to oldest). The parent's « tous » (all) view is therefore silent on an entire
class
of events: measurements only appear on the Croissance (Growth) screen (itself hidden in the menu, see B8).
A parent who wants « tout ce qui s'est passé aujourd'hui » (everything that happened today) does
not see the weight logged this morning.

### To do
**Part v1.2.1 — SHIPPED (do not redefine, it is the plan's contract)**: unified timeline in **read-only** —
`history_notifier` merges `tracking_events` and `measurements` sorted by timestamp, each row
rendering its unit from its own `unit` column; modification/deletion addressed to the source
table (never to both); **no duplication** in `tracking_events` — the plan refuses it
explicitly: `quantity` there is **in the clear** at rest, duplicating would create an unencrypted
copy of the app's most sensitive data. Tile
« échec de déchiffrement → `growthValueUndecryptable`, jamais un nombre inventé ».
See the plan for the editing details (`measurement_sheet.dart` or
`edit_event_dialog.dart`).

**Remaining part (v1.3.0 if still wanted)**:
1. `HistoryFilter.measurements` (value `'mesures'`, l10n label fr/en/es) on top of the inclusion in
   `all` (the latter arrives with the v1.2.1 timeline); `HistoryFilter.fromString`: `'mesures'` before the
   fallback `all` (the safe fallback already in place).
2. The chip is inserted into `_filters` of `history_screen.dart` — position and icon at the plan (measurements
   are neither a `TrackingType` type nor an existing colour).
3. Nothing to bump in the export format: measurements are already exported/imported, the chip is a
   pure read question.

### Do not
- Do not migrate `measurements` **into** `tracking_events` to « unifier » the history. The two
tables have
  different contracts (`unit` column, encrypted value, `kind` enum, no subtype); B1's debt shows
  precisely what a single numeric column carrying semantics does. A **display**
  merge is enough; a schema merge is an irreversible migration with no gain.
- Do not add `reminder_completions` or `reminder_dismissals` to the history: they are
  service logs, not the baby's events.

---

## B8 — Measurements: no dedicated tab, no visualisation

**Status:** open (owner request, 2026-10-06: « un onglet de visualisation pour les mesures ») ·
**Cost:** small on the router side, medium on the chart side (dependency or `CustomPainter`)
**Files:** `lib/core/router.dart:23` (`AppRoute`: home/history/menu), `:137` (route `/growth`
**outside** the shell), `lib/features/menu/presentation/screens/menu_screen.dart:111` (`context.push('/growth')`),
`lib/features/growth/presentation/screens/growth_screen.dart` (3 last-value cards + flat list, no
chart).

### The fact
Croissance (Growth) is today a full-screen push from the Menu — two taps deep — and its
« visualisation » is three last-value cards above a flat list. There is **no**
chart: no weight curve over time, no trend. A parent who follows their
newborn's weight is looking at tiles, not a trajectory.

### To do
1. Move `GrowthScreen` into the `ShellRoute` as the **fourth tab** of the bottom navigation. Order:
   Home, History, Croissance, Menu (to validate at the plan — the Menu stays last, it is the service
   tab; four tabs is Material's comfort limit, we do not add a fifth).
2. `AppRoute` enum + `routeIndex` + `_routeIndexForPath` + nav label/icon (new l10n key or
   reuse of `growthScreenTitle`/`growthMenuTile` — check the three arbs).
3. The Menu's « Croissance » tile becomes redundant: remove it or keep it as a shortcut —
   decision at the plan. If kept, the tab and the tile lead to the same place (the push disappears,
   replaced by tab navigation).
4. The visualisation itself: **weight over time** curve (height optional). Two paths:
   - (a) home-grown `CustomPainter` — zero dependencies, faithful to the privacy charter, ~one day;
   - (b) pure Dart chart package (e.g. `fl_chart`) — **audit required**: `make audit-trivy` +
     dependency privacy review (AGENTS.md: no dependency without audit, zero network,
     zero telemetry).
   Decision at the plan; (a) has no reason to be refused.
5. **Temperature** does not go into the chart: temperature has no meaning as a trend (it is a
   state, not a trajectory). It stays card + list. The chart carries weight (and height).

### Do not
- Do not overlay **WHO percentiles** (growth curves). It is clinical content: the research
  archive is explicit — no digital intervention has ever demonstrated an effect on neonatal mortality,
  the app must not market itself as a clinical tool, and the archive refuses to reconstruct IMNCI
  triage colours from second-hand sources. A percentile overlay without clinical
  review would be the app's first **interpretation** of health data. If percentiles are
  ever wanted, it is first a research task (docs/research/), not a chart parameter.
- Do not create a **fifth** tab « tous les événements » (all events): B7 merges measurements
into
  Historique (History). The Croissance tab and the history's `measurements` filter are complementary —
  the tab for the **visualisation**, the history for the **chronological register** — not rivals.
- Do not touch export/import in this ticket: measurements already travel (`docs/import-database-plan.md`,
  export format). The tab changes the presentation, not the data contract.

---

## B9 — Baby selection at the top of the app: the app bar's name is inert

**Status:** open (owner request, 2026-10-06: « baby selection in the top of app ») ·
**Cost:** small — one sheet + a clickable AppBar title
**Found:** verification of 2026-10-06 — the active baby's name is shown as the title of the home
    app bar (`home_screen.dart:316-335`, « contexte, pas titre » ) and does nothing; switching
    baby
   requires Menu → « Profil bébés » (baby profiles).
**Files:** `lib/features/home/presentation/screens/home_screen.dart:316-335` (AppBar, title = name,
   inert), `lib/core/providers/active_baby_provider.dart:32` (`switchProfile(id)` already exists),
   `lib/features/menu/presentation/widgets/baby_profile_section.dart` (existing list UI, for
   visual consistency), `lib/features/baby/presentation/providers/baby_profile_providers.dart`.

### To do
1. Make the home AppBar title clickable (affordance `expand_more`), opening a bottom sheet:
   list of profiles (avatar + name + birth date), active profile checked, tap →
   `ref.read(activeBabyProvider.notifier).switchProfile(id)`, the sheet closes.
2. An « Ajouter un bébé » (Add a baby) row at the bottom of the sheet → the existing profile
creation flow (the one
   the Menu section uses), so the top entry is complete: we switch **and** we add without
   going back down into the Menu.
3. Single-baby case: decision at the plan — the sheet still opens (consistent, it is also where we
   add the second one) or the affordance disappears (less noise, inconsistent). Recommendation: the sheet
   always opens, it is the « famille » (family) entry point.

### Why it is cheap and safe
The reactive chain already exists: the reminders notifier `watch`es `activeBabyProvider`, the history reads
`.value`, the home header re-renders on switch (the `home_screen.dart:316` comment
documents precisely why it is a `watch` and not a `read`). Nothing to invalidate manually —
the global invalidation after database reset (`menu_screen.dart:350-357`) already covers the providers
concerned.

### Do not
- Do not move profile **management** (edit name/birth, delete) into the top sheet.
  The top is a **switcher**; management stays in Menu → « Profil bébés ». Two entry points for
  deletion, that is how an accidental « supprimer ce profil » (delete this profile) gets made.
- Do not write under the carry-over `''` during a transient switch: the same trap that
  `markDone`/`snooze` document in `reminder_notifier.dart` — resolution via
  `activeBabyProvider.future`, never `.value` on a transient read (the `''` rows were read
  for **all** babies with the v10 share).
- Do not show the baby's name **and** a family icon: one or the other. Two context
  carriers on the same bar, it is a double voice.

---

## B10 — Code comments are in French: ~1 750 lines to anglicise

**Status:** open (owner request, 2026-10-06: « tous les commentaires de code en anglais ») ·
**Cost:** large, mechanical (~5–8 h) · **Risk:** low if the discipline is kept
**Counted:** 2026-10-06 — 945 lines of comments in `lib/` (56 files), 800 in `test/` (71 files),
   count on comment lines containing accented characters, generated files excluded.

### The fact
The code carries `//` and `///` comments in French through `lib/` and `test/` (user-facing
strings are, for their part, intentionally trilingual — `lib/l10n/*.arb` — but the **comments**
are monolingual by repo convention: English). French comments make the code harder to
search for a second reader and for the next agent: « trouver l'invariant » (finding the
invariant) requires French
words, and agent search (RAG included) is calibrated on English.

### To do
1. Translate `lib/` (excluding generated), then `test/`, file by file. Purely mechanical task —
   **ideal for a fan-out** of `box-coder`/`fast-coder` (no design decision), but the diff review
   stays human: some comments carry invariants (D1/D2/D3, the `''` carry-over, B1's
    backfill rule, B5's « do not » — archived in `BACKLOG-RESOLVED.md` ) that must survive **as
    reasoning**, not as summary.
   A translation that erases a « why » is a failure, not a simplification.
2. Generated files (`*.freezed.dart`, drift's `.g.dart`) **copy** the source's doc comments —
   never edit them by hand; translate the source, re-run `make codegen`, they follow.
3. After the pass: `make lint` + `make test` (the tests must remain unchanged in behaviour —
   only the language of the comments moves).
4. Optional, to decide at the review: a CI guard (grep of accented comment lines
   `é è ê à â ç ù û ô î ï` in `lib/**/*.dart` and `test/**/*.dart`) to prevent the regression —
   to wire into the existing pipeline (`make ci`).

### Do not
- Do not translate the **user-facing strings**: `lib/l10n/*.arb` and the generated `app_localizations_*.dart`
  stay untouched. That is the product, not code.
- Do not **remove** comments to « simplifier »: the AGENTS.md rule — no removal
  without justification and functional replacement. A lost « why » (B1's backfill trap
  is the example) is a loss of data of another type.
- Do not do this pass **in the same PR** as B6–B9: the diff would muddy the functional changes and
  the invariants review. A separate sweep PR, and preferably **before** any other work — everything
  we touch afterwards will be written in English and the debt will stop growing.
- Do not « translate » by summarising: a six-line comment must stay six lines. The translation
that
  loses a nuance of carry-over or invariant is worse than the original French.

---

## B11 — The language-change notification shows in the old language

**Status:** open (owner request, 2026-10-06:
« la notification de changement de langue doit être dans la langue cible ») · **Cost:** trivial
**Found:** verification of 2026-10-06 in `menu_screen.dart:217-218`.
**Files:** `lib/features/menu/presentation/screens/menu_screen.dart:211-220` (the tap of the language
   tile), `lib/l10n/app_localizations.dart:1711` (`lookupAppLocalizations(Locale)` — the fix
    mechanism, already public), the `languageChanged` keys in the three arbs (fr:
    « Langue changée » , en:
   « Language changed », es: « Idioma cambiado »).

### The fact
```dart
onTap: () async {
  await ref.read(localeProvider.notifier).setLocale(code);
  if (context.mounted) _showSnackBar(context, context.l.languageChanged);
},
```
After the switch, the widget tree is **still** built in the old locale — the
rebuild in the new one happens on the next frame, after the snackbar has read the string. A
parent who goes fr → en sees **« Langue changée »**: the confirmation arrives in the language
they just
left. The one string whose job is to say « you are now in English » is itself
still in French.

### The fix
Resolve the string in the **target locale**, not the current one — `lookupAppLocalizations` is public
and synchronous:
```dart
onTap: () async {
  await ref.read(localeProvider.notifier).setLocale(code);
  if (!context.mounted) return;
  final target = lookupAppLocalizations(Locale(code));
  _showSnackBar(context, target.languageChanged);
},
```
`Locale(code)` is always supported (the three codes of the screen are `fr`/`en`/`es`; `lookupAppLocalizations`
covers all of them, a language added tomorrow adds itself to `supportedLoces` and to the switch — the fix follows
with no extra code).

### Tests
- fr → en: snackbar « Language changed » ; fr → es: « Idioma cambiado » ; en → fr:
« Langue changée » .
  The three directions, not only that of the reporter.
- Existing widget test of the menu to extend: override `localeProvider`, tap the tile, pump, wait for the
  **target's** string (not the old one's). The assertion on the old string is the bug — never
  re-write it.

### Do not
- Do not « fix » by **deferring** the snackbar until the rebuild (`addPostFrameCallback` then
  reading `context.l`): that couples the message to the timing of a frame and shows the wrong string if the
  rebuild is delayed. Reading the target locale directly is the only deterministic fix.
- Do not remove the notification: it is the only confirmation of the change (the whole screen, for its part,
  updates on the next frame and the parent does not notice it) — fix it, don't kill it.

---

## B12 — Due reminders are at the bottom of the home: they should be at the top

**Status:** open (owner request, 2026-10-06:
« les rappels devraient être en haut de l'écran d'accueil » ) · **Cost:** trivial — a reordering
of the `Column`
**Found:** verification of 2026-10-06 — the due reminders list is the **third** child of the
   home `Column`, under the 2×2 tracking grid **and** under the row of growth buttons.
**Files:** `lib/features/home/presentation/screens/home_screen.dart:344-396` (the `Column`:
   `GridView.count` → `MeasurementButtonRow` → `HomeRemindersSection`),
   `lib/features/reminders/presentation/widgets/home_reminders_section.dart:19` (the doc comment says
   explicitly « sous les boutons de soin »).

### The fact
On the home, the current order is: (1) the 2×2 grid of tracking buttons
(`miam`/`santé`/`caca`/`dodo`), (2) the three measurement buttons
(weight/height/temperature), (3) the due reminders list of the active baby
(`HomeRemindersSection`). The reminders — the action of the day, « Vit. K à faire », « Yeux à nettoyer » — are therefore the **last** block of the screen: on a small phone, with two or
three due reminders, one has to scroll to see them. And yet it is the most urgent
information: a parent who opens the app in the morning first looks for « qu'est-ce qu'il reste à faire ? »
(what is left to do?), not « comment est-ce que j'enregistre ? » (how do I log?). The « +N » counter on the buttons' pills (`track_button.dart`) points to this list at
the bottom while the finger is at the top — the eye does a useless round trip.

### To do
1. In the `Column` of `home_screen.dart`, move `HomeRemindersSection` to the **first**
   child: due reminders → 2×2 grid → measurement buttons. It is a cut/paste of two widgets, no
   change to data, to provider, nor to behaviour tests.
2. Update the doc comment of `home_reminders_section.dart` (« sous les boutons de soin » →
   « au-dessus de la grille ») and the inline comment of `home_screen.dart:393`
   (« remplace la lecture du `+N` des pastilles, sans toucher à la grille ») — both are wrong after the
   reordering. (In English if B10 went first; otherwise in French, B10 will translate them.)
3. Empty state: `HomeRemindersSection` today renders the centred row
   « Rien à faire pour l'instant. » (`reminderListEmpty`) when no reminder is due. At the top of the screen, this row
   would take the first place **most of the time** (it is the normal state of a calm day).
   Decision at the plan: **hide the section when empty** (recommended — the silence is
   the information: nothing to do, we move to the buttons) or keep the discreet row. If hidden,
   the list appears/disappears through the day: verify that the layout jump does
   not disturb (the `SingleChildScrollView` absorbs it, but confirm on `Small_Phone`).

### Why it is trivial but not free
- The reordering is safe for tests: `home_screen_test.dart` and
  `home_baby_name_test.dart` assert the **presence** of the widgets (`findsOneWidget`,
  `findsNWidgets`), not their order — they pass unchanged. `home_reminders_section_test.dart`
  tests the widget alone, not its position.
- AGENTS.md is clear: unit tests do not render a layout on a 4.7-inch screen.
  The emulator pass (release gate) is **mandatory**: screenshots on `Small_Phone` + a
  normal device, with and without due reminders, **and** with the name in the app bar (B9) to verify
  that the top of the screen does not go crazy when the two tickets land.
- No migration, no export change, no provider: `reminderNotifierProvider`
  is watched by the widget whatever its position in the `Column`.

### Do not
- Do not touch the « +N » **pills** of the `TrackButton`s: they stay, they are the per-
  type indicator on the button; the top list is the detailed view. Removing them on the pretext that the list is
  now visible would be a feature removal without request — and B4 documents that
  these pills have a contrast problem to fix, not a redundancy.
- Do not reorder the **grid** itself (`miam`/`santé`/`caca`/`dodo`) nor the measurement buttons in this
  ticket: the request is « les rappels en haut », not « refaire l'accueil ». An extra
  reordering in the same diff is scope creep that complicates the review and the emulator
  pass.
- Do not hide the empty section **and** move the list to the top in the same PR without the
  `Small_Phone` capture: the layout jump on the first reminder resolved of the day (the list disappears, the
  grid comes back up) is exactly the kind of thing invisible in unit tests and annoying in
  real use — to validate by eye, not to guess.

---

## B13 — Sleep: the same minute is written in `quantity` AND in `duration`

**Status:** open, **post-v1.2.1** (the *display* part is already paid for in rc.2; the
*model* part is deferred) · **Cost:** small (write path + entity + tests); **zero migration**
if we do not clean up the existing rows
**Found:** 2026-10-13, at the rc.2 emulator pass — the owner saw « Quantité: 45 min » and
« Durée: 0 min » side by side on a nap.
**Files:** `lib/features/home/presentation/screens/home_screen.dart:204-208` (the `dodo` track
passes `duration: selection.minutes` **and** `quantity: selection.minutes`),
`lib/features/home/presentation/providers/track_notifier.dart:70-76` (`TrackingEvent.sleep`),
`lib/shared/domain/entities/tracking_event.dart:33` (`SleepEvent`: `duration` required + `quantity`
optional), `lib/data/local/app_db.dart` (columns `duration` and `quantity`, both `REAL NULL`),
`lib/features/history/presentation/widgets/history_tile.dart`.

### The fact
For a nap, the app logs **the same number of minutes in two columns**: `duration`
(the natural field of sleep, present since the beginning) and `quantity` (the generic field of
quantity, which v1.2.1 started filling for sleep so that
« la frise rende depuis la donnée comme toute autre ligne » — B1). The two columns exist for other reasons:
`quantity` serves the feed volume (ml/g), `duration` serves sleep. But for `dodo`, both
contain the same value.

The history tile was rendering **both**: `Quantité: 45 min` (from `quantity` + `unit`) and
`Durée: 45 min` (from `duration`). The same number, two labels. The owner first saw
`45` and `0` because the migration test database had `quantity=45` and `duration` absent (→ 0) —
but even with both at 45, the tile repeated the value.

### What rc.2 paid for (display only, not the model)
`history_tile.dart` no longer renders the `Quantité` row for a `SleepEvent`: a nap shows
**`Durée: X min`** only, the natural label of a dodo. The visible defect is fixed and tested
(`history_tile_test.dart`, « Sommeil : une seule ligne de valeur » group). The data model,
for its part, still writes both columns.

### The future fix — choose **one** canonical column for sleep
Goal: a nap carries its value **once**, in the field that makes sense.

- **Option A (recommended): sleep keeps `duration`, we stop writing `quantity`.**
  `home_screen.dart` passes `quantity: null` for `dodo`. `duration` is the semantic field of
  sleep; `quantity` stays the property of feeds (ml/g). **No migration**: new
  rows have `quantity=NULL`, old rows keep their two columns (identical, harmless)
  and are read via `duration`. Verify before touching: that no **read** path depends
  on `sleep.quantity` (the export already exports it, nullable; aggregates — B1 says nothing sums,
  to confirm for sleep duration).
- **Option B: sleep keeps `quantity` + `unit`, we stop writing `duration`.**
  Heavier: re-label the tile's label (today « Durée ») or accept « Quantité »
  for a dodo, and `duration` stays in the columns for existing rows. Less semantic.

### Why it is not in rc.2
rc.2 is the cursors removal + the date on two rows; adding the model point would add
nothing to the product (the visible defect is already fixed) but would open a **model decision** (entity
+ write path + possible cleanup of existing rows + export) at the worst time — the week
of a ship, on a base whose v11→v12 migration was just validated. It is a model debt,
not a display bug: it waits for a separate change, with its own review.

### Do not
- Do not **remove the column** `quantity` or `duration` from the schema: `quantity` is carried by the
  feeds (ml/g), `duration` has existed since v1. A column removal is an
  irreversible migration with no gain (B7 says the same thing for `measurements`).
- Do not **convert** a value: the two columns are equal, there is nothing to arithmeticise —
  the same rule as B1's backfill (« nommer, pas déduire »).
- Do not make this change **silently** in a sweep PR: it is a data
  semantics decision, it deserves its own ticket (this one) and its own review, even if the diff
  is small.

---

## B14 — "Custom reminders should make notifications"

**Status:** open (owner request, 2026-10-30: « custom reminder should make notifications ») ·
**Verification says the mechanism already exists in unreleased 1.3.0** — this ticket is
release-verify first, design only if the intent is narrower · **Cost:** zero if verification
closes it; medium (schema + export bump) if per-reminder times are the intent
**Found:** owner request 2026-10-30; state verified in `develop` (1.3.0+12) the same evening.
**Files:** `lib/features/reminders/domain/services/reminder_scheduler.dart:241-257`
(`_itemsForScope` — presets then customs), `:113-121` (enabled filter — a custom with no
`reminder_settings` row is scheduled),
`lib/features/reminders/presentation/providers/reminder_sync_notifier.dart:130-160`
(`_careLabel` — a custom's free-text label passes through untranslated),
`lib/features/reminders/presentation/providers/custom_reminders_notifier.dart:82` (create/edit →
`syncNow()` hook).

### The fact
**In `develop` (v1.3.0+12, merged via PR #50, not yet released), custom reminders *do* make
system notifications.** `_itemsForScope` appends every custom of the scope after the four presets;
the enabled filter skips only an explicit `false` row, so a freshly created custom is scheduled by
the very next `syncNow()`; the notification body carries the parent's label verbatim. Device-proof:
the M8 gate shows exactly the two seeded customs firing — « Nora : c'est l'heure de Bain. »,
« Léa : c'est l'heure de Portage. » (`docs/release-evidence/v1.3.0/iphone_17/`, app terminated,
10 delivered). **On the released build (v1.2.1) there are no system notifications at all** — that
release predates item 12 entirely. If the request comes from a phone running v1.2.1, shipping
v1.3.0 closes it.

### The gap that genuinely remains (the likely intent — confirm with the owner)
Every notification — presets *and* customs — fires at the **one global time**
(`notification_time_of_day`). A custom like « crème nombril, toutes les 8 h » rings at 09:00
whatever the routine says; and a custom created after that hour is silent until tomorrow's tick
(correct per D3, but it *feels* broken at the moment of creation). If the request means **a
notification time of its own per custom reminder**, it is a model change, not a schedule tweak:
- `custom_reminders` gains a nullable time column (schema v14) — `null` = inherit the global hour;
- export format **v5** + importer acceptance in the same change (AGENTS.md: the two features move
  together), `parseNotificationTime` as the single validator (the importer already reuses it);
- the plan key must fold the per-item time (content-aware diff, `_PlanEntry`) or an edited time
  leaves a stale schedule behind;
- form sheet: an optional time row on the custom-reminder form, fr/en/es l10n.

### To do
1. After v1.3.0 ships: verify on the owner's real device (real OEM banners differ from the
   simulator's — this behaviour has *device* evidence only from the gate's emulator/simulator).
2. Ask the owner whether « make notifications » meant *at all* (closed by shipping) or *their own
   time* (the model change above — then it is a planned milestone, not a patch).

### Do not
- Do not add a per-custom time column before the owner confirms that is the intent — one migration
  per guessed requirement is how schema debt compounds (B1's record).
- Do not deliver anything via network transport (FCM/APNs-remote) to « make notifications
  reliable »: local scheduling only, charter non-negotiable.
- Do not treat « no notification the hour it was created » as a bug to fix by firing at creation
  time: D3 catch-up already decides when a just-created reminder is genuinely due; double-firing
  at creation + at the tick is the nag the plan's diff model exists to prevent.

---

## B15 — Validation of a reminder or notification should create the action

**Status:** open (owner request, 2026-10-30: « Create action from reminder or notification
validation ») · **Cost:** medium (payload + response handler + one decision about D2) · **Risk:**
low, additive — nothing existing changes semantics
**Found:** owner request 2026-10-30; verified same evening — **today the tap is inert**.
**Files:** `lib/features/reminders/domain/services/reminder_scheduler.dart` (submits title/body,
no payload), `lib/features/reminders/data/services/flutter_local_notification_service.dart`,
`lib/features/reminders/presentation/providers/reminder_notifier.dart:153-166` (`markDone`),
`lib/main.dart` (no response handler anywhere — verified: zero hits for
`onDidReceiveNotificationResponse`/`getNotificationAppLaunchDetails` in `lib/`).

### The fact
A 3 a.m. parent who taps « Vitamine D — c'est l'heure » from the banner gets: the app, open,
home screen, nothing recorded. Two deliberate v1.3.0 choices add up to that dead end:
1. Scheduled notifications carry **no payload** (the scheduler was scoped to title/body — the
   identity of the firing item is not delivered), and **no response handler exists anywhere**
   (nothing to receive a tap even if the payload were there).
2. `markDone` on a treatment-linked item creates **no record** (D2: only the real health event
   settles it, by design — the pill button just re-evaluates). Only detached customs get a
   `reminder_completions` row.
So « validate from the notification » has no path at all: tap cannot confirm what tap cannot
identify, and confirming a preset is defined as *not* creating anything.

### To do
1. **Payload at schedule time**: `babyId` + the stable `item.id` (`vitamine_d`, `custom_7` —
   never the plan-index/OS id, which is a derived cache and reshuffles with the plan, D2/D5).
   Both values are already plaintext elsewhere (the body carries the name); the payload stays
   local — notifications never leave the device.
2. **Response handler** in the service + `main.dart`: foreground
   (`onDidReceiveNotificationResponse`) and Android background
   (`onDidReceiveNotificationResponse` + background handler; iOS category actions) — verify the
   cold-start semantics of `flutter_local_notifications` 22.x per platform before choosing what
   a tap-on-killed-app does; do not assume it fires.
3. **The action it creates — one decision, then the same path everywhere:**
   - detached/manual custom → `markDone` (`reminder_completions` row) — the semantics already exist;
   - treatment-linked item → open the app **on the matching health sub-type sheet, pre-filled**
     (parent taps the confirm that is already the product's one honest way to record the care) —
     or create the health event directly. Recommendation at the plan: **deep-link, not
     auto-create** — an auto-created event would make the app author health records the parent
     never entered through the care flow, and a mistap on a banner becomes a record in the
     paediatrician's export.
4. Either way, after validation: the current notification is settled until the next due (D3
   dismissal/completion discipline) — no re-fire tonight.
5. Scope discipline unchanged: `await ref.read(activeBabyProvider.future)`, never a transient
   `.value` (the `''` carry-over trap).

### Do not
- Do not treat a bare notification **tap** as completion of a treatment reminder — tap is
  attention, validation is a press on an explicit « Done » / the health sheet's confirm.
- Do not put the plan index or OS notification id in the payload; identity = `babyId` + `item.id`.
- No new permission, no network, no remote push — same charter as B14.
- Do not touch `sync()`'s diff model: the payload rides the existing submission path.

---

## B16 — No note when creating a feeding

**Status:** open (owner request, 2026-10-30: « Write note on food creation ») · **Cost:** small —
one optional field in one dialog; the storage, encryption and export paths already exist
**Found:** owner request 2026-10-30; verified same evening.
**Files:** `lib/features/home/presentation/widgets/feeding_tracking_dialog.dart` (zero note
mentions), `lib/features/home/presentation/providers/track_notifier.dart:34` (`track()` already
accepts `notes`), `lib/features/home/data/repositories/tracking_repository_impl.dart:66` (encrypts
`notes` before insert), `lib/data/local/app_db.dart:24` (`notes TEXT NULL`, encrypted at rest),
`lib/features/history/presentation/widgets/edit_event_dialog.dart` (today's only feeding-note
editor), `lib/features/home/presentation/screens/home_screen.dart:167-263` (the four `track()`
call sites — none passes `notes`).

### The fact
The note **already exists end to end** — column, encryption at insert, decryption through
`tracking_event_mapper` on export, rendering on the history tile — except at the one moment it is
worth anything: **creation**. None of the four creation dialogs exposes it (verified: 0 note
mentions in the feeding, health, waste and duration dialogs), so the parent who wants « refused
the left breast, fussy » must remember, later, to find the row in Historique and open the edit
dialog. At 3 a.m. the note is lost, and the app's whole note feature is reachable only from the
history screen. The request names food specifically; the same gap exists for the other three
types — **this ticket is feeding only** (the owner asked for feeding).

### To do
1. One optional field in `feeding_tracking_dialog.dart` — collapsed or single-line, disabled
   parent-side default is fine (empty field must insert `NULL`, not `''`); pass it through
   `track(notes: …)`; encryption is the repository's job (already is) — never encrypt in the UI.
2. `Small_Phone` release-gate screenshots, both themes: keyboard inside a dialog is exactly the
   layout overflow unit tests cannot see (AGENTS.md gate rule 2).
3. l10n: one placeholder key in the three arbs (fr « Note (facultatif) » style, term-aligned with
   the edit dialog's existing note label — reuse it if one exists).
4. Tests: empty note → `NULL` row; note round-trips through `track()` → history tile renders it;
   feeding note survives export/import (the `notes` column is already in the format-4 contract —
   **no version bump**).

### Do not
- Do not bump the export format: `notes` is already exported (decrypted, via the mapper) for every
  event type; creation-time input changes the entry point, not the contract.
- Do not silently widen the ticket to sleep/waste/health in the same PR without the owner asking;
  if they do want all four, it is the same diff four times and a bigger emulator pass.
- Do not render the feeding note anywhere it was not rendered before (history tile only) — the
  privacy surface of the note does not grow.

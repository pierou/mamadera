# Release plan — v1.3.0 (to ship) then v1.3.1 (legibility)

**Written:** 2026-11-01. **Verified by:** main session, against the working tree at `0a7ff68`
(`develop`, in sync with `origin/develop`), plus two subagent sweeps whose claims were
re-checked by hand — corrections are marked *(subagent claim, wrong)*.
Every number below was measured in this session; nothing is recalled.

---

## 1. v1.3.0 is staged, not shipped

| Check | Result |
|---|---|
| `git tag -l '*1.3*'` | empty — **no `v1.3.0` tag** |
| `gh release list` | newest is **v1.2.1**; the GitHub **"Latest" marker sits on v1.1.0** |
| `main` | at `9e61377` = v1.2.1. `develop` is **54 commits** ahead, `pubspec.yaml` = `1.3.0+12` |
| `gh issue list --state open` | empty. One open PR: **#52** (B14–B17 docs) |
| M8 device gate | **passed 2026-10-30** — `f8b3639` (10-27, "device pass pending") is an *ancestor* of `e3004e9` ("full M8 gate passed both platforms"). *(subagent claim, wrong: flagged as a contradiction; it is the normal order.)* Evidence: `docs/release-evidence/v1.3.0/{pixel_10_pro,iphone_17}` incl. the `1.2.1+11 → 1.3.0+12` migration proof |
| `store/v1.3.0/` | `fields/` (25 files), `release-notes/` (9), `machine/{fr,es}`, `screenshots/play/{en,es,fr}` 8×8, `check.py`, `capture.sh` — **complete per the toolchain**: `build_store_package.py` writes only `fields/`, `release-notes/`, `machine/`, `check.py`. *(subagent claim, over-stated: "upload package never assembled".)* v1.2.1's extra `apple/*.md`, `play/*.md`, `asc-resubmit.md` are hand-assembled paste bundles, and `fdroid/` is separate work |
| Play Console / App Store Connect | **unknown from this repo** — the one fact that decides whether v1.3.1 can exist. Ask before numbering anything |

Consequence: v1.3.0 has never been published, so it is still **editable**. Anything that must
reach users without a second review cycle belongs in it, not in a patch.

---

## 2. Decision: the milk-label fix belongs in v1.3.0, not v1.3.1

The uploadable store frames show the defect, in every locale:

- `store/v1.3.0/screenshots/play/fr/fr-feeding_dialog.png` → « ✓ 🥛**Lait …** » (label invisible)
  and « ☕**Lait Artif…** »
- `store/v1.3.0/screenshots/play/en/en-feeding_dialog.png` → « ✓ 🥛**Breas…** », « Formula », « Solid »

So publishing v1.3.0 as staged publishes a **store listing image displaying a broken selector**,
in the app's three listing locales — French being the highest-value one
(`docs/research/`, 368 485 neonatal deaths/yr = 16.2 % of the global total). The store set cannot
be honestly recaptured without the fix, and the fix is already written, tested and CI-green.

**Therefore:** `fix(feeding): subtype chips size to their label` lands **before** the `v1.3.0`
tag, and the feeding frames are recaptured for fr/en/es. v1.3.1 then carries the rest of the
legibility pass (§4). The build number stays `+12` — nothing was ever uploaded, and the counter
is monotonic per *release*, not per commit (`docs/PLAN-item-12-notifications.md:328`).

---

## 3. v1.3.0 gate status

`make gate` is the local mirror of CI (`Makefile:20`) — `make ci` is only the fast subset.

| Gate item | State |
|---|---|
| `version-sync` (pubspec ⇄ `AppConfig.version`) | green, CI-enforced at `.github/workflows/ci.yml:97-103` |
| `lint` (`--fatal-infos --fatal-warnings`) | green |
| `test` + `check-coverage` | green, 88 % vs 80 % floor |
| `check-architecture`, `check-complexity` | green |
| `format-check` | advisory only (`Makefile:41-48` never fails); the tree is largely unformatted — 144/257 files per `docs/AUDIT-2026-10-19.md:285`, owner decision pending |
| `store-check` | green for `v1.3.0`; **ASC WARN lines are a decision, not an accident**: `asc/fr/<size>` are empty because only bare-named captures exist under `screenshots/ios/asc/<size>/` |
| `audit-trivy`, `audit-gitleaks` | run in `gate`; no-op if the tool is absent |
| Chip-label fix | **committed** `5bec57b` — `OptionChipRow` + both dialogs + regression tests |
| Patch notes `1.3.0` | done in `eca8c1d` (fr/es noun form), `release-notes/` re-rendered via `make store-package` |
| Play screenshots | **recaptured 2026-11-01** on `Pixel_10_Pro` via `store/v1.3.0/capture.sh`: fr ✓ es ✓ en ✓, 8/8 per locale at 1280×2856, locale-prefixed, `check.py` → **PACKAGE OK**. The feeding frames now show the fixed selector in all three languages. `asc/*` (iOS) still empty = the pre-existing WARN, simulator pipeline not run |
| Emulator pass (AGENTS.md, non-negotiable) | **Small_Phone leg done 2026-11-01** — migration with old data, all touched screens, manual entry + export inspected. Evidence: `docs/release-evidence/v1.3.0/small_phone/` (§3a). Normal-size leg: `pixel_10_pro/` from 2026-10-30, pre-fix |
| `make gate` | **green end-to-end 2026-11-01**, exit 0 (version-sync, lint, 1500 tests, architecture + complexity ratchets, 88 % coverage, store-check, trivy, gitleaks) |
| F-Droid | `docs/fdroiddata/com.pvjio.mamadera.yml` stops at `versionName: 1.2.1 / versionCode: 11` — the `1.3.0 / 12` entry and its changelog are missing |
| Tag + GitHub release + move "Latest" off v1.1.0 | **not done**; push/publish stays with the owner |
| Console uploads (Play track, ASC metadata + screenshots) | human only |

### 3a. The Small_Phone leg, what it actually proved (2026-11-01, `small_phone/00-note.txt`)

Driven over adb only (`input tap` + `uiautomator dump` + `exec-out screencap`), on a wiped
`Small_Phone` AVD — the smallest target AGENTS.md names, which no evidence existed for until now.

1. **Migration, on a device that had old data.** v1.2.1+11 installed, profile "Nora" created, 3
   events logged through the UI, DB pulled: `user_version` 12, 1 profile / 3 events / 0 measurements.
   Installed v1.3.0+12 over it. After: `user_version` **13**, `app_settings` table created, all 3
   events present with subtype/quantity/unit intact and visible in History and on the tiles.
   A fresh install cannot prove any of this.
2. **The fix on hardware, before/after in French** — « ✓ 🥛…a… / ☕ Lait A… » on v1.2.1 vs
   « ✓ Lait Maternel / ☕ Lait Artificiel / Solide » on v1.3.0 (screenshots 18, 19), plus the edit
   dialog (20). Worth noting: `uiautomator` reported the **full** label on the broken build too —
   semantics never showed the truncation, only pixels did, so no semantics-based test could have
   caught it.
3. **Manual path + export.** Feeding + sleep (old build), weight (new build), then
   *Exporter mes données* → share sheet → JSON pulled out of `cache/` (24): `exportFormatVersion 4`,
   `databaseSchemaVersion 13`, all eight sections present, counts matching the DB row-for-row —
   including the `appSettings` section this release added. Weight is ciphertext in the DB and
   `"3510.0"` in the export, so at-rest encryption and the sanctioned plaintext exit both hold.
4. **Two findings that only hardware gave** — B4 pixel-sampled (⇒ §6.2 closed) and the hardcoded
   English baby age (new ticket **B18**, `BACKLOG.md`). It also cleared one suspicion: no `+N` pill
   on the tiles despite 3 events today, identical on both builds → not a v1.3.0 regression.
5. **Play frames recaptured afterwards**, on `Pixel_10_Pro` (1280×2856), all three locales, using
   `store/v1.3.0/capture.sh` unmodified behind a `--verbose` shim — `flutter drive` is *silent*
   without it on this Mac (§6.2). Measured in the artefact: selected chip **1.01:1 → 15.88:1**;
   unit toggle **1.32:1**, untouched and still failing → added to B4.

---

## 4. v1.3.1 — the legibility patch

The milk chips were one instance of a single root cause: **a label is painted with the accent
tint instead of a contrast-guaranteed foreground.**

Measured. WCAG AA = 4.5:1 normal text, 3:1 large. Computed from the `AppTheme` palette
(`theme.dart:35-38`) composited through `track_button.dart:173-214` (label colour = the accent
itself at `:210`, card = accent at 8 %/2 % over the scaffold colour). **Not pixel-sampled** —
B4's own to-do (#1) still asks for a device sample + calculator.

| Button label | light mode | dark mode | AA (large text ≥ 3:1) |
|---|---|---|---|
| `miam` Feeding | **1.17:1** | 8.64:1 | fails in light |
| `sante` Health | **2.04:1** | 5.08:1 | fails in light |
| `dodo` Sleep | **2.28:1** | 4.57:1 | fails in light |
| `caca` Diaper | 7.56:1 | **1.43:1** | fails in dark |

**4 of 8 button×theme pairs fail**, three of them near 1:1. Visible in the project's own release
evidence: in `docs/release-evidence/v1.3.0/pixel_10_pro/06-home-nora-after-migration.png`,
"Feeding" and "Weight" are pale yellow on pale cream and nearly disappear — the M8 gate passed
with that on screen.

`docs/BACKLOG.md:142` (B4) names two of these. The structural fix it recommends — keep the tints,
give the **label** a guaranteed-contrast colour — is exactly what was done for the chips: selected
chip label **1.05:1 → 15.29:1** (white on `miam` 20 % → `onSurface` on the same fill).

### Scope, with the state I verified myself

| Item | Verified state | Cost |
|---|---|---|
| B4 button labels + `+N` pills | 4 failures measured above; `track_button.dart:249-251` already picks white70/black54 by brightness, so the pattern exists in the same file | small + a verification pass on both themes, smallest device |
| Waste-type chip row | `edit_event_dialog.dart:415-421` is the last `Row`+`Expanded` selector. **Does not clip** — its `Text` has no ellipsis, so it soft-wraps; chips are 48 dp tall (= 2 lines) at 320/360/393 dp. Polish, not data loss. `:460-500` already use `Wrap` | one line, `OptionChipRow` exists |
| **B6 — Vitamin D default** | `reminder_providers.dart:87` still `settings[item.id] ?? true`; zero `enabledByDefault` in `lib/`; owner decision **A** (new default only, no migration) dates 2026-10-06 and was never built. Visible in the release evidence: the "Vit. D" pill is on | small: one field + fallback + 3 arb strings. Wording constraint: never "the app now follows the WHO" |
| B11 — language-change snackbar | `menu_screen.dart:240-242`, verbatim the documented bug; `lookupAppLocalizations` already exists | trivial, fix written in the doc |
| B18 — baby age hardcoded English | `baby_profile_section.dart:491-504`, seen on device in French; ARB keys exist in all 3 locales and are unused | ~10 lines + the anniversary arithmetic the same lines lack; no migration, no export bump |
| B12 — reminders below the fold | `home_screen.dart` Column: grid `:351` → measurements `:398` → reminders `:401`; now seen on the small device too (« Rappels à faire » at the very bottom edge of `small_phone/22-…png`) | trivial reorder + **owner decision: hide the section when empty, or keep "Rien à faire"** |

### Cut from v1.3.1

B3 sync (blocked on a **written** privacy-mandate change, `BACKLOG.md:130`) · B8 growth chart
(feature + dependency privacy audit) · B15/B16/B17 (features; PR #52 still open; B16 touches the
feeding dialog, so schedule it right after) · all clinical content (IMNCI colours, fever
threshold, percentiles — partner-gated per `docs/research/`) · **replacing** the four identity
tints (only the label colour changes; `BACKLOG.md` warns an unmeasured change breaks two others).

---

## 5. Corrections to stale docs

Found while planning; each measured in this session.

- **B4 understates the problem** — 4 failing pairs, not 2. Measurement now recorded in
  `docs/BACKLOG.md` B4.
- **B10 (French comments) is effectively done.** `lib/`: 2 accented comment lines remain, both
  legitimate — `tracking_event.dart:116` quotes the DB value `pâteux`, and
  `option_chip_row.dart:21` contains `×`. `test/`: **17 lines in 5 files**.
  `integration_test/`: **4 lines in 2 files**. So the remaining work is test-tree polish, not the
  "~5–8 h" in the ticket, and the CI guard the ticket proposes is now nearly free to add.
- **Roadmap §10 item 14** (± stepper buttons) shipped: `quantity_picker_inline.dart:220-221`.
- **Roadmap §10 item 18** (unlocalized baby age) — I called this obsolete and **I was wrong**;
  corrected 2026-11-01 after the device pass. The observation was right (`daysOld`/`monthsOld` are
  generated and used nowhere in `lib/`) but the conclusion inverted: the header is not the place,
  the **Menu baby card** is — `baby_profile_section.dart:491-504` hardcodes '"$days days old"', so
  a French UI shows « 0 days old » on a real device. Dead keys + live defect ⇒ they are dead
  *because the wiring was never written*. Opened as **B18**.
- **B9 stays real**: the AppBar title is a plain `Text` (`home_screen.dart:332-336`) and inert.
- Closed testing wording in `docs/SUBMISSION-CHECKLIST.md` still says "v1.1.0 is live on Google
  Play" and describes 1.1.1 as the routine update — stale by two releases.

---

## 6. Not verified / open

1. **Play Console and App Store Connect state** — nothing in the repo records an upload of
   `1.3.0+12`. Decides v1.3.0-vs-v1.3.1 numbering. Check the console before tagging.
2. ~~B4 ratios are computed, not sampled~~ **sampled 2026-11-01** — light mode on a device
   (1.15 / 1.89 / 2.07 / 6.47:1 against 1.17 / 2.04 / 2.28 / 7.56 computed) and the segmented
   toggle in the store frame at **1.32:1**. Tool: `scripts/wcag_sample.py`. Still open: the same
   sample in **dark** mode, which so far exists only as a computation.
   `flutter drive` was never broken: on this Mac, Flutter 3.44.8, with stdout redirected it emits
   **nothing** and looks hung (0 bytes, 0 % CPU, holding the SDK lock while it waits). With
   `--verbose` the same command finished 8 frames in ~90 s. Use
   `PATH=/tmp/flshim:$PATH VERSION=1.3.0 bash store/v1.3.0/capture.sh <serial>` with
   `flshim/flutter` = `exec ~/flutter/bin/flutter "$@" --verbose`, and kill orphaned
   `flutter_tools` processes before retrying — they hold the lock and freeze every later flutter
   command.
3. F-Droid publish status for 1.2.1 (`docs/AUDIT-2026-10-21.md:60` records PR #48/#49 merged,
   publish unrecorded).
4. `docs/RELEASE-PROCESS.md` still absent (`AUDIT-2026-10-21.md:194`, G2) — this file is a plan
   for two releases, not the reusable process doc.
5. Required GitHub checks are not enforced (`AUDIT-2026-10-21.md:52`, P1-1) and there is no
   `dependabot.yml` (P2-2). Both are free, neither is release-bound.

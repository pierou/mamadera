# Plan — French code comments → English (mamadera)

Status: **stage 0 done** (extraction + audit). Blocked at stage 1 on a memory decision.

## Scope (measured, not estimated)

| | |
|---|---|
| Dart files scanned | 238 |
| Files with French comments | 147 |
| French comment lines | 2 609 (160 338 chars) |
| Tokens in / out | ~44.5k / ~51.2k |
| Translation units (chunked) | 153 |

Excluded by design: `*.g.dart`, `*.freezed.dart`, `lib/l10n/**`, `*.arb`,
`assets/patch_notes/*.json`. Generated code is regenerated, and the ARB/patch-note
files are the French **product**, not comments. No non-Dart file carries French comments.

## Tooling

`scripts/fr_comments.py` — the model never sees code, never writes files.

`scan` · `extract` · `audit` · `translate --dry-run` · `translate --model mac|box` ·
`pack` · `review-apply` · `apply` · `verify` · `status`

- Comments are lifted with `line`, `marker`, `indent`, `prefix`; only the prose is sent.
- `apply` re-renders `indent + marker + prose` at the recorded line and aborts unless the
  **code skeleton** (all source with comment bodies blanked) is byte-identical to the
  snapshot taken at `extract`. A mistranslation cannot corrupt code silently.
- Contract per request: one output line per input line, none empty. Violation → chunk
  halves → single-line retry → `FAILED` (recorded, never guessed).
- Work dir `.fr2en/` (gitignored), resumable: `status` / rerun `translate`.

## Stage 1 — RESOLVED: box 12B translates, Flash Next hardens (measured 2026-10-16)

The mac 27B path was tried and rejected on measurement, not preference. Same 70 stratified
lines, official `tg-translate` template, temp 0:

| backend | clean | empty | loop | s/line | oMLX cost |
|---|---|---|---|---|---|
| **box `translategemma-12b-Q8`** | **70/70 = 100%** | 0 | 0 | **0.81** | **none** |
| mac `translategemma-27b-it-mlx-fp16` | 61/70 = 87% | 5 | 4 | ~5.0 | 56.7 GB of 98.8 ceiling |

The 12B was **faster and structurally more reliable**: it translated all 9 lines the 27B
blanked or looped on (`propage jusqu'aux pastilles…` → empty on 27B; `réglages → rappels
activés → service` → `→ → →` loop on 27B). The repetition loops live in **oMLX**, which has
no repetition penalty configured; llama.cpp's server-side defaults suppress them. Smaller
model, better service.

**Decision: the translator is cheap and the reviewer is the brain.** ~35 min on the box buys
machine throughput; the ~2.5 h saved is spent on the code-truth pass, which is the only thing
that can fix a fluent-but-wrong comment. Google's own MetricX claim (TranslateGemma-12B beats
the *Gemma 3 27B* baseline) pointed the same way: 27B buys nuance, it is not a rescue.

Because the 12B is **less literal** than the 27B, the review pass matters *more*, not less.
Already caught in the sample — the 12B dropped a qualifier from a code reference:

- ``base (`reminder_settings.baby_id`)`` → ``The `baby_id` is always used as the base``
  — **`reminder_settings.` gone**, and words added that are not in the source (*"clearly"*,
  *"It"*, trailing `...`). Correctness is the reviewer's job; the translator's word is never final.

## Stage 1b — two-pass self-disagreement (ambiguity ranking, costs no brain time)

Pass 2 re-translates every line at **temp 0.7** into `.fr2en/out2/` with its own cache, and
`disagree` scores each line against pass 1 (`difflib` on normalised text — case, quotes,
dashes, trailing punctuation are not signal).

**temp 0 would be byte-identical and prove nothing** — the pipeline is deterministic, so pass 2
must sample differently to be an independent measurement. Cache keys therefore include **model
and pass**: two backends must never share cached output (measured: the 27B blanks 13% of lines
the 12B translates cleanly, so a shared cache smuggles blanks into a box run).

| score | meaning | action |
|---|---|---|
| ≥ 0.98 | identical twice | low priority |
| 0.80–0.98 | wording differs, same meaning | skim |
| 0.60–0.80 | divergent | read against code |
| **< 0.60** | **say something different** | reviewer must decide, `review-priority.tsv` |

**Agreement is not correctness.** A line can agree twice and still be wrong about the code —
this ranks review effort, it does not replace the code-truth pass.

## Stage 2 — sequencing

Box run: ~0.81 s/line ⇒ **~35 min** per pass, resumable line-by-line, no memory dance. Two
hard constraints:

- **Never alongside a `box-*` agent** — the box runs one model instance; loading
  `qwen38-udiq4xs-CODER` evicts TranslateGemma mid-run. Pass 2 runs *after* pass 1.
- **Never two LAN model ids in one run.** Mac agents stay available during a box run.

The mac 27B stays available as the quality-ceiling option only (`--model mac`), never the
default: each mac load evicts the Mac brain, reload ≈ 111 GB × 0.77 s/GB ≈ **86 s**, so a mac
run must be one detached blocking call, never 153 turns.

## Stage 3 — code-truth review (the real risk)

TranslateGemma is faithful, not correct. Approximative French yields fluent wrong English.
Exemplar found in stage 0:

`lib/data/local/app_db.dart:28` — FR *"couleur de la selle ou pipe-délimitée (pipi|caca)"*
on the `color` column. `colorDbValue` writes `pipiColor|cacaColor` — **colours**, never
`pipi`/`caca`. A faithful translation freezes the error in English for years.

Two-layer check, after translation, per file:

1. **`audit`** (free, mechanical): every `identifier`, `'literal'`, `[dartdoc]` named in a
   comment must exist in the code skeleton corpus. Now: 513 named tokens, **19 unresolved**
   (`.fr2en/review/audit.tsv`) — placeholders, framework names, `lastDismissedAt` (stale?).
2. **`pack` → reviewer → `review-apply`**: packets give `L<line> / FR / EN / code window`.
   A **reasoning model** (never TranslateGemma) answers one line per entry:
   `OK` | `FIX\t<single-line English, ≤100 chars, no code>` | `ASK\t<question>`.
   `review-apply` refuses targets that are not comment lines, refuses code in FIX text,
   re-checks the skeleton, and prints the ASK list for you.

Routing: `box-coder` for the 90 `test/**` + `integration_test/**` packs (input-heavy,
3.4× prefill, one box agent per call); `reviewer` (27B Mac) for `lib/data/local`,
`lib/core`, and every domain repository — ~25 files, the ones where a wrong comment
becomes a wrong fix.

### Escalate, never auto-fix

- Clinical / WHO / vitamin-D statements — wording is load-bearing, severity must not drift.
- Privacy mandate sentences (encryption, "never leaves the device").
- Migration and schema version claims (`v10`→`v11`, `DEFAULT 'ml'`).
- Anything the reviewer answers `ASK`.

These go to `docs/TRANSLATION-FINDINGS.md` with FR, literal EN, adopted EN, code evidence.

## Stage 4 — gate

`flutter analyze --fatal-infos --fatal-warnings` → `make test` → `git diff` review of every
file → emulator pass per AGENTS.md before the PR. Comments-only diff: `verify` reports
0 skeleton drift, 0 French lines left.

## PR shape

1. `chore: add fr→en comment pipeline` (scripts + this plan)
2. `docs: translate lib/ comments` (lib, reviewed)
3. `docs: translate test/ + integration_test/ comments` (box-reviewed)

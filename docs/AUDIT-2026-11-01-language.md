# AUDIT — 2026-11-01 (Language: where French legitimately lives, where it does not, and what to fix)

Scope: this repo + `~/binvest` (the two repos the owner flagged on 2026-11-01: « badly
translated French in docs, and French in committed files that shouldn't contain French »).

Method: full scan of every git-tracked, non-binary file (accent characters + high-precision
French word list + French commit subjects), then **every French deliverable was read in full**
and every flagged code file was classified by hand. Scanner: `/tmp/fr_audit.py` (scratch, not
committed). Every claim below was verified on 2026-11-01 on branch `release/v1.3.0` unless
dated otherwise.

## 0. Scale

| | Files with French markers | French commit subjects |
|---|---|---|
| mamadera (this repo) | 277 tracked | 24 (2026-10-14 → 2026-10-21) |
| binvest | 76 tracked | 1 (a French domain word inside an English subject) |

Classification after reading: the large majority of both columns is **legitimate** — this is a
French-first product with a trilingual store. The actual defects are much smaller and all
located:

- **§2 — French that shouldn't be there** (code/tests): 378 test descriptions, 6 comment
  lines, 2 mangled doc-comment blocks, 24 historical commits.
- **§3 — French that is there but badly done** (user-facing deliverables): 3 defects in the
  legal CGU + a disputed CSV claim, dev-jargon patch notes in all 3 locales, calques in the
  v1.3.0 whats-new.
- **§4 — root causes** (why it keeps getting produced).
- **§5 — plan**, P1 (before v1.3.0 is tagged), P2 (soon), P3 (binvest), plus explicit
  do-nots.

## 1. Legitimate French — do not touch

| Location | Why it's correct |
|---|---|
| `lib/l10n/app_fr.arb`, generated `app_localizations_*.dart` | The product (strategic asset per AGENTS.md) |
| `assets/patch_notes/{fr,es}.json` (structure), `assets/terms/terms_{fr,es}.md` | User-facing FR/ES documents — *quality* issues only, see §3 |
| `store/**` FR/ES (`machine/`, `fields/`, `release-notes/`, `fdroid/changelogs/`), `fastlane/metadata/android/{fr,es}/`, FR screenshot campaigns | Store surfaces (v1.3.0 untagged → fixable before submission, §3.3) |
| `docs/release-notes/v1.1.0.fr.md` | Hand-written, reads well (read in full 2026-11-01) |
| `docs/release-evidence/**` | Captured UI logs in the FR locale — evidence, not prose |
| Test **fixtures and expected UI strings**: `'Bébé Test'`, `miam`/`pipi`/`caca` (DB values), baby names (Léo, Béa, Aimée, Léa), `find.text('Couleur du pipi')` etc. | The app defaults to French; tests assert the FR UI. Not translatable away |
| `docs/*.md` (BACKLOG, PLAN*, AUDIT*, ROADMAP*) quoting French UI strings in English prose | By design — the docs discuss French strings |
| `scripts/fr_comments.py`, `docs/PLAN-fr-comments-to-english.md`, `.fr2en/` (gitignored) | The B10 pipeline itself |
| The two `lib/` accent lines B10 already judged legitimate (2026-11-01 recount): `lib/shared/domain/entities/tracking_event.dart:116` (quotes DB value `pâteux`), `lib/shared/widgets/option_chip_row.dart:21` (a `×` — false positive, not a French character) | Closed in B10 |

## 2. Violations — French in files that should be English

### 2.1 FR test/group descriptions: **378 in 50 files** (the big one B10 missed)

B10's scope was comments only (« the code carries `//` and `///` comments in French »). The
`test()` / `testWidgets()` / `group()` **name strings** were never in scope, so they
survived the whole B10 sweep:

```
testWidgets('minuit est formaté correctement', …)          // test/core/l10n/date_localization_test.dart:46
test('encrypt("") retourne une chaîne vide (optimisation)') // test/core/services/encryption_service_test.dart:61
group('formatDate — les trois locales sur une date fixe')   // test/core/l10n/date_localization_test.dart:98
… 378 total, 50 files (worst: history_tile_test 23, encryption_service_test 20,
  edit_event_dialog_test 19, history_repository_impl_test 15)
```

These names are what `flutter test` prints and what RAG/agent search indexes — exactly the
readers B10's rationale names. Propose as **B19** (§5).

### 2.2 B10 tail — French *comments*: **6 lines, 1 file**

B10's 2026-11-01 recount said « 17 lines in 5 files » under `test/`. Re-run of the same
criterion on 2026-11-01: most of those 17 are **French baby names inside English comments**
(`// Aimée keeps her ids…`, `// Béa's vit K is due…`) — legitimate fixtures, not French
prose. The genuinely French comment prose left:

- `test/core/l10n/date_localization_test.dart:60-62, 89-90, 99` (6 lines, e.g. « elles ne
  doivent pas être « corrigées » en arrière »)
- `integration_test/`: 0 French prose lines (only FR UI quotes + names, legitimate)

So B10's comment work is 6 lines from done.

### 2.3 B10 stage-3 escapes — mangled English in `integration_test/` doc comments

The machine translation that anglicised `lib/` left two gate files half-broken (the plan's
stage-3 routing assigned `integration_test/**` to `box-coder`; the escapes show that review
either didn't happen or didn't catch mangled output):

- `integration_test/pickers_gate_rc2.dart:25-52` — French heading survives (`/// ##
  Lancement`, line 27) and sentences are truncated mid-clause:
  « (while `flutter drive` raises…) », « `(Relative path raises errno 30 on iOS), then exits
  the sandbox:` », « `while Android uses...` ».
- `integration_test/entry_sheet_gate_rc4.dart:17` — `/// ## Lancement` inside an otherwise
  clean English comment.

### 2.4 French commit subjects — 24 commits, 2026-10-14 → 2026-10-21

`b0c3d54` … `6133af9` (full list in the scanner output). Examples: « docs(audit): 2026-10-21
— CI, modèle de branches et release train », « fix(gitignore): le projet iOS et les preuves du
gate ne pouvaient pas être suivis ». **All commits since 2026-10-22 are English** (verified:
latest 8, 2026-11-01) — the practice has already stopped. Recommendation: do **not** rewrite
history; stop it structurally instead (§4, A7/A6).

## 3. Quality defects — French that is there but badly done

### 3.1 `assets/terms/terms_fr.md` — the legal CGU (P1, 3 defects — corrected 2026-11-01)

| Line | Defect | Fix |
|---|---|---|
| §10 (all caps) | « DES DOMMAGES RÉSULTANT DE LA **FIANCE** AUX DONNÉES » | « …DE LA **CONFIANCE ACCORDÉE**… » (EN source: « RELIANCE ») |
| §2, §5 | English loanword « les **patterns** de sommeil » / « routines et patterns » | « les **rythmes** de sommeil » / « les routines et les rythmes » |
| final line | Straight quotes `"J'accepte"` | « J'accepte » (matches `termsAcceptButton` in `app_fr.arb`) |

*Retracted from the first draft of this audit:* « **la** CCPA » is not an error — French legal
usage (CNIL) uses « la CCPA » with the implied « loi ». Not touched.

The **CSV claim** is open, not closed: §3.3 promises « Export your data in JSON **or CSV**
format » in all three locales, and `.github/SECURITY.md:43` repeats it (« JSON encrypted or
CSV ») — but `lib/` contains no CSV export (git-grep 2026-11-01: zero hits outside terms/docs),
and `docs/google-play-setup.md:51` states outright: *“CSV export does not exist.”* The owner
stated 2026-11-01 that “csv export is done”; the tree does not show it, so the claim was left
untouched and the discrepancy is flagged in the sweep PR — **awaiting: where the CSV export
lives** (unpushed branch? another repo?). If it does not exist, the line must come out of all
three CGU locales and SECURITY.md, not just the FR one. (§5, A1.)

### 3.2 `assets/patch_notes/*.json` — 1.0.0 is developer jargon, shown to users (P2)

`assets/patch_notes/` is consumed **in the app** (`lib/features/patchnotes/data/
patch_notes_repository.dart` — the What's-New screen) and is the **source the store builder
renders** (`scripts/build_store_package.py:22` — « renders from
`assets/patch_notes/<locale>.json`, already reviewed »).

The `1.0.0` entry in **all three locales** is a commit-message digest, not user prose:

- EN: « Update FeedingSubtype enum and migrate database values », « Implementation of
  anyBabyExistsProvider… »
- FR: « Mise à jour de l'**enumération** FeedingSubtype… », « Implémentation de
  anyBabyExistsProvider pour gérer l'état d'existence du profil bébé »
- ES: « Actualización del **enumerado** FeedingSubtype… »

The FR/ES are *faithful* — the defect is that the EN source was never written for parents.
`1.0.1`–`1.3.0` read as user prose in all three locales (read in full 2026-11-01). Fix:
rewrite `1.0.0` (and tidy `1.0.1`) EN first, then re-derive FR/ES (§5, A5).

### 3.3 The v1.3.0 whats-new calques — location corrected 2026-11-01

The first draft of this section blamed `store/v1.3.0/machine/`. Wrong layer: Apple's What's New
is **not** machine output — `scripts/build_store_package.py` renders
`release-notes/apple-whatsnew-fr.txt` from `assets/patch_notes/fr.json`, and the model never
touches it. The calques (« quand un rappel **est dû** », « restauration … **qui ne demande plus
rien à nouveau** », « notifications **fabriquées** », « le seul chemin de sortie ») live in
**`assets/patch_notes/fr.json` 1.3.0** — the reviewed, human-owned source, which is also what
the in-app What's New screen shows. Fix there, re-render, the store file follows.

The two original sub-claims are **retracted** after reading the generator:
- *Term drift `cryptés`/`chiffrées`*: the drift exists only in `machine/` (raw evidence, kept
  deliberately), and the shipped `fields/apple-fr-promo.txt` reads « chiffrés » — the `ALIGN`
  map already carries `cryptés → chiffrés (editorial)`. Verified in the generated files 2026-11-01.
- *`play-fr.txt` disagreement*: Play release notes are translated separately by design (they
  are a different, shorter text); `play-fr.txt` reads clean. No alignment needed.

Note the convention while fixing: AGENTS.md mandates **noun-form** fr/es patch-note items
(« Ajout de… », « Reprise de… ») — « Réglage de votre heure de notification… », flagged in the
first draft, is compliant and was left alone.

The checklist gate that let this through: `docs/SUBMISSION-CHECKLIST.md` required
`machine/` to exist (« proof the fr/es prose is TranslateGemma output ») and ARB alignment —
**no human-read gate on FR prose quality**, and nothing pointed at the patch notes as the
whats-new source. (§4, A2/A8.)

### 3.4 `docs/release-notes/v1.1.0-whats-new.md` — mixed FR/ES/EN working doc (P3, cosmetic)

One file carrying all three languages' whats-new for cross-reference. Acceptable as a working
doc; note it, don't fix it.

## 4. Root causes — why it keeps getting produced

1. **The language convention is not in AGENTS.md.** Grep of this repo's AGENTS.md on
   2026-11-01: zero normative language statements (only incidental store-screenshot lines).
   The convention lives in BACKLOG B10 (« comments are monolingual by repo convention:
   English ») — an agent that reads AGENTS.md but not BACKLOG has no rule to break or keep.
   binvest's AGENTS.md has the same gap.
2. **No CI guard.** B10 step 4 (« a CI guard … to decide at the review ») was never wired —
   `Makefile` and `.github/workflows/ci.yml` contain no accent check (verified 2026-11-01).
   Nothing stops new French comments or test names from merging.
3. **Store FR is machine-only by design, without a human-read gate.** `make store-prose` =
   TranslateGemma + ARB alignment; the checklist proves provenance, not quality (§3.3).
4. **B10's scope left the biggest surface out.** Comments: ~2 609 lines → done. Test
   descriptions: 378 → untouched (§2.1).
5. **Stage-3 review escapes.** Two `integration_test/` files carry mangled translations
   (§2.3) — the routing exists, the pass evidently didn't cover them.

## 5. Plan (proposed — nothing executed by this audit)

### P1 — before v1.3.0 is tagged / submitted (all small, mechanical)

| # | Action | Effort |
|---|---|---|
| A1 | `terms_fr.md`: FIANCE→CONFIANCE, la CCPA→le CCPA, patterns→FR, « » quotes; **decide the CSV claim** and fix en+fr+es consistently | 10 min + decision |
| A2 | `store/v1.3.0` machine FR: rewrite the 3 calque bullets in `apple-whatsnew-fr.txt`, align `play-fr.txt`, unify `chiffr-` across `machine/fr/*` and `fields/`; re-run `make store-check` | 30 min |
| A3 | `integration_test/`: rewrite the `pickers_gate_rc2.dart:25-52` block in clean English (rebuild from the code + the rc.2 gate log in `docs/release-evidence/`), `## Lancement`→`## Run` in both gate files | 30 min |
| A4 | `test/core/l10n/date_localization_test.dart:60-62,89-90,99` — the last 6 French comment lines; then B10 is fully closed (recount to 0) | 15 min |

### P2 — soon, after v1.3.0 ships

| # | Action | Effort |
|---|---|---|
| A5 | `patch_notes` `1.0.0` (+ `1.0.1`): rewrite EN in user language, re-derive FR/ES, keep commit-level detail in `docs/release-notes/` | ~1 h |
| **B19 (new BACKLOG item)** | 378 FR test/group descriptions → English, 50 files. Same discipline as B10: mechanical, fan-out eligible (`box-coder`/`fast-coder`), `flutter test` green before/after, diff = description strings only. Names quoting FR UI strings stay as quoted literals | 2–4 h with fan-out |
| A6 | CI guard (B10 step 4, now un-optional): Makefile target + `ci.yml` step — grep for accented `//` comment lines in `lib/ test/ integration_test/` with an explicit allowlist (the 2 legitimate `lib/` lines, FR-UI quotes in comments). Wire into `make gate` mirror so it can't drift | 1 h |
| A7 | Language rule in **AGENTS.md** (this repo): *code, comments, test descriptions, commit subjects, docs — English. FR/ES only in `lib/l10n/*.arb`, generated localizations, `assets/patch_notes/{fr,es}.json`, `assets/terms/terms_{fr,es}.md`, `store/` FR/ES, `fastlane` FR/ES, and as direct quotes of UI strings.* | 10 min |
| A8 | `SUBMISSION-CHECKLIST.md`: add a line — « FR/ES store prose read aloud by a human before submission; machine output is the floor, not the ceiling » | 5 min |

### P3 — binvest (`~/binvest`, separate repo)

Verdict: **binvest is essentially clean.** Every flagged file read as legitimate:
`data/statements/**` (CA clips — source data), `tests/**` fixtures (mirror real data),
`statement.py`/`scrape.py`/`parse_pdf.py` (regexes and labels that parse CA documents —
translating them breaks the parser), `phase.py` (intentionally bilingual EN+FR keyword list —
the news feed includes Le Monde et al.), `news.py` tags (`pétrole`, `émergents`, `climat`,
`souverain` are DB tag values), `data/available_funds.txt` (CA grid labels). No French
*documentation* exists in binvest, so there is no badly-translated French doc to fix there.

Remaining (small):

| # | Action |
|---|---|
| B-1 | Add the same language rule to binvest's AGENTS.md: *prose English; CA document labels (« fiche », « Répartition des supports », « versement ») stay in French but in « » or backticks when quoted; parsing strings, fixtures, `data/` are untouchable.* |
| B-2 | Going-forward discipline only (do **not** retro-edit `LOG.md` — it is an append-only journal): quote CA labels in `STRATEGY.md`/`DECISIONS.md` prose on future entries. The unquoted « fiche »/« versement » uses in historical entries are acceptable as domain vocabulary. |

### Do not

- Do not rewrite git history (the 24 French commits are history; the practice stopped 2026-10-22).
- Do not translate `lib/l10n/*.arb`, generated localizations, `store/source/en`, or binvest
  parsing strings/fixtures/`data/`.
- Do not delete comments or descriptions to « simplify » (B10 rule: a lost *why* is a data
  loss).
- Do not fold A1–A4 into a feature PR — one sweep PR, as B10 prescribed.

## 6. Followed up the same day (2026-11-01) — what was executed

Branch `chore/language-sweep-2026-11-01` off `release/v1.3.0` (the v1.3.0 store package exists
only on the release branch, and its fixes must ship with the tag), PR into `release/v1.3.0`.

| Plan item | Outcome |
|---|---|
| A1 — CGU | **3 defects fixed** in `terms_fr.md` (confiance accordée, rythmes ×2, « J'accepte »). « la CCPA » retracted (§3.1). **CSV claim untouched** — owner says the export is done, the tree does not show it (§3.1); awaiting the answer before touching three locales + SECURITY.md. |
| A2 — whats-new | **Fixed at the right layer**: `assets/patch_notes/fr.json` 1.3.0, three items (échéance, reprise…: ne les redemande plus, générées/via/chemin par lequel), noun-form kept per AGENTS.md; « Réglage de votre heure » left alone (compliant). `make store-package` re-rendered `apple-whatsnew-fr.txt` — the package diff is exactly those 3 lines. In-app What's New dialog for FR users is fixed by the same edit. |
| A3 — gate headers | `pickers_gate_rc2.dart` header rewritten from `RELEASE-GATE-v1.2.1-rc.2.md` + B2 (the « plage »→"beach" pass, truncations, and `## Lancement` all gone; `--no-uninstall` and the errno-30 note restored, sourced from the gate doc). `entry_sheet_gate_rc4.dart`: `## Lancement` → `## Run`. |
| A4 — last comments | `test/core/l10n/date_localization_test.dart`, three blocks translated; reasoning kept verbatim in meaning, no line lost. **B10 closed** in BACKLOG.md (archive on ship), final count 0. |
| A7 — AGENTS.md | New section “Language: the tree is English, French is the product”. |
| A8 — checklist | Human-read line added to Step 0, naming the patch notes as the whats-new source and `machine/` as frozen evidence. |
| A5, A6, §2.1 | Ticketed as **B21**, **B20**, **B19** — execution after v1.3.0 ships (owner agreed same batch; B20 rides the format-check rollout precedent: advisory → hard). |
| P3 — binvest | Untouched (AGENTS.md rule + future-entry discipline stay queued). |

**Verification.** `dart format` 0 changed · `flutter analyze --fatal-infos --fatal-warnings`
no issues · `flutter test` **1500 passed** · `make store-package` + `store-check` PACKAGE OK,
all fields within limits, only the pre-existing documented `tétées` WARNs · B10 criterion re-run:
0 French comment prose, the 16 hits are personal names and quoted UI/DB strings (the B20
allowlist). Emulator pass: **not run** — no simulator booted at sweep time; the diff moves no
behavioural code (assets/markdown, store text, comments, docs), and the v1.3.0 release-gate
device pass ahead of tagging covers the build regardless. Merge is the owner's call.

## Appendix — reproducible scan

```bash
# full scan (accent + French word list + commit subjects), all repos:
python3 /tmp/fr_audit.py                      # output cached at /tmp/fr_audit_full.txt
# FR test descriptions, per file:
cd ~/DEV/mamadera && python3 - <<'EOF'
import re, os
pat = re.compile(r"^\s*(?:test|testWidgets|group)\(\s*(?:r?['\"`]).*[\u00e0\u00e2\u00e9\u00e8\u00ea\u00eb\u00ee\u00ef\u00f4\u00f9\u00fb\u00e7\u0153]")
for root, dirs, fs in os.walk('test'):
    for f in fs:
        if f.endswith('.dart') and '.g.dart' not in f:
            c = sum(1 for l in open(f'{root}/{f}', encoding='utf-8') if pat.match(l))
            if c: print(f'{c:3d}  {root}/{f}')
EOF
# French comment lines (B10 criterion):
grep -rnE '^\s*(//|///).*[àâéèêëîïôùûçœ]' lib test integration_test --include='*.dart' | grep -v '\.g\.dart\|\.freezed\.dart\|app_localizations'
```

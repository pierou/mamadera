#!/usr/bin/env python3
"""Validate — and regenerate — a `store/v<version>/` package.

    python3 scripts/store_check.py store/v1.3.0            # verify, exit 1 on any blocker
    python3 scripts/store_check.py store/v1.3.0 --write    # rewrite Apple "What's New"
                                                             from the app's own patch notes

This is the **single** implementation of the store checks. Before it, each release
carried its own 266-line copy of this logic (`store/v1.2.1/check.py`), and every
copy read the version out of `pubspec.yaml` — so the day 1.3.0 was bumped, the
v1.2.1 checker started comparing v1.2.1's published release notes against 1.3.0's
patch notes and reported three blockers on a package that had not changed and could
not change. A released listing does not track the working tree.

A package therefore pins its own version, written by `scripts/build_store_package.py`
into a thin `store/v<version>/check.py` shim. Limits are the consoles' own —
ASC 30/30/100/170/4000, Play 30/80/4000/500.
"""

from __future__ import annotations

import json
import re
import struct
import sys
from pathlib import Path

# Single-sourced on purpose: the terminology table lives with the pipeline that
# writes the fields, the verdict lives with the checker. v1.4.0 proved the WARN
# there was not enough — the watched word still shipped.
from build_store_package import GLOSSARY_WATCH

ROOT = Path(__file__).resolve().parents[1]

LOCALES = ("fr", "en", "es")

# Paste-ready field kind → the console's hard character limit.
LIMITS = {"keywords": 100, "promo": 170, "description": 4000, "short": 80,
          "name": 30, "subtitle": 30, "title": 30}
# Fields TranslateGemma produced. Their raw model output must be archived under machine/:
# that archive is what makes "who wrote this sentence" answerable after the fact.
TRANSLATED = {"promo", "description", "short", "release-notes"}

# The canonical English files `build_store_package.py` copies verbatim into fields/.
CANONICAL_EN = [("apple", kind) for kind in
                ("name", "subtitle", "keywords", "promo", "description")] + [
    ("play", kind) for kind in ("title", "short", "description")]
# Per-locale editorial: brand names, subtitles and ASO keywords are never machine-
# translated — they are written per locale in store/source/<locale>/.
EDITORIAL = [("apple", "name"), ("apple", "subtitle"), ("apple", "keywords"),
             ("play", "title")]

# store slot → (directory under <package>/screenshots, expected size, required count).
# `required` means a missing/wrong set is a blocker: Play wants a screenshot set per
# localization and refuses a release whose listing language has none.
PLAY_SCREENS = ("home", "history", "menu", "feeding_dialog", "sleep_diagram",
                "diaper_dialog", "health_diagram", "growth")
PLAY_SLOTS = [(locale, 1280, 2856, len(PLAY_SCREENS)) for locale in LOCALES]

# Recaptured by the iOS simulator pipeline (asc_driver_main + postprocess.sh).
# B24 (2026-11-03): the accepted set is now 1206x2622 / 1179x2556 and their
# landscape twins (iPhone 17 / 17e); the old 1242x2688 / 1284x2778 pair is no
# longer uploadable.
#
# v1.4.0 audit: this list carried `asc/fr` only, so a wrong-language App Store set
# for the other two locales was invisible to the gate — while `AGENTS.md` says the
# locale must be provable from the filename. Every listing locale is checked now.
ASC_SIZES = (("1206x2622", 1206, 2622), ("1179x2556", 1179, 2556),
             ("2622x1206", 2622, 1206), ("2556x1179", 2556, 1179))
ASC_SLOTS = [(f"asc/{locale}/{name}", w, h)
             for locale in LOCALES for name, w, h in ASC_SIZES]

# The headline feature each release must sell, in the stem shared by fr/en/es.
# A release with no entry here is reported as a WARN, never silently skipped: the
# reason 1.2.1 nearly shipped a note that only listed fixes is that nobody had to
# name the feature.
HEADLINES = {
    "1.2.1": ("histor", "the unified history"),
    "1.3.0": ("notif", "system notifications"),
    # Quality release: the user-facing headline is that the app reads in the
    # language chosen — the stem "nivers" is the cognate all three notes carry
    # (anniversary / anniversaire / aniversario — Spanish keeps a single n).
    "1.3.1": ("nivers", "the age counted by anniversary"),
    # Fix release: the headline is the reminders list itself — the stem
    # "vitamin" is what all three notes carry (Vitamin / vitamine / vitamina).
    "1.3.2": ("vitamin", "the full reminders list for the selected baby"),
    # Reminder release: the headline is the reminder you can time. The stem is the
    # cognate all three notes carry — en/fr "notification", es "notificación" — and
    # it is verified against the shipped v1.3.2 notes, where both translations kept
    # the same root. If a future release notes file loses it, that is the day the
    # headline stopped being the story, and the check says so.
    "1.4.0": ("notific", "the reminder you can time"),
}

# ─────────────────────────────────────────────────────────────────────────────
# The translation gate (added after the v1.4.0 audit, 2026-11-20).
#
# Four copy defects shipped in v1.4.0 with `make store-check` green, because every
# rule they broke was written down in `AGENTS.md` and implemented nowhere. One of
# them put a sentence in the French and Spanish Play listings that promised an
# affordance the app does not have (« Modifiez le nom du bébé dans le titre » —
# B9 opens a switcher, it does not rename). The root cause was mechanical and
# invisible: term alignment is six literal replacements, nothing fired, and
# `release-notes/play-fr.txt` came out byte-identical to the raw TranslateGemma
# output. A package that changed nothing between the model and the console is a
# package nobody read.
#
# What these rules CAN do: catch the classes we have actually been bitten by, and
# make "the model's output was shipped unread" impossible. What they cannot do:
# judge whether a sentence reads well in French. That is still a human step, and
# the copy owner is the reviewer, not this file.
# ─────────────────────────────────────────────────────────────────────────────

# Shipped prose surface → the machine/ twin it must differ from, unless a human
# signed the no-op below. `fields/` carries the paste-ready fields; Play's release
# notes live under release-notes/ and are the surface that failed in v1.4.0.
ALIGNED_SURFACES = [
    ("fields/apple-{loc}-promo.txt", "machine/{loc}/apple-promo.txt"),
    ("fields/apple-{loc}-description.txt", "machine/{loc}/apple-description.txt"),
    ("fields/play-{loc}-short.txt", "machine/{loc}/play-short.txt"),
    ("fields/play-{loc}-description.txt", "machine/{loc}/play-description.txt"),
    ("release-notes/play-{loc}.txt", "machine/{loc}/play-release-notes.txt"),
]

# Files whose model output genuinely needed no term alignment. Empty by intent: an
# entry here is a human asserting "I read this translation", so it carries a reason.
NO_ALIGNMENT_NEEDED: dict[str, str] = {
    # Read 2026-11-21, after the v1.4.0 audit added this rule. The Spanish Apple
    # promotional text already carries the app's own words (« altura »,
    # « historial », « cifrados »), names no control, makes no clinical claim, and
    # holds no false friend — so nothing could fire, and that is the correct result
    # rather than an unreviewed one. Signing is a claim about one file, not a
    # setting: a re-translation re-rolls the sentence and must be read again.
    "fields/apple-es-promo.txt":
        "read 2026-11-21 — app terms already present (altura / historial / cifrados), "
        "no affordance named, no claim made: nothing to align",
}

# D-R11 (`AGENTS.md`): fr/es patch-note bullets take the NOUN form, never an
# infinitive. The whitelist is what the tree's own notes use; the infinitive list
# exists so a violation names itself instead of reading as "unknown lead word".
NOUN_LEADS = {
    "fr": ("ajout", "mise à jour", "correction", "modification", "amélioration",
           "optimisation", "refonte", "changement", "arrivée", "nouveauté",
           "nouvelles", "nouvelle", "implémentation", "création", "suppression",
           "activation", "désactivation", "ajustement", "traduction", "passage",
           "prise en charge", "reprise", "règles", "naissance"),
    "es": ("adición", "corrección", "mejora", "mejoras", "actualización",
           "cambio", "cambios", "nueva", "nuevas", "novedad", "novedades",
           "incorporación", "optimización", "implementación", "creación",
           "supresión", "activación", "desactivación", "ajuste", "adaptación",
           "traducción", "soporte", "reducción"),
}
INFINITIVE_LEADS = {
    "fr": ("ajouter", "corriger", "modifier", "actualiser", "améliorer", "optimiser",
           "définir", "renommer", "permettre", "pouvoir", "gérer", "créer",
           "supprimer", "changer", "adapter", "traduire", "activer", "désactiver",
           "réduire", "implémenter", "établir", "passer"),
    "es": ("añadir", "agregar", "corregir", "modificar", "actualizar", "mejorar",
           "optimizar", "definir", "renombrar", "permitir", "poder", "gestionar",
           "crear", "eliminar", "cambiar", "adaptar", "traducir", "activar",
           "desactivar", "reducir", "implementar", "establecer"),
}

# The clinical guard. The research archive (`docs/research/`) settled that no
# digital intervention has demonstrated a neonatal mortality effect, and the app
# ships a vitamin D reminder that WHO 2022 treats as research-only — so shipped
# copy may describe a DEFAULT and must never read as advice, prevention or cure.
# A blocklist: necessary, not sufficient. A human still reads the sentence.
CLINICAL_BANNED = [
    (r"réduit la mortalit|reduce la mortalidad|reduc\w*(e|ing)? mortality|saves? "
     r"lives|salva vidas|salvar vidas", "mortality or survival claim"),
    (r"prévient|previene|prevención de (la |las )?(maladie|enfermedad)|"
     r"prevents (disease|illness|infection|sudden)", "disease-prevention claim"),
    (r"recommandation médicale|conseil médical|recomendación médica|medical advice|"
     r"consultez (votre|un) médecin|consulte a su médico|see your doctor",
     "medical-advice framing"),
    (r"guérit|guarantee[sd]? (that )?no|soigne (la|le) maladie|cures? "
     r"(the )?(illness|disease)", "cure claim"),
]

# Claims that were WRONG in v1.4.0 and must never come back through a
# re-translation. `must` is the app's own vocabulary for the affordance (cited to
# the arb key or the widget); `forbidden` catches the machine translation that
# invented it. Keyed by release, like HEADLINES: a release with no entry WARNs.
# Patterns are matched against LOWERCASED text, so keep every pattern lowercase.
AFFORDANCES = {
    "1.4.0": {
        "en": {"must": [(r"\bhome\b", "navHome — the tap lands on Home"),
                        (r"once|one-time", "reminderFrequencyOnceChoice")],
               "forbidden": []},
        "fr": {"must": [(r"accueil", "navHome says « Accueil »"),
                        (r"une seule fois", "reminderFrequencyOneTime")],
               "forbidden": [
                   (r"(modifi|chang|renomm)\w*[^.\n]{0,45}nom du bébé",
                    "the Home title opens the baby SWITCHER (showBabyPickerSheet), "
                    "it does not rename the baby — v1.4.0 shipped this"),
                   (r"(modifi|chang)\w*[^.\n]{0,45}titre de (la page d|l)['’]accueil",
                    "same affordance, second phrasing of the same error"),
               ]},
        "es": {"must": [(r"inicio", "navHome says « Inicio »"),
                        (r"una sola vez", "reminderFrequencyOneTime")],
               "forbidden": [
                   (r"(cambi|modific|renombr)\w*[^.\n]{0,45}(título|nombre del bebé)",
                    "the Home title opens the baby SWITCHER, it does not rename — "
                    "v1.4.0 shipped « Cambie el título de la sección principal »"),
                   (r"frecuencia[^.\n]{0,3}cada vez",
                    "a one-shot is « una sola vez » (reminderFrequencyOneTime); "
                    "« cada vez » means EACH time"),
               ]},
    },
}

# Surfaces where a watched word is a defect: the prose that describes the app.
# Editorial fields (name, subtitle, ASO keywords, Play title) are excluded on
# purpose — a brand is a brand and a keyword is what users type, so
# `apple-fr-keywords.txt` carrying `tetee` is a search decision, not drift.


def pubspec_version(path: Path = ROOT / "pubspec.yaml") -> str:
    line = next(l for l in path.read_text(encoding="utf-8").splitlines()
                if l.startswith("version:"))
    return line.split(":", 1)[1].strip().split("+")[0]


def pubspec_build(path: Path = ROOT / "pubspec.yaml") -> str:
    """The `+17` half of `1.4.0+17` — the Android versionCode fastlane names changelogs after."""
    line = next(l for l in path.read_text(encoding="utf-8").splitlines()
                if l.startswith("version:"))
    return line.split(":", 1)[1].strip().split("+")[1]


_TEST_LITERALS: set[str] | None = None


def test_literals() -> set[str]:
    """Every quoted string in the test tree, lowercased. Cached; one read per process.

    Used only to answer « is this quoted example a piece of test data? ». Test
    DESCRIPTIONS are literals too, so the caller must clear a span against the ARB
    before calling it a leak — otherwise the ~330 French test names AGENTS.md
    records would every release look like leakage.
    """
    global _TEST_LITERALS
    if _TEST_LITERALS is None:
        found: set[str] = set()
        for directory in (ROOT / "test", ROOT / "integration_test"):
            for path in directory.rglob("*.dart"):
                try:
                    text = path.read_text(encoding="utf-8")
                except OSError:
                    continue
                for pattern in (r"'([^'\n]{6,90})'", r'"([^"\n]{6,90})"'):
                    for match in re.findall(pattern, text):
                        found.add(match.strip().lower())
        _TEST_LITERALS = found
    return _TEST_LITERALS


def arb_text(locale: str) -> str:
    """Everything the app itself says in this locale, lowercased, as one haystack."""
    path = ROOT / "lib" / "l10n" / f"app_{locale}.arb"
    try:
        doc = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return ""
    return " ".join(str(v) for k, v in doc.items() if not k.startswith("@")).lower()


def render_apple_notes(locale: str, version: str) -> str:
    """The in-app patch notes, flattened to the plain text ASC wants."""
    doc = json.loads(
        (ROOT / "assets" / "patch_notes" / f"{locale}.json").read_text(encoding="utf-8")
    )[version]
    out = [doc["title"]]
    for item in doc["items"]:
        item = item.strip()
        if not item:
            continue
        if item.startswith("###"):
            out += ["", item.lstrip("# ").strip()]
        else:
            out.append(item if item.startswith("-") else f"- {item}")
    return "\n".join(out).strip() + "\n"


PROBLEMS: list[str] = []


def report(good: bool, label: str, detail: str = "") -> None:
    """Print one result and remember the failures — bare name, 15 call sites.

    Module state, like the checker this was ported from: one process checks one package
    (`make store-check` runs each `store/v*/check.py` separately), and `main()` empties
    the list so a reuse inside a process cannot inherit another package's verdict.
    """
    print(f"  {'ok  ' if good else 'FAIL'} {label}{detail}")
    if not good:
        PROBLEMS.append(label)


class Checker:
    """Every check for one package, pinned to one version."""

    def __init__(self, pkg: Path, version: str) -> None:
        self.pkg = pkg
        self.version = version

    def check_version(self) -> None:
        print("== version")
        print(f"  package {self.version} (pubspec {pubspec_version()})")
        for locale in LOCALES:
            path = ROOT / "assets" / "patch_notes" / f"{locale}.json"
            notes = json.loads(path.read_text(encoding="utf-8"))
            report(self.version in notes, f"patch_notes/{locale}.json",
                   f" has {self.version}" if self.version in notes
                   else f" missing key {self.version}")

    def check_machine_archive(self) -> None:
        print("== TranslateGemma archive (machine/)")
        for locale in ("fr", "es"):
            for store, kinds in (("apple", ("promo", "description")),
                                 ("play", ("short", "description", "release-notes"))):
                for kind in kinds:
                    path = self.pkg / "machine" / locale / f"{store}-{kind}.txt"
                    report(path.exists(), f"machine/{locale}/{store}-{kind}.txt",
                           "" if path.exists()
                           else " missing — run build_store_package.py --translate")

    def check_fields(self) -> None:
        print("== paste-ready fields")
        for store, kinds in (("apple", ("name", "subtitle", "keywords", "promo",
                                         "description")),
                             ("play", ("title", "short", "description"))):
            for locale in LOCALES:
                for kind in kinds:
                    path = self.pkg / "fields" / f"{store}-{locale}-{kind}.txt"
                    if not path.exists():
                        report(False, f"{path.name}", " missing")
                        continue
                    body = path.read_text(encoding="utf-8").rstrip("\n")
                    limit = LIMITS[kind]
                    good = len(body) <= limit
                    detail = f" {len(body)}/{limit}"
                    if kind == "keywords":
                        tokens = body.split(",")
                        if (body.startswith(",") or body.endswith(",")
                                or ",," in body):
                            good = False
                            detail += " (empty token)"
                        if any(t != t.strip().lower() for t in tokens):
                            good = False
                            detail += " (space or uppercase in keywords)"
                    report(good, f"{store}-{locale}-{kind}", detail)

    def check_notes(self, write: bool) -> None:
        print("== release notes")
        for locale in LOCALES:
            apple = self.pkg / "release-notes" / f"apple-whatsnew-{locale}.txt"
            if write:
                apple.write_text(render_apple_notes(locale, self.version),
                                 encoding="utf-8")
            else:
                expected = render_apple_notes(locale, self.version)
                same = apple.exists() and apple.read_text(
                    encoding="utf-8") == expected
                report(same, f"apple-whatsnew-{locale}.txt",
                       "" if same
                       else " differs from assets/patch_notes — run --write")
            if apple.exists():
                body = apple.read_text(encoding="utf-8").rstrip("\n")
                report(len(body) <= 4000, f"apple whatsnew {locale}",
                       f" {len(body)}/4000")

            play = self.pkg / "release-notes" / f"play-{locale}.txt"
            if not play.exists():
                report(False, f"play-{locale}.txt", " missing")
                continue
            body = play.read_text(encoding="utf-8").rstrip("\n")
            report(len(body) <= 500, f"play release notes {locale}",
                   f" {len(body)}/500")
            # The headline feature of this release must be in the store text, in the
            # language of the listing — a note that only lists fixes undersells it.
            headline = HEADLINES.get(self.version)
            if headline is None:
                print(f"  WARN play-{locale}.txt — no headline registered for "
                      f"{self.version}; add it to HEADLINES in scripts/store_check.py")
            elif headline[0] not in body.lower():
                report(False, f"play-{locale}.txt",
                       f" never mentions {headline[1]}")

    def check_no_duplicate_prose(self) -> None:
        """A guide must point at a field file, never restate it.

        Two copies of a 1 700-character description is how v1.2.1 nearly shipped a French
        listing whose wording differed from the file being pasted. Long prose inside a
        guide is a bug.
        """
        print("== no duplicated prose inside the guides")
        for sub in ("apple", "play"):
            for guide in sorted((self.pkg / sub).glob("*.md")):
                blocks = re.findall(r"```\n(.*?)\n```",
                                    guide.read_text(encoding="utf-8"), re.S)
                long = [b for b in blocks if len(b.strip()) > 200]
                report(not long, guide.relative_to(self.pkg).as_posix(),
                       "" if not long else
                       f" holds {len(long)} long text block(s) — reference fields/ instead")

    def check_source_is_canonical(self, current: bool) -> None:
        """The EN fields and the per-locale editorial fields must be the source bytes.

        Only for the version being built. `store/source/en/` is one mutable file per
        field — it is the source of the *next* listing — so this check can only mean
        something for the package being prepared from it. Measured on `make store-check`
        after the v1.4.0 copy fixes reworded `apple-description.txt` and
        `play-description.txt`: four already-published packages each reported two
        blockers, because their archived fields hold the wording that was actually
        uploaded. Rewriting an uploaded listing to satisfy a check is not what a
        release gate is for.
        """
        if not current:
            print(f"== fields are copies of store/source/ — skipped: v{self.version} "
                  "is archived; the source moved on when the next version was cut")
            return
        print("== fields are copies of store/source/, not edits")
        source = ROOT / "store" / "source"
        for store, kind in CANONICAL_EN:
            src = source / "en" / f"{store}-{kind}.txt"
            dst = self.pkg / "fields" / f"{store}-en-{kind}.txt"
            if not src.exists():
                report(False, f"source/en/{store}-{kind}.txt", " missing")
                continue
            same = dst.exists() and src.read_bytes() == dst.read_bytes()
            report(same, f"{store}-en-{kind}",
                   "" if same else " differs from store/source/en/")
        for locale in ("fr", "es"):
            for store, kind in EDITORIAL:
                src = source / locale / f"{store}-{kind}.txt"
                dst = self.pkg / "fields" / f"{store}-{locale}-{kind}.txt"
                if not src.exists():
                    report(False, f"source/{locale}/{store}-{kind}.txt", " missing")
                    continue
                same = dst.exists() and src.read_bytes() == dst.read_bytes()
                report(same, f"{store}-{locale}-{kind} (editorial)",
                       "" if same
                       else " differs from store/source — the build owns this file")

    def check_screenshots(self) -> None:
        """Every uploaded screenshot carries its locale in the FILENAME, not just the folder.

        A bare `home.png` is unidentifiable outside its directory, and `screenshots/android/`
        holds whichever language ran last with no marker at all. A French shot in the English
        listing is otherwise indistinguishable from a correct one.
        """
        shots = self.pkg / "screenshots"
        print("== screenshots — Play (per locale, hard requirement)")
        for locale, w, h, want in PLAY_SLOTS:
            directory = shots / "play" / locale
            files = sorted(p for p in directory.glob("*.png")
                           if not p.name.startswith("_debug"))
            bad_size = [p.name for p in files if png_size(p) != (w, h)]
            no_locale = [p.name for p in files
                         if not p.name.startswith(f"{locale}-")]
            expected = {f"{locale}-{s}.png" for s in PLAY_SCREENS}
            missing = sorted(expected - {p.name for p in files})
            good = bool(files) and len(files) == want and not bad_size \
                and not no_locale and not missing
            detail = f" {len(files)}/{want} png {w}x{h}"
            if not good:
                detail += f" | no locale prefix: {no_locale}" if no_locale else ""
                detail += f" | wrong size: {bad_size}" if bad_size else ""
                detail += f" | missing: {missing}" if missing else ""
            report(good, f"play/{locale}", detail)

        print("== screenshots — App Store (per locale, simulator pipeline)")
        for rel, w, h in ASC_SLOTS:
            directory = shots / rel
            locale = rel.split("/")[1]
            files = sorted(p for p in directory.glob("*.png")
                           if not p.name.startswith("_debug"))
            if not files:
                print(f"  WARN {rel} — empty; recapture with asc_driver_main "
                      f"--dart-define=APP_LOCALE, or upload screenshots/ios/asc/ knowingly")
                continue
            bad_size = [p.name for p in files if png_size(p) != (w, h)]
            no_locale = [p.name for p in files
                         if not p.name.startswith(f"{locale}-")]
            report(not bad_size and not no_locale, rel,
                   f" {len(files)} png {w}x{h}"
                   + (f" | no locale prefix: {no_locale}" if no_locale else "")
                   + (f" | wrong size: {bad_size}" if bad_size else ""))


    # ── the translation gate ───────────────────────────────────────────────
    def _notes(self, locale: str) -> list[str]:
        doc = json.loads((ROOT / "assets" / "patch_notes" / f"{locale}.json")
                         .read_text(encoding="utf-8")).get(self.version)
        return list(doc["items"]) if doc else []

    def _shipped_lines(self, locale: str) -> list[str]:
        lines: list[str] = []
        for rel in (f"release-notes/play-{locale}.txt",
                    f"release-notes/apple-whatsnew-{locale}.txt"):
            path = self.pkg / rel
            if path.exists():
                lines += path.read_text(encoding="utf-8").splitlines()
        return lines

    def check_translation_gate(self, current: bool) -> None:
        """The copy rules `AGENTS.md` states and CI never checked (v1.4.0 audit).

        Only for the version being built. `make store-check` loops over every
        `store/v*/check.py`, and these rules were written in November against the
        copy conventions of November: run against v1.2.1 or v1.3.1 they report ten
        blockers each on **published listings nobody can amend** — the archived
        release notes of a shipped version are a record, not a draft, and a gate
        that fails the archive fails the build for something no action can fix.
        """
        if not current:
            print(f"== translation gate — skipped: v{self.version} is archived, "
                  "the gate governs the version being built, not a published listing")
            return
        print("== translation gate")
        self.check_alignment_no_op()
        self.check_play_note_parity()
        self.check_affordances()
        self.check_glossary()
        self.check_fixture_leakage()
        self.check_noun_form()
        self.check_clinical()
        self.check_fastlane_changelog()

    def check_alignment_no_op(self) -> None:
        """A shipped file identical to the model's raw output means nobody read it.

        Term alignment is a handful of literal replacements. When none of them fire,
        `fields/` and `release-notes/` are the model's words — which is exactly how
        v1.4.0's French and Spanish Play notes shipped, false feature claim included.
        """
        for locale in ("fr", "es"):
            for ship_rel, mach_rel in ALIGNED_SURFACES:
                ship = self.pkg / ship_rel.format(loc=locale)
                mach = self.pkg / mach_rel.format(loc=locale)
                if not ship.exists() or not mach.exists():
                    continue  # existence belongs to check_fields / check_machine_archive
                key = ship.relative_to(self.pkg).as_posix()
                same = (ship.read_text(encoding="utf-8").strip()
                        == mach.read_text(encoding="utf-8").strip())
                if not same:
                    continue
                reason = NO_ALIGNMENT_NEEDED.get(key)
                report(reason is not None, f"alignment {key}",
                       "" if reason else
                       " byte-identical to machine/ — nothing was aligned, nobody "
                       "read it (align, or sign it in NO_ALIGNMENT_NEEDED with a reason)")

    def check_play_note_parity(self) -> None:
        """fr/es Play notes must carry the English canonical's line count.

        A dropped or invented bullet is silent otherwise: four lines and five lines
        both fit under the console's 500.
        """
        canonical = ROOT / "store" / "source" / "en" / "play-release-notes.txt"
        if not canonical.exists():
            return
        want = len([x for x in canonical.read_text(encoding="utf-8").splitlines()
                    if x.strip()])
        for locale in LOCALES:
            path = self.pkg / "release-notes" / f"play-{locale}.txt"
            if not path.exists():
                continue
            got = len([x for x in path.read_text(encoding="utf-8").splitlines()
                       if x.strip()])
            report(got == want, f"play-{locale}.txt line count",
                   f" {got} vs store/source/en {want}"
                   if got != want else f" {got}")

    def check_affordances(self) -> None:
        """The listing may not promise a control the app does not have.

        `must` is the app's own word for the affordance; `forbidden` is the machine
        translation that invented one. Both are cited, because the reader of a
        failure has to be able to check the authority without leaving this file.
        """
        spec = AFFORDANCES.get(self.version)
        if spec is None:
            print(f"  WARN affordances — no entry for {self.version}; add one to "
                  f"AFFORDANCES in scripts/store_check.py so a re-translation cannot "
                  f"invent an affordance")
            return
        for locale in LOCALES:
            blob = "\n".join(self._shipped_lines(locale)).lower()
            if not blob:
                continue
            for pattern, why in spec.get(locale, {}).get("must", []):
                found = re.search(pattern, blob) is not None
                report(found, f"affordance {locale} — {why}",
                       "" if found else f" missing /{pattern}/")
            for pattern, why in spec.get(locale, {}).get("forbidden", []):
                hit = re.search(pattern, blob)
                report(hit is None, f"affordance {locale} — {why}",
                       "" if hit is None else f" found {hit.group(0)!r}")

    def check_glossary(self) -> None:
        """Where the app names a thing, the listing uses that word (the 1.2.1 class).

        `build_store_package.GLOSSARY_WATCH` used to print a WARN on the `--translate`
        path only, so the word could ship unopposed. The table stays single-sourced;
        the verdict here is a blocker.
        """
        for locale in ("fr", "es"):
            watch = GLOSSARY_WATCH.get(locale, {})
            if not watch:
                continue
            surfaces: list[tuple[str, str]] = [
                (f"{store}-{locale}-{kind}",
                 (self.pkg / "fields" / f"{store}-{locale}-{kind}.txt"))
                for store, kind in (("apple", "promo"), ("apple", "description"),
                                    ("play", "short"), ("play", "description"))
            ]
            surfaces.append((f"patch_notes/{locale}.json", None))
            surfaces.append((f"play-{locale}.txt",
                             self.pkg / "release-notes" / f"play-{locale}.txt"))
            hits: list[str] = []
            for label, path in surfaces:
                body = ("\n".join(self._notes(locale)) if path is None
                        else path.read_text(encoding="utf-8") if path.exists() else "")
                low = body.lower()
                for word, why in watch.items():
                    if re.search(rf"\b{re.escape(word.lower())}\b", low):
                        hits.append(f"{word} in {label} ({why})")
            report(not hits, f"terminology {locale}",
                   "" if not hits else " " + "; ".join(hits[:4]))

    def check_fixture_leakage(self) -> None:
        """A quoted example in shipped copy must be app vocabulary, not test data.

        v1.4.0 shipped « sein gauche refusé » in the French What's New: the phrase
        came from the B16 ticket's own example, which is also what two widget tests
        type into the note field. Developer shorthand reaching a store listing is a
        leak even when the grammar is fine.
        """
        spans: dict[str, str] = {}
        for locale in LOCALES:
            lines = self._notes(locale) + self._shipped_lines(locale)
            for line in lines:
                found = re.findall(r"\u00ab([^\u00bb]{6,80})\u00bb", line)
                found += re.findall(r'"([^"]{6,80})"', line)
                for span in found:
                    spans.setdefault(span.strip().lower(), locale)
        if not spans:
            report(True, "fixture leakage", " no quoted example in shipped copy")
            return
        literals = test_literals()
        haystack = " ".join(arb_text(locale) for locale in LOCALES)
        leaks = [f"{span!r} ({locale})"
                 for span, locale in spans.items()
                 if " " in span and span not in haystack
                 and any(span in literal for literal in literals)]
        report(not leaks, "fixture leakage",
               "" if not leaks else
               f" {len(spans)} spans checked; in test data, absent from the ARB: "
               + "; ".join(leaks[:3]))

    def check_noun_form(self) -> None:
        """D-R11: fr/es patch notes take the noun form, never an infinitive."""
        for locale in ("fr", "es"):
            bad: list[str] = []
            for item in self._notes(locale):
                text = item.strip()
                if not text.startswith("- "):
                    continue
                lead = text[2:].lower()
                if any(lead.startswith(w) for w in INFINITIVE_LEADS[locale]):
                    bad.append(f"infinitive {text[2:30]!r}")
                elif not any(lead.startswith(w) for w in NOUN_LEADS[locale]):
                    bad.append(f"lead word {text[2:22]!r} not a known noun form")
            report(not bad, f"D-R11 noun form ({locale})",
                   "" if not bad else " " + "; ".join(bad[:3]))

    def check_clinical(self) -> None:
        """No outcome, prevention or advice claim — a blocklist, so: not sufficient."""
        for locale in LOCALES:
            surfaces = [(f"patch_notes/{locale}", "\n".join(self._notes(locale)))]
            for rel, path in (("play", self.pkg / f"release-notes/play-{locale}.txt"),
                              ("whatsnew", self.pkg /
                               f"release-notes/apple-whatsnew-{locale}.txt")):
                if path.exists():
                    surfaces.append((rel, path.read_text(encoding="utf-8")))
            for store, kind in (("apple", "description"), ("play", "description")):
                path = self.pkg / "fields" / f"{store}-{locale}-{kind}.txt"
                if path.exists():
                    surfaces.append((f"{store}-{kind}",
                                     path.read_text(encoding="utf-8")))
            hits = [f"{label}: {why} {hit.group(0)!r}"
                    for label, text in surfaces
                    for pattern, why in CLINICAL_BANNED
                    if (hit := re.search(pattern, text.lower()))]
            report(not hits, f"clinical guard ({locale})",
                   "" if not hits else " " + "; ".join(hits[:3]))

    def check_fastlane_changelog(self) -> None:
        """The consoles want a changelog per build number, per locale. WARN, not
        blocker: the package is built before the tag exists."""
        build = pubspec_build()
        owed = [f"fastlane/metadata/android/{d}/changelogs/{build}.txt"
                for d in ("en-US", "fr", "es")
                if not (ROOT / "fastlane" / "metadata" / "android" / d /
                        "changelogs" / f"{build}.txt").exists()]
        if owed:
            print(f"  WARN fastlane changelogs — owed at the tag: {', '.join(owed)}")


def png_size(path: Path) -> tuple[int, int]:
    try:
        with path.open("rb") as handle:
            head = handle.read(26)
    except OSError:
        return (0, 0)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return (0, 0)
    return struct.unpack(">II", head[16:24])


def main(package: Path, version: str, write: bool = False) -> int:
    """Run every check for `package`, pinned to `version`."""
    if not package.is_dir():
        print(f"{package} — no such package directory")
        return 1
    print(f"── {package.relative_to(ROOT).as_posix()}  (version {version}, "
          f"pinned at build time)")
    PROBLEMS.clear()
    checker = Checker(package, version)
    # The gate is judged against the pubspec this run is building from, so a released
    # package's own pinned version goes into its archived state naturally when the next
    # version is cut — no list of exemptions to maintain.
    current = version == pubspec_version()
    checker.check_version()
    checker.check_fields()
    checker.check_machine_archive()
    checker.check_no_duplicate_prose()
    checker.check_source_is_canonical(current)
    checker.check_notes(write)
    checker.check_screenshots()
    checker.check_translation_gate(current)
    if PROBLEMS:
        print(f"\n{len(PROBLEMS)} BLOCKER(S):")
        for problem in PROBLEMS:
            print(f"  - {problem}")
        return 1
    print("\nPACKAGE OK — Play sets are ready per locale; check the ASC WARN lines above "
          "before touching App Store Connect.")
    return 0


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--write"]
    if not args:
        raise SystemExit("usage: scripts/store_check.py store/v<version> [--write]")
    target_dir = Path(args[0]).resolve()
    # The version comes from the package's own pinned shim when there is one, so a
    # released package can never be re-checked against a newer pubspec.
    shim = target_dir / "check.py"
    match = re.search(r'VERSION = "([0-9.]+)"',
                      shim.read_text(encoding="utf-8")) if shim.exists() else None
    pinned = match.group(1) if match else pubspec_version()
    sys.exit(main(target_dir, pinned, "--write" in sys.argv))

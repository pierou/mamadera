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

# Recaptured by the iOS simulator pipeline (asc_driver_main + postprocess.sh). Until each
# locale is run, the accepted-but-old ASC set lives in screenshots/ios/ — reported as a
# warning, because uploading it is a decision, not an accident.
ASC_SLOTS = [
    ("asc/fr/1284x2778", 1284, 2778),
    ("asc/fr/1242x2688", 1242, 2688),
    ("asc/fr/2688x1242", 2688, 1242),
    ("asc/fr/2778x1284", 2778, 1284),
]

# The headline feature each release must sell, in the stem shared by fr/en/es.
# A release with no entry here is reported as a WARN, never silently skipped: the
# reason 1.2.1 nearly shipped a note that only listed fixes is that nobody had to
# name the feature.
HEADLINES = {
    "1.2.1": ("histor", "the unified history"),
    "1.3.0": ("notif", "system notifications"),
}


def pubspec_version(path: Path = ROOT / "pubspec.yaml") -> str:
    line = next(l for l in path.read_text(encoding="utf-8").splitlines()
                if l.startswith("version:"))
    return line.split(":", 1)[1].strip().split("+")[0]


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

    def check_source_is_canonical(self) -> None:
        """The EN fields and the per-locale editorial fields must be the source bytes."""
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
    checker.check_version()
    checker.check_fields()
    checker.check_machine_archive()
    checker.check_no_duplicate_prose()
    checker.check_source_is_canonical()
    checker.check_notes(write)
    checker.check_screenshots()
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

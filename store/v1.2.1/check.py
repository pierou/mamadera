#!/usr/bin/env python3
"""Validate — and regenerate — the v1.2.1 store package.

    python3 store/v1.2.1/check.py           # verify, exit 1 on any blocker
    python3 store/v1.2.1/check.py --write   # rewrite the Apple "What's New" from the app's
                                            # own patch notes, then verify

This file owns the rendering of the Apple notes: there is no second copy of that logic
anywhere, so a store text and the in-app dialog cannot drift apart silently. Limits are the
consoles' own — ASC 30/30/100/170/4000, Play 30/80/4000/500.
"""

import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PKG = Path(__file__).resolve().parent
FIELDS = PKG / "fields"
NOTES = PKG / "release-notes"
LOCALES = ("fr", "en", "es")

# Paste-ready field kind → the console's hard character limit.
LIMITS = {"keywords": 100, "promo": 170, "description": 4000, "short": 80,
          "name": 30, "subtitle": 30, "title": 30}
# Fields TranslateGemma produced. Their raw model output must be archived under machine/:
# that archive is what makes "who wrote this sentence" answerable after the fact.
TRANSLATED = {"promo", "description", "short", "release-notes"}

# store slot → (directory under store/v1.2.1/screenshots, expected size, required)
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
SHOTS = PKG / "screenshots"

problems: list[str] = []


def report(good: bool, label: str, detail: str = "") -> None:
    print(f"  {'ok  ' if good else 'FAIL'} {label}{detail}")
    if not good:
        problems.append(label)


def pubspec_version() -> str:
    line = next(
        l for l in (ROOT / "pubspec.yaml").read_text(encoding="utf-8").splitlines()
        if l.startswith("version:")
    )
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


def check_version(version: str) -> None:
    print("== version")
    print(f"  pubspec {version}")
    for locale in LOCALES:
        path = ROOT / "assets" / "patch_notes" / f"{locale}.json"
        notes = json.loads(path.read_text(encoding="utf-8"))
        report(version in notes, f"patch_notes/{locale}.json", f" has {version}"
               if version in notes else f" missing key {version}")


def check_machine_archive() -> None:
    print("== TranslateGemma archive (machine/)")
    for locale in ("fr", "es"):
        for store, kinds in (("apple", ("promo", "description")),
                             ("play", ("short", "description", "release-notes"))):
            for kind in kinds:
                path = PKG / "machine" / locale / f"{store}-{kind}.txt"
                report(path.exists(), f"machine/{locale}/{store}-{kind}.txt",
                     "" if path.exists() else " missing — run build_store_package.py --translate")


def check_fields() -> None:
    print("== paste-ready fields")
    for store, kinds in (("apple", ("name", "subtitle", "keywords", "promo", "description")),
                        ("play", ("title", "short", "description"))):
        for locale in LOCALES:
            for kind in kinds:
                path = FIELDS / f"{store}-{locale}-{kind}.txt"
                if not path.exists():
                    report(False, f"{path.name}", " missing")
                    continue
                body = path.read_text(encoding="utf-8").rstrip("\n")
                limit = LIMITS[kind]
                good = len(body) <= limit
                detail = f" {len(body)}/{limit}"
                if kind == "keywords":
                    tokens = [t for t in body.split(",")]
                    if body.startswith(",") or body.endswith(",") or ",," in body:
                        good = False
                        detail += " (empty token)"
                    if any(t != t.strip().lower() for t in tokens):
                        good = False
                        detail += " (space or uppercase in keywords)"
                report(good, f"{store}-{locale}-{kind}", detail)


def check_notes(version: str, write: bool) -> None:
    print("== release notes")
    for locale in LOCALES:
        apple = NOTES / f"apple-whatsnew-{locale}.txt"
        if write:
            apple.write_text(render_apple_notes(locale, version), encoding="utf-8")
        else:
            expected = render_apple_notes(locale, version)
            same = apple.exists() and apple.read_text(encoding="utf-8") == expected
            report(same, f"apple-whatsnew-{locale}.txt",
                  "" if same else " differs from assets/patch_notes — run --write")
        if apple.exists():
            body = apple.read_text(encoding="utf-8").rstrip("\n")
            report(len(body) <= 4000, f"apple whatsnew {locale}", f" {len(body)}/4000")
        play = NOTES / f"play-{locale}.txt"
        if not play.exists():
            report(False, f"play-{locale}.txt", " missing")
            continue
        body = play.read_text(encoding="utf-8").rstrip("\n")
        report(len(body) <= 500, f"play release notes {locale}", f" {len(body)}/500")
        # The headline feature of this release must be in the store text, in the
        # language of the listing — a note that only lists fixes undersells 1.2.1.
        # 'historique' / 'history' / 'historial' all share this stem.
        if "histor" not in body.lower():
            report(False, f"play-{locale}.txt", " never mentions the unified history")


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        head = handle.read(26)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return (0, 0)
    return struct.unpack(">II", head[16:24])


def check_no_duplicate_prose() -> None:
    """A guide must point at a field file, never restate it.

    Two copies of a 1 700-character description is how v1.2.1 nearly shipped a French listing
    whose wording differed from the file being pasted. Long prose inside a guide is a bug.
    """
    print("== no duplicated prose inside the guides")
    for guide in sorted((PKG / "apple").glob("*.md")) + sorted((PKG / "play").glob("*.md")):
        blocks = re.findall(r"```\n(.*?)\n```", guide.read_text(encoding="utf-8"), re.S)
        long = [b for b in blocks if len(b.strip()) > 200]
        report(not long, guide.relative_to(PKG).as_posix(),
               "" if not long else f" holds {len(long)} long text block(s) — reference fields/ instead")


def check_source_is_canonical() -> None:
    """The EN fields and the per-locale editorial fields must be the source bytes."""
    print("== fields are copies of store/source/, not edits")
    source = ROOT / "store" / "source"
    for store, kind in (("apple", "name"), ("apple", "subtitle"), ("apple", "keywords"),
                        ("play", "title"), ("apple", "promo"), ("apple", "description"),
                        ("play", "short"), ("play", "description")):
        src = source / "en" / f"{store}-{kind}.txt"
        dst = PKG / "fields" / f"{store}-en-{kind}.txt"
        if not src.exists():
            report(False, f"source/en/{store}-{kind}.txt", " missing")
            continue
        same = dst.exists() and src.read_bytes() == dst.read_bytes()
        report(same, f"{store}-en-{kind}", "" if same else " differs from store/source/en/")
    for locale in ("fr", "es"):
        for store, kind in (("apple", "name"), ("apple", "subtitle"),
                            ("apple", "keywords"), ("play", "title")):
            src = source / locale / f"{store}-{kind}.txt"
            dst = PKG / "fields" / f"{store}-{locale}-{kind}.txt"
            if not src.exists():
                report(False, f"source/{locale}/{store}-{kind}.txt", " missing")
                continue
            same = dst.exists() and src.read_bytes() == dst.read_bytes()
            report(same, f"{store}-{locale}-{kind} (editorial)",
                   "" if same else " differs from store/source — the build owns this file")


def check_screenshots() -> None:
    """Every uploaded screenshot carries its locale in the FILENAME, not just the folder.

    A bare `home.png` is unidentifiable outside its directory, and `screenshots/android/`
    holds whichever language ran last with no marker at all. A French shot in the English
    listing is otherwise indistinguishable from a correct one.
    """
    print("== screenshots — Play (per locale, hard requirement)")
    for locale, w, h, want in PLAY_SLOTS:
        directory = SHOTS / "play" / locale
        files = sorted(p for p in directory.glob("*.png") if not p.name.startswith("_debug"))
        bad_size = [p.name for p in files if png_size(p) != (w, h)]
        no_locale = [p.name for p in files if not p.name.startswith(f"{locale}-")]
        expected = {f"{locale}-{s}.png" for s in PLAY_SCREENS}
        missing = sorted(expected - {p.name for p in files})
        good = len(files) == want and not bad_size and not no_locale and not missing
        detail = f" {len(files)}/{want} png {w}x{h}"
        if not good:
            detail += (f" | no locale prefix: {no_locale}" if no_locale else "")
            detail += (f" | wrong size: {bad_size}" if bad_size else "")
            detail += (f" | missing: {missing}" if missing else "")
        report(good, f"play/{locale}", detail)

    print("== screenshots — App Store (per locale, simulator pipeline)")
    for rel, w, h in ASC_SLOTS:
        directory = SHOTS / rel
        locale = rel.split("/")[1]
        files = sorted(p for p in directory.glob("*.png") if not p.name.startswith("_debug"))
        if not files:
            print(f"  WARN {rel} — empty; recapture with asc_driver_main "
                  f"--dart-define=APP_LOCALE, or upload screenshots/ios/asc/ knowingly")
            continue
        bad_size = [p.name for p in files if png_size(p) != (w, h)]
        no_locale = [p.name for p in files if not p.name.startswith(f"{locale}-")]
        report(not bad_size and not no_locale, rel, f" {len(files)} png {w}x{h}"
               + (f" | no locale prefix: {no_locale}" if no_locale else "")
               + (f" | wrong size: {bad_size}" if bad_size else ""))


def main() -> int:
    write = "--write" in sys.argv
    version = pubspec_version()
    check_version(version)
    check_fields()
    check_machine_archive()
    check_no_duplicate_prose()
    check_source_is_canonical()
    check_notes(version, write)
    check_screenshots()
    if problems:
        print(f"\n{len(problems)} BLOCKER(S):")
        for p in problems:
            print(f"  - {p}")
        return 1
    print("\nPACKAGE OK — Play sets are ready per locale; check the ASC WARN lines above "
          "before touching App Store Connect.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Build a store package for the release at hand: `store/v<version>/`.

    python3 scripts/build_store_package.py              # copy canonical text, check
    python3 scripts/build_store_package.py --translate  # also run TranslateGemma for fr/es

## Why this exists

The store package used to be assembled by hand, and that is how a listing ended up
promising « tétées » while the app's own home button (`homeButtonMiam`) says
« Nourriture ». This script makes the chain auditable instead of remembered:

    store/source/en/<store>-<field>.txt                       canonical prose, authored ONCE
        └─ tg-translate en→<locale> ─→ store/v<v>/machine/<locale>/<store>-<field>.txt
              └─ term alignment (cited to lib/l10n/app_<locale>.arb) ─→ fields/<store>-<locale>-<field>.txt

**What the model translates** — the prose: promotional text, both descriptions, Play's short
description and Play's release notes. **What it never touches** — brand names, subtitles and
ASO keywords: a name is a brand and a uniqueness check, keywords are the tokens users type,
and neither is a translation of the English. Each locale carries those in
`store/source/<locale>/`, and the copy is verbatim. Apple's "What's New" also stays out of
the model's hands: it renders from `assets/patch_notes/<locale>.json`, already reviewed.

Raw model output is kept under `machine/` so any wording on the live listing can be traced to
the call that produced it. Alignment rewrites terms only — it never re-translates — and every
rewrite names its authority: `arb:<key>` (the app wins over the model's synonym) or
`editorial` (a register choice with no app string to defer to, kept visible in the diff).

Hard character limits are enforced by `store/v<version>/check.py`. A faithful French
translation runs 20-50 % longer than its English, so when French is over the cap the fix is
to shorten `store/source/en/` — never to hand-trim the French, which would put unreviewed
human words back into the pipeline.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "store" / "source"
STORE = ROOT / "store"

LOCALES = ("fr", "en", "es")
TRANSLATE_INTO = ("fr", "es")

# (store, field) → the console's hard character limit.
LIMITS = {
    ("apple", "name"): 30,
    ("apple", "subtitle"): 30,
    ("apple", "keywords"): 100,
    ("apple", "promo"): 170,
    ("apple", "description"): 4000,
    ("play", "title"): 30,
    ("play", "short"): 80,
    ("play", "description"): 4000,
    ("play", "release-notes"): 500,
}
EDITORIAL = [("apple", "name"), ("apple", "subtitle"), ("apple", "keywords"), ("play", "title")]
TRANSLATED = [("apple", "promo"), ("apple", "description"), ("play", "short"),
              ("play", "description"), ("play", "release-notes")]

# Fields the consoles render on one line: the model ends every block with a period, and a
# title, subtitle, keyword list or short description does not want one.
NO_TRAILING_PERIOD = {("apple", "name"), ("apple", "subtitle"), ("apple", "keywords"),
                      ("play", "title"), ("play", "short")}

# Term alignment applied to model output. Cited, so a reviewer can check each one.
ALIGN = {
    "fr": [
        ("cryptage", "chiffrement", "editorial — « cryptage » is the angle-derived informal form"),
        ("cryptés", "chiffrés", "editorial — same choice, plural"),
        ("crypté", "chiffré", "editorial — same choice"),
        ("en dehors des plages acceptables", "hors plage", "arb:growthValueOutOfRange"),
        # MATERIAL: « télécharger » in French means DOWNload. The model turned
        # "nothing is ever uploaded" into "nothing is ever downloaded" — a weaker
        # promise in the one sentence that carries the app's whole claim. The app's
        # own wording (exportDataWarning) uses « envoyé »; the app wins.
        ("rien n'est jamais téléchargé", "rien n'est jamais envoyé", "arb:exportDataWarning — « envoyé », not « téléchargé » (= downloaded)"),
    ],
    "es": [
        ("encriptación", "cifrado", "editorial — « cifrado » is the standard term here"),
        ("encriptado", "cifrado", "editorial — same"),
        ("fuera del rango establecido", "fuera de rango", "arb:growthValueOutOfRange"),
        ("fuera del rango", "fuera de rango", "arb:growthValueOutOfRange"),
    ],
}

# Words a listing may use while the app shows something else. WARN, not blocker — context can
# justify the word — but never silent: this is exactly how 1.2.0 drifted.
GLOSSARY_WATCH = {
    "en": {},
    "fr": {"tétées": "homeButtonMiam says « Nourriture »",
           "tétée": "homeButtonMiam says « Nourriture »"},
    "es": {"pecho": "feedingSubtypeNatural says « Leche Materna »",
           "pechos": "feedingSubtypeNatural says « Leche Materna »"},
}


def pubspec_version() -> tuple[str, str]:
    for line in (ROOT / "pubspec.yaml").read_text(encoding="utf-8").splitlines():
        if line.startswith("version:"):
            version, build = line.split(":", 1)[1].strip().split("+")
            return version, build
    raise SystemExit("pubspec.yaml has no version:")


def tg(src: str, tgt: str, infile: Path, outfile: Path) -> str:
    """One TranslateGemma call. Returns its stderr timing line."""
    outfile.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(["tg-translate", src, tgt, str(infile), "--out", str(outfile)],
                         capture_output=True, text=True, cwd=ROOT)
    if proc.returncode != 0:
        raise SystemExit(f"tg-translate {src}→{tgt} {infile.name} failed: {proc.stderr.strip()}")
    return proc.stderr.strip().splitlines()[-1] if proc.stderr.strip() else ""


def align(locale: str, text: str, store: str, field: str) -> tuple[str, list[str]]:
    notes = []
    for bad, good, why in ALIGN.get(locale, []):
        if bad != good and bad in text:
            text = text.replace(bad, good)
            notes.append(f"       {bad!r} → {good!r}  ({why})")
    if (store, field) in NO_TRAILING_PERIOD:
        text = text.rstrip().rstrip(".")
    return text.strip() + "\n", notes


def apple_whatsnew(locale: str, version: str) -> str:
    doc = json.loads(
        (ROOT / "assets" / "patch_notes" / f"{locale}.json").read_text(encoding="utf-8"))[version]
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


def target(pkg: Path, store: str, locale: str, field: str) -> Path:
    # Play's release notes live in release-notes/ (they are the per-language "What's new in
    # this release" box, not a listing field); everything else is a listing field.
    if (store, field) == ("play", "release-notes"):
        return pkg / "release-notes" / f"play-{locale}.txt"
    if (store, field) == ("apple", "whatsnew"):
        return pkg / "release-notes" / f"apple-whatsnew-{locale}.txt"
    return pkg / "fields" / f"{store}-{locale}-{field}.txt"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--translate", action="store_true",
                    help="run TranslateGemma (box). Never alongside a queued or running box-* agent.")
    ap.add_argument("--version", help="default: pubspec version")
    args = ap.parse_args()

    version, build = pubspec_version()
    version = args.version or version
    pkg = STORE / f"v{version}"

    # Validate BEFORE touching the filesystem: a KeyError from deep inside the notes
    # renderer used to leave a half-built store/v<version>/ on disk (caught running the
    # next-release path dry, 2026-10-18). "Add the patch notes first" is the whole answer,
    # so say that instead of throwing.
    missing_notes = []
    for locale in LOCALES:
        path = ROOT / "assets" / "patch_notes" / f"{locale}.json"
        if not path.exists():
            missing_notes.append(f"{locale} (no {path.relative_to(ROOT)})")
        elif version not in json.loads(path.read_text(encoding="utf-8")):
            missing_notes.append(f"{locale} (no key {version})")
    if missing_notes:
        raise SystemExit(
            f"cannot build store/v{version}/: patch notes incomplete — {', '.join(missing_notes)}.\n"
            f"Add the {version} entry to assets/patch_notes/{{fr,en,es}}.json first "
            f"(that is also what the in-app 'What's New' dialog reads), then re-run.")
    if pkg.exists() and not (pkg / "check.py").exists():
        raise SystemExit(
            f"{pkg} exists but has no check.py — a previous run died mid-build.\n"
            f"Delete it and re-run; do not hand-fill a partial package.")

    created = not pkg.exists()
    (pkg / "fields").mkdir(parents=True, exist_ok=True)
    (pkg / "release-notes").mkdir(parents=True, exist_ok=True)
    print(f"store package {pkg.relative_to(ROOT)}  (build {build})")
    if created:
        print("  (directory created by this run)")

    missing = [f"en/{s}-{f}" for s, f in LIMITS if not (SOURCE / "en" / f"{s}-{f}.txt").exists()]
    for locale in TRANSLATE_INTO:
        missing += [f"{locale}/{s}-{f}" for s, f in EDITORIAL
                    if not (SOURCE / locale / f"{s}-{f}.txt").exists()]
    if missing:
        raise SystemExit(f"canonical source missing: {missing}")

    print("== canonical English — copied verbatim")
    for store, field in LIMITS:
        shutil.copyfile(SOURCE / "en" / f"{store}-{field}.txt",
                        target(pkg, store, "en", field))
        text = target(pkg, store, "en", field).read_text(encoding="utf-8").rstrip("\n")
        lim = LIMITS[(store, field)]
        print(f"  {'ok  ' if len(text) <= lim else 'OVER'} en-{store}-{field} {len(text)}/{lim}")

    print("== per-locale editorial (name, subtitle, keywords) — copied verbatim, never machine")
    for locale in TRANSLATE_INTO:
        for store, field in EDITORIAL:
            shutil.copyfile(SOURCE / locale / f"{store}-{field}.txt",
                            target(pkg, store, locale, field))
            text = target(pkg, store, locale, field).read_text(encoding="utf-8").rstrip("\n")
            lim = LIMITS[(store, field)]
            print(f"  {'ok  ' if len(text) <= lim else 'OVER'} {locale}-{store}-{field} {len(text)}/{lim}")

    print("== Apple What's New — rendered from assets/patch_notes (reviewed, not machine)")
    for locale in LOCALES:
        path = target(pkg, "apple", locale, "whatsnew")
        path.write_text(apple_whatsnew(locale, version), encoding="utf-8")
        print(f"  ok   apple-{locale}-whatsnew {len(path.read_text(encoding='utf-8').rstrip())}/4000")

    if args.translate:
        if not shutil.which("tg-translate"):
            raise SystemExit("tg-translate not on PATH")
        print("== TranslateGemma — prose only, raw output archived under machine/")
        for locale in TRANSLATE_INTO:
            for store, field in TRANSLATED:
                src = SOURCE / "en" / f"{store}-{field}.txt"
                raw = pkg / "machine" / locale / f"{store}-{field}.txt"
                timing = tg("en", locale, src, raw)
                text, notes = align(locale, raw.read_text(encoding="utf-8"), store, field)
                out = target(pkg, store, locale, field)
                out.write_text(text, encoding="utf-8")
                lim = LIMITS[(store, field)]
                n = len(text.rstrip("\n"))
                print(f"  {'ok  ' if n <= lim else 'OVER'} {locale}-{store}-{field:<24} {n:>5}/{lim}  {timing}")
                for note in notes:
                    print(note)
            # Keywords: translated for the record only. The live list stays editorial.
            raw = pkg / "machine" / locale / "apple-keywords.txt"
            tg("en", locale, SOURCE / "en" / "apple-keywords.txt", raw)
            print(f"  --   {locale}-apple-keywords archived, editorial list kept")

    print("\n== report")
    over = 0
    for locale in LOCALES:
        for (store, field), lim in LIMITS.items():
            path = target(pkg, store, locale, field)
            if not path.exists():
                print(f"  MISSING {locale}-{store}-{field}")
                over += 1
                continue
            text = path.read_text(encoding="utf-8")
            n = len(text.rstrip("\n"))
            if n > lim:
                print(f"  OVER {locale}-{store}-{field} {n}/{lim} — shorten store/source/en/, not the translation")
                over += 1
            for word, why in GLOSSARY_WATCH.get(locale, {}).items():
                if word in text.lower():
                    print(f"  WARN {locale}-{store}-{field}: uses {word!r} — app {why}")
    print(f"\n{'shorten the canonical and re-run' if over else 'all fields within limits'}")
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main())

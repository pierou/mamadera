# store/ — store assets

Two kinds of things live here:

1. **`source/en/`** — the canonical listing prose, authored **once** in English. This is the
   file you edit. French and Spanish are not written here: they are generated.
2. **Marketing art** at this level — banners, headers, feature graphics, generated trilingual
   by `/usr/bin/python3 mamadera_banner_final.py` (repo root — `../mamadera_banner_final.py` seen from this file). No suffix = French, `_en`, `_es`.
   These are app-branding assets, not per-release, so they are not versioned by directory.
3. **`v<version>/`** — one directory per release, **built** by
   `python3 scripts/build_store_package.py [--translate]`: the complete package to publish that
   version on each store, per language. Text paste-ready per console field, screenshots per
   device slot, and a checker that enforces the consoles' limits.

## Screenshot names carry the language

`<locale>-<screen>.png` — `fr-home.png`, `es-history.png`, `en-growth.png` — **inside**
`v<version>/screenshots/play/<locale>/` and `.../asc/<locale>/<size>/`.

The folder is not the record. `screenshots/android/` and `screenshots/ios/asc/<size>/` are
overwritten by every capture run and hold whichever language ran last with no marker at all;
the moment a bare `home.png` leaves its folder — dragged into the console, zipped, attached to
a ticket — nothing says which language it is, and a French shot in the English listing looks
exactly like a correct one. The locale in the filename survives all of that.
`store/v<x>/check.py` fails a package on a bare name;
`/usr/bin/python3 screenshots/android/verify_android.py --locale=fr` verifies an upload set.

## The translation chain (why the French is machine-made)

```
store/source/en/<store>-<field>.txt        ← authored once, English, the only hand-written copy
    └─ tg-translate en→fr | en→es         ← TranslateGemma (box, temp 0 = deterministic)
         └─ store/v<v>/machine/<locale>/  ← RAW model output, kept forever: proves who wrote it
              └─ term alignment           ← rewrites terms only, each cited to lib/l10n/app_<locale>.arb
                   └─ fields/<store>-<locale>-<field>.txt   ← what you paste into the console
```

The model translates the **prose only**. Brand names, subtitles and ASO keywords come from
`store/source/<locale>/` verbatim: a name is a brand and a uniqueness check, and keywords are
the tokens users type — machine-translating either produces fluent, useless strings. Apple's
"What's New" renders from `assets/patch_notes/<locale>.json`, already reviewed.

When French overflows a cap, shorten `store/source/en/` and re-run — never trim the French,
which would put unreviewed human words back into a machine-made pipeline.

| package | state |
|---|---|
| [`v1.3.0/`](v1.3.0/) | **current** — 1.3.0+1, not yet built on device: `check.py` is red on the 24 Play screenshots until `make store-shots VERSION=1.3.0` runs |
| [`v1.2.1/`](v1.2.1/README.md) | archived — 1.2.1+11, tag `v1.2.1`, **published**; kept and still checked, because it is the record of what went live |

Before uploading, always:

```bash
python3 store/v1.3.0/check.py        # limits + note consistency + screenshot inventory
python3 store/v1.3.0/check.py --write  # regenerate Apple "What's New" from assets/patch_notes
make store-prose                     # (next release) TranslateGemma fr/es from source/en/
```

Each `check.py` is **generated** by `scripts/build_store_package.py` and pins the version it
was built for; the checks themselves live once, in `scripts/store_check.py`. The pin is the
point: when 1.3.0 was bumped, the v1.2.1 checker — which used to read `pubspec.yaml` — began
demanding 1.3.0's patch notes from 1.2.1's published text and raised three blockers on files
that had not changed and must not change. A released listing does not track the working tree.

Older releases have no package directory here: 1.0.x–1.2.0 were submitted with the copy in
`docs/app-store-setup.md` and `docs/google-play-setup.md`, which still hold that (older)
listing text. Those two docs describe *how to submit*; `v<version>/` holds *what to submit*.

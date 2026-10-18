# store/ — store assets

Two kinds of things live here:

1. **`source/en/`** — the canonical listing prose, authored **once** in English. This is the
   file you edit. French and Spanish are not written here: they are generated.
2. **Marketing art** at this level — banners, headers, feature graphics, generated trilingual
   by `/usr/bin/python3 mamadera_banner_final.py`. No suffix = French, `_en`, `_es`.
   These are app-branding assets, not per-release, so they are not versioned by directory.
3. **`v<version>/`** — one directory per release, **built** by
   `python3 scripts/build_store_package.py [--translate]`: the complete package to publish that
   version on each store, per language. Text paste-ready per console field, screenshots per
   device slot, and a checker that enforces the consoles' limits.

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
| [`v1.2.1/`](v1.2.1/README.md) | **current** — 1.2.1+11, tag `v1.2.1` |

Before uploading, always:

```bash
python3 store/v1.2.1/check.py        # limits + note consistency + screenshot inventory
python3 store/v1.2.1/check.py --write  # regenerate Apple "What's New" from assets/patch_notes
make store-prose                     # (next release) TranslateGemma fr/es from source/en/
```

Older releases have no package directory here: 1.0.x–1.2.0 were submitted with the copy in
`docs/app-store-setup.md` and `docs/google-play-setup.md`, which still hold that (older)
listing text. Those two docs describe *how to submit*; `v<version>/` holds *what to submit*.

# store/ — store assets

Two kinds of things live here:

1. **Marketing art** at this level — banners, headers, feature graphics, generated trilingual
   by `/usr/bin/python3 mamadera_banner_final.py`. No suffix = French, `_en`, `_es`.
   These are app-branding assets, not per-release, so they are not versioned by directory.
2. **`v<version>/`** — one directory per release: the complete package to publish that
   version on each store, per language. Text paste-ready per console field, screenshots per
   device slot, and a checker that enforces the consoles' limits.

| package | state |
|---|---|
| [`v1.2.1/`](v1.2.1/README.md) | **current** — 1.2.1+11, tag `v1.2.1` |

Before uploading, always:

```bash
python3 store/v1.2.1/check.py        # limits + note consistency + screenshot inventory
python3 store/v1.2.1/check.py --write  # regenerate Apple "What's New" from assets/patch_notes
```

Older releases have no package directory here: 1.0.x–1.2.0 were submitted with the copy in
`docs/app-store-setup.md` and `docs/google-play-setup.md`, which still hold that (older)
listing text. Those two docs describe *how to submit*; `v<version>/` holds *what to submit*.

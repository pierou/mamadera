#!/usr/bin/env python3
"""Verify the Android store screenshots before upload.

Exists because the pipeline had NO verification step for Android at all, and
its README asserted "0 reddish pixels across the whole top zone of every file
— no patching step is needed". That claim was false: a `flutter drive` run
builds a DEBUG APK, which draws the red diagonal DEBUG ribbon, and every
captured file carried it (6260 reddish pixels in the top-right zone) until
`integration_test/screenshot_capture.dart` set
`WidgetsApp.debugAllowBannerOverride = false`.

The accepted uploads in git are ribbon-free, so a run that produces a ribbon
is a regression. This script is the check that catches it, and it fails loudly.

Usage:
    /usr/bin/python3 screenshots/android/verify_android.py
"""

import sys
from pathlib import Path

from PIL import Image

BASE = Path(__file__).resolve().parent

# Pixel_10_Pro emulator native resolution.
EXPECTED_SIZE = (1280, 2856)

# The seven uploadable screens plus growth (v1.2.0). `_debug_*.png` files are
# one-off pipeline artifacts and are ignored.
EXPECTED = [
    "home",
    "history",
    "menu",
    "feeding_dialog",
    "sleep_diagram",
    "diaper_dialog",
    "health_diagram",
    "growth",
]


def red_count(im: Image.Image) -> int:
    """Reddish pixels in the top-right zone, where the DEBUG ribbon sits."""
    w, h = im.size
    zone = im.crop((int(w * 0.6), 0, w, int(h * 0.12)))
    return sum(
        1
        for r, g, b in zone.convert("RGB").getdata()
        if r > 100 and r > g + 30 and r > b + 30
    )


def main() -> None:
    failures = 0

    for name in EXPECTED:
        p = BASE / f"{name}.png"
        if not p.exists():
            print(f"[FAIL] {name}.png: missing")
            failures += 1
            continue
        im = Image.open(p)
        reds = red_count(im)
        ok = im.size == EXPECTED_SIZE and reds == 0
        if not ok:
            failures += 1
        print(
            f"[{'ok' if ok else 'FAIL'}] {name}.png "
            f"{im.size[0]}x{im.size[1]} red={reds}"
        )

    if failures:
        sys.exit(f"\n{failures} Android screenshot(s) failed verification")
    print(f"\nAll {len(EXPECTED)} Android screenshots verified "
          f"(exact size {EXPECTED_SIZE[0]}x{EXPECTED_SIZE[1]}, no DEBUG ribbon).")


if __name__ == "__main__":
    main()

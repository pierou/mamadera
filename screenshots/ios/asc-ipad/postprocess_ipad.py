#!/usr/bin/env python3
"""Postprocess raw iPad simulator captures into ASC-exact-size PNGs.

The iPad driver run is seeded with --dart-define=ASC_NO_BANNER=true, so the
raw captures carry no DEBUG ribbon and need no pixel patching — only
resize (13") and an alpha strip (ASC rejects PNGs with an alpha channel,
even fully opaque ones).

Input (written by test_driver/asc_screenshots.dart via ASC_RAW_DIR):
  screenshots/ios/asc-ipad/raw-11/  11" Pro (M5) native 1668x2388
  screenshots/ios/asc-ipad/raw-13/  13" Pro (M5) native 2064x2752

Output (12 files, verified exact dimensions + 24-bit RGB + 0 red banner
pixels in the top zone):
  1668x2388/  (ASC 11" iPad slot, portrait — the canonical slot size)
  2048x2732/  (ASC 13" iPad slot, portrait)

Six screens: home, feeding, sleep, diaper, history, menu.

Portrait only: iPadOS ignores SystemChrome.setPreferredOrientations and
this host has no Simulator.app GUI to drive the I/O > Rotate menu,
so landscape iPad captures are not part of the pipeline. The ASC iPad
slots accept portrait uploads (the listed slot sizes are portrait).
"""

import sys
from pathlib import Path

from PIL import Image

BASE = Path(__file__).resolve().parent

# (raw dir, out dir, target WxH)
SETS = [
    ("raw-11", "1668x2388", (1668, 2388)),
    ("raw-13", "2048x2732", (2048, 2732)),
]

SCREENS = ["home", "feeding", "sleep", "diaper", "history", "menu"]


def red_scan(im: Image.Image) -> int:
    """Count reddish pixels in the top-right banner zone (ribbon check)."""
    w, h = im.size
    zone = im.crop((w // 2, 0, w, min(h // 8, 340)))
    return sum(
        1
        for r, g, b in zone.getdata()
        if r > 100 and r > g + 30 and r > b + 30
    )


def main() -> None:
    failures = 0
    for raw_dir, out_dir, (tw, th) in SETS:
        for s in SCREENS:
            src = BASE / raw_dir / f"{s}.png"
            if not src.exists():
                print(f"[FAIL] {raw_dir}: missing {s}.png")
                failures += 1
                continue
            im = Image.open(src).convert("RGB")
            w, h = im.size
            if h < w:
                print(f"[FAIL] {raw_dir}/{s}.png: expected portrait, got {w}x{h}")
                failures += 1
                continue
            if (w, h) != (tw, th):
                im = im.resize((tw, th), Image.LANCZOS)
            out = BASE / out_dir / f"{s}.png"
            out.parent.mkdir(parents=True, exist_ok=True)
            im.save(out, format="PNG")

    # Verification pass: exact dimensions, no alpha, no red banner pixels.
    print("\n=== Verification ===")
    for raw_dir, out_dir, (tw, th) in SETS:
        for s in SCREENS:
            p = BASE / out_dir / f"{s}.png"
            if not p.exists():
                print(f"[FAIL] {out_dir}/{s}.png: missing")
                failures += 1
                continue
            im = Image.open(p)
            ok = im.size == (tw, th) and im.mode == "RGB"
            reds = red_scan(im)
            status = "ok" if ok and reds == 0 else "FAIL"
            if status == "FAIL":
                failures += 1
            print(
                f"[{status}] {out_dir}/{s}.png "
                f"{im.size[0]}x{im.size[1]} mode={im.mode} red={reds}"
            )

    if failures:
        sys.exit(f"{failures} file(s) failed verification")
    print("\nAll 12 iPad screenshots verified (exact size, RGB24, no ribbon).")


if __name__ == "__main__":
    main()

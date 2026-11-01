#!/usr/bin/env python3
"""Pixel-sampled WCAG contrast from a screenshot — stdlib only.

Why this exists: B4 (`docs/BACKLOG.md`) asked for the real ratios of the accent-tinted
widgets, and the ratios quoted until 2026-11-01 were *computed* from theme constants. The
computed numbers were within ~10 % of the device sample, but a colour decision should rest on
the pixels a parent actually reads. There is no PIL on this Mac and `sips` cannot read a pixel,
so PNGs go through `sips -s format bmp` and the BMP is parsed here.

Usage
    scripts/wcag_sample.py IMAGE --find cream,blue,yellow      # auto-locate + measure
    scripts/wcag_sample.py IMAGE x0,y0,x1,y1 [label] ...       # measure a box

Method, per box: the background is the **dominant quantised colour inside the box** (a text box
is mostly background), and the label is the pixel furthest from it in luminance. That is the
pair a WCAG calculator wants, and it is why no hand-picked "empty patch" coordinates are needed.

Anti-aliasing makes the extreme pixel slightly more favourable than the average glyph, so read
these as the *best case* for the text — if the best case fails AA, the text fails.
"""

from __future__ import annotations

import argparse
import collections
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

# What to look for when --find is used: target colour (approx, from the theme) and a tolerance.
# Values are the palette in lib/core/theme.dart composited over the light scaffold, as observed
# in captures — extend rather than guess coordinates on every new screen.
FIND = {
    "cream":   ((255, 249, 230), 10),   # selected chip fill (miam at ~20 % on the sheet)
    "blue":    ((179, 229, 252), 26),   # selected segmented-button segment
    "yellow":  ((255, 213, 79),  30),   # miam accent painted as text
    "green":   ((102, 187, 106), 30),   # sante accent
    "bluetxt": ((66, 165, 245),  30),   # dodo accent
    "brown":   ((93, 64, 55),     30),  # caca accent
}


def _from_bmp(path: Path):
    d = path.read_bytes()
    off = struct.unpack_from("<I", d, 10)[0]
    w = struct.unpack_from("<i", d, 18)[0]
    h = struct.unpack_from("<i", d, 22)[0]
    ch = struct.unpack_from("<H", d, 28)[0] // 8
    top = h < 0
    height = abs(h)

    def px(x: int, y: int):
        yy = y if top else height - 1 - y
        i = off + (yy * w + x) * ch
        return d[i + 2], d[i + 1], d[i]

    return w, height, px


def _from_png(path: Path):
    """Minimal PNG reader (8-bit RGB/RGBA, non-interlaced) — screencap output qualifies."""
    d = path.read_bytes()
    if d[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos, idat, meta = 8, bytearray(), None
    while pos < len(d):
        (ln,) = struct.unpack_from("<I", d, pos)
        kind = d[pos + 4:pos + 8]
        body = d[pos + 8:pos + 8 + ln]
        if kind == b"IHDR":
            meta = struct.unpack_from(">IIBBBBB", body, 0)
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
        pos += ln + 12
    w, h, depth, color, interlace = meta[0], meta[1], meta[2], meta[3], meta[6]
    if depth != 8 or interlace != 0 or color not in (2, 6):
        raise ValueError(f"{path}: need 8-bit non-interlaced RGB/RGBA, got depth={depth} color={color}")
    nch = 3 if color == 2 else 4
    raw = zlib.decompress(bytes(idat))
    stride = w * nch
    prev = bytearray(stride)
    rows: list[bytearray] = []
    i = 0
    for _ in range(h):
        ft = raw[i]
        i += 1
        line = bytearray(raw[i:i + stride])
        i += stride
        if ft == 1:
            for x in range(nch, stride):
                line[x] = (line[x] + line[x - nch]) & 255
        elif ft == 2:
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 255
        elif ft == 3:
            for x in range(stride):
                a = line[x - nch] if x >= nch else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 255
        elif ft == 4:
            for x in range(stride):
                a = line[x - nch] if x >= nch else 0
                b = prev[x]
                c = prev[x - nch] if x >= nch else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 255
        rows.append(line)
        prev = line

    def px(x: int, y: int):
        r = rows[y]
        return r[x * nch], r[x * nch + 1], r[x * nch + 2]

    return w, h, px


def load(path: Path):
    """Return (width, height, px) — BMP if already converted, else decode the PNG directly."""
    if path.suffix.lower() == ".bmp":
        return _from_bmp(path)
    try:
        return _from_png(path)
    except (zlib.error, struct.error, ValueError):
        # Fallback for PNGs this reader cannot handle (16-bit, palette, interlaced).
        out = Path(tempfile.gettempdir()) / (path.stem + ".wcag.bmp")
        subprocess.run(["/usr/bin/sips", "-s", "format", "bmp", str(path), "--out", str(out)],
                       check=True, capture_output=True)
        return _from_bmp(out)


def _lin(v: int) -> float:
    v /= 255.0
    return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4


def lum(c) -> float:
    return 0.2126 * _lin(c[0]) + 0.7152 * _lin(c[1]) + 0.0722 * _lin(c[2])


def ratio(a, b) -> float:
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def measure(w, h, px, x0, y0, x1, y1, note="", extreme="auto"):
    """Dominant colour in the box = background; the label = the pixel furthest from it.

    `extreme` matters and is why the flag exists: on a light fill a dark icon glyph inside the
    same box outranks pale text, so `auto` reports the more extreme of the two and can describe
    the icon rather than the label. When you know the text colour (white label on a tinted
    chip = the B4 case), say so with `--extreme light`.
    """
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(w, x1), min(h, y1)
    cols = [px(x, y) for y in range(y0, y1) for x in range(x0, x1)]
    if not cols:
        return None
    hist = collections.Counter((r >> 3, g >> 3, b >> 3) for r, g, b in cols)
    q, n = hist.most_common(1)[0]
    bg = tuple(v << 3 | 7 for v in q)
    lb = lum(bg)
    dark = min(cols, key=lum)
    light = max(cols, key=lum)
    if extreme == "light":
        far = light
    elif extreme == "dark":
        far = dark
    else:
        far = light if abs(lum(light) - lb) >= abs(lum(dark) - lb) else dark
    r = ratio(far, bg)
    aa = "AA normal 4.5" if r >= 4.5 else ("AA large 3.0" if r >= 3.0 else "FAILS AA")
    print(f"  box {x0},{y0}-{x1},{y1}  label {far} on bg {bg} ({n} px of box)  ->  {r:5.2f}:1  [{aa}] {note}")
    return r


def find_bbox(w, h, px, target, tol):
    """Bounding box of pixels near `target`; None if absent."""
    minx = miny = 10**6
    maxx = maxy = -1
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            c = px(x, y)
            if all(abs(c[i] - target[i]) <= tol for i in range(3)):
                if x < minx: minx = x
                if x > maxx: maxx = x
                if y < miny: miny = y
                if y > maxy: maxy = y
    if maxx < 0:
        return None
    return minx, miny, maxx + 1, maxy + 1


def main() -> int:
    ap = argparse.ArgumentParser(description="pixel-sampled WCAG contrast from a screenshot")
    ap.add_argument("image", type=Path)
    ap.add_argument("--find", help=f"comma list of: {','.join(FIND)}")
    ap.add_argument("boxes", nargs="*", help="x0,y0,x1,y1 [note]")
    ap.add_argument("--extreme", choices=["auto", "light", "dark"], default="auto",
                    help="which end of the box is the text (default: whichever is more extreme)")
    args = ap.parse_args()

    if not args.image.exists():
        print(f"no such file: {args.image}", file=sys.stderr)
        return 2
    if shutil.which("sips") is None and args.image.suffix.lower() == ".png":
        print("this reader needs either a decodable PNG or /usr/bin/sips", file=sys.stderr)
        return 2
    w, h, px = load(args.image)
    print(f"{args.image.name}  {w}x{h}")

    if args.find:
        for name in args.find.split(","):
            name = name.strip().lower()
            if name not in FIND:
                print(f"  unknown target '{name}' (have: {', '.join(FIND)})", file=sys.stderr)
                continue
            target, tol = FIND[name]
            bb = find_bbox(w, h, px, target, tol)
            if bb is None:
                print(f"  {name:9} not present in this capture")
                continue
            print(f"  [{name}] located at {bb[0]},{bb[1]}-{bb[2]},{bb[3]} "
                  f"({bb[2]-bb[0]}x{bb[3]-bb[1]})")
            measure(w, h, px, *bb, note=f"target {name}", extreme=args.extreme)

    it = iter(args.boxes)
    for spec in it:
        try:
            x0, y0, x1, y1 = (int(v) for v in spec.split(","))
        except ValueError:
            print(f"bad box '{spec}' (want x0,y0,x1,y1)", file=sys.stderr)
            return 2
        note = next(it, "")
        measure(w, h, px, x0, y0, x1, y1, note=note, extreme=args.extreme)
    return 0


if __name__ == "__main__":
    sys.exit(main())

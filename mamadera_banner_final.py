#!/usr/bin/env python3
"""Generate store images for Mamadera.

Produces two marketing images matching the app icon's brand palette
(warm gold, soft teal, lavender on a light cream background):

  store/play_feature_graphic.png  1024x500  Google Play feature graphic
  store/appstore_promo.png        1280x800  App Store / web promo tile

Design notes
------------
- Background: diagonal 3-stop gradient (cream -> lavender -> soft teal)
  with true alpha-composited radial glows (no banding).
- Typography: SF Rounded (variable, Weight axis) for display text,
  SF Pro for body. Falls back to system fonts on non-macOS machines.
- Feature glyphs are drawn as vector shapes (bottle, moon, diaper, pill,
  baby, lock) — no emoji-font dependency, so output is identical on any
  machine and any OS.
- Layouts respect the store safe zone: all important content stays at
  least ~56 px from every edge.

Run: /usr/bin/python3 mamadera_banner_final.py
"""
from PIL import Image, ImageDraw, ImageFont
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ICON_PATH = os.path.join(HERE, "assets", "splash", "launcher_icon_ios.png")
OUT_DIR = os.path.join(HERE, "store")

# ── Brand palette (sampled from the app icon) ──────────────────────────────
GOLD     = (245, 198, 79)    # icon hair
TEAL     = (78, 195, 219)    # icon skirt
LAVENDER = (183, 159, 232)   # icon hat
INK      = (46, 27, 82)      # deep plum — display text
BODY     = (74, 61, 110)     # secondary text
MUTED    = (156, 143, 188)   # footer text
CREAM    = (255, 249, 239)
SOFT_LAV = (243, 236, 250)
SOFT_TEAL = (227, 244, 246)
WHITE    = (255, 255, 255)

CHIP_INDIGO = (108, 111, 224)   # night / sleep
CHIP_GREEN  = (108, 197, 150)   # health reminders
CHIP_PEACH  = (247, 160, 114)   # baby profile
CHIP_PLUM   = (138, 111, 209)   # encryption


# ── Fonts ───────────────────────────────────────────────────────────────────
SF_ROUNDED_CANDIDATES = [
    "/System/Library/Fonts/SFNSRounded.ttf",
    "/Library/Fonts/Arial Rounded MT Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]
SF_PRO_CANDIDATES = [
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/HelveticaNeue.ttc",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
]


def _load(candidates, size):
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _set_weight(font, weight):
    """Set the Weight variation axis of a variable font (no-op otherwise)."""
    try:
        axes = font.get_variation_axes()
        values = {}
        for axis in axes:
            name = axis["name"].decode() if isinstance(axis["name"], bytes) else axis["name"]
            values[name] = axis["default"]
        for name in list(values):
            if name.lower() in ("weight", "wght"):
                values[name] = weight
        names = [
            a["name"].decode() if isinstance(a["name"], bytes) else a["name"]
            for a in axes
        ]
        font.set_variation_by_axes([values[name] for name in names])
    except Exception:
        pass  # non-variable font — keep default weight


def sf_rounded(size, weight=800):
    font = _load(SF_ROUNDED_CANDIDATES, size)
    _set_weight(font, weight)
    return font


def sf_pro(size, weight=500):
    font = _load(SF_PRO_CANDIDATES, size)
    _set_weight(font, weight)
    return font


# ── Background: diagonal 3-stop gradient + radial glows ────────────────────
def _blend(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def gradient_bg(w, h, c1, c2, c3):
    """Diagonal gradient: c1 (top-left) -> c2 (middle) -> c3 (bottom-right)."""
    ramp = []
    n = w + h - 2  # index = x + y
    for i in range(n + 1):
        t = i / n
        ramp.append(_blend(c1, c2, t * 2) if t < 0.5 else _blend(c2, c3, (t - 0.5) * 2))
    buf = bytearray()
    extend = buf.extend
    for y in range(h):
        for x in range(w):
            extend(ramp[x + y])
    return Image.frombytes("RGB", (w, h), bytes(buf))


def add_glow(img, cx, cy, radius, color, peak_alpha):
    """Soft radial glow, alpha-composited (no hard ellipse edges)."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    px = layer.load()
    x0, x1 = max(0, int(cx - radius)), min(img.width, int(cx + radius) + 1)
    y0, y1 = max(0, int(cy - radius)), min(img.height, int(cy + radius) + 1)
    r2 = radius * radius
    for y in range(y0, y1):
        dy = y - cy
        dy2 = dy * dy
        for x in range(x0, x1):
            dx = x - cx
            d2 = dx * dx + dy2
            if d2 >= r2:
                continue
            a = int(peak_alpha * (1 - (d2 ** 0.5) / radius) ** 1.8)
            if a > 0:
                px[x, y] = (color[0], color[1], color[2], a)
    img.alpha_composite(layer)


def paint_background(w, h, glows):
    img = gradient_bg(w, h, CREAM, SOFT_LAV, SOFT_TEAL).convert("RGBA")
    for cx, cy, radius, color, alpha in glows:
        add_glow(img, cx, cy, radius, color, alpha)
    return img


# ── App icon tile (iOS-style squircle mask) ─────────────────────────────────
def icon_tile(size):
    icon = Image.open(ICON_PATH).convert("RGB").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=int(size * 0.224), fill=255
    )
    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile.paste(icon, (0, 0), mask)
    return tile


# ── Feature glyphs (vector shapes, drawn inside a chip box) ─────────────────
def glyph_bottle(d, box, color, chip):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    bw = w * 0.52
    bx = (x0 + x1) / 2 - bw / 2
    by = y0 + h * 0.30
    d.rounded_rectangle([bx, by, bx + bw, y1], radius=bw * 0.35, fill=color)
    nw = w * 0.34
    d.rectangle([(x0 + x1) / 2 - nw / 2, y0 + h * 0.16,
                 (x0 + x1) / 2 + nw / 2, by], fill=color)
    d.ellipse([x0 + w * 0.32, y0, x0 + w * 0.68, y0 + h * 0.30], fill=color)


def glyph_moon(d, box, color, chip):
    x0, y0, x1, y1 = box
    r = (x1 - x0) * 0.46
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    rr = r * 0.86
    d.ellipse([cx - rr + r * 0.42, cy - rr - r * 0.30,
               cx + rr + r * 0.42, cy + rr - r * 0.30], fill=chip)


def glyph_diaper(d, box, color, chip):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    d.rounded_rectangle([x0, y0 + h * 0.18, x1, y1], radius=w * 0.18, fill=color)
    # waistband
    d.rectangle([x0 + w * 0.06, y0 + h * 0.30, x1 - w * 0.06, y0 + h * 0.44], fill=chip)
    # side tabs
    d.rectangle([x0, y0, x0 + w * 0.22, y0 + h * 0.22], fill=color)
    d.rectangle([x1 - w * 0.22, y0, x1, y0 + h * 0.22], fill=color)


def glyph_pill(d, box, color, chip):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    d.rounded_rectangle([x0 + w * 0.10, y0 + h * 0.30,
                         x0 + w * 0.90, y0 + h * 0.70], radius=h * 0.20, fill=color)
    # separator line in the capsule
    d.line([(x0 + w * 0.50, y0 + h * 0.30), (x0 + w * 0.50, y0 + h * 0.70)],
           fill=chip, width=max(2, int(h * 0.10)))


def glyph_baby(d, box, color, chip):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    r = w * 0.42
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2 + w * 0.04
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    er = w * 0.075
    for ex in (cx - r * 0.42, cx + r * 0.42):
        d.ellipse([ex - er, cy - r * 0.30 - er, ex + er, cy - r * 0.30 + er], fill=chip)
    d.arc([cx - r * 0.45, cy - r * 0.10, cx + r * 0.45, cy + r * 0.60],
          start=20, end=160, fill=chip, width=max(2, int(w * 0.09)))


def glyph_lock(d, box, color, chip):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    bw = w * 0.62
    bx = (x0 + x1) / 2 - bw / 2
    by = y0 + h * 0.42
    d.rounded_rectangle([bx, by, bx + bw, y1], radius=bw * 0.22, fill=color)
    d.arc([bx + bw * 0.12, y0, bx + bw * 0.88, y0 + h * 0.56],
          start=180, end=360, fill=color, width=max(2, int(w * 0.13)))
    kr = w * 0.09
    kx, ky = (x0 + x1) / 2, by + (y1 - by) * 0.42
    d.ellipse([kx - kr, ky - kr, kx + kr, ky + kr], fill=chip)
    d.rectangle([kx - kr * 0.45, ky, kx + kr * 0.45, ky + kr * 1.6], fill=chip)


FEATURES = [
    ("Tétées & biberons",  glyph_bottle, GOLD),
    ("Sommeil",            glyph_moon,   CHIP_INDIGO),
    ("Couches",            glyph_diaper, TEAL),
    ("Rappels santé",      glyph_pill,   CHIP_GREEN),
    ("Profils multiples",  glyph_baby,   CHIP_PEACH),
    ("Chiffrement local",  glyph_lock,   CHIP_PLUM),
]


def feature_item(img, x, y, chip_size, chip_color, glyph, label, font,
                 label_color, label_below=False):
    """Chip + centered glyph + label (to the right, or centered below)."""
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x, y, x + chip_size, y + chip_size],
                        radius=int(chip_size * 0.30), fill=chip_color)
    pad = int(chip_size * 0.24)
    glyph(d, [x + pad, y + pad, x + chip_size - pad, y + chip_size - pad],
          WHITE, chip_color)
    if label_below:
        d.text((x + chip_size / 2, y + chip_size + 12), label, font=font,
               fill=label_color, anchor="ma")
    else:
        d.text((x + chip_size + 12, y + chip_size / 2), label, font=font,
               fill=label_color, anchor="lm")


def draw_lock_line(img, x, y, text, font, color, glyph_size=22):
    """Small lock glyph + text, left-anchored."""
    d = ImageDraw.Draw(img)
    box = [x, y, x + glyph_size, y + glyph_size]
    # Keyhole is 'cut' with a darkened version of the lock color.
    cut = tuple(int(c * 0.55) for c in color)
    glyph_lock(d, box, color, cut)
    d.text((x + glyph_size + 10, y + glyph_size / 2), text, font=font,
           fill=color, anchor="lm")


# ── 1. Google Play feature graphic (1024x500) ──────────────────────────────
def build_play_banner():
    w, h = 1024, 500
    img = paint_background(w, h, glows=[
        (0.70 * w, 0.15 * h, 250, GOLD, 42),
        (0.12 * w, 0.85 * h, 230, TEAL, 38),
        (0.88 * w, 0.82 * h, 260, LAVENDER, 36),
    ])
    d = ImageDraw.Draw(img)

    # App icon (left, vertically centered)
    icon_size = 220
    tile = icon_tile(icon_size)
    img.paste(tile, (62, (h - icon_size) // 2), tile)

    # Title + subtitle
    title_font = sf_rounded(92, 900)
    sub_font = sf_pro(30, 600)
    d.text((320, 84), "Mamadera", font=title_font, fill=INK)
    d.text((322, 214), "Suivi nouveau-né · 100 % local & chiffré",
           font=sub_font, fill=BODY)

    # Features: 2 columns x 3 rows
    feat_font = sf_pro(24, 550)
    cols = (320, 664)
    rows = (272, 324, 376)
    for i, (label, glyph, color) in enumerate(FEATURES):
        feature_item(img, cols[i % 2], rows[i // 2], 44, color, glyph, label,
                     feat_font, BODY)

    # Footers
    draw_lock_line(img, 64, 434, "100 % local · sans cloud · sans suivi",
                   sf_pro(21, 600), BODY)
    d.text((w - 64, 444), "Open source · MIT",
           font=sf_pro(20, 500), fill=MUTED, anchor="rm")

    return img


# ── 2. App Store / web promo tile (1280x800) ───────────────────────────────
def build_appstore_promo():
    w, h = 1280, 800
    img = paint_background(w, h, glows=[
        (0.78 * w, 0.12 * h, 330, GOLD, 40),
        (0.10 * w, 0.88 * h, 310, TEAL, 36),
        (0.88 * w, 0.85 * h, 340, LAVENDER, 34),
    ])
    d = ImageDraw.Draw(img)

    # App icon (top center)
    icon_size = 280
    tile = icon_tile(icon_size)
    img.paste(tile, ((w - icon_size) // 2, 84), tile)

    # Title + subtitle (centered)
    d.text((w / 2, 470), "Mamadera", font=sf_rounded(104, 900),
           fill=INK, anchor="mm")
    d.text((w / 2, 570), "Suivi nouveau-né · 100 % local & chiffré",
           font=sf_pro(34, 600), fill=BODY, anchor="mm")

    # Features: row of 6, labels under chips
    slot = 164
    x0 = (w - slot * len(FEATURES)) // 2
    for i, (label, glyph, color) in enumerate(FEATURES):
        feature_item(img, x0 + slot * i + slot // 2 - 28, 636, 56, color, glyph,
                     label, sf_pro(18, 550), BODY, label_below=True)

    # Footer (centered)
    d.text((w / 2, 752),
           "100 % local · sans cloud · sans suivi    ·    Open source (MIT)",
           font=sf_pro(22, 550), fill=MUTED, anchor="mm")

    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    outputs = [
        (build_play_banner(), os.path.join(OUT_DIR, "play_feature_graphic.png"),
         (1024, 500)),
        (build_appstore_promo(), os.path.join(OUT_DIR, "appstore_promo.png"),
         (1280, 800)),
    ]
    for img, path, expected in outputs:
        if img.size != expected:
            raise SystemExit(f"{path}: size {img.size} != expected {expected}")
        img.convert("RGB").save(path, "PNG")
        print(f"Saved: {path}  ({img.size[0]}x{img.size[1]}, "
              f"{os.path.getsize(path) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()

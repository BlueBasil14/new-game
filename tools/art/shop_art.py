"""Shop and turf art for Turf Loop, drawn with Pillow (Figma MCP was rate-limited on 2026-11-17).
Run: py tools/art/shop_art.py  ->  assets/shop/*.png (256 px)

- pattern_<name>.png: seamless white pattern tiles. Tinted with a skin's colorB over colorA, both on the
  shop card and as the in-game turf Texture (TurfRenderer).
- trail_band / trail_core / trail_line: a ribbon in three layers; the game tints band = colorA,
  core = colorB and draws the navy line layer (outline + shine) underneath / on top.
- effect_<id>.png: full-colour capture-effect icons in the Arcade Commons style (navy outline, shine).
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "shop")
S = 1024  # draw size; saved at 256 (4x supersampling)
T = 256
NAVY = (32, 40, 64, 255)  # UI ink #202840


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.resize((T, T), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))


def blank():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def mask():
    return Image.new("L", (S, S), 0)


# Patterns: draw each shape at the 9 wrap offsets so the tile repeats with no seam.
def tile(draw_fn):
    m = mask()
    d = ImageDraw.Draw(m)
    for ox in (-S, 0, S):
        for oy in (-S, 0, S):
            draw_fn(d, ox, oy)
    img = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    img.putalpha(m)
    return img


def star_points(cx, cy, r_out, r_in, n=5, rot=-math.pi / 2):
    pts = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = rot + i * math.pi / n
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def hex_points(cx, cy, r):
    return [(cx + r * math.cos(math.pi / 6 + i * math.pi / 3), cy + r * math.sin(math.pi / 6 + i * math.pi / 3)) for i in range(6)]


def patterns():
    q = S / 4

    def stripes(d, ox, oy):  # 45-degree bands, period S/2 along x+y
        w = S / 2
        for k in range(-2, 3):
            a = k * w
            d.polygon([(ox + a, oy), (ox + a + w / 2, oy), (ox + a + w / 2 - S, oy + S), (ox + a - S, oy + S)], fill=255)

    def dots(d, ox, oy):
        r = S / 8
        for cx, cy in ((q, q), (3 * q, 3 * q)):
            d.ellipse([ox + cx - r, oy + cy - r, ox + cx + r, oy + cy + r], fill=255)

    def checker(d, ox, oy):
        h = S / 2
        d.rectangle([ox, oy, ox + h, oy + h], fill=255)
        d.rectangle([ox + h, oy + h, ox + S, oy + S], fill=255)

    def waves(d, ox, oy):
        for base in (q, 3 * q):
            pts = [(ox + x, oy + base + S * 0.07 * math.sin(2 * math.pi * x / S * 2)) for x in range(-8, S + 9, 8)]
            d.line(pts, fill=255, width=int(S * 0.11), joint="curve")

    def stars(d, ox, oy):
        d.polygon([(ox + x, oy + y) for x, y in star_points(q, q, S * 0.17, S * 0.075)], fill=255)
        d.polygon([(ox + x, oy + y) for x, y in star_points(3 * q, 3 * q, S * 0.11, S * 0.05, rot=-math.pi / 2 + 0.4)], fill=255)

    def hexes(d, ox, oy):
        for cx, cy in ((q, q), (3 * q, 3 * q), (3 * q, q), (q, 3 * q)):
            r = S * 0.15 if (cx == cy) else S * 0.09
            d.polygon([(ox + x, oy + y) for x, y in hex_points(cx, cy, r)], fill=255)

    for name, fn in (("stripes", stripes), ("dots", dots), ("checker", checker), ("waves", waves), ("stars", stars), ("hex", hexes)):
        save(tile(fn), "pattern_" + name)


# Outlined icon: layers = [(mask, rgba)], outline drawn around the union, plus a soft shine.
def compose(layers, outline=40, shine=None):
    union = mask()
    for m, _ in layers:
        union = ImageChops.lighter(union, m)
    out = blank()
    ring = union.filter(ImageFilter.MaxFilter(outline * 2 + 1)) if outline else union
    out.paste(Image.new("RGBA", (S, S), NAVY), (0, 0), ring)
    for m, color in layers:
        out.paste(Image.new("RGBA", (S, S), color), (0, 0), m)
    if shine:
        sm = mask()
        ImageDraw.Draw(sm).ellipse(shine, fill=110)
        sm = ImageChops.multiply(sm, union)
        out.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), sm)
    return out


def shape(fn):
    m = mask()
    fn(ImageDraw.Draw(m))
    return m


def poly(pts):
    return shape(lambda d: d.polygon(pts, fill=255))


def circle(cx, cy, r):
    return shape(lambda d: d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255))


def heart(cx, cy, r):
    def f(d):
        d.ellipse([cx - r, cy - r * 0.9, cx + 0.05 * r, cy + 0.15 * r], fill=255)
        d.ellipse([cx - 0.05 * r, cy - r * 0.9, cx + r, cy + 0.15 * r], fill=255)
        d.polygon([(cx - r * 0.96, cy - r * 0.25), (cx + r * 0.96, cy - r * 0.25), (cx, cy + r * 1.05)], fill=255)
    return shape(f)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def effects():
    c = S / 2
    # Sparkle (default): two four-point stars
    big = poly(star_points(c - 60, c + 40, 330, 90, n=4))
    small = poly(star_points(c + 270, c - 250, 150, 45, n=4))
    save(compose([(big, hexc("#FFE88A")), (small, hexc("#FFFFFF"))], shine=(c - 260, c - 260, c + 20, c - 60)), "effect_sparkle")

    # Fireworks: a burst of rays with tipped dots, pink and gold
    rays = mask()
    tips = mask()
    d1, d2 = ImageDraw.Draw(rays), ImageDraw.Draw(tips)
    for i in range(10):
        a = i * math.pi / 5
        r0, r1 = 120, 380
        d1.line([(c + r0 * math.cos(a), c + r0 * math.sin(a)), (c + r1 * math.cos(a), c + r1 * math.sin(a))], fill=255, width=60)
        tr = 62 if i % 2 == 0 else 46
        d2.ellipse([c + 430 * math.cos(a) - tr, c + 430 * math.sin(a) - tr, c + 430 * math.cos(a) + tr, c + 430 * math.sin(a) + tr], fill=255)
    core = circle(c, c, 110)
    save(compose([(rays, hexc("#FF4F8B")), (tips, hexc("#FFC83D")), (core, hexc("#FFC83D"))], outline=30), "effect_fireworks")

    # Bubbles: three bubbles with shine arcs
    layers = []
    for cx, cy, r in ((c - 120, c + 110, 270), (c + 250, c - 210, 170), (c + 270, c + 290, 110)):
        layers.append((circle(cx, cy, r), hexc("#7CC4FF")))
    img = compose(layers, outline=36)
    d = ImageDraw.Draw(img)
    for cx, cy, r in ((c - 120, c + 110, 270), (c + 250, c - 210, 170), (c + 270, c + 290, 110)):
        d.arc([cx - r * 0.7, cy - r * 0.7, cx + r * 0.7, cy + r * 0.7], 200, 260, fill=(255, 255, 255, 255), width=int(r * 0.16))
        d.ellipse([cx + r * 0.25, cy - r * 0.55, cx + r * 0.45, cy - r * 0.35], fill=(255, 255, 255, 230))
    save(img, "effect_bubbles")

    # Lightning: chunky bolt, gold with a blue spark
    bolt = poly([(c + 90, c - 440), (c - 260, c + 60), (c - 20, c + 60), (c - 140, c + 450), (c + 260, c - 80), (c + 20, c - 80), (c + 170, c - 440)])
    spark = poly(star_points(c - 300, c - 260, 130, 40, n=4))
    save(compose([(bolt, hexc("#FFE88A")), (spark, hexc("#4F8BFF"))], shine=(c - 120, c - 420, c + 140, c - 160)), "effect_lightning")

    # Hearts: big pink heart, small light heart
    save(compose([(heart(c - 50, c + 40, 330), hexc("#FF4F8B")), (heart(c + 300, c - 290, 140), hexc("#FFB8E0"))],
                 shine=(c - 330, c - 300, c - 130, c - 140)), "effect_hearts")


def stroke(pts, width):
    """Thick smooth path: overlapping discs (Pillow's wide lines leave hairline gaps)."""
    m = mask()
    d = ImageDraw.Draw(m)
    r = width / 2
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / 4))
        for j in range(n + 1):
            x, y = x0 + (x1 - x0) * j / n, y0 + (y1 - y0) * j / n
            d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    return m


def trail():
    # S-curve ribbon from bottom-left to top-right; game tints band (colorA) and core (colorB).
    pts = []
    for i in range(0, 121):
        t = i / 120
        x = 170 + t * (S - 340)
        y = S - 230 - t * (S - 460) + 150 * math.sin(t * 2 * math.pi)
        pts.append((x, y))
    band = stroke(pts, 210)
    core = stroke(pts[8:-8], 64)
    line = blank()
    ring = band.filter(ImageFilter.MaxFilter(73))
    line.paste(Image.new("RGBA", (S, S), NAVY), (0, 0), ring)
    line.paste(Image.new("RGBA", (S, S), (0, 0, 0, 0)), (0, 0), band)  # outline ring only; tinted band shows through
    save(line, "trail_line")
    white = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    b = white.copy(); b.putalpha(band); save(b, "trail_band")
    k = white.copy(); k.putalpha(core); save(k, "trail_core")


if __name__ == "__main__":
    import sys
    only = sys.argv[1:]
    for name, fn in (("patterns", patterns), ("effects", effects), ("trail", trail)):
        if not only or name in only:
            fn()
    print("wrote", sorted(os.listdir(OUT)))

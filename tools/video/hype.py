"""Hype shorts with the full cosmetic line-up (owner request 2026-11-20: Paper.io callback, every kind of skin and
animation, super hype, a little slower than v01-v07). Usage: py tools/video/hype.py s01
Skins, trails and effects mirror src/shared/Catalog.luau (names, colours, patterns, animations)."""
import colorsys
from collections import deque
import math
import os
import random
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa: E402,F403

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "marketing", "videos", "out")
SHEETS = os.path.join(ROOT, "marketing", "videos", "sheets")
GOLD, RARE_BLUE = hexc("#FFC83D"), hexc("#4F8BFF")

# (name, colour A, colour B, pattern, anim) straight from Catalog.luau
RARES = [("CANDY STRIPE", "#FF4F8B", "#FFFFFF", "stripes"), ("OCEAN WAVES", "#3D8BFF", "#9DD3FF", "waves"),
         ("DISCO FLOOR", "#FF5CD6", "#3DDCFF", "checker"), ("GALAXY SWIRL", "#2B1F6B", "#C45CFF", "stars"),
         ("COSMIC CRYSTAL", "#3DDCFF", "#C45CFF", "hex"), ("CHERRY DOTS", "#FF4D4D", "#FFFFFF", "dots")]
LEGENDS = [("NEON PULSE", "#FF2E9A", "#00F0FF", "stripes", "pulse"), ("MAGMA SURGE", "#E8361A", "#FFC83D", "waves", "flow"),
           ("STARFALL", "#1B1F5E", "#FFE88A", "stars", "drift"), ("PRISM STORM", "#7C5CFF", "#FFFFFF", "hex", "rainbow")]
TRAILS = [("RAINBOW STREAK", "#FF4D4D", "#4F8BFF", "stripes"), ("STARDUST", "#FFE88A", "#C45CFF", "stars")]
EFFECTS = [("FIREWORKS", "#FF4F8B", "#FFC83D"), ("BUBBLES", "#7CC4FF", "#FFFFFF"),
           ("LIGHTNING", "#FFE88A", "#4F8BFF"), ("HEARTS", "#FF4F8B", "#FFB8E0")]
T = 12  # pattern tile size in canvas pixels


def tile(a, b, pattern):
    """One seamless T x T pattern tile in colours a/b."""
    im = Image.new("RGB", (T, T), a)
    px = im.load()
    for y in range(T):
        for x in range(T):
            on = False
            if pattern == "stripes":
                on = ((x + y) // 3) % 2 == 0
            elif pattern == "checker":
                on = ((x // 6) + (y // 6)) % 2 == 0
            elif pattern == "dots":
                on = (x - 5.5) ** 2 + (y - 5.5) ** 2 <= 6.5
            elif pattern == "waves":
                on = ((y + round(1.6 * math.sin(x / T * 2 * math.pi))) // 3) % 2 == 0
            elif pattern == "stars":
                cx, cy = (2, 3) if (x < 6) == (y < 6) else (8, 9)
                dx, dy = abs(x % 6 - cx % 6), abs(y % 6 - cy % 6)
                on = (dx == 0 and dy <= 2) or (dy == 0 and dx <= 2)
            elif pattern == "hex":
                row = y // 4
                xx = (x + (3 if row % 2 else 0)) % 6
                on = y % 4 == 0 or xx == 0
            if on:
                px[x, y] = b
    return im


def hue_shift(c, h):
    r, g, bb = (v / 255 for v in c)
    hh, ll, ss = colorsys.rgb_to_hls(r, g, bb)
    r, g, bb = colorsys.hls_to_rgb((hh + h) % 1.0, ll, max(ss, 0.6))
    return (int(r * 255), int(g * 255), int(bb * 255))


def skin_board(w, h, a, b, pattern, anim, t):
    """Full-board pattern image (w x h px) for one skin at time t, animated like TurfAnim (pulse/flow/drift/rainbow)."""
    a, b = hexc(a) if isinstance(a, str) else a, hexc(b) if isinstance(b, str) else b
    if anim == "rainbow":
        a, b = hue_shift(a, t * 0.35), hue_shift(b, t * 0.35 + 0.5)
    tl = tile(a, b, pattern)
    ox = int(t * 18) % T if anim == "flow" else 0
    oy = int(t * 10) % T if anim == "drift" else 0
    big = Image.new("RGB", (w + T, h + T))
    for y in range(0, h + T, T):
        for x in range(0, w + T, T):
            big.paste(tl, (x, y))
    out = big.crop((ox, oy, ox + w, oy + h))
    if anim == "pulse":
        k = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 1.8)
        out = Image.blend(out, Image.new("RGB", (w, h), WHITE), 0.28 * k)
    return out


def mask_of(ar, rid, cp, which="owner", col_limit=None, flip=False):
    n = ar.n
    m = Image.new("L", (n, n), 0)
    grid = ar.owner if which == "owner" else ar.trail
    m.putdata([255 if grid[y][x] == rid and (col_limit is None or ((x < col_limit) != flip)) else 0
               for y in range(n) for x in range(n)])
    return m.resize((n * cp, n * cp), Image.NEAREST)


def runner_sprite(img, ar, rid, x0, y0, cp, t, label=True):
    r = ar.runners[rid]
    if not r.alive:
        return
    frac = max(0.0, min(1.0, (t - ar.t) / ar.dt))
    fx = r.px + (r.x - r.px) * frac
    fy = r.py + (r.y - r.py) * frac
    s = cp + 2
    px, py = x0 + fx * cp - 1, y0 + fy * cp - 1
    d = ImageDraw.Draw(img)
    d.rectangle((px - 1, py - 1, px + s, py + s), fill=DARK)
    d.rectangle((px, py, px + s - 1, py + s - 1), fill=r.color)
    d.rectangle((px + s * 0.25, py + s * 0.3, px + s * 0.25 + 2, py + s * 0.3 + 2), fill=WHITE)
    d.rectangle((px + s * 0.62, py + s * 0.3, px + s * 0.62 + 2, py + s * 0.3 + 2), fill=WHITE)
    if label:
        draw_text(img, "YOU", px + s / 2, py - 18, 2, WHITE, DARK)


def tree(img, cx, cy, k, seed):
    """Pixel tree for Living Woodland, k = grow 0..1 (overshoots like the game's grow-in)."""
    if k <= 0:
        return
    s = ease_back(min(1.0, k))
    d = ImageDraw.Draw(img)
    th = int(6 * s)
    d.rectangle((cx - 1, cy - th, cx + 1, cy), fill=(110, 72, 40))
    r = int((5 + seed % 3) * s)
    greens = [(46, 140, 70), (74, 170, 80), (120, 200, 90)]
    d.ellipse((cx - r, cy - th - r * 1.6, cx + r, cy - th + r * 0.3), fill=greens[seed % 3], outline=DARK)
    d.ellipse((cx - r * 0.4, cy - th - r * 1.3, cx + r * 0.1, cy - th - r * 0.8), fill=(160, 225, 120))


class Effects:
    """Capture effects: fireworks, bubbles, lightning, hearts."""

    def __init__(self):
        self.items = []
        self.rng = random.Random(5)

    def fire(self, kind, cx, cy, t, region):
        x0, y0, x1, y1 = region
        rng = self.rng
        if kind == "FIREWORKS":
            for _ in range(5):
                bx, by = rng.uniform(x0, x1), rng.uniform(y0, y1)
                col = rng.choice([PINK, YELLOW, GEM, GREEN, WHITE])
                for i in range(24):
                    a = i / 24 * 2 * math.pi
                    self.items.append(("spark", bx, by, math.cos(a) * 120, math.sin(a) * 120, t + rng.uniform(0, 0.3), col))
        elif kind == "BUBBLES":
            for _ in range(26):
                self.items.append(("bubble", rng.uniform(x0, x1), rng.uniform(y0, y1), rng.uniform(-8, 8), -rng.uniform(30, 60),
                                   t + rng.uniform(0, 0.4), (124, 196, 255)))
        elif kind == "LIGHTNING":
            for _ in range(5):
                self.items.append(("bolt", rng.uniform(x0, x1), y0 - 60, rng.uniform(x0, x1), rng.uniform(y0, y1),
                                   t + rng.uniform(0, 0.2), rng.randint(0, 999)))
        elif kind == "HEARTS":
            for _ in range(20):
                self.items.append(("heart", rng.uniform(x0, x1), rng.uniform(y0, y1), rng.uniform(-10, 10), -rng.uniform(35, 70),
                                   t + rng.uniform(0, 0.4), rng.choice([PINK, (255, 184, 224), RED])))

    def draw(self, img, t):
        d = ImageDraw.Draw(img)
        keep = []
        for it in self.items:
            kind, x, y, vx, vy, t0, col = it
            age = t - t0
            if age < 0:
                keep.append(it)
                continue
            if age > 1.1:
                continue
            keep.append(it)
            if kind == "spark":
                px, py = x + vx * age, y + vy * age + 60 * age * age
                d.rectangle((px, py, px + 4, py + 4), fill=col if age < 0.7 else shade(col, 0.6), outline=DARK)
            elif kind == "bubble":
                px, py = x + vx * age, y + vy * age
                r = 6 + age * 10
                d.ellipse((px - r, py - r, px + r, py + r), outline=WHITE if age < 0.8 else col, width=2)
            elif kind == "bolt" and age < 0.35:
                rng = random.Random(col + int(age * 20))
                pts, n = [], 6
                for i in range(n + 1):
                    k = i / n
                    pts.append((x + (vx - x) * k + (rng.uniform(-7, 7) if 0 < i < n else 0), y + (vy - y) * k))
                d.line(pts, fill=(255, 232, 138), width=6)
                d.line(pts, fill=WHITE, width=2)
            elif kind == "heart":
                px, py = x + vx * age, y + vy * age
                for (hx, hy) in ((0, 0), (2, 0), (-1, 1), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (1, 3)):
                    d.rectangle((px + hx * 4, py + hy * 4, px + hx * 4 + 3, py + hy * 4 + 3), fill=col)
        self.items = keep


def name_card(img, name, tier, t_in, t, y=374):
    """Bottom card: skin name + tier badge, slides up on the beat."""
    k = ease_back(min(1.0, (t - t_in) / 0.22))
    yy = y + (1 - k) * 40
    col = GOLD if "LEGENDARY" in tier or "LIMITED" in tier else (RARE_BLUE if tier == "RARE" else GREEN)
    hgt = 62 if len(name) <= 13 else 84
    plate = Image.new("RGBA", (W - 16, hgt), (14, 16, 26, 230))
    img.paste(plate, (8, int(yy)), plate)
    d = ImageDraw.Draw(img)
    d.rectangle((8, int(yy), W - 9, int(yy) + hgt - 1), outline=col, width=2)
    draw_text(img, tier, W / 2, yy + 6, 2, col, DARK)
    if len(name) <= 13:
        draw_text(img, name, W / 2, yy + 28, 3, WHITE, DARK)
    else:  # one size for every name: long names go to a 2-line card
        a, b2 = name.split(" ", 1)
        draw_text(img, a, W / 2, yy + 24, 3, WHITE, DARK)
        draw_text(img, b2, W / 2, yy + 50, 3, WHITE, DARK)


# ============================================================ s01 Paper.io callback -> every skin
def s01():
    v = Video("s01_skins_hype", 108, 44, music=dict(mode="major", root=60, seed=77, prog=[0, 5, 3, 4], sections=[
        (0, 3.5, {"kick", "hat", "arp"}), (3.5, 4, set()), (4, 18, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (18, 26, {"kick", "snare", "hat", "bass", "arp", "lead"}), (26, 40, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (40, 44, {"kick", "snare", "hat", "bass", "lead"})]))
    X0, Y0, CP, N = 7, 112, 16, 16  # 256 px board

    # ---------- hook: the old school-computer game (retro CRT, our own art) ----------
    old = Arena(20, seed=2)
    old.dt = v.spb / 4
    old.ground = (18, 52, 30)
    h0 = old.add(1, (90, 255, 140), 7, 11, 5)
    h0.x, h0.y, h0.px, h0.py = 9, 11, 9, 11
    h0.script = path_from([(9, 11), (14, 11), (14, 6), (9, 6), (9, 9)])  # claim on step 13 (beat 3.25)
    old_in = arena_scene(v, old, 0, 6, 130, 13, hero=1, fx=FX(), sounds=True, t_offset=14 * old.dt)  # 18-step loop closes on beat 1

    def retro(img, tl, tg):
        ImageDraw.Draw(img).rectangle((0, 0, W, H), fill=(8, 24, 14))
        old_in(img, tl, tg)
        d = ImageDraw.Draw(img)
        for y in range(0, H, 3):
            d.line((0, y, W, y), fill=(0, 0, 0))

    v.scene(0, 4, retro, "HOOK: green retro school-computer screen, a runner closes a square loop on beat 1")
    v.caption(0, 2.2, "REMEMBER PLAYING PAPER.IO IN CLASS?", y=70, size=3, color=YELLOW)
    v.sound(0, "hit")
    v.caption(2.2, 4, "IT GREW UP...", y=70, size=4, color=WHITE)
    v.sound(3, "whoosh")

    # ---------- drop: Turf Loop reveal ----------
    def reveal(img, tl, tg):
        bg_checker(img, tg, c1=(40, 18, 60), c2=(58, 26, 86), speed=30)
        k = ease_back(tl / 0.35)
        logo(img, 150 - (1 - k) * 80, 4, tg)
        draw_lines(img, "ON ROBLOX", 230, 4, YELLOW)
        if tl > v.spb * 0.5:
            draw_lines(img, "WITH SKINS. SO MANY SKINS.", 320, 3, WHITE)

    v.scene(4, 6, reveal, "DROP: TURF LOOP logo slams in, ON ROBLOX, WITH SKINS. SO MANY SKINS.")
    v.flash(4, WHITE, 0.15)
    v.sound(4, "hit")
    v.sound(4.02, "crown")
    v.shake(4, 0.35, 6)

    # ---------- the main board: one live match the skins are worn on ----------
    ar = Arena(N, seed=31)
    ar.dt = v.spb / 4
    hero = ar.add(1, hexc(RARES[0][1]), 8, 8, 7)
    hero.hungry, hero.reach, hero.shield = True, (3, 5), True
    rival = ar.add(2, PLAYERS[0], 14, 14, 3)
    rival.reach = (1, 2)
    efx, tfx = Effects(), FX()
    seen = [0]

    # timeline (beats) of what the hero wears
    R0, RSTEP = 6, 1.5                       # 6 rares x 1.5 beats
    L0, LSTEP = R0 + len(RARES) * RSTEP, 2   # 4 legendaries x 2 beats
    T0, TSTEP = L0 + len(LEGENDS) * LSTEP, 2  # 2 trails x 2 beats
    E0, E1 = T0 + len(TRAILS) * TSTEP, T0 + len(TRAILS) * TSTEP + 6  # effects, one per claim
    W0, W1 = E1, E1 + 4                       # Living Woodland
    END = W1

    def skin_at(b):
        if b < L0:
            i = min(len(RARES) - 1, int((b - R0) / RSTEP))
            n, a, c, p = RARES[i]
            return i, (n, a, c, p, None, "RARE"), R0 + i * RSTEP
        i = min(len(LEGENDS) - 1, int((b - L0) / LSTEP))
        n, a, c, p, an = LEGENDS[i]
        j = len(RARES) + i
        return j, (n, a, c, p, an, "LEGENDARY"), L0 + i * LSTEP

    eff_i = [0]
    eff_label = [EFFECTS[0][0], v.b(E0)]

    def board(img, tl, tg):
        b = tg / v.spb
        bg_checker(img, tg, speed=14)
        ar.dt = v.spb / 8 if E0 <= b < E1 else v.spb / 4  # faster loops while showing capture effects
        ar.update(tl)
        draw_arena(img, ar, tl, X0, Y0, CP, None, None)
        # skin on the hero's turf, with a left-to-right wipe from the previous skin on every change
        cur = min(b, W0 - 0.001)
        idx, sk, s_b0 = skin_at(cur)
        prev = skin_at(s_b0 - 0.01)[1] if idx > 0 else sk
        wipe = min(1.0, (b - s_b0) / 0.35) if b < W0 else 1.0
        colm = int(wipe * N + 0.999)
        w = N * CP
        if b < W0:
            new_im = skin_board(w, w, sk[1], sk[2], sk[3], sk[4], tg)
            img.paste(new_im, (X0, Y0), mask_of(ar, 1, CP, col_limit=colm))
            if wipe < 1:
                old_im = skin_board(w, w, prev[1], prev[2], prev[3], prev[4], tg)
                img.paste(old_im, (X0, Y0), mask_of(ar, 1, CP, col_limit=colm, flip=True))
                xw = X0 + colm * CP
                ImageDraw.Draw(img).line((xw, Y0, xw, Y0 + w), fill=WHITE, width=3)
            hero.color = hexc(sk[1])
        else:  # Living Woodland: green grass turf + trees growing across it
            grass = skin_board(w, w, "#A3CF62", "#8DBF4E", "dots", None, tg)
            img.paste(grass, (X0, Y0), mask_of(ar, 1, CP))
            hero.color = hexc("#A3CF62")
        # trail skin
        if T0 <= b < E1:
            ti = min(len(TRAILS) - 1, int((b - T0) / TSTEP)) if b < E0 else len(TRAILS) - 1
            tn, ta, tb, tp = TRAILS[ti]
            img.paste(skin_board(w, w, ta, tb, tp, "flow", tg), (X0, Y0), mask_of(ar, 1, CP, which="trail"))
        if b >= W0:
            for y in range(N):
                for x in range(N):
                    if ar.owner[y][x] == 1 and (x * 7 + y * 13) % 3 == 0:
                        delay = (abs(x - 8) + abs(y - 8)) * 0.045
                        tree(img, X0 + x * CP + CP // 2, Y0 + y * CP + CP - 2, (tg - v.b(W0) - delay) / 0.4, x * 31 + y)
        # claims -> capture effects / coins
        for (et, kind, data) in ar.events[seen[0]:]:
            if kind == "claim" and data["id"] == 1 and data["cells"] > 0:
                cx, cy = X0 + (data["at"][0] + 0.5) * CP, Y0 + (data["at"][1] + 0.5) * CP
                if E0 <= b < E1 and eff_i[0] < len(EFFECTS):
                    name = EFFECTS[eff_i[0]][0]
                    efx.fire(name, cx, cy, tg, (X0 + 10, Y0 + 10, X0 + w - 10, Y0 + w - 10))
                    v.sfx.append((tg, "levelup" if name == "FIREWORKS" else "claim", 6))
                    eff_label[0], eff_label[1] = name, tg
                    eff_i[0] += 1
                else:
                    v.sfx.append((tg, "claim", min(12, data["cells"] / 6)))
                    tfx.coins(cx, cy, 8, tg)
            elif kind == "cut":
                v.sfx.append((tg, "cut", 0))
        seen[0] = len(ar.events)
        tfx.draw(img, tg)
        efx.draw(img, tg)
        runner_sprite(img, ar, 2, X0, Y0, CP, tl, label=False)
        runner_sprite(img, ar, 1, X0, Y0, CP, tl, label=b < R0 + 2)
        # name cards
        if b < W0:
            if b < T0 or b >= E1:
                name_card(img, sk[0], sk[5], v.b(s_b0), tg)
            elif b < E0:
                ti = min(len(TRAILS) - 1, int((b - T0) / TSTEP))
                name_card(img, TRAILS[ti][0], "TRAIL", v.b(T0 + ti * TSTEP), tg)
            elif eff_label[0]:
                name_card(img, eff_label[0], "CAPTURE EFFECT", eff_label[1], tg)
        else:
            name_card(img, "LIVING WOODLAND", "LEGENDARY BIOME", v.b(W0), tg)

    v.scene(6, END, board, f"live 16x16 match; your turf wears {len(RARES)} rare skins (1.5 beats each, wipe + name card), "
            f"{len(LEGENDS)} animated legendaries (2 beats each), {len(TRAILS)} trails, capture effects on each claim, then Living Woodland trees")
    v.flash(6)
    v.sound(6, "hit")
    # per-skin cues on the beat
    for i in range(len(RARES)):
        v.sound(R0 + i * RSTEP, "pop", i)
    for i in range(len(LEGENDS)):
        v.sound(L0 + i * LSTEP, "crown")
        v.flash(L0 + i * LSTEP, GOLD, 0.1)
    for i in range(len(TRAILS)):
        v.sound(T0 + i * TSTEP, "whoosh")
    v.sound(W0, "levelup")
    v.flash(W0, (163, 207, 98), 0.15)
    v.caption(6, 7.5, "LOOP HOME = IT'S YOURS", color=GREEN)
    v.caption(7.5, L0, "RARE SKINS", color=RARE_BLUE, size=4)
    v.caption(L0, T0, "LEGENDARY. THEY MOVE.", color=GOLD)
    v.caption(T0, E0, "TRAILS", color=WHITE, size=4)
    v.caption(E0, E1, "CAPTURE EFFECTS", color=PINK)
    v.caption(W0, END, "YOUR TURF GROWS A FOREST", color=GREEN)
    v.watermark(0, END)

    # comment bait + end card
    def bait(img, tl, tg):
        bg_checker(img, tg, c1=(40, 30, 10), c2=(60, 46, 14), speed=20)
        allskins = [(n, a, c, p, None) for (n, a, c, p) in RARES] + list(LEGENDS)
        for i, (n, a, c, p, an) in enumerate(allskins):
            col, row = i % 5, i // 5
            x, y = 15 + col * 50, 120 + row * 58
            k = ease_back(min(1.0, (tl - i * 0.04) / 0.25))
            if k <= 0:
                continue
            sz = int(42 * k)
            img.paste(skin_board(sz, sz, a, c, p, an, tg), (x + (42 - sz) // 2, y + (42 - sz) // 2))
            ImageDraw.Draw(img).rectangle((x - 1, y - 1, x + 42, y + 42), outline=GOLD if an else WHITE, width=2)
            draw_text(img, str(i + 1), x + 21, y + 14, 2, WHITE, DARK)
        draw_lines(img, "WHICH ONE ARE YOU GETTING?", 330, 3, YELLOW)
        draw_lines(img, "COMMENT A NUMBER", 395, 3, WHITE)

    v.scene(END, END + 3, bait, "comment bait: all 10 skins tiled, WHICH ONE ARE YOU GETTING? COMMENT BELOW")
    v.sound(END, "hit")
    avatar_end(v, END + 3, END + 7)
    v.dur = v.b(END + 7)
    return v


# ------------------------------------------------------------ Roblox-style avatars (blocky pixel figure, our own art)
OUTFITS = {  # rid -> (skin tone, hair, shirt, pants)
    1: ((255, 206, 160), (70, 45, 30), (79, 139, 255), (43, 47, 58)),
    2: ((198, 134, 86), (25, 25, 30), (255, 200, 61), (60, 90, 160)),
    3: ((241, 194, 125), (230, 120, 40), (255, 79, 139), (40, 40, 48)),
    4: ((141, 85, 60), (20, 20, 24), (74, 222, 128), (90, 60, 40)),
}


def avatar(img, cx, feet, outfit, t, moving=True, s=1, king=False, label=None):
    """Blocky avatar standing with its feet at (cx, feet); legs/arms swap every 0.1 s while moving."""
    skin, hair, shirt, pants = outfit
    d = ImageDraw.Draw(img)
    st = int(t * 10) % 2 if moving else 0
    cx, feet = int(cx), int(feet)
    ty = feet - 11 * s
    hy = ty - 6 * s
    parts = [  # (x0, y0, x1, y1, colour)
        (cx - 4 * s, feet - 5 * s - (s if st else 0), cx - s, feet - (s if st else 0), pants),
        (cx + s, feet - 5 * s - (0 if st else s), cx + 4 * s, feet - (0 if st else s), pants),
        (cx - 4 * s, ty, cx + 4 * s, ty + 6 * s, shirt),
        (cx - 6 * s, ty + (s if st else 0), cx - 4 * s, ty + 5 * s + (s if st else 0), skin),
        (cx + 4 * s, ty + (0 if st else s), cx + 6 * s, ty + 5 * s + (0 if st else s), skin),
        (cx - 3 * s, hy, cx + 3 * s, hy + 6 * s, skin),
        (cx - 3 * s, hy, cx + 3 * s, hy + 2 * s, hair),
    ]
    d.ellipse((cx - 6 * s, feet - 2 * s, cx + 6 * s, feet + 2 * s), fill=(60, 64, 78))
    for (a, b, c, e, _) in parts:
        d.rectangle((a - 1, b - 1, c, e), fill=DARK)
    for (a, b, c, e, col) in parts:
        d.rectangle((a, b, c - 1, e - 1), fill=col)
    d.rectangle((cx - 2 * s, hy + 3 * s, cx - s - 1 + (s > 1), hy + 4 * s - 1), fill=DARK)  # eyes
    d.rectangle((cx + s, hy + 3 * s, cx + 2 * s - 1 + (s > 1), hy + 4 * s - 1), fill=DARK)
    if s >= 2:
        d.rectangle((cx - s, hy + 5 * s - 1, cx + s, hy + 5 * s), fill=DARK)  # smile
    top = hy - 2
    if king:
        cs = max(2, s)
        top -= 5 * cs + 1
        crown(img, cx, top, cs)
    if label:
        draw_text(img, label, cx, top - 18, 2, WHITE, DARK)


def mask_ready(ar, rid, cp, t, which="owner"):
    """Like mask_of, but a freshly claimed cell joins the skin only after the white claim wave has passed it."""
    n = ar.n
    m = Image.new("L", (n, n), 0)
    data = []
    for y in range(n):
        for x in range(n):
            ok = False
            if which == "owner" and ar.owner[y][x] == rid:
                ox, oy = ar.corig[y][x]
                ok = t - ar.ctime[y][x] - math.hypot(x - ox, y - oy) * 0.018 > 0.16
            elif which == "trail" and ar.trail[y][x] == rid:
                ok = True
            data.append(255 if ok else 0)
    m.putdata(data)
    return m.resize((n * cp, n * cp), Image.NEAREST)


def skinned(img, ar, t, x0, y0, cp, skins, trails=None, hero=None, kings=(), outfits=OUTFITS, scale=1, hero_scale=2):
    """Arena with every runner's turf/trail in its skin and avatars instead of squares."""
    alive = {rid: r.alive for rid, r in ar.runners.items()}
    for r in ar.runners.values():
        r.alive = False  # draw_arena: cells only
    draw_arena(img, ar, t, x0, y0, cp, None, None)
    for rid, a in alive.items():
        ar.runners[rid].alive = a
    w = ar.n * cp
    for rid, sk in skins.items():
        img.paste(skin_board(w, w, sk[0], sk[1], sk[2], sk[3], t), (x0, y0), mask_ready(ar, rid, cp, t))
    for rid, sk in (trails or {}).items():
        img.paste(skin_board(w, w, sk[0], sk[1], sk[2], "flow", t), (x0, y0), mask_ready(ar, rid, cp, t, "trail"))
    frac = max(0.0, min(1.0, (t - ar.t) / ar.dt))
    for r in sorted(ar.runners.values(), key=lambda r: r.y):
        if not r.alive:
            continue
        fx = r.px + (r.x - r.px) * frac
        fy = r.py + (r.y - r.py) * frac
        avatar(img, x0 + (fx + 0.5) * cp, y0 + (fy + 0.85) * cp, outfits.get(r.id, outfits[1]), t,
               moving=(r.px, r.py) != (r.x, r.y), s=hero_scale if r.id == hero else scale, king=r.id in kings,
               label="YOU" if r.id == hero else None)


def demo24(dt):
    """Scripted 24x24 match (same as videos.demo_arena): claim at step 26, you cut pink at 36, claim at 42."""
    ar = Arena(24, seed=3)
    ar.dt = dt
    h = ar.add(1, PLAYERS[7], 6, 14, 5)
    h.x, h.y, h.px, h.py = 8, 12, 8, 12
    h.script = path_from([(8, 12), (8, 5), (14, 5), (14, 12), (8, 12), (8, 16), (12, 16), (12, 18), (8, 18), (8, 16)])
    h.shield = True
    y = ar.add(2, PLAYERS[2], 12, 1, 3)
    y.x, y.y, y.px, y.py = 11, 2, 11, 2
    y.script = deque([(11, 2)] * 24) + path_from([(11, 2), (11, 5), (11, 2)])
    p = ar.add(3, PLAYERS[11], 18, 19, 5)
    p.x, p.y, p.px, p.py = 16, 18, 16, 18
    p.script = deque([(16, 18)] * 30) + path_from([(16, 18), (9, 18), (9, 21)])
    p.respawn = False
    return ar


def sk(name_list, name):
    for row in name_list:
        if row[0] == name:
            return (row[1], row[2], row[3], row[4] if len(row) > 4 else None)
    raise KeyError(name)


def avatar_end(v, b0, b1, skin=("#FF2E9A", "#00F0FF", "stripes", "pulse"), line="FOLLOW TO PLAY FIRST"):
    """End card with avatars, not squares: logo, a big avatar on an animated skin pad, a pulsing CTA."""
    def fn(img, tl, tg):
        bg_checker(img, tg)
        k = ease_back(tl / 0.3)
        logo(img, 24 - (1 - k) * 40, 4, tg)
        draw_lines(img, "COMING SOON TO ROBLOX", 86, 2, YELLOW)
        img.paste(skin_board(200, 150, skin[0], skin[1], skin[2], skin[3], tg), (35, 118))
        ImageDraw.Draw(img).rectangle((34, 117, 235, 268), outline=GOLD, width=3)
        avatar(img, 110, 250, OUTFITS[1], tg, moving=True, s=4, king=True)
        avatar(img, 182, 254, OUTFITS[3], tg + 0.05, moving=True, s=3)
        ph = (tl / v.spb) % 1.0
        g = 4 if ph < 0.15 else 0
        ImageDraw.Draw(img).rectangle((14 - g, 300 - g, W - 15 + g, 378 + g), fill=GREEN, outline=DARK, width=3)
        draw_lines(img, line, 340, 3, DARK, None, max_chars=12)

    v.scene(b0, b1, fn, "end card: logo, COMING SOON TO ROBLOX, two avatars (one crowned) on an animated skin pad, pulsing FOLLOW TO PLAY FIRST")
    v.sound(b0, "hit")
    v.sound(b0 + 0.02, "crown")


# ============================================================ s02 You're not a square anymore
def s02():
    v = Video("s02_avatar_hype", 108, 30, music=dict(mode="major", root=62, seed=88, prog=[0, 4, 5, 3], sections=[
        (0, 3.5, {"kick", "hat", "arp"}), (3.5, 4, set()), (4, 26, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (26, 30, {"kick", "snare", "hat", "bass", "lead"})]))

    # hook: the old game, you were a square (big CRT, loop closes on beat 1)
    old = Arena(12, seed=2)
    old.dt = v.spb / 4
    old.ground = (18, 52, 30)
    h0 = old.add(1, (90, 255, 140), 3, 7, 3)
    h0.x, h0.y, h0.px, h0.py = 4, 7, 4, 7
    h0.script = path_from([(4, 7), (8, 7), (8, 3), (4, 3), (4, 6)])  # 14 steps
    old_in = arena_scene(v, old, 0, 15, 140, 20, hero=1, fx=FX(), t_offset=10 * old.dt)

    def retro(img, tl, tg):
        ImageDraw.Draw(img).rectangle((0, 0, W, H), fill=(8, 24, 14))
        old_in(img, tl, tg)
        d = ImageDraw.Draw(img)
        for y in range(0, H, 4):
            d.line((0, y, W, y), fill=(0, 0, 0))

    v.scene(0, 3, retro, "HOOK: big green retro screen, you are a little square; your loop closes on beat 1")
    v.caption(0, 3, "IN PAPER.IO YOU WERE A SQUARE.", y=70, size=3, color=YELLOW)
    v.sound(0, "hit")

    def morph(img, tl, tg):  # the square grows and turns into your avatar
        bg_checker(img, tg, c1=(40, 18, 60), c2=(58, 26, 86), speed=30)
        k = min(1.0, tl / v.b(1))
        if k < 0.6:
            sz = int(20 + 60 * k / 0.6)
            ImageDraw.Draw(img).rectangle((W / 2 - sz / 2, 260 - sz / 2, W / 2 + sz / 2, 260 + sz / 2), fill=(90, 255, 140), outline=DARK, width=3)
        else:
            avatar(img, W / 2, 330, OUTFITS[1], tg, moving=True, s=6)
        if tl > v.b(1):
            draw_lines(img, "YOUR ROBLOX AVATAR", 410, 3, YELLOW)

    v.scene(3, 6, morph, "the square grows and morphs into a big blocky Roblox-style avatar (6x), walking in place")
    v.caption(3, 6, "IN TURF LOOP... YOU'RE YOU.", y=70, size=3, color=WHITE, sound=False)
    v.sound(3, "whoosh")
    v.flash(4, WHITE, 0.15)
    v.sound(4, "hit")
    v.sound(4.02, "levelup")
    v.shake(4, 0.35, 6)
    v.stamp(4, "THAT'S YOU!", YELLOW, y=150, beats=2, size=4, sound=None)

    # gameplay with avatars wearing skins: loop, claim, K.O., crown
    G = 6
    dt = v.spb / 4
    ar = demo24(dt)
    fx = FX()
    seen = [0]
    sk_hero = sk(LEGENDS, "NEON PULSE")
    skins = {1: sk_hero, 2: ("#FFC83D", "#FF8A3D", "dots", None), 3: sk(RARES, "CANDY STRIPE")}
    trails = {1: ("#00F0FF", "#FF2E9A", "stripes"), 3: ("#FF9ACB", "#FFFFFF", "stripes")}
    crown_b = G + 42 / 4 + 0.5

    def game(img, tl, tg):
        bg_checker(img, tg)
        ar.update(tl)
        skinned(img, ar, tl, 3, 130, 11, skins, trails, hero=1, kings=(1,) if tg >= v.b(crown_b) else ())
        for (et, kind, data) in ar.events[seen[0]:]:
            cx, cy = 3 + (data["at"][0] + 0.5) * 11, 130 + (data["at"][1] + 0.5) * 11
            if kind == "claim" and data["id"] == 1:
                v.sfx.append((tg, "claim", 8))
                fx.coins(cx, cy, 14, tg)
                fx.pop(cx, max(140, cy - 46), f"+{data['cells']}", tg, YELLOW, 3)
            elif kind == "cut":
                v.sfx.append((tg, "cut", 0))
                fx.burst(cx, cy, 30, tg, PINK)
        seen[0] = len(ar.events)
        fx.draw(img, tg)

    v.scene(G, G + 13, game, "24x24 match with avatars: you (Neon Pulse turf) draw a loop as yellow arrives too late, claim, cut pink's trail (K.O.), claim again, crown")
    v.flash(G)
    v.caption(G, G + 3, "PLAY AS YOUR OWN AVATAR", color=YELLOW)
    v.caption(G + 3, G + 6.5, "DRAW A LOOP...", color=WHITE)
    v.caption(G + 6.5, G + 9, "LOOP HOME = IT'S YOURS", color=GREEN)
    v.stamp(G + 6.5, "MINE!", GREEN, beats=1.5, sound=None)
    v.caption(G + 9, crown_b, "CUT THEIR TRAIL = THEY'RE OUT", color=RED)
    v.stamp(G + 9 + 0.25, "K.O.!", RED, beats=1.5)
    v.caption(crown_b, G + 13, "MOST TURF = THE CROWN", color=YELLOW)
    v.stamp(crown_b, "KING!", YELLOW, beats=2, sound="crown")

    # your avatar + any skin
    S = G + 13
    fits = [("GALAXY SWIRL", sk(RARES, "GALAXY SWIRL"), "RARE"), ("MAGMA SURGE", sk(LEGENDS, "MAGMA SURGE"), "LEGENDARY"),
            ("PRISM STORM", sk(LEGENDS, "PRISM STORM"), "LEGENDARY"), ("STARFALL", sk(LEGENDS, "STARFALL"), "LEGENDARY")]

    def wardrobe(img, tl, tg):
        bg_checker(img, tg, speed=14)
        i = min(len(fits) - 1, int(tl / v.b(1.5)))
        name, s_, tier = fits[i]
        pad = skin_board(240, 170, s_[0], s_[1], s_[2], s_[3], tg)
        img.paste(pad, (15, 150))
        ImageDraw.Draw(img).rectangle((14, 149, 255, 320), outline=GOLD if tier == "LEGENDARY" else WHITE, width=3)
        avatar(img, W / 2, 290, OUTFITS[1], tg, moving=True, s=5, label="YOU")  # same you, only the skin changes
        name_card(img, name, tier, v.b(S + i * 1.5), tg, y=336)

    v.scene(S, S + 6, wardrobe, "wardrobe: big avatar on a pad that swaps skin every 1.5 beats (Galaxy Swirl, Magma Surge, Prism Storm, Starfall)")
    v.caption(S, S + 6, "YOUR AVATAR. ANY SKIN.", color=YELLOW)
    for i in range(4):
        v.sound(S + i * 1.5, "crown" if i else "pop")
        v.flash(S + i * 1.5, WHITE, 0.08)
    v.watermark(0, S + 6)
    avatar_end(v, S + 6, S + 10, skin=sk(LEGENDS, "MAGMA SURGE"))
    return v


# ============================================================ s03 Turf Pass + limited-time events
PASS_TRACK = [  # tier -> (free, premium); kinds: coins/gems/keys/boost/skin/trail/legend (docs/BATTLEPASS.md)
    ("coins 2.5K", "legend NEON PULSE"), ("coins 3K", "coins 6K"), ("keys 1", "keys 2"), ("boost 15M", "boost 30M"),
    ("skin ZIGZAG ROOKIE", "skin SOUR BLAST"), ("coins 3.5K", "coins 8K"), ("gems 10", "keys 2"), ("keys 1", "gems 20"),
    ("coins 4K", "coins 10K"), ("boost 15M", "legend MAGMA SURGE"), ("coins 4.5K", "boost 60M"), ("gems 15", "skin FROST BITE"),
    ("keys 1", "keys 2"), ("trail PEBBLE DASH", "coins 12K"), ("boost 30M", "keys 3"), ("coins 5.5K", "gems 20"),
    ("gems 20", "coins 14K"), ("keys 1", "skin BUBBLE POP"), ("coins 6K", "boost 60M"), ("boost 30M", "legend STARFALL"),
    ("coins 7K", "coins 16K"), ("skin TURBO TIDE", "keys 3"), ("keys 1", "gems 20"), ("coins 8K", "coins 18K"),
    ("gems 25", "keys 3"), ("coins 9K", "skin SUNSET RIOT"), ("keys 1", "boost 60M"), ("coins 10K", "coins 20K"),
    ("gems 30", "gems 40"), ("trail NEON STREAK", "legend PRISM STORM"),
]
PASS_SKINS = {"ZIGZAG ROOKIE": ("#4F8BFF", "#FFC83D", "waves"), "SOUR BLAST": ("#B6FF3B", "#FFE14D", "checker"),
              "FROST BITE": ("#9FE8FF", "#FFFFFF", "hex"), "BUBBLE POP": ("#FF8AD8", "#FFFFFF", "dots"),
              "TURBO TIDE": ("#00C2B8", "#E6FFF9", "waves"), "SUNSET RIOT": ("#FF6A3D", "#7C2BD9", "stripes"),
              "PEBBLE DASH": ("#C9B8FF", "#B8A6F0", "dots"), "NEON STREAK": ("#00F0FF", "#FF2E9A", "stripes")}


def reward_card(img, kind_label, x, y, t, premium):
    kind, _, val = kind_label.partition(" ")
    d = ImageDraw.Draw(img)
    legend = kind == "legend"
    frame = GOLD if legend or premium else RARE_BLUE
    d.rectangle((x, y, x + 52, y + 60), fill=(26, 30, 46), outline=frame, width=2)
    if kind in ("skin", "trail"):
        a, b, p = PASS_SKINS[val]
        img.paste(skin_board(44, 34, a, b, p, "flow" if kind == "trail" else None, t), (x + 4, y + 4))
        draw_text(img, "TRAIL" if kind == "trail" else "SKIN", x + 26, y + 44, 1, WHITE, None)
    elif legend:
        a, b, p, an = sk(LEGENDS, val)
        img.paste(skin_board(44, 34, a, b, p, an, t), (x + 4, y + 4))
        draw_text(img, "LEGEND", x + 26, y + 44, 1, GOLD, None)
    elif kind == "coins":
        d.ellipse((x + 16, y + 8, x + 36, y + 28), fill=YELLOW, outline=DARK, width=2)
        draw_text(img, val, x + 26, y + 40, 1, YELLOW, None)
    elif kind == "gems":
        d.polygon([(x + 26, y + 6), (x + 38, y + 18), (x + 26, y + 32), (x + 14, y + 18)], fill=GEM, outline=DARK)
        draw_text(img, val, x + 26, y + 40, 1, GEM, None)
    elif kind == "keys":
        d.ellipse((x + 12, y + 10, x + 24, y + 22), outline=GOLD, width=3)
        d.rectangle((x + 23, y + 15, x + 40, y + 17), fill=GOLD)
        d.rectangle((x + 34, y + 17, x + 36, y + 22), fill=GOLD)
        draw_text(img, "KEY X" + val, x + 26, y + 40, 1, GOLD, None)
    elif kind == "boost":
        draw_text(img, "2X", x + 26, y + 10, 3, GREEN, DARK)
        draw_text(img, val, x + 26, y + 40, 1, GREEN, None)


def s03():
    v = Video("s03_turf_pass_hype", 108, 30, music=dict(mode="minor", root=57, seed=99, prog=[0, 5, 2, 6], sections=[
        (0, 1.5, {"kick", "hat", "arp"}), (1.5, 2, set()), (2, 26, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (26, 30, {"kick", "snare", "hat", "bass", "lead"})]))

    def countdown(img, tg, y=118, speed=9000):
        left = 14 * 86400  # a full season: the pass is not live yet, so no real countdown is implied
        dd, hh, mm, ss = left // 86400, left % 86400 // 3600, left % 3600 // 60, left % 60
        txt = "14 DAYS PER SEASON"
        ImageDraw.Draw(img).rectangle((12, y - 6, W - 13, y + 26), fill=RED, outline=DARK, width=2)
        draw_text(img, txt, W / 2, y + 1, 3, WHITE, DARK)

    def hook(img, tl, tg):
        bg_checker(img, tg, c1=(30, 10, 40), c2=(50, 16, 66), speed=24)
        a, b, p, an = sk(LEGENDS, "PRISM STORM")
        k = ease_back(min(1.0, tl / 0.3))
        sz = int(220 * k)
        if sz > 4:
            img.paste(skin_board(sz, int(sz * 0.8), a, b, p, an, tg * 2), (int(W / 2 - sz / 2), int(260 - sz * 0.4)))
            ImageDraw.Draw(img).rectangle((W / 2 - sz / 2 - 2, 260 - sz * 0.4 - 2, W / 2 + sz / 2 + 1, 260 + sz * 0.4 + 1), outline=GOLD, width=3)
            avatar(img, W / 2, 320, OUTFITS[1], tg, moving=True, s=5, king=True)
        countdown(img, tg, y=372)
        draw_text(img, "LEGENDARY: PRISM STORM", W / 2, 404, 2, GOLD, DARK)

    v.scene(0, 2, hook, "HOOK: animated Prism Storm legendary pops in, red season countdown ticking down fast")
    v.caption(0, 2, "LIMITED-TIME SKINS. 14-DAY SEASONS.", y=62, size=3, color=YELLOW)
    v.sound(0, "hit")
    v.sound(0.02, "crown")

    # the pass track
    keys_ = [(2, 0.0), (3.6, 0.0), (5, 9.0), (6.2, 9.0), (8, 19.0), (9.2, 19.0), (11, 29.0), (14, 29.0)]

    def pos_at(b):
        for (b0, p0), (b1, p1) in zip(keys_, keys_[1:]):
            if b <= b1:
                return p0 + (p1 - p0) * ease_out((b - b0) / (b1 - b0)) if b1 > b0 else p1
        return keys_[-1][1]

    def track(img, tl, tg):
        b = tg / v.spb
        bg_checker(img, tg, c1=(30, 10, 40), c2=(50, 16, 66), speed=10)
        pos = pos_at(b)
        d = ImageDraw.Draw(img)
        ribbon = Image.new("RGBA", (W, 26), (255, 200, 61, 255))
        img.paste(ribbon, (0, 112))
        draw_text(img, "SEASON 1: NEON RUSH", W / 2, 118, 2, DARK, None)
        for i, (free, prem) in enumerate(PASS_TRACK):
            x = int(W / 2 + (i - pos) * 62 - 26)
            if x < -60 or x > W:
                continue
            reward_card(img, prem, x, 156, tg, True)
            reward_card(img, free, x, 268, tg, False)
            node_on = i <= pos + 0.01
            cy = 240
            d.rectangle((x - 5, cy - 3, x + 57, cy + 3), fill=GOLD if node_on else (70, 74, 96))
            d.ellipse((x + 12, cy - 14, x + 40, cy + 14), fill=GOLD if node_on else (70, 74, 96), outline=DARK, width=2)
            draw_text(img, str(i + 1), x + 26, cy - 7, 2, DARK if node_on else WHITE, None)
        draw_text(img, "PREMIUM", 30, 140, 1, GOLD, DARK)
        draw_text(img, "FREE", 20, 332, 1, RARE_BLUE, DARK)
        cur = int(round(pos))
        prem = PASS_TRACK[cur][1]
        if prem.startswith("legend") and abs(pos - cur) < 0.05:
            name_card(img, prem.split(" ", 1)[1], "TIER %d LEGENDARY" % (cur + 1), v.b(b - (b % 1.2)), tg, y=356)

    v.scene(2, 14, track, "battle pass track: tiers scroll right with the gold rail filling; it stops on each animated legendary (tiers 1, 10, 20, 30) with a name card")
    v.flash(2)
    v.sound(2, "whoosh")
    for (b0, p0) in keys_[1::2][:4]:
        v.sound(b0 - 1.2, "crown")
        v.flash(b0 - 1.2, GOLD, 0.1)
    for b_ in (3.6, 4.0, 4.4, 6.6, 7.0, 7.4, 9.6, 10.0, 10.4):
        v.sound(b_, "blip")
    v.caption(2, 5, "TURF PASS. SEASON 1.", color=GOLD)
    v.caption(5, 8, "30 TIERS. FREE + PREMIUM.", color=WHITE)
    v.caption(8, 11, "4 ANIMATED LEGENDARIES", color=GOLD)
    v.caption(11, 14, "EARN XP FROM DAILY MISSIONS", color=GREEN)

    # limited-time events: Crown Rush weekend + 2x coins weekend
    E = 14
    ar = Arena(16, seed=41)
    ar.dt = v.spb / 4
    h = ar.add(1, PLAYERS[7], 8, 9, 5)
    h.hungry, h.reach, h.shield = True, (3, 5), True
    for i, (x, y) in enumerate(((3, 3), (13, 3), (3, 13))):
        ar.add(i + 2, PLAYERS[(i * 4 + 2) % 12], x, y, 3).reach = (2, 3)
    skins = {1: sk(LEGENDS, "STARFALL"), 2: sk(RARES, "CHERRY DOTS"), 3: sk(RARES, "OCEAN WAVES"), 4: ("#4ADE80", "#B6E33B", "waves", None)}
    fx = FX()
    seen = [0]
    rush_trail = ("#FFC83D", "#2B2F3A", "stars")

    def events(img, tl, tg):
        b = tg / v.spb
        bg_checker(img, tg, c1=(40, 30, 10), c2=(60, 46, 14), speed=16)
        ar.update(tl)
        trails = {1: rush_trail} if b >= E + 4 else {}
        skinned(img, ar, tl, 7, 140, 16, skins, trails, hero=1, kings=(1,))
        for (et, kind, data) in ar.events[seen[0]:]:
            if kind == "claim" and data["id"] == 1:
                cx, cy = 7 + (data["at"][0] + 0.5) * 16, 140 + (data["at"][1] + 0.5) * 16
                n = 22 if b >= E + 5 else 10
                fx.coins(cx, cy, n, tg)
                v.sfx.append((tg, "coin", 0))
        seen[0] = len(ar.events)
        if b >= E + 5:  # coin rain
            rng = random.Random(int(tg * 30))
            for _ in range(2):
                fx.coins(rng.uniform(10, W - 10), 120, 1, tg)
        fx.draw(img, tg)
        if b < E + 4:  # crown hold timer (fast-forwarded)
            held = min(300, int(max(0.0, tg - v.b(E + 0.5)) / v.b(3) * 300))
            draw_text(img, f"CROWN HELD {held // 60}:{held % 60:02d} / 5:00", W / 2, 405, 2, GOLD, DARK)
            draw_text(img, "FAST FORWARD >>", W / 2, 428, 1, CREAM, None)
        elif b < E + 5:
            name_card(img, "CROWN RUSH TRAIL", "LIMITED EVENT TRAIL", v.b(E + 4), tg, y=392)
        else:
            draw_text(img, "2X", W / 2, 396, 6, YELLOW, DARK, 2)

    v.scene(E, E + 8, events, "events: CROWN RUSH weekend on a 16x16 board (you are King, crown timer fast-forwards to 5:00 -> limited Crown Rush Trail appears on your trail), then 2X COINS weekend with coin rain")
    v.flash(E)
    v.sound(E, "hit")
    v.caption(E, E + 2, "LIMITED-TIME EVENTS", color=RED)
    v.caption(E + 2, E + 3, "CROWN RUSH: KING EARNS 2X", color=GOLD)
    v.caption(E + 3, E + 5, "HOLD THE CROWN 5 MIN = LIMITED TRAIL", color=GOLD)
    v.stamp(E + 4, "LIMITED TRAIL!", GOLD, beats=1, size=4, sound="levelup")
    v.caption(E + 5, E + 8, "WEEKENDS = 2X COINS", color=YELLOW)
    v.sound(E + 5, "coin")
    v.sound(E + 5.5, "coin")

    def last(img, tl, tg):
        bg_checker(img, tg, c1=(30, 10, 40), c2=(50, 16, 66), speed=24)
        for i, (n, a, b2, p, an) in enumerate(LEGENDS):
            x = 18 + i * 60
            img.paste(skin_board(52, 52, a, b2, p, an, tg), (x, 150))
            ImageDraw.Draw(img).rectangle((x - 1, 149, x + 52, 202), outline=GOLD, width=2)
            draw_text(img, str(i + 1), x + 26, 162, 4, WHITE, DARK)
            draw_text(img, n.split(" ")[0], x + 26, 208, 1, GOLD, None)
        countdown(img, tg, y=250)
        draw_lines(img, "SEASON 1 STARTS AT LAUNCH", 320, 3, YELLOW)

    v.scene(E + 8, E + 10, last, "all 4 legendaries animating + season countdown: DON'T MISS SEASON 1")
    v.caption(E + 8, E + 10, "WHICH ARE YOU GRINDING FOR? COMMENT 1-4", color=WHITE)
    v.watermark(0, E + 10)
    avatar_end(v, E + 10, E + 14, skin=sk(LEGENDS, "PRISM STORM"))
    v.dur = v.b(E + 14)
    return v


ALL = {"s01": s01, "s02": s02, "s03": s03}

if __name__ == "__main__":
    for n in sys.argv[1:] or list(ALL):
        print("rendered", ALL[n]().render(OUT, SHEETS))

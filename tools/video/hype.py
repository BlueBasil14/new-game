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
                on = ((x + y) // 6) % 2 == 0  # coarse: thin diagonal hatching moires under compression
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
            for _ in range(13):
                self.items.append(("bubble", rng.uniform(x0, x1), rng.uniform(y0, y1), rng.uniform(-8, 8), -rng.uniform(30, 60),
                                   t + rng.uniform(0, 0.4), (124, 196, 255)))
        elif kind == "LIGHTNING":
            for _ in range(5):
                self.items.append(("bolt", rng.uniform(x0, x1), y0, rng.uniform(x0, x1), rng.uniform(y0, y1),
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


def name_card(img, name, tier, t_in, t, y=344):
    """Bottom card: skin name + tier badge, slides up on the beat."""
    if t < t_in:
        return
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
RARES4 = [RARES[0], RARES[1], RARES[2], RARES[3]]  # 4 contrasting rares at 2 beats each (R3: 6 was too many)


def s01():
    v = Video("s01_skins_hype", 108, 43, music=dict(mode="major", root=60, seed=77, prog=[0, 5, 3, 4], sections=[
        (0, 3.5, {"kick", "hat", "arp"}), (3.5, 4, set()), (4, 18, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (18, 26, {"kick", "snare", "hat", "bass", "arp", "lead"}), (26, 39, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (39, 43, {"kick", "snare", "hat", "bass", "lead"})]))
    X0, Y0, CP, N = 15, 96, 15, 16  # 240 px board, clear of the raised name cards and footer

    # ---------- hook: the old school-computer game (big retro CRT, our own art), loop closes on beat 1 ----------
    old = Arena(12, seed=2)
    old.dt = v.spb / 4
    old.ground = (18, 52, 30)
    h0 = old.add(1, (90, 255, 140), 3, 7, 3)
    h0.x, h0.y, h0.px, h0.py = 4, 7, 4, 7
    h0.script = path_from([(4, 7), (8, 7), (8, 3), (4, 3), (4, 6)])  # 14 steps
    old_in = arena_scene(v, old, 0, 15, 150, 20, hero=1, fx=FX(), t_offset=10 * old.dt)
    off_t = v.b(4) - 0.3

    def retro(img, tl, tg):
        ImageDraw.Draw(img).rectangle((0, 0, W, H), fill=(8, 24, 14))
        old_in(img, tl, tg)
        d = ImageDraw.Draw(img)
        for y in range(0, H, 4):
            d.line((0, y, W, y), fill=(4, 14, 8))
        if tl > off_t:  # CRT power-off: squash to a line, then a dot
            k = min(1.0, (tl - off_t) / 0.3)
            hh = max(2, int(H * (1 - k) ** 3))
            ww = W if k < 0.7 else max(4, int(W * (1 - (k - 0.7) / 0.3)))
            sq = Image.blend(img.resize((ww, hh)), Image.new("RGB", (ww, hh), WHITE), min(1.0, k * 1.2))
            img.paste((0, 0, 0), (0, 0, W, H))
            img.paste(sq, ((W - ww) // 2, (H - hh) // 2))

    v.scene(0, 4, retro, "HOOK: big green retro school-computer screen; a square closes its loop on beat 1 (+N at 0.56 s); CRT powers off at 1.9 s")
    v.caption(0, 2.5, "REMEMBER PLAYING PAPER.IO IN CLASS?", y=70, size=3, color=YELLOW)
    v.sound(0, "hit")
    v.caption(2.5, 4, "IT GREW UP...", y=70, size=4, color=WHITE)
    v.sound(3.45, "whoosh")

    # ---------- drop: Turf Loop reveal ----------
    def reveal(img, tl, tg):
        bg_checker(img, tg, c1=(40, 18, 60), c2=(58, 26, 86), speed=30)
        k = ease_back(tl / 0.35)
        logo(img, 150 - (1 - k) * 80, 4, tg)
        draw_lines(img, "COMING TO ROBLOX", 225, 3, YELLOW)
        if tl > v.spb * 0.5:
            draw_lines(img, "WITH SKINS. SO MANY SKINS.", 320, 3, WHITE)

    v.scene(4, 6, reveal, "DROP: TURF LOOP logo slams in, COMING TO ROBLOX, WITH SKINS. SO MANY SKINS.")
    v.flash(4, WHITE, 0.15)
    v.sound(4, "hit")
    v.sound(4.02, "crown")
    v.shake(4, 0.35, 6)

    # ---------- the main board: one live match, players are avatars, your turf wears the skins ----------
    ar = Arena(N, seed=31)
    ar.dt = v.spb / 4
    hero = ar.add(1, hexc(RARES4[0][1]), 8, 8, 7)
    hero.hungry, hero.reach, hero.shield = True, (3, 5), True
    hero.x, hero.y, hero.px, hero.py = 11, 8, 11, 8
    hero.script = path_from([(11, 8), (14, 8), (14, 3), (9, 3), (9, 5)])  # 15 steps, claim on step 15
    hero.after_script = "bot"
    pre = 9 * ar.dt  # trail already out at frame 1, claim 1.5 beats into the board
    rival = ar.add(2, PLAYERS[2], 14, 14, 3)
    rival.reach = (1, 2)
    efx, tfx = Effects(), FX()
    seen = [0]

    G0 = 6                                     # board starts
    R0, RSTEP = 8.5, 2                         # LOOP HOME held 2.5 beats, then 4 rares x 2 beats
    L0, LSTEP = R0 + len(RARES4) * RSTEP, 2    # 4 legendaries x 2 beats
    T0, T1 = L0 + len(LEGENDS) * LSTEP, L0 + len(LEGENDS) * LSTEP + 3  # 1 trail, 3 beats, long trail
    E0, E1 = T1, T1 + 5                        # capture effects, one per claim
    W0, W1 = E1, E1 + 3                        # Living Woodland
    END = W1
    WIPE = 0.2

    def skin_at(b):
        if b < L0:
            i = max(0, min(len(RARES4) - 1, int((b - R0) // RSTEP)))
            n, a, c, p = RARES4[i]
            return i, (n, a, c, p, None, "RARE"), R0 + i * RSTEP
        i = min(len(LEGENDS) - 1, int((b - L0) / LSTEP))
        n, a, c, p, an = LEGENDS[i]
        return len(RARES4) + i, (n, a, c, p, an, "LEGENDARY"), L0 + i * LSTEP

    eff_i = [0]
    eff_label = [None, 0.0]

    def board(img, tl, tg):
        b = tg / v.spb
        st = tl + pre
        bg_checker(img, tg, speed=14)
        ar.dt = v.spb / 8 if E0 <= b < E1 else v.spb / 4  # faster loops while showing capture effects
        hero.reach = (6, 9) if T0 <= b < T1 else (3, 5)  # long trail for the trail skin
        ar.update(st)
        alive = {rid: r.alive for rid, r in ar.runners.items()}
        for r in ar.runners.values():
            r.alive = False
        draw_arena(img, ar, st, X0, Y0, CP, None, None)
        for rid, a in alive.items():
            ar.runners[rid].alive = a
        cur = min(b, W0 - 0.001)
        idx, sk_, s_b0 = skin_at(cur)
        prev = skin_at(s_b0 - 0.01)[1] if idx > 0 else sk_
        wipe = min(1.0, (tg - v.b(s_b0)) / WIPE) if b < W0 else 1.0
        colm = int(wipe * N + 0.999)
        w = N * CP
        if b < W0:
            img.paste(skin_board(w, w, sk_[1], sk_[2], sk_[3], sk_[4], tg), (X0, Y0), mask_of(ar, 1, CP, col_limit=colm))
            if wipe < 1:
                img.paste(skin_board(w, w, prev[1], prev[2], prev[3], prev[4], tg), (X0, Y0),
                          mask_of(ar, 1, CP, col_limit=colm, flip=True))
            hero.color = hexc(sk_[1])
        else:  # Living Woodland: grass turf + trees growing across it
            img.paste(skin_board(w, w, "#A3CF62", "#8DBF4E", "dots", None, tg), (X0, Y0), mask_of(ar, 1, CP))
            hero.color = hexc("#A3CF62")
        if T0 <= b < E1:
            tn, ta, tb, tp = TRAILS[0]
            img.paste(skin_board(w, w, ta, tb, tp, "flow", tg), (X0, Y0), mask_of(ar, 1, CP, which="trail"))
        if b >= W0:
            for y in range(N):
                for x in range(N):
                    if ar.owner[y][x] == 1 and (x * 7 + y * 13) % 3 == 0:
                        delay = (abs(x - 8) + abs(y - 8)) * 0.045
                        tree(img, X0 + x * CP + CP // 2, Y0 + y * CP + CP - 2, (tg - v.b(W0) - delay) / 0.4, x * 31 + y)
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
                    tfx.coins(cx, cy, 10, tg)
                    if b < R0:
                        tfx.pop(cx + 46 if cx + 46 < W - 30 else cx - 46, cy - 20, f"+{data['cells']}", tg, YELLOW, 3)
            elif kind == "cut":
                v.sfx.append((tg, "cut", 0))
        seen[0] = len(ar.events)
        tfx.draw(img, tg)
        efx.draw(img, tg)
        draw_avatars(img, ar, st, X0, Y0, CP, hero=1, scale=2, hero_scale=2)
        if b < R0:
            return
        if b < W0:
            if b < T0:
                name_card(img, sk_[0], sk_[5], v.b(s_b0) + WIPE, tg)  # card lands after the wipe finishes
            elif b < E0:
                name_card(img, TRAILS[0][0], "TRAIL", v.b(T0), tg)
            elif eff_label[0]:
                name_card(img, eff_label[0], "CAPTURE EFFECT", eff_label[1], tg)
        else:
            name_card(img, "LIVING WOODLAND", "LEGENDARY BIOME", v.b(W0), tg)

    v.scene(G0, END, board, f"live 16x16 match with avatars; you loop home and claim (+N) under LOOP HOME, then your turf wears "
            f"{len(RARES4)} rare skins (2 beats each, fast wipe, then name card), {len(LEGENDS)} animated legendaries (2 beats each), "
            "a long Rainbow Streak trail, capture effects on each claim, then Living Woodland trees")
    v.flash(G0)
    v.sound(G0, "hit")
    for i in range(len(RARES4)):
        v.sound(R0 + i * RSTEP, "pop", i)
    for i in range(len(LEGENDS)):
        v.sound(L0 + i * LSTEP, "crown")
        v.flash(L0 + i * LSTEP, GOLD, 0.1)
    v.sound(T0, "whoosh")
    v.sound(W0, "levelup")
    v.flash(W0, (163, 207, 98), 0.15)
    v.caption(G0, R0, "LOOP HOME = IT'S YOURS", color=GREEN)
    v.caption(R0, L0, "RARE SKINS", color=RARE_BLUE, size=4)
    v.caption(L0, T0, "LEGENDARY. THEY MOVE.", color=GOLD)
    v.caption(T0, E0, "TRAILS", color=WHITE, size=4)
    v.caption(E0, E1, "CAPTURE EFFECTS", color=PINK)
    v.caption(W0, END, "YOUR TURF GROWS A FOREST", color=GREEN)

    # comment bait + end card
    def bait(img, tl, tg):
        bg_checker(img, tg, c1=(40, 30, 10), c2=(60, 46, 14), speed=20)
        draw_lines(img, "WHICH ONE ARE YOU GETTING?", 92, 3, YELLOW)
        allskins = [(n, a, c, p, None) for (n, a, c, p) in RARES4] + list(LEGENDS)
        for i, (n, a, c, p, an) in enumerate(allskins):
            col, row = i % 4, i // 4
            x, y = 21 + col * 60, 150 + row * 66
            k = ease_back(min(1.0, (tl - i * 0.04) / 0.25))
            if k <= 0:
                continue
            sz = int(50 * k)
            img.paste(skin_board(sz, sz, a, c, p, an, tg), (x + (50 - sz) // 2, y + (50 - sz) // 2))
            ImageDraw.Draw(img).rectangle((x - 1, y - 1, x + 50, y + 50), outline=GOLD if an else WHITE, width=2)
            draw_text(img, str(i + 1), x + 25, y + 15, 3, WHITE, DARK)
        draw_lines(img, "COMMENT A NUMBER", 320, 3, WHITE)

    v.scene(END, END + 3, bait, "comment bait: WHICH ONE ARE YOU GETTING? above all 8 skins tiled, COMMENT A NUMBER")
    v.sound(END, "hit")
    footer(v, 0, END + 3)
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
    draw_avatars(img, ar, t, x0, y0, cp, hero, kings, outfits, scale, hero_scale)


def draw_avatars(img, ar, t, x0, y0, cp, hero=None, kings=(), outfits=OUTFITS, scale=1, hero_scale=2, label=True):
    """Every live runner as its blocky avatar (YOU tag on the hero until its first claim)."""
    frac = max(0.0, min(1.0, (t - ar.t) / ar.dt))
    for r in sorted(ar.runners.values(), key=lambda r: r.y):
        if not r.alive:
            continue
        fx = r.px + (r.x - r.px) * frac
        fy = r.py + (r.y - r.py) * frac
        avatar(img, x0 + (fx + 0.5) * cp, y0 + (fy + 0.85) * cp, outfits.get(r.id, outfits[1]), t,
               moving=(r.px, r.py) != (r.x, r.y), s=hero_scale if r.id == hero else scale, king=r.id in kings,
               label="YOU" if r.id == hero and label and not getattr(r, "claims", 0) else None)


FOOT_Y = H - 47  # footer raised ~120 px (at 1080 wide) out of the TikTok/Shorts bottom UI


def footer(v, b0, b1):
    """Brand bar that says COMING SOON, matching the end card (graders flagged ON ROBLOX vs COMING SOON)."""
    def fn(img, t):
        ImageDraw.Draw(img).rectangle((0, FOOT_Y, W, FOOT_Y + 17), fill=(14, 16, 26))
        cols = [PLAYERS[j] for j in (0, 2, 4, 7, 0, 9, 11, 1, 5)]
        for i, ch in enumerate("TURF LOOP"):
            tim = text_img(ch, 2, cols[i], None)
            img.paste(tim, (10 + i * 12, FOOT_Y + 2), tim)
        draw_text(img, "COMING SOON", 128, FOOT_Y + 2, 2, CREAM, None, align="left")

    v.overlay(b0, b1, fn)


def rewind(v, b0, b1):
    """Visible REWIND cue: dark scanlines + << stamp + whoosh."""
    def fn(img, t):
        dark = Image.new("RGB", (W, H), (10, 10, 20))
        img.paste(Image.blend(img, dark, 0.45))
        d = ImageDraw.Draw(img)
        off = int(t * 240) % 6
        for y in range(off, H, 6):
            d.line((0, y, W, y), fill=(0, 0, 0))
        draw_text(img, "<< REWIND", W / 2, 220, 4, WHITE, DARK)

    v.overlay(b0, b1, fn)
    v.sound(b0, "whoosh")
    v.log.append(f"{v.b(b0):5.2f}-{v.b(b1):5.2f}s  REWIND cue: dark scanlines + << REWIND")


def match_scene(v, ar, x0, y0, cp, skins, trails=None, hero=1, kings=None, sim=None, view=None,
                scale=1, hero_scale=2, fx=None, on_event=None, bg=None, kozoom=True):
    """Scene fn for a skinned avatar match. sim(tl) -> sim time (preroll / slow-mo); view=(vw, vh) crops a camera
    that follows the hero (zoom = bigger cp). Claims by the hero pop +N with coins; cuts burst and K.O.-zoom."""
    fx = fx or FX()
    seen = [0]
    n = ar.n
    pops = []  # score pops on a dark chip (graders: yellow +N got lost on busy skins)
    cam = [x0, y0]

    def fn(img, tl, tg):
        (bg or bg_checker)(img, tg)
        st = sim(tl) if sim else tl
        ar.update(st)
        ks = kings(tg) if kings else ()
        if view:
            vw, vh = view
            off = Image.new("RGB", (n * cp, n * cp + cp), (14, 16, 26))
            skinned(off, ar, st, 0, cp, cp, skins, trails, hero, ks, scale=scale, hero_scale=hero_scale)
            r = ar.runners[hero]
            frac = max(0.0, min(1.0, (st - ar.t) / ar.dt))
            hx = (r.px + (r.x - r.px) * frac + 0.5) * cp
            hy = (r.py + (r.y - r.py) * frac + 0.5) * cp + cp
            ox = int(max(0, min(off.width - vw, hx - vw / 2)))
            oy = int(max(0, min(off.height - vh, hy - vh / 2)))
            img.paste(off.crop((ox, oy, ox + vw, oy + vh)), (x0, y0))
            ImageDraw.Draw(img).rectangle((x0 - 2, y0 - 2, x0 + vw + 1, y0 + vh + 1), outline=DARK, width=2)
            sx, sy = x0 - ox, y0 + cp - oy
        else:
            skinned(img, ar, st, x0, y0, cp, skins, trails, hero, ks, scale=scale, hero_scale=hero_scale)
            sx, sy = x0, y0
        cam[:] = [sx, sy]
        for (et, kind, data) in ar.events[seen[0]:]:
            cx, cy = sx + (data["at"][0] + 0.5) * cp, sy + (data["at"][1] + 0.5) * cp
            if kind == "claim" and data["cells"] > 0:
                if data["id"] == hero:
                    v.sfx.append((tg, "claim", min(12, data["cells"] / 6)))
                    fx.coins(cx, cy, min(24, 6 + data["cells"] // 4), tg)
                    pops[:] = [(min(W - 40, max(40, cx + 50 if cx + 50 < W - 40 else cx - 50)), max(y0 + 12, cy - 34), f"+{data['cells']}", tg)]
            elif kind == "cut":
                v.sfx.append((tg, "cut", 0))
                fx.burst(cx, cy, 30, tg, ar.runners[data["victim"]].color)
                if kozoom:
                    v.zooms = getattr(v, "zooms", []) + [[tg, cx, cy]]
            if on_event:
                on_event(kind, data, cx, cy, tg)
        seen[0] = len(ar.events)
        fx.draw(img, tg)
        for (px, py, txt, t0) in pops:
            age = tg - t0
            if 0 <= age < 1.0:
                tim = text_img(txt, 4 if age > 0.08 else 5, YELLOW, DARK)
                yy = int(py - ease_out(age / 0.4) * 14)
                ImageDraw.Draw(img).rectangle((px - tim.width // 2 - 4, yy - 3, px + tim.width // 2 + 4, yy + tim.height + 3),
                                              fill=(14, 16, 26), outline=DARK)
                img.paste(tim, (int(px - tim.width / 2), yy), tim)

    fn.cam = cam
    return fn


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
        logo(img, 22 - (1 - k) * 40, 4, tg)
        draw_lines(img, "COMING SOON TO ROBLOX", 92, 3, YELLOW, max_chars=12)  # 2 big lines
        img.paste(skin_board(200, 136, skin[0], skin[1], skin[2], skin[3], tg), (35, 130))
        ImageDraw.Draw(img).rectangle((34, 129, 235, 266), outline=GOLD, width=3)
        avatar(img, 110, 250, OUTFITS[1], tg, moving=True, s=4, king=True)
        avatar(img, 182, 254, OUTFITS[3], tg + 0.05, moving=True, s=3)
        ph = (tl / v.spb) % 1.0
        on = ph < 0.2  # pulse on every beat: button grows and the text flashes white
        g = 6 if on else 0
        ImageDraw.Draw(img).rectangle((14 - g, 290 - g, W - 15 + g, 368 + g), fill=YELLOW if on else GREEN, outline=DARK, width=3)
        draw_lines(img, line, 330, 3, DARK, WHITE if on else None, max_chars=12)

    v.scene(b0, b1, fn, "end card: logo, COMING SOON TO ROBLOX, two avatars (one crowned) on an animated skin pad, pulsing FOLLOW TO PLAY FIRST")
    v.sound(b0, "hit")
    v.sound(b0 + 0.02, "crown")


# ============================================================ s02 You're not a square anymore
def s02():
    v = Video("s02_avatar_hype", 108, 22, music=dict(mode="major", root=62, seed=88, prog=[0, 4, 5, 3], sections=[
        (0, 10.5, {"kick", "snare", "hat", "bass", "arp", "lead"}), (10.5, 11, set()),
        (11, 19, {"kick", "snare", "hat", "bass", "arp", "lead"}), (19, 22, {"kick", "snare", "hat", "bass", "lead"})]))

    # hook (R6): open ON the game: your avatar one beat from closing a loop (+N pops by 0.9 s); Paper.io callback on top.
    G = 0
    PRE = 22  # your loop is 4 steps from closing at frame 1
    dt = v.spb / 2.5
    ar = demo24(dt)
    pre = PRE * dt
    skins = {1: sk(LEGENDS, "NEON PULSE"), 2: ("#FFC83D", "#FF8A3D", "dots", None), 3: sk(RARES, "CANDY STRIPE")}
    trails = {1: ("#00F0FF", "#00F0FF", "stripes"), 3: ("#FF9ACB", "#FF9ACB", "stripes")}  # solid trails: line != turf
    claim_b, pink_go, ko_b, crown_b = (26 - PRE) / 2.5, (30 - PRE) / 2.5, (36 - PRE) / 2.5, (42 - PRE) / 2.5 + 0.5
    cam_game = match_scene(v, ar, 5, 122, 18, skins, trails, hero=1, sim=lambda tl: tl + pre, view=(260, 290),
                           scale=2, hero_scale=3, kings=lambda tg: (1,) if tg >= v.b(crown_b) else ())

    def game(img, tl, tg):
        cam_game(img, tl, tg)
        sx, sy = cam_game.cam
        b = tg / v.spb
        for rid, lab, b0, b1 in ((2, "DANGER!", G, claim_b), (3, "CUT IT!", pink_go, ko_b)):
            r = ar.runners[rid]
            if b0 <= b < b1 and r.alive:
                x, y = sx + (r.x + 0.5) * 18, sy + (r.y - 1.6) * 18
                if 10 < x < W - 10 and 128 < y < 400:
                    tim = text_img(lab, 2, WHITE, DARK)
                    xx = int(min(W - tim.width - 8, max(8, x - tim.width / 2)))
                    ImageDraw.Draw(img).rectangle((xx - 3, int(y) - 3, xx + tim.width + 3, int(y) + tim.height + 3), fill=RED, outline=DARK)
                    img.paste(tim, (xx, int(y)), tim)

    GL = 11
    v.scene(G, GL, game, "HOOK on the game: 24x24 match, camera zoomed 1.6x following YOU (Neon Pulse turf, solid cyan trail): your loop is 4 steps from "
            "closing (claim +N at ~0.9 s), yellow (DANGER! tag) arrives a beat too late, pink draws a trail (CUT IT! tag), you cut it (K.O.), claim again, crown")
    v.sound(0, "hit")
    v.caption(G, claim_b, "REMEMBER PAPER.IO?", color=YELLOW)
    v.stamp(claim_b, "MINE!", GREEN, y=372, beats=1.5, sound=None)
    v.caption(claim_b, pink_go, "LOOP HOME = IT'S YOURS", color=GREEN)
    v.caption(pink_go, ko_b, "CUT THEIR TRAIL = THEY'RE OUT", color=WHITE)
    v.stamp(ko_b, "K.O.!", RED, y=372, beats=1.5)
    v.caption(ko_b, crown_b, "LOOP HOME AGAIN", color=WHITE)
    v.caption(crown_b, GL, "MOST TURF = THE CROWN", color=YELLOW)
    v.stamp(crown_b, "KING!", YELLOW, y=372, beats=2, sound="crown")

    # payoff of the Paper.io line: the square grows and turns into your avatar
    M = GL

    def morph(img, tl, tg):
        bg_checker(img, tg, c1=(40, 18, 60), c2=(58, 26, 86), speed=30)
        sq = v.b(1.5)
        if tl < sq:
            sz = int(40 + 90 * tl / sq)
            ImageDraw.Draw(img).rectangle((W / 2 - sz / 2, 250 - sz / 2, W / 2 + sz / 2, 250 + sz / 2), fill=(90, 255, 140), outline=DARK, width=3)
        else:
            ph_ = (tl / v.spb) % 1.0
            avatar(img, W / 2, 330, OUTFITS[1], tg, moving=True, s=8 if ph_ < 0.18 or tl < sq + v.b(0.3) else 6)  # punch-in on every beat
            draw_lines(img, "YOUR ROBLOX AVATAR", 400, 3, YELLOW)

    v.scene(M, M + 3.5, morph, "hard cut: a green square grows (Paper.io), then morphs into a big blocky Roblox-style avatar (6x), walking in place")
    v.caption(M, M + 1.5, "PAPER.IO: A SQUARE.", color=WHITE)
    v.caption(M + 1.5, M + 3.5, "TURF LOOP: YOU'RE YOU.", color=YELLOW)
    v.flash(M, WHITE, 0.15)
    v.sound(M, "hit")
    v.flash(M + 1.5, WHITE, 0.15)
    v.sound(M + 1.5, "levelup")
    v.shake(M + 1.5, 0.35, 6)

    # your avatar + any skin (4 animated legendaries / rares at 1 beat each)
    S = M + 3.5
    fits = [("GALAXY SWIRL", sk(RARES, "GALAXY SWIRL"), "RARE"), ("MAGMA SURGE", sk(LEGENDS, "MAGMA SURGE"), "LEGENDARY"),
            ("PRISM STORM", sk(LEGENDS, "PRISM STORM"), "LEGENDARY"), ("STARFALL", sk(LEGENDS, "STARFALL"), "LEGENDARY")]

    def wardrobe(img, tl, tg):
        bg_checker(img, tg, speed=14)
        i = min(len(fits) - 1, int(tl / v.b(1)))
        name, s_, tier = fits[i]
        img.paste(skin_board(240, 170, s_[0], s_[1], s_[2], s_[3], tg), (15, 140))
        ImageDraw.Draw(img).rectangle((14, 139, 255, 310), outline=GOLD if tier == "LEGENDARY" else WHITE, width=3)
        avatar(img, W / 2, 285, OUTFITS[1], tg, moving=True, s=5, label="YOU")  # same you, only the skin changes
        name_card(img, name, tier, v.b(S + i), tg, y=330)

    v.scene(S, S + 4, wardrobe, "wardrobe: the same YOU avatar on a pad that swaps skin on every beat (Galaxy Swirl, Magma Surge, Prism Storm, Starfall)")
    v.caption(S, S + 4, "YOUR AVATAR. ANY SKIN.", color=YELLOW)
    for i in range(4):
        v.sound(S + i, "crown" if i else "pop")
        v.flash(S + i, WHITE, 0.08)
    footer(v, S, S + 4)
    avatar_end(v, S + 4, S + 7, skin=sk(LEGENDS, "MAGMA SURGE"))
    v.dur = v.b(S + 7)
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
    v = Video("s03_turf_pass_hype", 108, 33, music=dict(mode="minor", root=57, seed=99, prog=[0, 5, 2, 6], sections=[
        (0, 3, {"kick", "hat", "arp"}), (3, 29, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (29, 33, {"kick", "snare", "hat", "bass", "lead"})]))
    purple = dict(c1=(30, 10, 40), c2=(50, 16, 66))

    # hook: your avatar closes a loop in Prism Storm (tier-30 legendary) on beat 1
    hk = Arena(12, seed=2)
    hk.dt = v.spb / 4
    h0 = hk.add(1, hexc("#7C5CFF"), 3, 7, 3)
    h0.x, h0.y, h0.px, h0.py = 4, 7, 4, 7
    h0.script = path_from([(4, 7), (8, 7), (8, 3), (4, 3), (4, 6)])  # 14 steps, claim on step 14
    hk.add(2, PLAYERS[0], 9, 10, 3).reach = (1, 2)
    hook = match_scene(v, hk, 3, 126, 22, {1: sk(LEGENDS, "PRISM STORM"), 2: sk(RARES, "CHERRY DOTS")},
                       {1: ("#7C5CFF", "#FFFFFF", "hex")}, hero=1, sim=lambda tl: tl + 10 * hk.dt,
                       scale=2, hero_scale=3, bg=lambda img, tg: bg_checker(img, tg, speed=24, **purple))

    def hook_fn(img, tl, tg):
        fl = v.b(1.5)
        if tl < fl:  # R5: open on a full-frame flash of the 4 animated legendaries, big avatar, TURF LOOP badge
            n_, a_, b_, p_, an_ = LEGENDS[min(3, int(tl / (fl / 4)))]
            img.paste(skin_board(W, 300, a_, b_, p_, an_, tg), (0, 100))
            ImageDraw.Draw(img).rectangle((0, 99, W, 401), outline=GOLD, width=3)
            avatar(img, W / 2, 380, OUTFITS[1], tg, moving=True, s=7)
            draw_text(img, n_, W / 2, 150, 3, GOLD, DARK)
            ImageDraw.Draw(img).rectangle((6, 108, 112, 128), fill=(14, 16, 26))
            draw_text(img, "TURF LOOP", 10, 112, 2, WHITE, None, align="left")
        else:
            hook(img, tl - fl, tg)
            draw_text(img, "TIER 30: PRISM STORM", W / 2, 396, 2, GOLD, DARK)

    v.scene(0, 3, hook_fn, "HOOK: 1.5 beats of full-frame animated legendaries with your avatar and a TURF LOOP badge, then your avatar closes a loop and its turf fills with PRISM STORM (+N pop)")
    v.caption(0, 3, "FREE TRACK + 4 LEGENDARIES", y=62, size=3, color=YELLOW)
    v.sound(0, "hit")
    for i in range(1, 4):
        v.sound(i * 0.375, "pop")
    v.sound(2.5, "crown")

    # the pass track (R5): one big centred card per stop (tiers 1, 10, 20, 30), no scrolling ticker
    stops = [1, 10, 20, 30]
    SB = 2.25  # beats per stop
    arrivals = [3 + SB * i for i in range(4)]

    def track(img, tl, tg):
        b = tg / v.spb
        bg_checker(img, tg, speed=10, **purple)
        i = min(3, int((b - 3) / SB))
        tier = stops[i]
        into = b - arrivals[i]
        free, prem = PASS_TRACK[tier - 1]
        d = ImageDraw.Draw(img)
        img.paste(Image.new("RGBA", (W, 26), (255, 200, 61, 255)), (0, 112))
        draw_text(img, "SEASON 1: NEON RUSH", W / 2, 118, 2, DARK, None)
        k = ease_back(min(1.0, into / 0.4))
        draw_text(img, "TIER %d" % tier, W / 2, 146, max(3, int(5 * k)), WHITE, DARK)
        draw_text(img, "FREE: " + free.upper(), W / 2, 187, 2, GREEN, DARK)
        d.rectangle((14, 205, W - 15, 217), fill=(14, 16, 26), outline=DARK, width=2)  # 30-tier progress bar
        pf = (stops[i - 1] if i else 0) + (tier - (stops[i - 1] if i else 0)) * ease_out(min(1.0, into / 0.5))
        d.rectangle((16, 207, 16 + int((W - 32) * pf / 30), 215), fill=GOLD)
        s_ = sk(LEGENDS, prem.split(" ", 1)[1])
        img.paste(skin_board(220, 100, s_[0], s_[1], s_[2], s_[3], tg), (25, 228))
        d.rectangle((24, 227, 245, 329), outline=GOLD, width=3)
        avatar(img, W / 2, 320, OUTFITS[1], tg, moving=True, s=3)
        draw_text(img, "PREMIUM", 30, 232, 1, GOLD, DARK, align="left")
        name_card(img, prem.split(" ", 1)[1], "TIER %d LEGENDARY" % tier, v.b(arrivals[i]), tg, y=350)

    v.scene(3, 12, track, "battle pass: one big centred card per stop at tiers 1, 10, 20, 30 (TIER N slams in, 30-tier bar fills, the animated "
            "premium legendary with your avatar and a name card)")
    v.flash(3)
    for a in arrivals:
        v.sound(a, "crown")
        v.flash(a, GOLD, 0.1)
        v.sound(a - 0.02, "whoosh")
    v.caption(3, 5.25, "TURF PASS. SEASON 1.", color=GOLD)
    v.caption(5.25, 7.5, "30 TIERS. FREE + PREMIUM.", color=WHITE)
    v.caption(7.5, 12, "4 ANIMATED LEGENDARIES", color=GOLD)

    # a trail cut: a visible threat + K.O. (R4: s03 had no gameplay threat)
    K = 12
    kdt = v.spb / 2
    kar = demo24(kdt)
    kpre = 32 * kdt  # pink has drawn two trail cells at frame 1; you cut it 4 steps later
    kcam = match_scene(v, kar, 5, 112, 18, {1: sk(LEGENDS, "PRISM STORM"), 2: ("#FFC83D", "#FF8A3D", "dots", None), 3: sk(RARES, "CHERRY DOTS")},
                       {1: ("#7C5CFF", "#FFFFFF", "hex"), 3: ("#FF9ACB", "#FF9ACB", "stripes")}, hero=1, sim=lambda tl: tl + kpre,
                       view=(260, 290), scale=2, hero_scale=3, bg=lambda img, tg: bg_checker(img, tg, speed=24, **purple))

    def kgame(img, tl, tg):
        kcam(img, tl, tg)
        sx, sy = kcam.cam
        r = kar.runners[3]
        if tg < v.b(K + 2) and r.alive:
            x, y = sx + (r.x + 0.5) * 18, sy + (r.y - 1.6) * 18
            if 10 < x < W - 10 and 128 < y < 400:
                tim = text_img("CUT IT!", 2, WHITE, DARK)
                xx = int(min(W - tim.width - 8, max(8, x - tim.width / 2)))
                ImageDraw.Draw(img).rectangle((xx - 3, int(y) - 3, xx + tim.width + 3, int(y) + tim.height + 3), fill=RED, outline=DARK)
                img.paste(tim, (xx, int(y)), tim)

    v.scene(K, K + 4, kgame, "trail cut: you (Prism Storm turf) loop past pink who is drawing a trail (CUT IT! tag); you cut it, K.O. (freeze + zoom)")
    v.sound(K, "hit")
    v.caption(K, K + 2, "CUT A TRAIL...", color=WHITE)
    v.caption(K + 2, K + 4, "...THEY'RE OUT", color=YELLOW)
    v.stamp(K + 2, "K.O.!", RED, y=372, beats=1.5)

    # daily missions -> XP
    def missions(img, tl, tg):
        bg_checker(img, tg, speed=10, **purple)
        d = ImageDraw.Draw(img)
        d.rectangle((3, 110, W - 4, 340), fill=(26, 30, 46), outline=GOLD, width=3)
        draw_text(img, "DAILY MISSIONS", W / 2, 120, 3, GOLD, DARK)
        rows = [("LOOP 3 TIMES", "+150 XP"), ("CUT 1 TRAIL", "+100 XP"), ("CLAIM 20%", "+200 XP")]
        for i, (task, xp) in enumerate(rows):
            y = 156 + i * 46
            done = tl > v.b(0.25 + i * 0.5)
            d.rectangle((24, y + 4, 50, y + 30), fill=GREEN if done else (50, 54, 70), outline=DARK, width=2)
            if done:
                d.line([(29, y + 17), (35, y + 24), (46, y + 9)], fill=WHITE, width=3)
            draw_text(img, task, 60, y + 2, 2, WHITE, DARK, align="left")
            draw_text(img, xp, 60, y + 20, 2, GREEN if done else CREAM, DARK, align="left")
        fill = min(1.0, max(0.0, (tl - v.b(0.25)) / v.b(1.5)))
        d.rectangle((24, 300, W - 25, 324), fill=(14, 16, 26), outline=DARK, width=2)
        d.rectangle((26, 302, 26 + int((W - 53) * fill), 322), fill=YELLOW)
        draw_text(img, "XP", W / 2, 305, 2, DARK if fill > 0.5 else WHITE, None)
        if fill >= 1:
            draw_text(img, "TIER UP!", W / 2, 352, 5, YELLOW, DARK)

    v.scene(K + 4, K + 6, missions, "daily missions panel: 3 missions tick off on the beat (+150/+100/+200 XP), the XP bar fills, TIER UP!")
    v.caption(K + 4, K + 6, "EARN XP FROM DAILY MISSIONS", color=GREEN)
    for i in range(3):
        v.sound(K + 4.25 + i * 0.5, "coin")
    v.sound(K + 5.75, "levelup")

    # limited-time events: Crown Rush weekend + 2x coins weekend
    E = K + 6
    ar = Arena(16, seed=41)
    ar.dt = v.spb / 4
    h = ar.add(1, PLAYERS[7], 8, 9, 5)
    h.hungry, h.reach, h.shield = True, (3, 5), True
    for i, (x, y) in enumerate(((3, 3), (13, 3), (3, 13))):
        ar.add(i + 2, PLAYERS[(i * 4 + 2) % 12], x, y, 3).reach = (2, 3)
    skins = {1: sk(LEGENDS, "STARFALL"), 2: sk(RARES, "CHERRY DOTS"), 3: sk(RARES, "OCEAN WAVES"), 4: ("#4ADE80", "#B6E33B", "waves", None)}
    fx = FX()
    rush_trail = ("#FFC83D", "#2B2F3A", "stars")
    trails = {}
    gold = dict(c1=(40, 30, 10), c2=(60, 46, 14))

    def on_ev(kind, data, cx, cy, tg):
        if kind == "claim" and data["id"] == 1:
            fx.coins(cx, cy, 22 if tg >= v.b(E + 6) else 10, tg)
            v.sfx.append((tg, "coin", 0))

    match = match_scene(v, ar, 15, 112, 15, skins, trails, hero=1, kings=lambda tg: (1,), scale=2, hero_scale=2,
                        on_event=on_ev, kozoom=False, bg=lambda img, tg: bg_checker(img, tg, speed=16, **gold))

    def events(img, tl, tg):
        b = tg / v.spb
        if b >= E + 5:
            trails[1] = rush_trail
        match(img, tl, tg)
        if b >= E + 6:  # coin rain
            rng = random.Random(int(tg * 30))
            for _ in range(2):
                fx.coins(rng.uniform(10, W - 10), 120, 1, tg)
        fx.draw(img, tg)
        if b < E + 4.5:  # crown hold timer (fast-forwarded)
            held = min(300, int(max(0.0, tg - v.b(E + 0.5)) / v.b(4) * 300))
            draw_text(img, f"CROWN HELD {held // 60}:{held % 60:02d} / 5:00", W / 2, 362, 2, GOLD, DARK)
            draw_text(img, "FAST FORWARD >>", W / 2, 382, 1, CREAM, None)
        elif b < E + 6:
            draw_text(img, "CROWN RUSH TRAIL", W / 2, 362, 2, GOLD, DARK)
            draw_text(img, "LIMITED EVENT TRAIL", W / 2, 388, 2, WHITE, DARK)
        else:
            draw_text(img, "2X COINS", W / 2, 362, 4, YELLOW, DARK, 2)

    v.scene(E, E + 9, events, "events: CROWN RUSH weekend on a 16x16 board with avatars (you are King, crown timer fast-forwards to 5:00 -> "
            "limited Crown Rush Trail appears on your trail), then 2X COINS weekend with coin rain")
    v.flash(E)
    v.sound(E, "hit")
    v.caption(E, E + 1.5, "LIMITED-TIME EVENTS", color=RED)
    v.caption(E + 1.5, E + 3.5, "CROWN RUSH: KING EARNS 2X", color=GOLD)
    v.caption(E + 3.5, E + 6, "HOLD THE CROWN 5 MIN = LIMITED TRAIL", color=GOLD)
    v.stamp(E + 5, "LIMITED TRAIL!", GOLD, y=300, beats=1, size=4, sound="levelup")
    v.caption(E + 6, E + 9, "WEEKENDS = 2X COINS", color=YELLOW)
    v.sound(E + 6, "coin")
    v.sound(E + 6.5, "coin")

    def last(img, tl, tg):
        bg_checker(img, tg, speed=24, **purple)
        for i, (n, a, b2, p, an) in enumerate(LEGENDS):
            x = 18 + i * 60
            img.paste(skin_board(52, 60, a, b2, p, an, tg), (x, 140))
            ImageDraw.Draw(img).rectangle((x - 1, 139, x + 52, 200), outline=GOLD, width=2)
            draw_text(img, str(i + 1), x + 26, 144, 4, WHITE, DARK)
            avatar(img, x + 26, 196, OUTFITS[1 + i % 4], tg + i * 0.05, moving=True, s=1)
            draw_text(img, n.split(" ")[0], x + 26, 206, 1, GOLD, None)
        ImageDraw.Draw(img).rectangle((12, 244, W - 13, 276), fill=RED, outline=DARK, width=2)
        draw_text(img, "14 DAYS PER SEASON", W / 2, 254, 2, WHITE, DARK)
        draw_lines(img, "SEASON 1 STARTS AT LAUNCH", 330, 3, YELLOW)

    v.scene(E + 9, E + 12, last, "all 4 legendaries animating with an avatar on each, 14 DAYS PER SEASON, SEASON 1 STARTS AT LAUNCH")
    v.caption(E + 9, E + 12, "WHICH ARE YOU GRINDING FOR? COMMENT 1-4", color=WHITE)
    footer(v, E + 9, E + 12)
    avatar_end(v, E + 12, E + 15, skin=sk(LEGENDS, "PRISM STORM"))
    v.dur = v.b(E + 15)
    return v


# ============================================================ s04 1 cell from home (idea #8)
def s04():
    v = Video("s04_one_cell", 108, 24, music=dict(mode="major", root=60, seed=123, prog=[0, 5, 3, 4], sections=[
        (0, 1.75, {"kick", "hat", "arp"}), (1.75, 5, {"kick", "arp"}), (5, 20, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (20, 24, {"kick", "snare", "hat", "bass", "lead"})]))
    dt = v.spb / 4
    X0, Y0, CP = 9, 112, 18  # 14 x 18 = 252 px board
    skins = {1: sk(LEGENDS, "MAGMA SURGE"), 2: ("#FFC83D", "#FF8A3D", "dots", None)}
    trails = {1: ("#FFC83D", "#E8361A", "stripes")}

    def take(second, d):
        ar = Arena(14, seed=8)
        ar.dt = d
        h = ar.add(1, hexc("#E8361A"), 3, 10, 4)  # home turf x 1-4, y 8-11
        h.x, h.y, h.px, h.py = 4, 8, 4, 8
        h.respawn = False
        if second:  # go home early (claim on step 22), then cut yellow's trail (step 28), loop home again
            h.script = path_from([(4, 8), (4, 3), (10, 3), (10, 7), (4, 7), (4, 8), (4, 10), (8, 10), (8, 11), (4, 11)])
        else:  # the big loop: one cell from home on step 22, yellow steps on the trail that same step
            h.script = path_from([(4, 8), (4, 3), (10, 3), (10, 9), (5, 9)]) + deque([(5, 9)] * 5) + deque([(4, 9)])  # stalls one cell from home
        y = ar.add(2, PLAYERS[2], 8, 13, 3)
        y.script = deque([(8, 13)] * (18 if second else 21)) + path_from([(8, 13), (8, 8), (11, 8), (11, 6)])
        y.respawn = False
        return ar

    # ---------- take 1: so close (slow-mo on the last steps, cut lands at 0.97 s) ----------
    a1 = take(False, dt)
    pre = 22 * dt  # frame 0: YOU already stands one cell from home

    def slow(tl):
        return pre + tl / 2.5

    ko_b = 1.75  # K.O. lands at ~0.97 s (yellow steps on the trail ~3 slow steps in)
    ghost = []
    ZC = 26  # hook camera: ~2x zoom on the gap
    def on1(kind, data, cx, cy, tg):
        if kind == "cut" and data["victim"] == 1:
            ghost[:] = [cx, cy, tg]

    t1 = match_scene(v, a1, 5, 112, ZC, skins, trails, hero=1, sim=slow, view=(260, 262), scale=3, hero_scale=3, on_event=on1)

    def take1(img, tl, tg):
        t1(img, tl, tg)
        if ghost:  # grey ghost of YOU drifts up from the cut
            gx, gy, g0 = ghost
            a_ = tg - g0
            if a_ >= 0:
                avatar(img, gx, gy - a_ * 30, (150, 154, 170, 0) if False else ((170, 174, 190), (120, 124, 140), (140, 144, 160), (110, 114, 130)), tg, moving=False, s=3)
                d_ = ImageDraw.Draw(img)
                d_.line((gx - 22, gy - 40, gx + 22, gy + 4), fill=RED, width=6)  # explicit X: you're out
                d_.line((gx + 22, gy - 40, gx - 22, gy + 4), fill=RED, width=6)
        if tg >= v.b(0.5):  # R4: plate before the K.O.
            ImageDraw.Draw(img).rectangle((20, 124, W - 21, 146), fill=(14, 16, 26), outline=RED, width=2)
            draw_text(img, "TRAIL HIT = OUT", W / 2, 128, 2, RED, WHITE if ghost else None)
        if tg < v.b(ko_b):  # pulsing bracket on the one home cell you still need
            sx, sy = t1.cam
            hx, hy = sx + 4 * ZC, sy + 9 * ZC
            g = 4 if int(tg * 6) % 2 else 0
            d = ImageDraw.Draw(img)
            d.rectangle((hx - g, hy - g, hx + ZC - 1 + g, hy + ZC - 1 + g), outline=WHITE, width=5)
            d.polygon([(hx + ZC / 2, hy + ZC + 4), (hx + ZC / 2 - 13, hy + ZC + 24), (hx + ZC / 2 + 13, hy + ZC + 24)], fill=WHITE, outline=DARK)
            draw_text(img, "1 CELL", max(75, min(W - 75, hx + ZC / 2)), hy + ZC + 30, 5, WHITE, DARK)
            yl = a1.runners[2]  # red danger arrow above yellow's path, pointing up at your trail
            if yl.alive:
                ax, ay = sx + (yl.x + 0.5) * ZC, sy + (yl.y - 1.1) * ZC
                d.polygon([(ax, ay - 24), (ax - 14, ay), (ax + 14, ay)], fill=RED, outline=DARK)
                d.rectangle((ax - 5, ay, ax + 5, ay + 14), fill=RED, outline=DARK)

    v.scene(0, 4, take1, "HOOK: camera zoomed ~2x on the gap: your avatar (Magma Surge turf) is ONE cell from home (pulsing bracket + "
            "'1 CELL' arrow on that cell); yellow walks up toward your trail; slow-mo; yellow steps on your trail at 0.97 s -> K.O. (freeze + zoom), your turf vanishes")
    v.caption(0, ko_b, "1 CELL FROM HOME...", y=58, size=3, color=YELLOW)
    v.stamp(ko_b, "SO CLOSE.", RED, y=400, beats=2.25, sound=None)
    v.sound(ko_b + 0.1, "fail")
    v.caption(ko_b, 4, "WE'VE ALL BEEN HERE.", y=58, size=3, color=WHITE)

    # ---------- take 2: rewind, go home first, then get revenge ----------
    dt2 = v.spb / 3  # take 2 a little slower so the claim and the revenge get room
    a2 = take(True, dt2)
    efx = Effects()
    W2 = 4

    def on2(kind, data, cx, cy, tg):
        if kind == "claim" and data["id"] == 1 and data["cells"] > 10:
            efx.fire("FIREWORKS", cx, cy, tg, (X0 + 20, Y0 + 20, X0 + 232, Y0 + 232))
            v.sfx.append((tg, "levelup", 0))

    t2 = match_scene(v, a2, X0, Y0, CP, skins, trails, hero=1, sim=lambda tl: 10 * dt2 + tl, scale=2, hero_scale=2,
                     on_event=on2, kings=lambda tg: (1,) if tg >= v.b(W2 + 6) else ())

    def take2(img, tl, tg):
        t2(img, tl, tg)
        efx.draw(img, tg)

    v.scene(W2, W2 + 8.5, take2, "take 2 after a REWIND: same board, you head home early -> claim (+N, Fireworks capture effect), "
            "then cut yellow's trail (K.O.), loop home again, crowned")
    rewind(v, W2, W2 + 1)
    v.flash(W2 + 1)
    v.sound(W2 + 1, "hit")
    v.caption(W2 + 1, W2 + 4, "TAKE 2: GO HOME FIRST", color=GREEN)
    v.stamp(W2 + 4, "MINE!", GREEN, y=400, beats=1.5, sound=None)
    v.caption(W2 + 4, W2 + 6, "DRAW A LOOP. CLAIM THE TURF.", color=GREEN)
    v.stamp(W2 + 6, "REVENGE!", RED, y=400, beats=1.5)
    v.caption(W2 + 6, W2 + 8.5, "CUT THEIR TRAIL = THEY'RE OUT", color=RED)

    # ---------- lose a round, keep your skins (Turf Pass legendaries) ----------
    S = W2 + 8.5
    fits = [("MAGMA SURGE", "TIER 10 LEGENDARY"), ("NEON PULSE", "TIER 1 LEGENDARY"),
            ("STARFALL", "TIER 20 LEGENDARY"), ("PRISM STORM", "TIER 30 LEGENDARY")]

    def wardrobe(img, tl, tg):
        bg_checker(img, tg, speed=14)
        i = min(len(fits) - 1, int(tl / v.b(0.5)))
        name, tier = fits[i]
        s_ = sk(LEGENDS, name)
        img.paste(skin_board(240, 170, s_[0], s_[1], s_[2], s_[3], tg), (15, 140))
        ImageDraw.Draw(img).rectangle((14, 139, 255, 310), outline=GOLD, width=3)
        avatar(img, W / 2, 285, OUTFITS[1], tg, moving=True, s=5, label="YOU")
        draw_text(img, "TURF PASS LEGENDARIES", W / 2, 120, 2, GOLD, DARK)
        name_card(img, name, tier, v.b(S + i * 0.5), tg, y=330)

    v.scene(S, S + 2, wardrobe, "the same YOU avatar on a pad swapping animated legendaries every half beat, each labelled with its Turf Pass tier")
    v.caption(S, S + 2, "LOSE A ROUND. KEEP YOUR SKINS.", color=YELLOW)
    for i in range(4):
        v.sound(S + i * 0.5, "crown" if i else "pop")
        v.flash(S + i * 0.5, WHITE, 0.08)

    # ---------- comment bait ----------
    B = S + 2

    def bait(img, tl, tg):
        bg_checker(img, tg, speed=20)
        draw_lines(img, "WHAT'S YOUR CLOSEST CALL?", 100, 3, YELLOW)
        d = ImageDraw.Draw(img)
        y = 200
        img.paste(skin_board(54, 54, *sk(LEGENDS, "MAGMA SURGE")[:3], "flow", tg), (24, y))  # home
        d.rectangle((23, y - 1, 78, y + 54), outline=WHITE, width=2)
        draw_text(img, "HOME", 51, y + 60, 2, WHITE, DARK)
        for i in range(4):  # trail cells, the gap is the first one
            x = 84 + i * 42
            d.rectangle((x, y + 12, x + 36, y + 42), fill=(232, 54, 26) if i else (60, 64, 78), outline=DARK, width=2)
        avatar(img, 105, y + 40, OUTFITS[1], tg, moving=True, s=2)
        if int(tl / v.spb * 2) % 2 == 0:  # blinking gap cell
            d.rectangle((84, y + 12, 120, y + 42), fill=WHITE, outline=RED, width=3)
        ImageDraw.Draw(img).rectangle((20, y - 34, W - 21, y - 2), fill=(14, 16, 26), outline=RED, width=2)
        draw_text(img, "? CELLS", W / 2, y - 28, 3, RED, WHITE)
        ImageDraw.Draw(img).rectangle((10, 326, W - 11, 374), fill=(14, 16, 26), outline=DARK, width=2)
        draw_lines(img, "COMMENT HOW MANY CELLS", 332, 3, WHITE)

    v.scene(B, B + 2.5, bait, "comment bait: WHAT'S YOUR CLOSEST CALL? a home pad, a 1-cell gap with your avatar, COMMENT HOW MANY CELLS")
    v.sound(B, "hit")
    avatar_end(v, B + 2.5, B + 6.5, skin=sk(LEGENDS, "MAGMA SURGE"))
    v.dur = v.b(B + 6.5)
    return v


# ============================================================ s05 Head-On (idea #9)
def s05():
    v = Video("s05_head_on", 108, 22, music=dict(mode="minor", root=59, seed=205, prog=[0, 5, 3, 6], sections=[
        (0, 5, {"kick", "hat", "arp", "bass"}), (5, 6.5, {"kick", "arp"}), (6.5, 18, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (18, 22, {"kick", "snare", "hat", "bass", "lead"})]))
    N, CP, X0, Y0 = 16, 16, 7, 112
    skins = {1: sk(LEGENDS, "NEON PULSE"), 2: sk(RARES, "CANDY STRIPE")}
    trails = {1: ("#00F0FF", "#00F0FF", "stripes"), 2: ("#FF9ACB", "#FF9ACB", "stripes")}
    outf = dict(OUTFITS)

    def take(second, d):
        ar = Arena(N, seed=5)
        ar.dt = d
        h = ar.add(1, PLAYERS[7], 3, 10, 4)  # home x 1-4, y 8-11
        h.x, h.y, h.px, h.py = 4, 8, 4, 8
        h.respawn, h.after_script, h.shield = False, "idle", False
        r = ar.add(2, PLAYERS[11], 13, 10, 4)  # home x 11-14, y 8-11
        r.x, r.y, r.px, r.py = 11, 8, 11, 8
        r.respawn, r.after_script = False, "idle"
        if not second:  # both race up and along y=4 straight at each other
            h.script = path_from([(4, 8), (4, 4), (7, 4)])
            r.script = path_from([(11, 8), (11, 4), (8, 4)])

            def both_out(a):
                if a.steps == 7:  # same step: their heads meet, both trails hit
                    for x, y in ((1, 2), (2, 1)):
                        if a.runners[x].alive:
                            a.kill(a.runners[x], a.runners[y])
            ar.after_step = both_out
        else:  # you loop home first (claim at step 13), then cut their trail (step 18)
            h.script = path_from([(4, 8), (4, 5), (7, 5), (7, 9), (4, 9), (7, 9), (7, 10), (8, 10)])
            r.script = path_from([(11, 8), (11, 4), (8, 4), (8, 10), (10, 10), (10, 11)])
        return ar

    # ---------- take 1: head-on, both out ----------
    dt1 = v.spb / 2
    a1 = take(False, dt1)
    ko1 = 1.5  # beats: 3 steps after frame 1
    c1 = match_scene(v, a1, X0, Y0, CP, skins, trails, hero=1, sim=lambda tl: tl + 4 * dt1, scale=2, hero_scale=2)

    def hook(img, tl, tg):
        c1(img, tl, tg)
        sx, sy = c1.cam
        if tg < v.b(ko1):
            b = tg / v.spb
            if int(b * 4) % 2 == 0:  # pulsing VS between the two trails
                draw_text(img, "VS", sx + 8 * CP, sy + 2.2 * CP, 4, RED, DARK)
            r = a1.runners[2]
            if r.alive:
                x = min(W - 40, max(40, sx + (r.x + 0.5) * CP))
                ImageDraw.Draw(img).rectangle((x - 30, sy + (r.y - 1.7) * CP - 3, x + 30, sy + (r.y - 1.7) * CP + 17), fill=RED, outline=DARK)
                draw_text(img, "THEM", x, sy + (r.y - 1.7) * CP, 2, WHITE, None)

    v.scene(0, 5, hook, "HOOK: 16x16 board, your avatar (Neon Pulse, YOU) and a rival (Candy Stripe, THEM) both have 4 trail cells and run straight "
            "at each other along one row; their heads meet on the same step: both K.O. (freeze + zoom) and both turfs vanish")
    v.sound(0, "hit")
    v.caption(0, ko1, "WHO WINS?", y=58, size=4, color=YELLOW)
    v.stamp(ko1, "DRAW.", WHITE, y=372, beats=3, sound="fail")
    v.caption(ko1, 5, "BOTH TRAILS HIT = BOTH OUT", color=WHITE)

    # ---------- take 2: don't race, loop home first ----------
    W2 = 5
    dt2 = v.spb / 3
    a2 = take(True, dt2)
    efx = Effects()

    def on2(kind, data, cx, cy, tg):
        if kind == "claim" and data["id"] == 1 and data["cells"] > 10:
            efx.fire("FIREWORKS", cx, cy, tg, (X0 + 20, Y0 + 20, X0 + 232, Y0 + 232))
            v.sfx.append((tg, "levelup", 0))

    t2 = match_scene(v, a2, X0, Y0, CP, skins, trails, hero=1, sim=lambda tl: tl + 4 * dt2, scale=2, hero_scale=2,
                     on_event=on2, kings=lambda tg: (1,) if tg >= v.b(W2 + 6.5) else ())

    def take2(img, tl, tg):
        t2(img, tl, tg)
        efx.draw(img, tg)

    v.scene(W2, W2 + 8.5, take2, "take 2 after a REWIND: same board, you skip the race and loop home first (claim +N, Fireworks), then cut the "
            "rival's trail (K.O.), crowned")
    rewind(v, W2, W2 + 1)
    v.flash(W2 + 1)
    v.sound(W2 + 1, "hit")
    v.caption(W2 + 1, W2 + 3, "TAKE 2: DON'T RACE", color=GREEN)
    v.stamp(W2 + 3, "MINE!", GREEN, y=372, beats=1.5, sound=None)
    v.caption(W2 + 3, W2 + 4.67, "DRAW A LOOP. CLAIM THE TURF.", color=GREEN)
    v.stamp(W2 + 4.67, "K.O.!", RED, y=372, beats=1.8)
    v.caption(W2 + 4.67, W2 + 6.5, "CUT THEIR TRAIL = OUT", color=WHITE)
    v.stamp(W2 + 6.5, "WINNER!", YELLOW, y=372, beats=2, sound="crown")
    v.caption(W2 + 6.5, W2 + 8.5, "FIRST HOME WINS", color=YELLOW)

    # ---------- bait + end ----------
    B = W2 + 8.5

    def bait(img, tl, tg):
        bg_checker(img, tg, speed=20)
        ImageDraw.Draw(img).rectangle((10, 90, W - 11, 160), fill=(14, 16, 26), outline=DARK, width=2)
        draw_lines(img, "HEAD-ON. WHO WINS?", 96, 3, YELLOW)
        sh = 5 if int(tl / v.spb * 2) % 2 == 0 else 0
        avatar(img, 62 + sh, 300, OUTFITS[1], tg, moving=True, s=5, label="YOU")
        avatar(img, 208 - sh, 300, OUTFITS[3], tg + 0.05, moving=True, s=5, label="THEM")
        draw_text(img, "VS", W / 2, 230, 5, RED, DARK)
        ImageDraw.Draw(img).rectangle((10, 336, W - 11, 396), fill=(14, 16, 26), outline=DARK, width=2)
        draw_lines(img, "COMMENT: DRAW OR WIN?", 342, 3, WHITE)

    v.scene(B, B + 3, bait, "comment bait: YOU vs THEM avatars bobbing toward each other, 'HEAD-ON. WHO WINS?', 'COMMENT: DRAW OR WIN?'")
    v.sound(B, "hit")
    footer(v, B, B + 3)
    avatar_end(v, B + 3, B + 7, skin=sk(LEGENDS, "NEON PULSE"))
    v.dur = v.b(B + 7)
    return v


ALL = {"s01": s01, "s02": s02, "s03": s03, "s04": s04, "s05": s05}

if __name__ == "__main__":
    for n in sys.argv[1:] or list(ALL):
        print("rendered", ALL[n]().render(OUT, SHEETS))

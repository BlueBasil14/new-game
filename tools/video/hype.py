"""Hype shorts with the full cosmetic line-up (owner request 2026-11-20: Paper.io callback, every kind of skin and
animation, super hype, a little slower than v01-v07). Usage: py tools/video/hype.py s01
Skins, trails and effects mirror src/shared/Catalog.luau (names, colours, patterns, animations)."""
import colorsys
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
    col = GOLD if tier == "LEGENDARY" else (RARE_BLUE if tier == "RARE" else GREEN)
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
    end_card(v, END + 3, END + 7, "COMING SOON TO ROBLOX", " ", "FOLLOW TO PLAY FIRST")
    v.dur = v.b(END + 7)
    return v


ALL = {"s01": s01}

if __name__ == "__main__":
    for n in sys.argv[1:] or list(ALL):
        print("rendered", ALL[n]().render(OUT, SHEETS))

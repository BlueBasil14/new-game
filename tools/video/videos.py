"""Turf Loop shorts. Usage: py tools/video/videos.py v01 v03   (no args = all). Ideas: marketing/videos/IDEAS.md
Round 2 (2026-11-19): reworked v01-v05 from the round-1 grader fixes (marketing/videos/GRADES.md)."""
import os
import sys
from collections import deque

from PIL import Image, ImageDraw, ImageOps

sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa: E402,F403
import hype  # noqa: E402,F401  (registers the promo-code card after every end card)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "marketing", "videos", "out")
SHEETS = os.path.join(ROOT, "marketing", "videos", "sheets")


def place(r, x, y):
    r.x, r.y, r.px, r.py = x, y, x, y


def waits(r, n):
    return deque([(r.x, r.y)] * n)


def run_events(make, seconds):
    """Pre-run a deterministic arena to learn when claims/cuts happen (for caption timing)."""
    ar = make()
    ar.update(seconds)
    return ar


def king_updater(ar):
    best = max((r for r in ar.runners.values() if r.alive), key=lambda r: ar.cells(r.id), default=None)
    for r in ar.runners.values():
        r.king = r is best and ar.share(r.id) >= 0.03


def bots(ar, n, start_id, reach=(2, 5), seed_cells=None):
    spots = seed_cells or [(5, 5), (ar.n - 6, 5), (5, ar.n - 6), (ar.n - 6, ar.n - 6), (ar.n // 2, 4),
                           (ar.n // 2, ar.n - 5), (4, ar.n // 2), (ar.n - 5, ar.n // 2)]
    out = []
    for i in range(n):
        x, y = spots[i % len(spots)]
        r = ar.add(start_id + i, PLAYERS[(start_id + i * 3) % len(PLAYERS)], x, y, 3)
        r.reach = reach
        out.append(r)
    return out


# ------------------------------------------------------------ shared scripted demo (claim -> K.O. -> crown)
DEMO_CLAIM, DEMO_CUT, DEMO_CLAIM2 = 26, 36, 42  # steps (4 per beat)


def demo_arena(dt):
    """24x24 scripted match: you leave turf, draw a big loop (yellow arrives just too late), claim at step 26,
    then cut pink's trail at step 36 (K.O.) and claim again at step 42."""
    ar = Arena(24, seed=3)
    ar.dt = dt
    h = ar.add(1, PLAYERS[7], 6, 14, 5)
    place(h, 8, 12)
    h.script = path_from([(8, 12), (8, 5), (14, 5), (14, 12), (8, 12), (8, 16), (12, 16), (12, 18), (8, 18), (8, 16)])
    h.shield = True
    y = ar.add(2, PLAYERS[2], 12, 1, 3)
    place(y, 11, 2)
    y.script = waits(y, 20) + deque([(11, 3), (11, 4)]) + deque([(11, 4)] * 4) + deque([(11, 5), (11, 4), (11, 3), (11, 2)])
    p = ar.add(3, PLAYERS[11], 18, 19, 5)
    place(p, 16, 18)
    p.script = waits(p, 30) + path_from([(16, 18), (9, 18), (9, 21)])
    p.respawn = False
    return ar


def danger(img, ar, rid, x0, y0, cp, t, label="DANGER!", vx=0, vy=0):
    """Blinking red box + label on a rival that is heading for your trail (show the threat, don't tell it)."""
    r = ar.runners[rid]
    if not r.alive:
        return
    cx, cy = x0 + (r.x - vx) * cp + cp / 2, y0 + (r.y - vy) * cp + cp / 2
    d = ImageDraw.Draw(img)
    g = cp + (2 if int(t * 8) % 2 else 0)
    d.rectangle((cx - g, cy - g, cx + g, cy + g), outline=RED, width=2)
    half = len(label) * 6 + 2  # keep the whole label on screen
    lx = max(half + 2, min(W - half - 2, cx))
    ly = cy + g + 3 if cy - g - 20 < y0 else cy - g - 18
    draw_text(img, label, lx, ly, 2, RED, WHITE if int(t * 8) % 2 else DARK)


def demo_threats(img, ar, tl, spb, x0=3, y0=140, cp=11):
    """Demo arena: yellow is a threat while it creeps in (steps 20-26), pink's trail is the target (steps 32-36)."""
    st = tl / (spb / 4)
    if 20 <= st < 26:
        danger(img, ar, 2, x0, y0, cp, tl)
    if 31 <= st < 36:
        danger(img, ar, 3, x0, y0, cp, tl, "CUT IT!")


def too_late(v, b, x0=3, y0=140, cp=11):
    px, py = x0 + 11 * cp + cp // 2, y0 + 5 * cp - 24
    v.overlay(b, b + 1.5, lambda img, t: draw_text(img, "TOO LATE!", px, py, 2, RED, DARK))
    v.sound(b, "blip")


# ============================================================ v01 Computer Lab
def v01():
    v = Video("v01_computer_lab", 120, 24, music=dict(mode="minor", root=57, seed=11, sections=[
        (0, 5, {"kick", "hat", "bass", "arp"}), (5, 7, {"arp", "hat"}), (7, 20, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (20, 24, {"kick", "snare", "hat", "bass", "lead"})]))
    SX, SY, CP = 20, 150, 5
    COLS, ROWS = 46, 34
    SW, SH = COLS * CP, ROWS * CP
    lab = Arena(46, seed=5)
    lab.dt = v.spb / 8
    hero = lab.add(1, PLAYERS[6], 8, 20, 3)
    place(hero, 9, 20)
    hero.script = path_from([(9, 20), (15, 20), (15, 14), (9, 14), (9, 19)])  # claim at step 23
    hero.after_script = "bot"
    hero.reach = (3, 7)
    for i, (x, y) in enumerate([(6, 4), (38, 5), (8, 30), (34, 28), (26, 16), (40, 18)]):
        r = lab.add(i + 2, PLAYERS[(i * 2 + 1) % len(PLAYERS)], x, y, 3)
        r.reach = (3, 7)
    lab_off = (23 - 8) * lab.dt  # hero's claim lands on beat 1 (0.5 s)
    labfx = FX()
    teacher_in, teacher_out = v.b(2), v.b(5)
    alt_tab, alt_back = v.b(3.5), v.b(5)

    def draw_lab(img, t):
        d = ImageDraw.Draw(img)
        d.rectangle((0, 0, W, 360), fill=(190, 205, 186))
        for x in range(0, W, 30):
            d.line((x, 0, x, 360), fill=(178, 194, 174))
        d.rectangle((0, 352, W, 480), fill=(132, 92, 58))
        d.rectangle((0, 352, W, 357), fill=(102, 70, 44))
        if teacher_in <= t < teacher_out:  # teacher walks past behind the monitor
            k = (t - teacher_in) / (teacher_out - teacher_in)
            tx = 320 - k * 400
            d.ellipse((tx - 20, 92, tx + 20, 134), fill=(52, 56, 72))
            d.rectangle((tx - 32, 134, tx + 32, 352), fill=(52, 56, 72))
        d.rectangle((6, 132, 264, 342), fill=(222, 214, 190), outline=DARK, width=2)
        d.rectangle((SX - 4, SY - 4, SX + SW + 3, SY + SH + 3), fill=(20, 22, 28))
        d.ellipse((248, 330, 254, 336), fill=GREEN)
        d.rectangle((115, 342, 155, 356), fill=(206, 198, 174), outline=DARK)
        d.rectangle((30, 378, 216, 430), fill=(214, 206, 182), outline=DARK)
        for row in range(4):
            for col in range(16):
                d.rectangle((36 + col * 11, 384 + row * 11, 43 + col * 11, 391 + row * 11), fill=(236, 230, 210))
        d.rectangle((230, 386, 252, 420), fill=(214, 206, 182), outline=DARK)
        if alt_tab <= t < alt_back:  # the panic spreadsheet
            d.rectangle((SX, SY, SX + SW - 1, SY + SH - 1), fill=WHITE)
            d.rectangle((SX, SY, SX + SW - 1, SY + 12), fill=(33, 115, 70))
            draw_text(img, "BUDGET.XLS", SX + 4, SY + 3, 1, WHITE, None, align="left")
            for gx in range(SX, SX + SW, 28):
                d.line((gx, SY + 13, gx, SY + SH), fill=(200, 200, 200))
            for gy in range(SY + 13, SY + SH, 10):
                d.line((SX, gy, SX + SW, gy), fill=(200, 200, 200))
        else:
            lab.update(t + lab_off)
            draw_arena(img, lab, t + lab_off, SX, SY, CP, (0, 0, COLS, ROWS), hero=1, border=False)
            for (et, kind, data) in lab.events[getattr(lab, "_seen", 0):]:
                if kind == "claim" and data["id"] == 1:
                    cx, cy = SX + data["at"][0] * CP, SY + data["at"][1] * CP
                    labfx.coins(cx, cy, 14, t)
                    labfx.pop(cx, cy - 8, f"+{data['cells']}", t, YELLOW, 2)
            lab._seen = len(lab.events)
            labfx.draw(img, t)
        sl = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
        sd = ImageDraw.Draw(sl)
        for y in range(0, SH, 2):
            sd.line((0, y, SW, y), fill=(0, 0, 0, 36))
        img.paste(sl, (SX, SY), sl)

    v.scene(0, 5, lambda img, tl, tg: draw_lab(img, tg),
            "classroom CRT fills the frame; a runner closes a big loop and floods it at beat 2; teacher walks past, ALT+TAB to a spreadsheet")
    v.caption(0, 1.5, "REMEMBER THIS GAME?", color=YELLOW, size=4)
    v.caption(1.5, 2.5, "FROM COMPUTER CLASS?", color=YELLOW, size=4)
    v.sound(0, "hit")
    v.stamp(1, "MINE!", YELLOW, y=236, beats=1.2, size=6, sound=None, flash=False)
    v.caption(2.5, 3.5, "TEACHER!!", color=RED, size=4)
    v.stamp(3.5, "ALT+TAB", WHITE, y=260, beats=1.5, size=5, sound="click", flash=False)  # hard cut, no white fade

    def zoom(img, tl, tg):
        lab.hide_label = True
        full = Image.new("RGB", (W, H), DARK)
        draw_lab(full, v.b(5) + tl)
        k = ease_out(tl / v.b(2)) ** 1.3
        cx, cy = SX + SW / 2, SY + SH / 2
        tw, th = SH * 0.5625, SH
        box = (cx - tw / 2) * k, (cy - th / 2) * k, W + (cx + tw / 2 - W) * k, H + (cy + th / 2 - H) * k
        img.paste(full.crop(tuple(int(b) for b in box)).resize((W, H), Image.NEAREST))

    v.scene(5, 7, zoom, "camera dives into the CRT screen")
    v.sound(5, "whoosh")
    v.caption(5, 7, "IT'S BACK...", color=WHITE)

    ar = demo_arena(v.spb / 4)
    inner = arena_scene(v, ar, 7, 3, 140, 11, hero=1, fx=FX(), pct=1)
    G = 7

    def game(img, tl, tg):
        bg_checker(img, tg)
        ar.runners[1].king = tl >= v.b(DEMO_CLAIM2 / 4 + 0.5)
        inner(img, tl, tg)
        demo_threats(img, ar, tl, v.spb)

    v.scene(G, 20, game, "Turf Loop demo: big loop claim (yellow creeps in with a DANGER! box, arrives too late), CUT IT! box on pink's trail, K.O., crown")
    v.sound(G, "hit")
    v.caption(G, G + 3, "NOW IT'S ON ROBLOX. WITH FRIENDS.", color=YELLOW)
    v.caption(G + 3, G + 5, "LEAVE YOUR TURF...", color=WHITE)
    v.caption(G + 5, G + DEMO_CLAIM / 4, "...DON'T GET CAUGHT", color=RED)
    v.caption(G + DEMO_CLAIM / 4, G + DEMO_CUT / 4, "LOOP BACK = IT'S YOURS", color=GREEN)
    v.stamp(G + DEMO_CLAIM / 4, "MINE!", GREEN, beats=1.5, sound=None)
    too_late(v, G + 27 / 4)
    v.caption(G + DEMO_CUT / 4, G + DEMO_CLAIM2 / 4 + 0.5, "CUT THEIR LINE = THEY'RE OUT", color=RED)
    v.stamp(G + DEMO_CUT / 4 + 0.25, "K.O.!", RED, beats=1.5)
    v.caption(G + DEMO_CLAIM2 / 4 + 0.5, 20, "MOST TURF WEARS THE CROWN", color=YELLOW)
    v.stamp(G + DEMO_CLAIM2 / 4 + 0.5, "KING!", YELLOW, beats=2, sound="crown")
    v.watermark(G, 20)
    end_card(v, 20, 24, "COMING SOON TO ROBLOX", "WHAT COLOR WERE YOU?", "FOLLOW TO PLAY FIRST", colors=(PLAYERS[7], PLAYERS[11]))
    return v


# ============================================================ v02 0% -> 100%
def v02():
    v = Video("v02_zero_to_hundred", 120, 30, music=dict(mode="major", root=60, seed=22, sections=[
        (0, 2, {"kick", "hat"}), (2, 24, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (24, 30, {"kick", "snare", "hat", "bass", "lead"})]))
    GAME_CPS = 5.5  # cells per second a real runner covers (22 studs/s on 4-stud cells): steps -> game time

    def make(seed):
        ar = Arena(32, seed=seed)
        ar.dt = v.spb / 4
        h = ar.add(1, PLAYERS[7], 16, 16, 3)
        h.hungry, h.reach, h.shield = True, (3, 7), True
        for b in bots(ar, 6, 2, reach=(1, 3)):
            b.respawn = False
        ar.after_step = finish_off
        return ar

    def finish_off(ar):  # past 97%, leftover runners are out so the map really ends at 100%
        if ar.share(1) >= 0.97:
            for r in list(ar.runners.values()):
                if r.id != 1 and r.alive:
                    ar.kill(r, ar.runners[1])

    def simulate(seed):
        ar = make(seed)
        best, drop, marks, cut1 = 0.0, 0.0, {}, None
        while ar.cells(1) < ar.n * ar.n and ar.steps < 9000:
            ar.t += ar.dt
            ar.step()
            sh = ar.share(1)
            best = max(best, sh)
            drop = max(drop, best - sh)
            for m in (0.6, 0.8):
                if m not in marks and sh >= m:
                    marks[m] = ar.steps
            if cut1 is None and any(k == "cut" and d["id"] == 1 for (_, k, d) in ar.events):
                cut1 = ar.steps
        return ar, drop, marks, cut1

    seed = 8
    for cand in range(8, 60):
        ar_, drop, marks, cut1 = simulate(cand)
        if ar_.cells(1) == ar_.n * ar_.n and drop <= 0.01 and cut1 and cut1 < marks.get(0.6, 0):
            seed = cand
            break
    pre, drop, marks, cut1 = simulate(seed)
    total = pre.steps
    cut1 = cut1 or marks[0.6] // 2
    keys = [(0, 0), (1.5, 6), (4, 40), (11, marks[0.6]), (17, max(marks[0.8], total - 32)), (20, total)]  # local beats

    def steps_at(tl):
        b = tl / v.spb
        for (b0, s0), (b1, s1) in zip(keys, keys[1:]):
            if b <= b1:
                return int(s0 + (s1 - s0) * (b - b0) / (b1 - b0))
        return total

    def beat_of(step):
        for (b0, s0), (b1, s1) in zip(keys, keys[1:]):
            if step <= s1:
                return b0 + (b1 - b0) * (step - s0) / max(1, s1 - s0)
        return keys[-1][0]

    def clock(steps):
        sec = steps / GAME_CPS
        return f"{int(sec // 60)}:{int(sec % 60):02d}"

    ar = make(seed)
    S = 2

    def view(tl):
        if tl < v.b(4):
            h = ar.runners[1]
            return (max(0, min(16, h.x - 8)), max(0, min(16, h.y - 8)), 16, 16, 16, 7, 120)
        return (0, 0, 32, 32, 8, 7, 120)

    inner = arena_scene(v, ar, S, 7, 120, 8, hero=1, fx=FX(), steps_fn=steps_at, view_fn=view, pops=lambda tl: tl < v.b(4))
    last = [-1.0]

    def game(img, tl, tg):
        bg_checker(img, tg)
        n0 = len(v.sfx)
        inner(img, tl, tg)
        king_updater(ar)
        kept = v.sfx[:n0]
        for s_ in v.sfx[n0:]:  # timelapse: at most one claim sound per 16th, on the grid
            q = round(s_[0] / (v.spb / 4)) * (v.spb / 4)
            if s_[1] == "cut" or q - last[0] >= v.spb / 4 - 1e-6:
                kept.append((q, s_[1], s_[2]))
                last[0] = q
        v.sfx[:] = kept
        if not any(a <= tg < b for (a, b) in getattr(v, "stamp_windows", [])):
            draw_text(img, "TURF", 70, 380, 1, CREAM, None)
            draw_text(img, "GAME TIME", 200, 380, 1, CREAM, None)
            draw_text(img, f"{int(ar.share(1) * 100 + 1e-6)}%", 70, 392, 4, YELLOW, DARK)
            draw_text(img, clock(ar.steps), 200, 392, 4, WHITE, DARK)
        d = ImageDraw.Draw(img)
        d.rectangle((7, 442, 263, 452), fill=DARK)
        d.rectangle((8, 443, 8 + int(254 * ar.share(1)), 451), fill=YELLOW)

    def cold(img, tl, tg):
        bg_checker(img, tg, c1=(40, 30, 10), c2=(60, 46, 14))
        draw_arena(img, pre, pre.t + 5, 7, 120, 8, None, None, frac=1.0)

    v.scene(0, S, cold, "cold open: the finished, fully blue 100% map")
    v.stamp(0, "100%", YELLOW, y=250, beats=2, size=8)
    v.caption(0, S, "HOW FAST CAN YOU TAKE THE WHOLE MAP?", color=YELLOW, sound=False)
    cut_b = S + beat_of(cut1)
    v.scene(S, S + 20, game, f"rewind to 0%: 2x zoom on your first loop, full map from beat {S + 4}; timelapse seed {seed}, max dip {drop * 100:.1f}%, first cut at beat {cut_b:.1f}; % + game clock; 100% on beat {S + 20} at {clock(total)}")
    v.flash(S)
    v.sound(S, "whoosh")
    v.caption(S, S + 4, "LOOP BACK = IT'S YOURS", color=GREEN)
    v.flash(S + 4)
    v.caption(S + 4, max(S + 6, cut_b + 2), "NOW STEAL EVERYTHING", color=WHITE)
    v.stamp(cut_b, "CUT!", RED, beats=1.5)
    v.caption(max(S + 6, cut_b + 2), S + 13, "THEY'RE RUNNING OUT OF ROOM", color=YELLOW)
    v.caption(S + 13, S + 17, "DON'T GET GREEDY...", color=WHITE)
    v.caption(S + 17, S + 20, "LAST CORNER", color=YELLOW)

    def win(img, tl, tg):
        bg_checker(img, tg, c1=(40, 30, 10), c2=(60, 46, 14))
        draw_arena(img, ar, ar.t + 5, 7, 120, 8, None, None, frac=1.0)
        draw_lines(img, f"MY TIME: {clock(total)}", 404, 3, WHITE)
        draw_lines(img, "+5,000 COINS", 60, 3, YELLOW)

    v.scene(S + 20, S + 23, win, f"100% stamp, my time {clock(total)}, +5,000 coins")
    v.stamp(S + 20, "100%", YELLOW, y=250, beats=3, size=8, sound="levelup")
    v.sound(S + 20.5, "coin")
    v.sound(S + 21, "coin")
    v.watermark(0, S + 23)
    end_card(v, S + 23, 30, "COMING SOON TO ROBLOX", f"BEAT {clock(total)}?", "COMMENT YOUR TIME")
    return v


# ============================================================ v03 How to play in 10 seconds
def v03():
    v = Video("v03_how_to_play", 120, 20, music=dict(mode="major", root=62, seed=33, sections=[
        (0, 2, {"kick", "hat", "arp"}), (2, 16, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (16, 20, {"kick", "snare", "hat", "bass", "lead"})]))
    dt = v.spb / 4
    cold = demo_arena(dt)
    cold_in = arena_scene(v, cold, 0, 3, 140, 11, hero=1, fx=FX(), t_offset=(DEMO_CLAIM - 1) * dt, sounds=True,
                          view_fn=lambda tl: (3, 0, 19, 24, 14, 2, 96))
    v.scene(0, 2, lambda img, tl, tg: (bg_checker(img, tg), cold_in(img, tl, tg)),
            "cold open, zoomed so the board fills 70% of the height: the big loop closes and floods at 0.12s")
    v.caption(0, 2, "TURF LOOP IN 10 SECONDS", color=YELLOW)
    v.stamp(0.25, "MINE!", GREEN, y=250, beats=1.75, sound=None)

    ar = demo_arena(dt)
    inner = arena_scene(v, ar, 2, 3, 140, 11, hero=1, fx=FX(), pct=1)
    S = 2

    def game(img, tl, tg):
        bg_checker(img, tg)
        ar.runners[1].king = tl >= v.b(DEMO_CLAIM2 / 4 + 0.5)
        inner(img, tl, tg)
        demo_threats(img, ar, tl, v.spb)
        if tl >= v.b(DEMO_CLAIM2 / 4 + 0.5):  # mini leaderboard under the crown
            ImageDraw.Draw(img).rectangle((4, 96, W - 5, 118), fill=(14, 16, 26))
            items = [(f"{nm} {int(ar.share(rid) * 100)}%" if ar.runners[rid].alive else f"{nm} KO", ar.runners[rid].color)
                     for rid, nm in ((1, "YOU"), (2, "YEL"), (3, "PINK"))]
            x = W / 2 - (sum(len(s_) * 12 - 2 for s_, _ in items) + 16) / 2
            for s_, col in items:
                tw, _ = draw_text(img, s_, x, 100, 2, col, DARK, align="left")
                x += tw + 8

    v.scene(S, 16, game, "rewind: the same match from the start: leave, loop (yellow just too late), claim, K.O. pink, crown")
    v.flash(S)
    v.sound(S, "whoosh")
    v.caption(S, S + 2, "1. LEAVE YOUR TURF")
    v.caption(S + 2, S + 5.5, "2. YOUR TRAIL IS YOUR WEAK SPOT", color=RED)
    v.caption(S + 5.5, S + 8.25, "3. LOOP HOME = IT'S ALL YOURS", color=GREEN)
    v.stamp(S + DEMO_CLAIM / 4, "SAFE!", GREEN, beats=1.2, sound=None)
    too_late(v, S + 27 / 4)
    v.caption(S + 8.25, S + 11, "4. CROSS THEIR TRAIL = K.O.", color=RED)
    v.stamp(S + DEMO_CUT / 4 + 0.25, "K.O.!", RED, beats=1.5)
    v.caption(S + 11, 16, "5. MOST TURF = THE CROWN", color=YELLOW)
    v.stamp(S + DEMO_CLAIM2 / 4 + 0.5, "KING!", YELLOW, beats=2, sound="crown")
    v.watermark(0, 16)
    end_card(v, 16, 20, "COMING SOON TO ROBLOX", "WHICH STEP DO YOU FORGET?", "FOLLOW TO PLAY FIRST", colors=(PLAYERS[7], PLAYERS[11]))
    return v


# ============================================================ v04 Your own line can't kill you
def v04():
    v = Video("v04_own_line", 120, 22, music=dict(mode="minor", root=55, seed=44, sections=[
        (0, 1.5, {"kick", "hat", "bass", "arp"}), (1.5, 2.75, set())]))  # rest of the sections set once the K.O. beat is known
    loop = [(8, 12), (16, 12), (16, 4), (11, 4), (11, 16), (8, 16), (8, 14)]
    cross_step = 29  # re-enters its own trail at (11, 12)

    def make(retro):
        ar = Arena(20, seed=2)
        ar.dt = v.spb / (4 if retro else 8)
        if retro:
            ar.ground = (18, 52, 30)
        h = ar.add(1, (90, 255, 140) if retro else PLAYERS[0], 6, 12, 5)
        place(h, 8, 12)
        h.script = path_from(loop)
        if not retro:  # back half: a rival lays a trail across your path and you cut it
            h.script += deque([(8, 14)] * 16) + path_from([(8, 14), (8, 19), (12, 19), (12, 16), (11, 16)])
            h.after_script = "bot"
            h.hungry, h.reach = True, (4, 9)
            e = ar.add(2, PLAYERS[2], 17, 17, 3)
            e.script = waits(e, 50) + path_from([(17, 17), (17, 19), (12, 19), (12, 18)])
            e.respawn = False
        return ar

    old = make(True)
    cross_b = 1.0  # the crossing lands at 0.5 s
    old_off = cross_step - 4
    old_in = arena_scene(v, old, 0, 3, 140, 13, hero=1, fx=FX(), sounds=False,
                         steps_fn=lambda tl: min(cross_step, old_off + int(tl / old.dt)))
    XC, YC = 3 + 11 * 13 + 6, 140 + 12 * 13 + 6  # pixel centre of the crossing cell

    def scan(img):
        d = ImageDraw.Draw(img)
        for y in range(0, H, 3):
            d.line((0, y, W, y), fill=(0, 0, 0))

    def old_game(img, tl, tg):
        ImageDraw.Draw(img).rectangle((0, 0, W, H), fill=(8, 24, 14))
        old_in(img, tl, tg)
        draw_text(img, "LIVES: 1", W / 2, 412, 2, (120, 255, 160), None)
        if tl >= v.b(cross_b):
            d = ImageDraw.Draw(img)
            d.line((XC - 16, YC - 16, XC + 16, YC + 16), fill=RED, width=5)
            d.line((XC - 16, YC + 16, XC + 16, YC - 16), fill=RED, width=5)
        scan(img)

    def old_zoom(img, tl, tg):
        full = Image.new("RGB", (W, H), DARK)
        old_game(full, tl, tg)
        cw, ch = int(W / 1.5), int(H / 1.5)
        x = max(0, min(W - cw, XC - cw // 2))
        y = max(0, min(H - ch, YC - ch // 2))
        img.paste(full.crop((x, y, x + cw, y + ch)).resize((W, H), Image.NEAREST))

    v.scene(0, 1.5, old_zoom, "OLD .IO GAMES (1.5x zoom on the crossing): green retro CRT; the figure-8 crosses its own line at 0.5s -> red X")
    v.caption(0, 2.75, "OLD .IO GAMES: CROSS YOUR OWN LINE = DEAD", color=YELLOW)
    v.sound(0, "hit")
    v.sound(cross_b, "cut")
    v.shake(cross_b, 0.3, 5)
    v.flash(cross_b, RED, 0.25)

    def over(img, tl, tg):
        old_game(img, v.b(1.5) + tl, tg)
        d = ImageDraw.Draw(img)
        d.rectangle((0, 186, W, 300), fill=(0, 0, 0))
        if int(tl * 6) % 2 == 0 or tl > 0.5:
            draw_text(img, "GAME OVER", W / 2, 200, 4, RED, None)
        draw_lines(img, "YOU CROSSED YOUR OWN LINE", 262, 2, WHITE, None)

    v.scene(1.5, 2.75, over, "GAME OVER card (0.6 s, hard cut)")
    v.sound(1.5, "gameover")

    N0 = 2.75
    new = make(False)
    off = (cross_step - 12) * new.dt  # crossing 1.5 beats after the cut to Turf Loop
    cross_tl = v.b(1.5)
    slow_a = cross_tl - v.b(0.25)
    slow_len, slow_rate = v.b(3), 0.2  # 1.5 s at 20% speed around the crossing

    def warp(tl):
        if tl < slow_a:
            return off + tl
        if tl < slow_a + slow_len:
            return off + slow_a + (tl - slow_a) * slow_rate
        return off + slow_a + slow_len * slow_rate + (tl - slow_a - slow_len)

    new_in = arena_scene(v, new, N0, 3, 140, 13, hero=1, fx=FX(), warp=warp, pct=1, pct_y=414)
    pre = make(False)
    pre.update(off + 12)
    claim_sim = next(t for (t, k, d) in pre.events if k == "claim") - off
    claim_tl = claim_sim + slow_len * (1 - slow_rate) if claim_sim > slow_a + slow_len * slow_rate else claim_sim
    claim_b = N0 + claim_tl / v.spb
    cut_sim = next(t for (t, k, d) in pre.events if k == "cut") - off
    cut_b = N0 + (cut_sim + slow_len * (1 - slow_rate)) / v.spb
    rival_step = 50 + 2  # rival leaves its turf

    def new_game(img, tl, tg):
        bg_checker(img, tg)
        new_in(img, tl, tg)
        if slow_a <= tl < slow_a + slow_len:  # slow-mo ring on the crossing
            r = 10 + int((tl - slow_a) * 30) % 14
            ImageDraw.Draw(img).ellipse((XC - r, YC - r, XC + r, YC + r), outline=GREEN, width=5)
        if new.runners[2].alive and new.steps >= rival_step:
            danger(img, new, 2, 3, 140, 13, tl, "CUT IT!")

    v.scene(N0, 40, new_game, f"TURF LOOP: same figure-8, slow-mo 20% for 1.5s over the crossing with a green ring + SAFE!, both lobes claimed at beat {claim_b:.2f}; yellow rival lays a trail across your path (red CUT IT! box), you cut it: K.O. at beat {cut_b:.2f}")
    v.sound(N0, "hit")
    v.overlay(N0, N0 + 1, lambda img, t: logo(img, 116, 3, t))
    v.caption(N0, N0 + 1.5, "IN TURF LOOP?", color=YELLOW, sound=False, size=4)
    v.stamp(N0 + 1.5, "SAFE!", GREEN, beats=3, sound="coin")
    v.caption(N0 + 1.5, claim_b, "CROSS IT. KEEP GOING.", color=GREEN)
    v.caption(claim_b, claim_b + 1.5, "BOTH LOOPS ARE YOURS", color=GREEN)
    v.caption(claim_b + 1.5, cut_b, "BUT THEIR LINE?", color=RED)
    v.stamp(cut_b, "K.O.!", RED, beats=1.5)
    END = round((cut_b + 2.5) * 2) / 2
    v.caption(cut_b, END, "YOUR LINE: SAFE. THEIRS: K.O.", color=YELLOW)
    v.watermark(N0, END)
    end_card(v, END, END + 4, "COMING SOON TO ROBLOX", "WHAT WAS YOUR .IO NAME?", "FOLLOW TO PLAY FIRST", colors=(PLAYERS[0], PLAYERS[2]))
    v.dur = v.b(END + 4)
    v.scenes = [(a, v.b(END) if b == v.b(40) else b, f) for (a, b, f) in v.scenes]
    v.log = [ln.replace(f"{v.b(40):5.2f}s", f"{v.b(END):5.2f}s") for ln in v.log]
    v.music["sections"] += [(2.75, END, {"kick", "snare", "hat", "bass", "arp", "lead"}),
                            (END, END + 4, {"kick", "snare", "hat", "bass", "lead"})]
    return v


# ============================================================ v05 The math of a perfect loop
def v05():
    v = Video("v05_loop_math", 120, 32, music=dict(mode="major", root=60, seed=55, prog=[0, 3, 4, 3], sections=[
        (0, 4, {"kick", "hat", "arp"}), (4, 28, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (28, 32, {"kick", "snare", "hat", "bass", "lead"})]))
    A_COL, B_COL = PLAYERS[2], PLAYERS[7]

    def make(square):
        ar = Arena(24, seed=4)
        ar.dt = v.spb / 4
        h = ar.add(1, B_COL if square else A_COL, 3, 12, 3)
        if square:
            place(h, 4, 12)
            h.script = path_from([(4, 12), (11, 12), (11, 6), (4, 6), (4, 11)])
        else:
            place(h, 4, 13)
            h.script = path_from([(4, 13), (14, 13), (14, 15), (3, 15), (3, 13)])
        return ar

    preA, preB = run_events(lambda: make(False), 8), run_events(lambda: make(True), 8)
    ga = next(d["cells"] for (t, k, d) in preA.events if k == "claim")
    gb = next(d["cells"] for (t, k, d) in preB.events if k == "claim")
    ratio = gb / max(1, ga)
    A, B = make(False), make(True)
    hold = lambda tl: 24 if tl < v.b(4) else 25 + int((tl - v.b(4)) / (v.spb / 4))  # drawn at frame 1, close on beat 4
    VIEW, CP = (1, 4, 15, 13), 8  # crop to the loops: 120 x 104 px per panel
    ia = arena_scene(v, A, 0, 10, 150, CP, view=VIEW, fx=FX(), steps_fn=hold, pops=False)
    ib = arena_scene(v, B, 0, 140, 150, CP, view=VIEW, fx=FX(), steps_fn=hold, sounds=False, pops=False)

    def duel(img, tl, tg):
        bg_checker(img, tg)
        ia(img, tl, tg)
        ib(img, tl, tg)
        draw_text(img, "A", 70, 122, 3, A_COL)
        draw_text(img, "B", 200, 122, 3, B_COL)
        draw_text(img, "TRAIL 25", 70, 264, 2, WHITE)
        draw_text(img, "TRAIL 25", 200, 264, 2, WHITE)
        if tl >= v.b(4):
            k = ease_back((tl - v.b(4)) / 0.25)
            draw_text(img, f"+{ga}", 70, 330 - 20 * k, 5, A_COL)
            draw_text(img, f"+{gb}", 200, 330 - 20 * k, 5, B_COL)

    v.scene(0, 8, duel, f"A (yellow strip) vs B (blue square), both 25-cell trails drawn at frame 1, cropped close; 3-2-1; close on beat 4: +{ga} vs +{gb}")
    v.caption(0, 4, "WHICH LOOP GETS MORE TURF? A OR B?", color=YELLOW)
    v.sound(0, "hit")
    for i, n in enumerate("321"):
        v.stamp(1 + i, n, WHITE, y=380, beats=0.9, size=8, sound="blip")
    v.caption(4, 8, f"B WINS: {ratio:.1f}X THE TURF. SQUARES WIN.", color=GREEN)

    def make_greed():
        ar = Arena(24, seed=9)
        ar.dt = v.spb / 4
        h = ar.add(1, B_COL, 4, 20, 3)
        place(h, 5, 20)
        h.script = path_from([(5, 20), (5, 6), (18, 6), (18, 21)])
        e = ar.add(2, PLAYERS[0], 14, 12, 3)
        place(e, 14, 11)
        e.script = waits(e, 25) + path_from([(14, 11), (14, 3)])
        e.respawn = False
        return ar

    G0 = 8
    pre = run_events(make_greed, 10)
    cut_b = G0 + next(t for (t, k, d) in pre.events if k == "cut") / v.spb
    Gm = make_greed()
    ig = arena_scene(v, Gm, G0, 3, 128, 11, hero=1, fx=FX())

    def meter(img, risk):
        d = ImageDraw.Draw(img)
        d.rectangle((14, 418, 256, 438), fill=DARK)
        d.rectangle((16, 420, 16 + int(238 * risk), 436), fill=mix(GREEN, RED, risk))
        draw_text(img, f"RISK {int(risk * 100)}%", W / 2, 398, 2, WHITE)

    def greed(img, tl, tg):
        bg_checker(img, tg)
        ig(img, tl, tg)
        h = Gm.runners[1]
        if not any(a <= tg < b for (a, b) in getattr(v, "stamp_windows", [])):
            meter(img, min(1.0, len(h.trail) / 30) if h.alive else 1.0)

    v.scene(G0, cut_b + 2, greed, f"greed: a giant square, risk meter climbs, red turns toward you, CUT at beat {cut_b:.2f}: all your turf vanishes")
    v.flash(G0)
    v.caption(G0, G0 + 3, "SO WHY NOT ONE GIANT SQUARE?", color=YELLOW)
    v.caption(G0 + 3, cut_b, "BIGGER LOOP = MORE TRAIL TO CUT", color=RED)
    v.stamp(cut_b, "CUT!", RED, beats=2, size=6)
    v.caption(cut_b, cut_b + 2, "LOST EVERYTHING", color=RED, sound=False)
    v.sound(cut_b + 0.5, "fail")

    S0 = cut_b + 2

    def make_small():
        ar = Arena(24, seed=6)
        ar.dt = v.spb / 8
        h = ar.add(1, B_COL, 12, 12, 3)
        place(h, 13, 12)
        h.script = path_from([(13, 12), (17, 12), (17, 8), (13, 8), (13, 11),
                              (13, 13), (13, 17), (9, 17), (9, 13), (11, 13),
                              (11, 11), (11, 7), (7, 7), (7, 11), (10, 11),
                              (10, 7), (10, 3), (14, 3), (14, 7),
                              (14, 13), (18, 13), (18, 18), (14, 18), (14, 17)])
        return ar

    Sm = make_small()
    pre_s = run_events(make_small, 12)
    small = [d["cells"] for (t, k, d) in pre_s.events if k == "claim"]
    is_ = arena_scene(v, Sm, S0, 3, 128, 11, hero=1, fx=FX())

    def small_scene(img, tl, tg):
        bg_checker(img, tg)
        is_(img, tl, tg)
        meter(img, min(1.0, len(Sm.runners[1].trail) / 30))

    v.scene(S0, 28, small_scene, f"the meta: {len(small)} quick small squares {small}, risk bar stays low")
    v.flash(S0)
    v.caption(S0, 28, f"SMALL + OFTEN: +{sum(small)} SAFE VS 0", color=GREEN)
    v.watermark(0, 28)
    end_card(v, 28, 32, "COMING SOON TO ROBLOX", "SQUARE OR GREEDY?", "FOLLOW TO PLAY FIRST")
    return v


# ============================================================ v06 The Greed Meter
def v06():
    v = Video("v06_greed_meter", 128, 29.5, music=dict(mode="minor", root=52, seed=66, sections=[
        (0, 3.5, {"kick", "hat", "bass", "arp"}), (3.5, 21, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (21, 23.5, {"bass"}), (23.5, 29.5, {"kick", "snare", "hat", "bass", "lead"})]))
    HERO, RIVAL = PLAYERS[6], PLAYERS[0]
    X0, Y0, CP = 3, 132, 11

    def make():
        ar = Arena(24, seed=6)
        ar.dt = v.spb / 4
        h = ar.add(1, HERO, 6, 17, 5)
        place(h, 8, 17)
        h.script = path_from([(8, 17), (11, 17), (11, 14), (8, 14), (8, 15),  # small loop
                              (8, 9), (14, 9), (14, 16), (11, 16),  # bigger loop
                              (11, 21), (21, 21), (21, 1), (17, 1)])  # the greedy one
        h.respawn = False
        e = ar.add(2, RIVAL, 16, 12, 3)
        e.script = waits(e, 52)  # then edges one cell toward your trail on every beat and steps on it
        for x in (17, 18, 19, 20):
            e.script += deque([(x, 12)] * 4)
        e.script.append((21, 12))
        e.respawn = False
        return ar

    pre = run_events(make, 20)
    claims = [t for (t, k, d) in pre.events if k == "claim" and d["id"] == 1]
    cut_t = next(t for (t, k, d) in pre.events if k == "cut")
    S = 3.5  # main run starts at beat 3.5 (1.6 s cold open)
    c1, c2, cut_b = (S + claims[0] / v.spb, S + claims[1] / v.spb, S + cut_t / v.spb)
    out_b = S + 12.5  # roughly when the greedy loop starts laying trail (step ~50)

    def meter(img, ar, tl):
        """Greed = how much trail is out right now (fills only while trailing). TURF % sits beside it."""
        h = ar.runners[1]
        n = len(h.trail) if h.alive else 40
        b = int(tl / v.spb)  # the bar fills on the beat, not on every step
        if not hasattr(meter, "q") or meter.q[0] != b:
            meter.q = (b, n)
        risk = min(1.0, meter.q[1] / 26)  # the giant loop must read TOO GREEDY before the cut
        home = h.alive and not h.trail
        lab, col = ("HOME", GREEN) if home else ("SAFE", GREEN) if risk < 0.35 else ("RISKY", YELLOW) if risk < 0.7 else ("TOO GREEDY!", RED)
        d = ImageDraw.Draw(img)
        d.rectangle((14, 406, 162, 424), fill=DARK, outline=WHITE, width=1)
        d.rectangle((16, 408, 16 + int(144 * risk), 422), fill=mix(GREEN, RED, risk))
        for i in range(1, 6):
            d.line((16 + i * 144 // 6, 408, 16 + i * 144 // 6, 422), fill=DARK)
        pct = int(ar.share(1) * 100) if h.alive else 0
        draw_text(img, f"TURF {pct}%", 214, 409, 2, YELLOW, DARK)
        draw_text(img, f"GREED: {lab}", 14, 432, 2, col, DARK, align="left")

    # cold open: the cut, at full greed
    cold = make()
    cold_in = arena_scene(v, cold, 0, X0, Y0, CP, hero=1, fx=FX(), t_offset=cut_t - v.b(1.25), sounds=True, pops=False,
                          view_fn=lambda tl: (5, 0, 19, 21, 14, 2, 104))

    def cold_scene(img, tl, tg):
        bg_checker(img, tg, c1=(48, 18, 22), c2=(62, 24, 28))
        cold_in(img, tl, tg)
        if cold.runners[1].alive:
            danger(img, cold, 2, 2, 104, 14, tl, vx=5)
        meter(img, cold, 99)
        if not cold.runners[1].alive and tl > v.b(1.6):
            draw_text(img, "0%", W / 2, 230, 9, RED, DARK)

    v.scene(0, S, cold_scene, "cold open (board zoomed to 70% of the height): the greedy loop at max greed, red steps onto it, CUT at 0.59 s (freeze + zoom), turf goes to 0%, held to 1.6 s")
    v.caption(0, 1.75, "HOW BIG IS TOO BIG?", color=YELLOW, size=4)
    v.caption(1.75, S, "MAX GREED = 0% TURF", color=RED, size=4)
    v.sound(0, "hit")
    v.stamp(1.25, "CUT!", RED, y=300, beats=0.75, size=6, sound=None)

    ar = make()
    inner = arena_scene(v, ar, S, X0, Y0, CP, hero=1, fx=FX())

    def game(img, tl, tg):
        bg_checker(img, tg)
        inner(img, tl, tg)
        if ar.runners[1].alive and ar.steps >= 50:
            danger(img, ar, 2, X0, Y0, CP, tl, "DANGER!")
        if not any(a <= tg < b for (a, b) in getattr(v, "stamp_windows", [])):
            meter(img, ar, tl)
        if not ar.runners[1].alive:  # the ghost of what you had
            draw_text(img, "0%", W / 2, Y0 + 100, 8, RED, DARK)

    v.scene(S, 23.5, game, f"rewind: small loop (claim beat {c1:.1f}), bigger loop (claim beat {c2:.1f}), then a giant loop while the greed bar fills on every beat; red waits beside your trail (red box from beat {out_b:.1f}) and steps on it at beat {cut_b:.2f}: K.O., 0%")
    v.flash(S)
    v.sound(S, "whoosh")
    for b in range(int(c2) + 1, int(cut_b) + 1):  # noqa  # tension ticks: one click per beat while the bar climbs
        v.sound(b, "click")
    v.caption(S, c1, "SMALL LOOP. SAFE.", color=GREEN)
    v.caption(c1, c2, "BIGGER LOOP. BIGGER REWARD.", color=YELLOW)
    v.caption(c2, out_b, "BIGGER. BIGGER!!", color=YELLOW)
    v.caption(out_b, cut_b, "GO HOME. GO HOME. GO HOME.", color=RED)
    v.stamp(cut_b, "K.O.!", RED, beats=2, size=6)
    v.sound(cut_b + 0.5, "fail")
    v.caption(cut_b, 23.5, "KNOW WHEN TO GO HOME.", color=WHITE)
    v.watermark(0, 23.5)
    end_card(v, 23.5, 29.5, "COMING SOON TO ROBLOX", "HOW BIG DO YOU GO?", "FOLLOW TO PLAY FIRST", colors=(HERO, RIVAL))
    return v

# ============================================================ v07 POV: you cut the King
def v07():
    v = Video("v07_cut_the_king", 120, 20, music=dict(mode="major", root=57, seed=77, sections=[
        (0, 3.5, {"kick", "hat", "bass", "arp"}), (3.5, 5.5, {"kick", "hat", "bass", "arp"}), (5.5, 7.5, {"hat", "bass"}),
        (7.5, 14, {"kick", "snare", "hat", "bass", "arp", "lead"}), (14, 20, {"kick", "snare", "hat", "bass", "lead"})]))
    YOU, KING = PLAYERS[7], PLAYERS[11]
    CUT_STEP = 24  # you step on the King's trail at (8, 17)

    def make():
        ar = Arena(24, seed=7)
        ar.dt = v.spb / 4
        k = ar.add(2, KING, 16, 8, 9)  # big turf, crown on
        place(k, 16, 12)
        k.king, k.respawn = True, False
        k.script = path_from([(16, 12), (16, 20), (8, 20), (8, 14), (12, 14), (12, 12)])  # the greedy loop
        h = ar.add(1, YOU, 5, 17, 6)  # 6% of the map: big enough to take the crown (KingMinShare 3%)
        place(h, 7, 17)
        h.script = waits(h, CUT_STEP - 1) + deque([(8, 17), (7, 17)])
        h.after_script, h.hungry, h.reach, h.shield = "bot", True, (3, 6), True
        return ar

    def crown_fx(ar, state, tg, x0, y0, cp, vx=0, vy=0):
        """After the K.O. the crown arcs from the King to you, then sits on your head."""
        cut = next((d for (t, k_, d) in ar.events if k_ == "cut"), None)
        if cut is None:
            return
        if "tc" not in state:
            state["tc"] = tg
        k = (tg - state["tc"]) / 0.6
        h = ar.runners[1]
        if k >= 1:
            h.king = True
            return
        fx_, fy_ = x0 + (cut["at"][0] - vx + 0.5) * cp, y0 + (cut["at"][1] - vy - 1) * cp
        tx, ty = x0 + (h.x - vx + 0.5) * cp, y0 + (h.y - vy - 1) * cp
        e = ease_out(k)
        crown(img_ref[0], int(fx_ + (tx - fx_) * e), int(fy_ + (ty - fy_) * e - 40 * math.sin(k * math.pi)), 4)

    img_ref = [None]

    def board_box(img, cx, cy, cp, t, label):
        d = ImageDraw.Draw(img)
        g = cp + (2 if int(t * 8) % 2 else 0)
        d.rectangle((cx - g, cy - g, cx + g, cy + g), outline=RED, width=2)
        half = len(label) * 6 + 2
        draw_text(img, label, cx + g + 4, cy - 7, 2, RED if int(t * 8) % 2 else YELLOW, DARK, align="left")  # right of the box, clear of YOU

    # cold open: the cut itself, zoomed in, at 0.5 s
    cold = make()
    CV = (2, 2, 19, 21, 14, 2, 104)
    cold_in = arena_scene(v, cold, 0, 0, 0, 14, hero=1, fx=FX(), t_offset=CUT_STEP * cold.dt - v.b(1), view_fn=lambda tl: CV)
    cst = {}

    def cold_scene(img, tl, tg):
        bg_checker(img, tg, c1=(46, 20, 40), c2=(60, 26, 52))
        img_ref[0] = img
        cold_in(img, tl, tg)
        crown_fx(cold, cst, tg, CV[5], CV[6], CV[4], CV[0], CV[1])

    v.scene(0, 3.5, cold_scene, "cold open (board at 70% of the height): you step on the pink King's long trail at 0.5 s (freeze + zoom), the King's whole turf vanishes, the crown arcs onto your head")
    v.caption(0, 1.75, "POV: THE KING GOT GREEDY", color=YELLOW)
    v.caption(1.75, 3.5, "AND YOU WERE WAITING", color=GREEN)
    v.sound(0, "hit")
    v.stamp(1.1, "KING K.O.!", RED, y=300, beats=1.2, size=5)
    v.sound(1.5, "crown")

    X0, Y0, CP = 3, 124, 11
    S = 3.5
    ar = make()
    SKIP = 8  # rewind starts 2 beats into the King's loop (round 6: the rewind dragged)
    inner = arena_scene(v, ar, S, X0, Y0, CP, hero=1, fx=FX(), t_offset=SKIP * ar.dt)  # the strip is the only % readout
    st = {}

    def game(img, tl, tg):
        bg_checker(img, tg)
        img_ref[0] = img
        inner(img, tl, tg)
        crown_fx(ar, st, tg, X0, Y0, CP)
        b = tl / v.spb
        k = ar.runners[2]
        if k.alive and b < 2:
            danger(img, ar, 2, X0, Y0, CP, tl, "GREEDY!")
        if k.alive and 2 <= b:
            board_box(img, X0 + 8 * CP + CP / 2, Y0 + 17 * CP + CP / 2, CP, tl, "CUT HERE!")
        if any(z[0] <= tg < z[0] + 0.5 for z in getattr(v, 'zooms', [])):
            return  # the K.O. zoom would push the strip under the caption
        # leaderboard strip: who holds the crown right now
        ImageDraw.Draw(img).rectangle((4, 98, W - 5, 118), fill=(14, 16, 26))
        rows = sorted(((ar.share(r.id), r) for r in ar.runners.values() if r.alive), key=lambda x: -x[0])
        items = [(("YOU " if r.id == 1 else "KING ") + f"{int(sh * 100)}%", r.color, r.king) for sh, r in rows]
        if not k.alive:
            items.append(("KING KO", KING, False))
        x = W / 2 - (sum(len(s_) * 12 - 2 for s_, _, _ in items) + 22 * len(items)) / 2
        for s_, col, has in items:
            if has:
                crown(img, int(x + 7), 102, 2)
            tw, _ = draw_text(img, s_, x + 18, 101, 2, col, DARK, align="left")
            x += tw + 22 + 8

    cut_b = S + (CUT_STEP - SKIP) / 4
    v.scene(S, 14, game, f"rewind: the pink King (crown, 14% of the map) leaves home on a huge loop; GREEDY! box on the King, then a blinking CUT HERE! box on the King's trail; you step on it at beat {cut_b}: K.O., the King's turf vanishes, crown flies to you; you then flood the empty space; leaderboard strip on top")
    v.flash(S)
    v.sound(S, "whoosh")
    v.caption(S, S + 1, "WATCH THE KING...", color=YELLOW)
    v.caption(S + 1, S + 2.5, "LEFT HOME. HUGE TRAIL.", color=RED)
    v.caption(S + 2.5, cut_b, "WAIT FOR IT...", color=WHITE)
    for b in (S + 2.5, S + 3, S + 3.5):
        v.sound(b, "click")
    v.stamp(cut_b, "KING K.O.!", RED, beats=1.5, size=5)
    v.caption(cut_b, cut_b + 2.5, "CUT THE KING = TAKE THE CROWN", color=GREEN)
    v.sound(cut_b + 0.5, "crown")
    v.caption(cut_b + 2.5, 14, "KING K.O. = 2X COINS", color=YELLOW)
    v.stamp(cut_b + 2.5, "2X COINS!", YELLOW, beats=1.5, size=5, sound="coin")
    v.sound(cut_b + 2.75, "coin")
    v.sound(cut_b + 3, "coin")
    v.watermark(0, 14)
    end_card(v, 14, 20, "COMING SOON TO ROBLOX", "WHO WAS KING IN YOUR CLASS?", "FOLLOW TO PLAY FIRST", colors=(YOU, KING))
    return v


ALL = {"v01": v01, "v02": v02, "v03": v03, "v04": v04, "v05": v05, "v06": v06, "v07": v07}

if __name__ == "__main__":
    names = sys.argv[1:] or list(ALL)
    for n in names:
        vid = ALL[n]()
        print("rendered", vid.render(OUT, SHEETS))

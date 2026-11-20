"""Turf Loop shorts. Usage: py tools/video/videos.py v01 v03   (no args = all). Ideas: marketing/videos/IDEAS.md
Round 2 (2026-11-19): reworked v01-v05 from the round-1 grader fixes (marketing/videos/GRADES.md)."""
import os
import sys
from collections import deque

from PIL import Image, ImageDraw, ImageOps

sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa: E402,F403

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
    y.script = waits(y, 24) + path_from([(11, 2), (11, 5), (11, 2)])
    p = ar.add(3, PLAYERS[11], 18, 19, 5)
    place(p, 16, 18)
    p.script = waits(p, 30) + path_from([(16, 18), (9, 18), (9, 21)])
    p.respawn = False
    return ar


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
    lab_off = (23 - 16) * lab.dt  # hero's claim lands on beat 2
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
    v.caption(0, 2.5, "REMEMBER THIS GAME FROM COMPUTER CLASS?", color=YELLOW)
    v.sound(0, "hit")
    v.stamp(2, "MINE!", YELLOW, y=236, beats=1.2, size=6, sound=None)
    v.caption(2.5, 3.5, "TEACHER!!", color=RED)
    v.stamp(3.5, "ALT+TAB", WHITE, y=260, beats=1.5, size=5, sound="click")

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

    v.scene(G, 20, game, "Turf Loop demo: big loop claim (yellow arrives too late), K.O. on pink, crown")
    v.flash(G)
    v.sound(G, "hit")
    v.caption(G, G + 3, "NOW IT'S ON ROBLOX. WITH FRIENDS.", color=YELLOW)
    v.caption(G + 3, G + DEMO_CLAIM / 4, "DRAW A LOOP...", color=WHITE)
    v.caption(G + DEMO_CLAIM / 4, G + DEMO_CUT / 4, "LOOP BACK = IT'S YOURS", color=GREEN)
    v.stamp(G + DEMO_CLAIM / 4, "MINE!", GREEN, beats=1.5, sound=None)
    too_late(v, G + 27 / 4)
    v.caption(G + DEMO_CUT / 4, G + DEMO_CLAIM2 / 4 + 0.5, "CUT THEIR LINE = THEY'RE OUT", color=RED)
    v.stamp(G + DEMO_CUT / 4 + 0.25, "K.O.!", RED, beats=1.5)
    v.caption(G + DEMO_CLAIM2 / 4 + 0.5, 20, "MOST TURF WEARS THE CROWN", color=YELLOW)
    v.stamp(G + DEMO_CLAIM2 / 4 + 0.5, "KING!", YELLOW, beats=2, sound="crown")
    v.watermark(G, 20)
    end_card(v, 20, 24, "COMING SOON TO ROBLOX", "WHAT COLOR WERE YOU?", "FOLLOW TO PLAY FIRST")
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
    cold_in = arena_scene(v, cold, 0, 3, 140, 11, hero=1, fx=FX(), t_offset=(DEMO_CLAIM - 1) * dt, sounds=True)
    v.scene(0, 2, lambda img, tl, tg: (bg_checker(img, tg), cold_in(img, tl, tg)),
            "cold open: the big loop closes and floods at 0.12s")
    v.caption(0, 2, "TURF LOOP IN 10 SECONDS", color=YELLOW)
    v.stamp(0.25, "MINE!", GREEN, beats=1.75, sound=None)

    ar = demo_arena(dt)
    inner = arena_scene(v, ar, 2, 3, 140, 11, hero=1, fx=FX(), pct=1)
    S = 2

    def game(img, tl, tg):
        bg_checker(img, tg)
        ar.runners[1].king = tl >= v.b(DEMO_CLAIM2 / 4 + 0.5)
        inner(img, tl, tg)

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
    end_card(v, 16, 20, "COMING SOON TO ROBLOX", "WHICH STEP DO YOU FORGET?", "FOLLOW TO PLAY FIRST")
    return v


# ============================================================ v04 Your own line can't kill you
def v04():
    v = Video("v04_own_line", 120, 26, music=dict(mode="minor", root=55, seed=44, sections=[
        (0, 1.5, {"kick", "hat", "bass", "arp"}), (1.5, 4.5, set()), (4.5, 22, {"kick", "snare", "hat", "bass", "arp", "lead"}),
        (22, 26, {"kick", "snare", "hat", "bass", "lead"})]))
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
        if not retro:
            h.after_script = "bot"
            h.hungry, h.reach = True, (4, 9)
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

    v.scene(0, 1.5, old_game, "OLD .IO GAMES: green retro CRT; the figure-8 crosses its own line at 0.5s -> red X")
    v.caption(0, 4.5, "OLD .IO GAMES: CROSS YOUR OWN LINE = DEAD", color=YELLOW)
    v.sound(0, "hit")
    v.sound(cross_b, "cut")
    v.shake(cross_b, 0.3, 5)

    def over(img, tl, tg):
        old_game(img, v.b(1.5) + tl, tg)
        d = ImageDraw.Draw(img)
        d.rectangle((0, 186, W, 300), fill=(0, 0, 0))
        if int(tl * 6) % 2 == 0 or tl > 0.5:
            draw_text(img, "GAME OVER", W / 2, 200, 4, RED, None)
        draw_lines(img, "YOU CROSSED YOUR OWN LINE", 262, 2, WHITE, None)

    v.scene(1.5, 4.5, over, "GAME OVER card")
    v.sound(1.5, "gameover")

    N0 = 4.5
    new = make(False)
    off = (cross_step - 6) * new.dt  # crossing 0.75 beats after the cut to Turf Loop
    cross_tl = v.b(0.75)
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

    def new_game(img, tl, tg):
        bg_checker(img, tg)
        new_in(img, tl, tg)
        if slow_a <= tl < slow_a + slow_len:  # slow-mo ring on the crossing
            r = 10 + int((tl - slow_a) * 30) % 14
            ImageDraw.Draw(img).ellipse((XC - r, YC - r, XC + r, YC + r), outline=GREEN, width=3)

    v.scene(N0, 22, new_game, f"TURF LOOP: same figure-8, slow-mo 20% for 1.5s over the crossing with a green ring + SAFE!, both lobes claimed at beat {claim_b:.2f}, then keeps looping")
    v.flash(N0)
    v.sound(N0, "hit")
    v.overlay(N0, N0 + 1, lambda img, t: logo(img, 116, 3, t))
    v.caption(N0, N0 + 0.75, "IN TURF LOOP?", color=YELLOW, sound=False)
    v.stamp(N0 + 0.75, "SAFE!", GREEN, beats=3, sound="coin")
    v.caption(N0 + 0.75, claim_b, "CROSS IT. KEEP GOING.", color=GREEN)
    v.caption(claim_b, claim_b + 2.5, "BOTH LOOPS ARE YOURS", color=GREEN)
    rest = (22 - claim_b - 2.5) / 3
    v.caption(claim_b + 2.5, claim_b + 2.5 + rest, "LOOP ANY SHAPE.", color=YELLOW)
    v.caption(claim_b + 2.5 + rest, claim_b + 2.5 + 2 * rest, "NO FEAR.", color=WHITE)
    v.caption(claim_b + 2.5 + 2 * rest, 22, "TAKE THE WHOLE MAP.", color=YELLOW)
    v.watermark(N0, 22)
    end_card(v, 22, 26, "COMING SOON TO ROBLOX", "WHAT WAS YOUR .IO NAME?", "FOLLOW TO PLAY FIRST")
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


ALL = {"v01": v01, "v02": v02, "v03": v03, "v04": v04, "v05": v05}

if __name__ == "__main__":
    names = sys.argv[1:] or list(ALL)
    for n in names:
        vid = ALL[n]()
        print("rendered", vid.render(OUT, SHEETS))

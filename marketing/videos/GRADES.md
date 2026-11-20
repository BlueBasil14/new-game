# Turf Loop shorts: grades

Running:

Pass mark 7/10 overall from a fresh grader subagent (`GRADER_PROMPT.md`). Max 6 rework rounds per video (raised from 3 on 2026-11-20: all five plateaued at 6 and the owner asked for 7+), then parked with reasons.

| Video | Idea | R1 | R2 | R3 | R4 | R5 | R6 | Status |
|---|---|---|---|---|---|---|---|---|
| v01_computer_lab | #1 | 5 | 6 | 6 | 6 | | | rework (4 rounds; re-rendered with round-5/6 engine, not regraded) |
| v02_zero_to_hundred | #2 | 5 | 6 | 6 | – | | | rework (3 rounds; re-rendered, not regraded) |
| v03_how_to_play | #3 | 5 | 6 | 6 | 6 | 6 | | rework (5 rounds: one left before parking) |
| v04_own_line | #4 | 5 | 6 | 6 | 6 | 6 | | rework (5 rounds: one left before parking) |
| v05_loop_math | #5 | 6 | 6 | 6 | – | | | rework (3 rounds; re-rendered, not regraded) |
| v06_greed_meter | #6 | 6 | 6 | | | | | rework (2 rounds) |
| v07_cut_the_king | #7 | 6 | 6 | | | | | rework (2 rounds) |

## Round 1 (2026-11-19): shared problems
Every grader raised the same five things:
- Captions are too small and thin for a phone.
- The board leaves dead space above and below it.
- The payoff comes too late, and the hook is a title card.
- Key moments (K.O., cut, safe crossing) have no impact frame.
- End cards are 3–4 s of static logo with a weak call to action, and the brand is missing until the end.

## Round 1 details
**v01 (5)** hook 6, clarity 4, style 6, pacing 5, readability 5, cta 4.
- The CRT is too small to read at 0 s.
- Gameplay starts at 6 s.
- The loop and cut are never taught.
- "Own line can't kill you" plays over a death burst.
- The end card is too long.

**v02 (5)** hook 5, clarity 4, style 7, pacing 5, readability 5, cta 6.
- The hook shows an empty board.
- The counter goes backwards (38→34%).
- The jump from 68% to 100% reads as a skip.
- The loop mechanic is never visible.
- The text is small.

**v03 (5)** hook 4, clarity 6, style 7, pacing 5, readability 6, cta 5.
- Opens on a title card.
- Steps 3 and 4 flash by in under 0.9 s while step 5 drags.
- A claim fires during "leave your turf".
- The K.O. is unreadable.
- The end card is long.

**v04 (5)** hook 5, clarity 6, style 7, pacing 4, readability 6, cta 4.
- The death lands at about 4 s.
- The harmless crossing gets no feedback.
- The board freezes at 23% for 5 s under "SPIRALS. ZIGZAGS. CHAOS.".
- The text is small.

**v05 (6)** hook 6, clarity 6, style 7, pacing 5, readability 6, cta 4.
- The hook starts with stubs instead of full loops.
- The cut climax is invisible.
- "Small squares" is told, not shown.
- "Team A or B" asks a question the video already answered.
- A is the same red as the enemy.

## Round 2 (2026-11-20 00:30): all 6/10, up from 5
Shared problems:
- Score pops and stamps cover the runner and the action.
- The crown is promised but too small to see.
- The bottom brand bar is too small to read.
- End cards have no gameplay, and their CTA appears late.
Per video:
- **v01:** the crown line is up for 0.5 s. The flood on the CRT is small. Yellow's "too late" moment can't be read. "COLOUR" should be "COLOR" for the US audience.
- **v02:** no clock, yet it asks viewers to "comment your time". The 100% frames aren't really full. Show one cut. The rewind is slow. The % counter has low contrast.
- **v03:** the cold open must flood by 0.3 s. Step 3 is up for 0.87 s. Yellow never visibly threatens. The crown is invisible.
- **v04:** the crossing must land by 0.5 s. The "safe" crossing flashes past in 0.5 s. A 5 s stretch has one caption. The pale trail is hard to see.
- **v05:** the panels are too small. The +34 pop is clipped. Small loops (+27) lose to one square (+54), which breaks the lesson. The cut frame isn't visible. A caption starts with a dangling "=".

## Round 3 (2026-11-20 01:30): all 6/10 again
The round-2 fixes landed:
- v02 now has a clock and a true 100% map.
- v04's death lands at 0.5 s, and its crossing plays in slow-mo.
- Stamps moved to the bottom band.
- The end cards show a live mini-match.

Graders then found the next layer. **Round 4 to-do, in priority order:**
1. **Shared engine work:**
   - Score pops still overlap the YOU tag. Anchor pops up and to the right of the runner.
   - Stamps must sit above the brand bar (their bottom edge above y 455), and particles must draw behind stamp text.
   - The "YOUR TURF %" counter needs white or yellow digits that blip when they change.
   - The end card's mini-match should use the match's colours and be about 1.5x bigger.
   - The CTA should pulse on the beat.
   - Make boards bigger (about 90% width), with slimmer caption plates.
2. **Show threats, don't tell them.** Every "danger" or "greedy" caption needs a rival visibly heading for your trail (red outline plus a "DANGER!" pop). Every K.O. needs the crossing visible about 0.3 s before the stamp. Back halves (v02 past 83%, v04 after the claim) need a rival and a cut.
3. **Hooks:**
   - v01: bigger hook text and CRT, flood by 0.5 s, the spreadsheet held 0.4 s, a hard cut instead of the white fade at 3.5 s.
   - v02: open on the final loop flooding the last corner.
   - v03: open on a big flood or K.O.
   - v04: zoom 1.5x on the crossing, plus a red full-screen flash.
4. **Per video:**
   - v01: split "DRAW A LOOP".
   - v02: pay off the win with "1:50" as the hero number instead of a second 100% card.
   - v03: a mini leaderboard (YOU / YELLOW / PINK) at the crown.
   - v04: hold "IN TURF LOOP?" 0.75 s, bring the music back under the slow-mo, a thicker ring on the runner.
   - v05: fill the claim on the beat with counting-up numbers (needs fractional steps in `steps_fn` mode, so the board doesn't flash grey for one 16th). Small loops must be clean squares that keep risk under 35%, with a running counter "+N vs GREEDY 0". Keep YOU visible where you died.

## Round 4 (2026-11-20 01:00-01:45): v01, v03, v04 reworked, v06 new. All 6 again.
**What changed (engine, affects every video):**
- Score pops sit about 54 px beside the runner, so they no longer cover the YOU tag.
- Stamps sit above the brand bar on a dark plate that hides particles.
- The YOUR TURF counter has white/yellow digits that pop when they change.
- The end card's mini-match is 1.5x bigger and uses the video's own colors, and the CTA button pulses on every beat.
- `stamp(..., flash=False)` gives a hard cut.

**What changed (per video):**
- Shared demo: yellow creeps in with a red DANGER! box, and pink's trail gets a CUT IT! box before the K.O.
- v01: size-4 hook captions, flood at 0.5 s, ALT+TAB as a hard cut, "LEAVE YOUR TURF... / ...DON'T GET CAUGHT".
- v03: a YOU / YEL / PINK leaderboard strip at the crown.
- v04: 1.5x zoom and a red flash on the old-game crossing, "IN TURF LOOP?" held 0.75 s, a thicker ring, a yellow rival cut in the back half (K.O. at 6.3 s), cut to 11 s.

**Scores:**
- **v01 (6)** hook 6, clarity 7, style 7, pacing 6, readability 5, cta 6.
  - The 0.5 s MINE! stamp is huge on its first frames, runs off the left edge and hides the flood.
  - The teacher is just a blob, and the spreadsheet never shows in the sampled frames.
  - 3.5-5 s: "NOW IT'S ON ROBLOX" plays over a near-empty board. Start mid-action with 4-6 territories.
  - About 7.5 s: TOO LATE / +55 / YOU / CUT IT! overlap. Stagger them and drop the YOU tag after about 6 s.
- **v03 (6)** hook 6, clarity 7, style 7, pacing 7, readability 6, cta 6.
  - The cold-open board is too small: zoom it to about 70% of the height in the first second and put MINE! on the board.
  - "CUT IT!" overlaps YOU at the K.O. Freeze 2-3 frames on contact.
  - The leaderboard strip is still clipped at the right. KING! on 16% feels small, so count the % up live.
  - Step 2's danger never pays off: add a "PHEW" beat or a ghost of the cut, plus a "crossing your own trail = fine" flash.
- **v04 (6)** hook 6, clarity 7, style 7, pacing 5, readability 6, cta 6.
  - The GAME OVER card is too long: hard-cut to Turf Loop by about 1.4 s, and show a flash of the bright board at 0-0.3 s.
  - 6.3-9 s is filler under one caption. Trim it to about 9.5 s total.
  - The K.O. rival is tiny: zoom 1.3-1.5x on the cut and freeze-frame it.
  - +24 and +28 stack, and YOU is clipped at the board edge.
- **v06 (6)** hook 6, clarity 6, style 7, pacing 7, readability 5, cta 6.
  - The cold open's CUT passes too fast (0.59 s, rewind at 0.94 s). Make the open about 1.6 s with "100% -> 0%" and a freeze.
  - The greed bar empties after each claim, so it looks like greed falls as rewards grow. Fill it only while trailing, and add a TURF % counter beside it.
  - DANGER! and WATCHING. are clipped at the right edge.
  - Red sits still: animate it edging toward the trail on each beat.
  - "GREED GREEDY!" reads oddly. Use "TOO GREEDY!".

**Round 5 to-do, in priority order:**
1. **Shared engine work:**
   - Brand bar to about 3.5% of the height, with readable "SOON ON ROBLOX" text.
   - CTA button about 1.3-1.5x bigger, placed higher (out of the TikTok bottom-UI zone) and above the comment-bait line.
   - Only one score pop on screen at a time.
   - Hide the YOU tag after the first claim, or whenever another label is near it.
   - Clamp danger and other labels inside the board.
   - YOUR TURF % counts up over about 0.5 s instead of jumping.
   - Stamp pop-in capped near 1.4x so the first frames don't overflow the frame.
2. **Hooks:** zoom the board to about 70% of the height for the first second (v03, v06), and keep every hook payoff on screen for at least 0.8 s before a cut.
3. **Freeze plus zoom on every K.O.:** 2-3 frames of freeze and a 1.3x zoom on the contact point.
4. **Per video:**
   - v01: a teacher silhouette, the spreadsheet held 0.4 s, and a mid-action board at 3.5 s.
   - v04: shorten the GAME OVER card and trim the tail.
   - v06: the meter fills only while trailing, red edges in on each beat, a longer cold open.

## Round 5 (2026-11-20 12:00): engine round-5 fixes, v03/v04/v06 reworked, v07 new. All 6 again.
**What changed (engine, every video):**
- Brand bar slimmer, with "ON ROBLOX" at full size.
- End card: a bigger CTA placed higher, above the comment line.
- One score pop at a time. The YOU tag hides after the first claim.
- The % counter counts up over 0.5 s.
- Stamps pop in at 1.4x at most.
- Every K.O. freezes for 3 frames and zooms 1.3x on the contact point.

**Per video:**
- v03: cold open zoomed to about 70% of the height, MINE! on the board, a centered leaderboard strip.
- v04: the GAME OVER card cut to 0.6 s, with a hard cut, and the tail trimmed (about 9 s).
- v06: 1.6 s cold open ending in a big red 0%, greed bar beside a TURF % counter, red edging in on each beat, "TOO GREEDY!".
- v07 Cut the King (idea #7, new): a cold open where you cut the greedy King and the crown arcs onto you, a rewind, CUT HERE!, KING K.O. = 2X COINS (true in game: `KingKillMultiplier = 2`), and an end card asking "WHO WAS KING IN YOUR CLASS?".

**Scores:**
- **v03 (6)** hook 6, clarity 7, style 7, pacing 5, readability 6, cta 7.
  - The hook reads as a tutorial. Start mid-trail with the loop 1 beat from closing, land MINE! at 0.5 s, and use a stake line such as "STEAL THE MAP IN 10 SECONDS".
  - Step 2 holds 1.75 s with a 3-line caption. Cut it to 1 s, "2. TRAIL = WEAK SPOT", with DANGER! right away.
  - TOO LATE! and SAFE! clash. Drop TOO LATE!.
  - The leaderboard strip is too small. The crown payoff (16%) feels small, so count it up toward 40%.
  - The HUD and footer sit in the platform UI zone.
- **v04 (6)** hook 6, clarity 6, style 7, pacing 7, readability 6, cta 6.
  - The opening caption is too wordy. Use "CROSS YOUR LINE = DEAD" with a small "OLD .IO GAMES" tag, a bigger GAME OVER line, and "LIVES: 0" as the joke.
  - The yellow rival trail isn't visible before the cut. Show 3+ tiles held for 2 beats.
  - The K.O. flash washes out the frame. (Fixed in the engine this round, see below.)
  - YOU sits on the green ring and reads "YOL". Fill the second lobe on the beat at 4.0 s.
  - The end card is long. The footer says "ON ROBLOX" while the card says "COMING SOON".
- **v06 (6)** hook 6, clarity 7, style 7, pacing 6, readability 5, cta 6.
  - Show the 0% on the same frame as CUT!, and the caption "MAX GREED = 0% TURF" from frame 0.
  - Add a visible REWIND cue.
  - The K.O. flash washes out the frame. (Fixed in the engine.)
  - The greed labels go up and down. Use one ladder that only climbs, and a bar 2x taller under the caption.
  - "BIGGER LOOP" drags for 2.6 s. Bring the +44 earlier.
- **v07 (6)** hook 7, clarity 6, style 7, pacing 7, readability 5, cta 7.
  - The cut frame is cluttered (the strip shows under the caption during the zoom) and the K.O. stamp is washed out.
  - The strip % and the bottom % disagree.
  - CUT HERE! overlaps YOU.
  - The rewind repeats the cold open.
  - The end card is static.

**Applied after grading (round 6, this run):**
- Engine: the stamp now draws on top of its flash, and the flash is 40% max and 0.07 s. Every K.O. and payoff frame was washed out before. All videos re-rendered.
- v07: the rewind starts 2 beats later, so the K.O. lands at 3.75 s instead of 4.75 s. The strip is the only % readout and hides during the K.O. zoom. CUT HERE! sits to the right of the box, clear of YOU. 10 s total.

**v07 regrade after those fixes: 6** (hook 7, clarity 6, style 7, pacing 6, readability 6, cta 6).
- The payoff happens twice: the cold open shows the whole cut, then the rewind shows it again. Make the cold open a 0.8 s freeze on contact with a hard cut, and save the turf-vanish and crown-steal for 3.75 s. The cold-open board leaves the bottom 30% empty.
- The "+1" pop after a K.O. is cryptic. Use "+CROWN", and keep number pops for territory.
- CUT HERE! and GREEDY! are too small. Put them on a yellow plate with an arrow, at 2x size.
- The end card is 30% of the video. Use about 2 s.
- Drop the 2X COINS beat and teach "LOOP HOME = IT'S YOURS" instead.

**Round 6 to-do (next run), shared first:**
1. Engine: a K.O. pop should read "+CROWN"/"K.O." rather than "+1" (claim pops only for territory). Footer: make it read as "coming soon" so it matches the end card (graders flagged "ON ROBLOX" vs "COMING SOON"). Consider raising the HUD out of the bottom ~15%.
2. Every hook: start mid-action, 1 beat before the payoff, with a stake caption (not a tutorial title). One short line, with a small tag above it.
3. Add a visible REWIND cue (scanlines plus a "<<" stamp and SFX) wherever a video jumps back after a cold open (v06, v07).
4. v03: drop TOO LATE!, shorten step 2, bigger crown payoff. v04: hook rewrite, a visible rival trail, YOU off the ring. v06: a meter ladder that only climbs, and 0% on the CUT! frame.

## s01_skins_hype (2026-11-20, owner request: Paper.io callback + every cosmetic, 108 BPM). Script: tools/video/hype.py
| Round | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|
| R1 | 6 | 7 | 5 | 7 | 6 | 6 | 6 |
| R2 | 6 | 7 | 5 | 7 | 6 | 6 | 7 |
| R3 | 6 | 7 | 5 | 7 | 6 | 6 | 7 |
| R4 | 6 | 7 | 5 | 8 | 6 | 7 | 7 |

Status: rework (4 rounds). Older fix lists below; the R4 list is in the 2026-11-20 13:00 run section at the end.
R2 fixes:
1. Make the green CRT playfield 2x bigger with lighter scanlines, and put the +33 burst on screen by 0.6 s. Turn "IT GREW UP..." into a CRT power-off before the logo slam.
2. Hold "LOOP HOME = IT'S YOURS" for 2 beats over one clear loop and claim. Add one visible cut around the trails section ("CUT THEIR TRAIL = THEY'RE OUT").
3. Show 4 contrasting rare skins at 1 beat or more each instead of 6. Remove the leftover white wipe line.
4. Safe zones: move the footer and name cards up about 120 px, and put "WHICH ONE ARE YOU GETTING?" above the tile grid.
5. On the end card, pulse "FOLLOW TO PLAY FIRST" on the beat and make "COMING SOON TO ROBLOX" bigger.

R3 notes for s01:
- Hold "LOOP HOME" for 2 beats or more, over one full loop and fill.
- Show 4 rares at 2 beats each, and finish each wipe before its name card.
- Trails need a long curving trail on open grid. Use half the bubble rings and keep lightning bolts inside the board.
- Move the footer into the safe zone.
- Say "COMING TO ROBLOX", not "ON ROBLOX", so the drop text matches the end card.

## s02_avatar_hype (2026-11-20, owner: "you move with your Roblox character, not a square"). Script: tools/video/hype.py
Blocky avatar sprites are our own art and not Roblox's logo. The Paper.io square morphs into your avatar, avatars play the match with skins, the wardrobe shows the same avatar wearing different skins, and the end card shows avatars.
| Round | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|
| R1 | 6 | 7 | 6 | 7 | 7 | 6 | 6 |
| R2 | 6 | 7 | 6 | 7 | 6 | 6 | 6 |
| R3 | 6 | 6 | 5 | 7 | 6 | 7 | 7 |
| R4 | 6 | 6 | 7 | 7 | 7 | 6 | 7 |

Fixed after R2: the wardrobe keeps the same avatar with a YOU tag. Still to do:
- The in-match avatars are too small. Zoom the camera about 1.8x on YOU (needs a view crop in `skinned()`).
- Cut "PLAY AS YOUR OWN AVATAR".
- Give the claim and the K.O. more time.
- Re-break the caption as "IN TURF LOOP... / YOU'RE YOU.".
- Use coarser patterns, because diagonal hatching will moiré under compression.

## s03_turf_pass_hype (2026-11-20, owner: "battle pass with limited time events"). Script: tools/video/hype.py
| Round | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|
| R1 | 6 | 5 | 6 | 7 | 7 | 5 | 6 |
| R2 | 5 | 4 | 5 | 6 | 6 | 5 | 6 |
| R3 | 6 | 5 | 6 | 7 | 6 | 5 | 6 |

Fixed after R2: honesty. The pass isn't live, so there's no ticking countdown. The hook is now "LIMITED-TIME SKINS. 14-DAY SEASONS." and the closing line is "SEASON 1 STARTS AT LAUNCH". Still to do:
- Open on the avatar running a loop with the Prism Storm trail and claiming on beat 1.
- Tier labels 2x bigger, with a whoosh or skip marker on each jump.
- Show legendaries as moving trails on a mini board.
- A 1 s daily-missions panel ("LOOP 3 TIMES +150 XP", a tick, the XP bar filling).
- Hold Crown Rush for 2 beats or more.
- Put the LIMITED TRAIL! stamp in the centre over the board.
- A 1 s core-loop shot by 3 s.
- Note that graders misread frame boundaries on the contact sheet as overlap ("12/18", "SKINSKIN").

## Run 2026-11-20 13:00 (weekend task): s01-s03 reworked, s04 new. Still no 7.
**Shared changes in `tools/video/hype.py` (all s-videos re-rendered; v01-v07 untouched):**
- s01 now uses avatars, not squares. `draw_avatars()` is shared.
- `match_scene()`: a skinned avatar match with preroll or slow-mo (`sim`), an optional follow camera (`view` crops a zoomed board), and +N pops on a dark chip at size 4.
- `footer()`: "TURF LOOP COMING SOON", raised about 120 px (at 1080 wide) out of the bottom UI. Name cards also moved up.
- `rewind()` cue: dark scanlines, "<< REWIND" and a whoosh.
- Coarser diagonal stripes (no moiré). The YOU tag hides after the first claim.
- End card: a bigger 2-line "COMING SOON TO ROBLOX", and the CTA button flashes yellow and grows on every beat.

**s01 R4 (6)** hook 7, clarity 5, style 8, pacing 6, readability 7, cta 7.
Applied: a big CRT hook with the loop at 0.56 s and a power-off, "COMING TO ROBLOX" on the drop, LOOP HOME held 2.5 beats over a scripted loop and claim, 4 rares at 2 beats with a fast wipe and then the name card, 1 trail, half the bubbles, bolts inside the board, the question above an 8-tile grid.
Next fixes:
1. It is a skin catalog with almost no gameplay. Give LOOP HOME about 2.5 s with a visible trail, and add a 1-beat "CUT A TRAIL = THEY'RE OUT" cut (script the rival) before RARE SKINS.
2. TRAILS: put the trail on plain or default turf and drag a long thick rainbow trail across empty grid. It currently reads as another turf skin.
3. CAPTURE EFFECTS: plain turf, bubbles 3-4x bigger, and keep the avatar off the board's top edge.
4. Trim to 2 rares and 2 legendaries at 1-2 beats each. The first rare needs its name card visible in the sampled frame.
5. Bait: hold 2.5 s and put a 1-word name under each tile.

**s02 R3 (6)** hook 6, clarity 5, style 7, pacing 6, readability 7, cta 7.
Applied R2 fixes: a 1.6x follow camera, "PLAY AS YOUR OWN AVATAR" cut, a slower match, the split caption, coarse stripes.
**s02 R4 (6)** hook 6, clarity 7, style 7, pacing 7, readability 6, cta 7.
Applied R3 fixes: the loop closes at 0.28 s, a hard cut to the avatar at 1.1 s, a solid cyan trail (the line now differs from the turf), MINE! at 5.0 s, DANGER!/CUT IT! tags on the rivals, a 4-beat wardrobe.
Next fixes:
1. Hook: a 3x bigger, brighter square, and draw the +N above the scanlines. The avatar reveal needs a punch-in or overshoot on the beat. 1.1-2.8 s is a still avatar.
2. Never place a tag or pop over a sprite: offset DANGER!, CUT IT! and +N by at least one avatar height.
3. Keep yellow on screen closing in during "...BEFORE THEY CATCH YOU". Remove the dark bar at the arena top (the offscreen padding row of the camera).
4. The K.O. needs a bigger pink burst and a flash on pink's trail. Use a bigger crown at KING.
5. Bigger viewport (about 75% of the height). Wardrobe at 2 beats per skin.

**s03 R3 (6)** hook 5, clarity 6, style 7, pacing 6, readability 5, cta 6.
Applied: an avatar loop-and-claim hook in Prism Storm, big tier numbers, a >> SKIP >> marker and whooshes, a daily-missions panel (3 ticks, XP bar, TIER UP!), Crown Rush held 2 beats, LIMITED TRAIL! centred, an avatar on each legendary tile, no fake countdown.
Next fixes:
1. Hook: full-width board, a zoomed fill burst, and a value line instead of "THE TURF PASS IS COMING". It must stay honest: no "0 Robux" claims unless true. Free-track rewards are real, so something like "FREE TRACK + 4 LEGENDARIES" works.
2. Track: one big centred tier card per stop. Hide non-current bubbles while skipping. (The "38"/"1218" and "KEY XEY" the grader saw are mostly contact-sheet frame seams, but one card per stop removes the doubt.)
3. Missions: 1 mission with a big "+200 XP -> TIER UP!", or 2 more beats.
4. The comment 1-4 beat needs about 2.5 s with big numbers. Take the time from the end card.
5. Drop the K.O. zoom during the 2X COINS beat (it pushes the label onto the footer). A core-loop shot by 3 s.

**s04_one_cell (idea #8, new, 108 BPM, 13 s).** A 1-cell-from-home fail in slow-mo (yellow steps on your trail at 0.97 s, "SO CLOSE.", sad "fail" tune), "WE'VE ALL BEEN HERE.", << REWIND, take 2: go home first (+35, Fireworks), REVENGE! cut, crowned. Then "LOSE A ROUND. KEEP YOUR SKINS." showing the 4 Turf Pass legendaries, "WHAT'S YOUR CLOSEST CALL?", avatar end card.
| Round | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|
| R1 | 6 | 6 | 6 | 8 | 6 | 6 | 7 |
| R2 | 6 | 6 | 5 | 7 | 6 | 7 | 7 |
R2 applied: a ~2x follow camera on the gap, a pulsing "1 CELL" bracket, chip-backed pops, a slower take 2, a 4-beat carousel, a 3-beat bait on navy.
Next fixes:
1. The hook geometry must match the caption from frame 0: start with YOU already on the cell next to home, the bracket on the single gap cell, and the "1 CELL" label above the board.
2. After the K.O. leave a ghost or tombstone of YOU plus a "TRAIL HIT = OUT" flash, and drain the turf over about 4 frames before SO CLOSE.
3. Music: keep the kick and arp under the rewind, and start the full band at TAKE 2 (2.78 s), not at 4 beats.
4. Claim frame: about 60% fewer confetti particles, +35 above the claimed block. Show yellow at the moment of the cut (REVENGE!).
5. Bait: grey cells with a dashed trail and a "? CELLS" gap, or fold it into the end card.

**Pattern across 23 grades:** every s-video sits at 6 with style 7-8. The ceiling is clarity and hook (5-6): graders want one instantly readable mechanic shot in the first 2 s and threats and cuts that are visible in stills. The next run should spend its rounds on those, not on more cosmetics.

## Run 2026-11-20 15:52 (weekend task): s02 R5, s03 R4, s04 R3 reworked. All 6 again. No new video this run.
**Applied:** s04: hook starts with YOU already one cell from home (stalls there, yellow steps on the trail at ~1 s), grey ghost + "TRAIL HIT = OUT", kick+arp kept under the rewind and the full band at TAKE 2, bait shows "? CELLS". s03: hook caption "FREE TRACK + 4 LEGENDARIES", bigger hook board, track hides far tiers while skipping, bigger tier numbers on the comment card (now 4.5 beats), end card 3 beats, no K.O. zoom in the events scene (`kozoom=False` in `match_scene`). s02: avatar punch-in on every beat, taller 290 px camera, wardrobe 1.5 beats per skin.

**s02 R5 (6)** hook 6, clarity 7, style 6, pacing 6, readability 7, cta 6.
1. Hook: "IN PAPER.IO YOU WERE A SQUARE." is a dull 3-line opener on a green CRT that doesn't look like the game. Open on the avatar mid-loop with a +55 pop and keep the square-to-avatar morph as the payoff.
2. 1.1-2.8 s is a static idle avatar and the first claim lands at 5 s. Compress the reveal and move the claim under 2 s.
3. Gameplay is small, grey and flat. Bigger flood and +N, and a 0.3 s hold on the K.O.
4. Use one high-contrast caption color (the red on navy is hard to read) and keep stamps clear of the footer.
5. Wardrobe repeats one caption and only swaps the pad behind the avatar. Cut to about 1.8 s or recolor the avatar's own turf and trail. The end card is cluttered.

**s03 R4 (6)** hook 5, clarity 5, style 7, pacing 6, readability 6, cta 6.
1. Hook board is still a tiny grey 3x3 look with a +23 pop and no game name. Open on a full-frame Prism Storm fill or a flash of all 4 legendaries, with TURF LOOP in a corner badge.
2. Track: mid-scroll tier numbers still collide ("38", "128") and "KEY X1" is clipped. One big reward card per beat, no ticker.
3. No threat or K.O. anywhere. Add a 1.5 s trail/cut beat at about 1.7 s, taking time from Crown Rush or the comment card.
4. Second half drags (comment card 2.5 s, small Crown Rush board). Fix the LIMITED TRAIL! stamp overlapping the faded "7" counter.
5. The permanent footer is wallpaper by the end.

**s04 R3 (6)** hook 6, clarity 6, style 7, pacing 6, readability 7, cta 7.
1. Hook: enlarge the bracket and "1 CELL" label 2x, add a red danger arrow on yellow's path, a bigger SO CLOSE.
2. The ghost and red particles confuse: show an explicit "YOU'RE OUT"/X, and put "TRAIL HIT = OUT" on a dark plate at about 0.6 s, before the K.O.
3. Wardrobe (2.2 s) is off-topic: cut to about 1.2 s or move it after the bait. Use the time for a second claim or kill.
4. Comment-bait card is static: shorten to 1.2 s, animate it, larger text on a plate.
5. Footer repeats the end card and is in the bottom UI zone: remove on the end card. Add "DRAW A LOOP. CLAIM THE TURF." to the mid captions.

**Next run priorities (s02 5 rounds, s03 4, s04 3):** s02 is one round from parking. Shared: footer off on end cards and for most of the video, a hook with a visible threat in frame 0 for s02/s03, wardrobe and bait sections about 1.2 s. Then build the next unbuilt idea (#9 Head-On).

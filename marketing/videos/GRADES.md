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

## Run 2026-11-20 18:53 (weekend task): s02 R6, s03 R5, s04 R4 reworked, s05 (idea #9 Head-On) new. All 6 again.
**Applied:** s02: opens ON the game (loop 4 steps from closing, +55 at ~0.9 s, "REMEMBER PAPER.IO?"), the square-to-avatar morph is now the payoff after the match, 4-skin wardrobe at 1 beat each, stamps raised clear of the footer, no red captions, footer only on the last scene. s03: hook is 1.5 beats of full-frame animated legendaries plus big avatar, then loop+claim; the track is now one big centred card per stop (tiers 1/10/20/30, progress bar, FREE reward line, name card); new 4-beat cut/K.O. scene; the missions scene was shifted; the comment card was cut to 3 beats; footer only on the last card. s04: bracket and "1 CELL" label 2x, red danger arrow on yellow, OUT plate and red X on the ghost, wardrobe 2 beats, animated bait, footer removed. s05: new video, 108 BPM, ~12 s: head-on race (both K.O.) -> "DRAW." -> rewind -> take 2 loop home first, Fireworks, cut -> WINNER! -> YOU vs THEM bait -> avatar end card.

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s02 | R6 | 6 | 5 | 7 | 7 | 6 | 7 | 6 |
| s03 | R5 | 6 | 5 | 6 | 7 | 6 | 6 | 6 |
| s04 | R4 | 6 | 7 | 5 | 7 | 6 | 7 | 6 |
| s05 | R1 | 6 | 6 | 6 | 7 | 6 | 7 | 6 |

**s02: PARKED after 6 rounds (all 6).** Style 7 and readability 7 every time; the hook is the stuck point: a nostalgia-only line ("REMEMBER PAPER.IO?") over a quiet board, claim at 0.9 s. Last fix list if reopened: first frame already mid-claim with +55 at 0-0.3 s ("PAPER.IO, BUT YOU'RE YOU"), cut the repeated "LOOP HOME AGAIN" beat (game segment about 4.5 s), K.O. zoom plus "K.O." on the victim, show square and avatar in one frame (arena behind the morph), a 2.5 s end card, a corner brand tag from frame 1.

**s03 R5 (6):** 1) The hook is a static avatar on a pink pattern. Open mid-fill with Prism Storm and a +55 in the first 0.3 s, caption "4 LEGENDARY SKINS. FREE TRACK.", drop the tiny corner badge. 2) Tier cards take about 5 s before gameplay. Cut each stop to ~0.8-1 beat and caption once; move the K.O. to about 3.5 s. 3) The FREE subtitle sat too close to the TIER number (moved 5 px down this run, not re-graded); PREMIUM tag and FAST FORWARD / CROWN HELD lines are too small. 4) The loop needs a 1-2 s trail-drawn-and-closed beat before the cut; zoom the 16x16 event boards. 5) Comment card is crowded: give "COMMENT 1-4" its own beat, make FOLLOW the biggest element, drop the footer on the card.

**s04 R4 (6):** 1) Hook: "TRAIL HIT = OUT" is tiny and the grey ghost plus X is ambiguous; show the loop being drawn first, make the trail flash at impact, move yellow closer so the K.O. lands by ~0.7 s, and cut the clutter on frame 1 (bar, arrow, bracket, tag all compete). 2) Take 2 repeats captions: shorten "TAKE 2" to ~1 s, claim by ~3.5 s, a 2x bigger +35, a longer REVENGE freeze. 3) The skins and bait beats are off-topic filler: merge the bait into the end card and use the time for a second action beat. 4) The end card shows no gameplay: put a 1 s loop behind the logo, a bigger COMING SOON line, wording "HOW MANY CELLS?".

**s05 R1 (6):** 1) The hook shows no collision before the K.O.; by 1.45 s the board is empty, so the crash is never seen. Open on the near-collision, K.O. at ~0.8-1.0 s, and keep the two avatars visible for 0.5 s before DRAW. 2) "DRAW." over an empty board is dead air for ~1.7 s: cut to ~0.6 s or add ghost avatars and "BOTH OUT" icons; trim the rewind. 3) Slow the claim to a clean frame (loop closing, flash, +18), show the rival trail being snipped (red X) before K.O. 4) The bait card has empty black bars and small avatars; drop the footer there. 5) Corner TURF LOOP tag from 0 s; a 1 s gameplay loop behind the end CTA.

**Next run priorities (s03 5 rounds, s04 4, s05 1; s02 parked):** s03, s04, s05. Shared: a corner brand tag from frame 0 (engine overlay), a gameplay loop behind the end card (`avatar_end`), drop the footer on bait cards, merge bait into the end card. Then build idea #10.

## Run 2026-11-20 21:53 (weekend task): s03 R6, s04 R5, s05 R2 reworked, s06 (idea #10 Color Battle Royale) new. No 7.
**Applied:** shared: corner TURF LOOP tag from frame 0 (`brand_tag`, added by `avatar_end`), end card is now a live looping mini-match (24x24, crowned hero) instead of a pad. s05: take 1 cut to 3.5 beats, shorter rewind and take 2, bait card has no footer, 2.5 beats. s04: wardrobe removed, take 2 claims about 1.5 s earlier, captions shortened (no 3-line wrap under the tag), bait is "HOW MANY CELLS?" at 2 beats. s03: tier stops 1.25 beats each, K.O. at 4.4 s, shorter captions, no footer on the comment card. s06: 6 colored avatars, live sorted bar chart, crown on the leader, winner stamp and reveal.

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s03 | R6 | 6 | 6 | 5 | 7 | 6 | 7 | 6 |
| s04 | R5 | 6 | 7 | 5 | 7 | 6 | 6 | 6 |
| s05 | R2 | 6 | 6 | 6 | 7 | 6 | 7 | 6 |
| s06 | R1 | 5 | 5 | 5 | 7 | 5 | 7 | 5 |

**s03 (PARKED after 6 rounds, all 5-6):** hook is a small board with dead grey space; clarity: a cold viewer never learns the loop; tier cards and missions are static slabs; events block is 5 s of near-identical frames. If reopened: first frame a full-bleed Prism Storm fill with +N by 0.5 s, "LOOP HOME = CLAIM TURF" line at 0-2 s, events cut to 3.5 s, bigger boards (60% of height), bigger comment thumbnails, end card 2 s+.
**s04 (R5, 6):** 1) "TRAIL HIT = OUT" banner is cut off and overlaps the caption at 1.25 s and "1 CELL" collides with yellow: move or hide the banner during the stamp. 2) Red/white block board at 1.25 s reads as a glitch. 3) +35 claim is crowded by confetti (hold it longer, bigger, fewer particles); the +8 revenge cut is tiny and the rival trail faint: zoom the crossing and burst the rival. 4) Bait card static, cut to about 0.6 s or put it over a replay. 5) Mini-match on the end card is small: enlarge to about 70% width.
**s05 (R2, 6):** 1) Hook board too small, VS overlaps THEM: zoom to fill, impact by 1.2 s, big "K.O. x2" freeze. 2) +18 chip and particles cover the avatars; keep the rival and the cut point in frame in take 2 and show the pink trail snapping. 3) WINNER beat is a near duplicate for 1.1 s: cut to 0.6 s. Bait card padded: about 1 s, bigger type. 4) Captions sit in the top UI zone (move down about 150 px); standardize colors. 5) CTA wording and a bigger end mini-match.
**s06 (R1, 5):** 1) Hook "PICK YOUR COLOR. GO." is vague on a busy tiny board with no obvious YOU: freeze on the 6 tiles first or add "YOU = BLUE", stake line "6 PLAYERS. 1 MAP. 10 SECONDS." 2) Avatars about 12 px: crop to about 60% of the board following one actor, thicker trails, a hero capture with +N% at 2-3 s and one visible elimination by 4 s. 3) 1.7-5.5 s is near static; cut preroll to about 3 s, event every 0.5 s; lone white-square glitch at 2.15 s; bigger labeled bars. 4) Winner reveal late (5.6 s): move to about 4 s, 1.5 s long, and make the avatar match the winner color; bigger COMMENT line. 5) End card cluttered and corner tag tiny: enlarge the tag about 2x, make FOLLOW the biggest element.

**Shared next run:** make `brand_tag` about 2x bigger; captions down about 100 px out of the top UI zone; enlarge the end-card mini-match; and a follow-camera crop for multi-bot scenes. Then continue s04, s05, s06 (s02 and s03 parked), then idea #11.

## Run 2026-11-21 00:55 (weekend task): s04 R6, s05 R3, s06 R2 reworked. No new video this run.
**Applied (shared, `tools/video/hype.py`):** corner TURF LOOP tag 2x; every caption pushed down about 100 px at 1080 wide (monkey-patched `Video.caption` in hype.py only); end-card mini-match 7 px cells (about 170 px) with the CTA moved lower. s04: TRAIL HIT = OUT plate only before the K.O., bait cut to 1.5 beats. s05: hook zoomed with a 28 px follow camera, "K.O. x2!" stamp, WINNER beat 1.2 beats, bait 1.8 beats. s06: 22 px follow camera on the winner, preroll shorter, game 7 beats, stake caption "6 PLAYERS. 1 MAP.", winner stamp moved to beat 6, reveal 2.5 beats.

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s04 | R6 | 6 | 7 | 6 | 7 | 6 | 6 | 6 |
| s06 | R2 | 5 | 5 | 4 | 7 | 5 | 5 | 6 |

**s04 (PARKED after 6 rounds, all 6):** hook 7 every recent round; clarity and the revenge beat keep it at 6. If reopened: drop "WE'VE ALL BEEN HERE." until 1.5 s, cut the red banner for the first beat and tag the orange turf "HOME", shrink and offset +35 with far fewer particles, lighter rewind scanlines, "CUT = OUT" caption, merge the comment bait into the end card ("COMMENT YOUR CLOSEST CALL").
**s06 (R2, 5):** 1) The core mechanic is never shown: add one clean loop-and-claim on YOU at 0.3-1.5 s and one visible elimination with "CUT!" at about 2.3 s (the +88 lands on a pre-existing blob). 2) The hook line is generic: use a stake line ("1 LOOP = 88% OF THE MAP") and open on a rival next to your trail. 3) The winner stamp collides with the LIVE TURF % bars: centre it on the board or hide the chart for 0.3 s; shorten the caption to one line. 4) Reveal is 1.4 s of near-identical frames and the tile row touches "COMMENT YOUR COLOR": cut to about 0.8 s, space 20 px. Pick one of COMMENT or FOLLOW. 5) End-card logo is clipped at the top while it slams in.
| s05 | R3 | 6 | 6 | 6 | 7 | 6 | 6 | 7 |

**s05 (R3, 6):** 1) Hook board still reads small and grey: thicker brighter trails, avatars running at each other from frame 1. 2) Show 3-4 frames of the two heads touching (flash and freeze) before "K.O. x2!"; keep ghosted avatars instead of clearing the board. 3) Take-2 setup is 1 s of little action: cut to about 0.6 s and claim by about 3.0 s. 4) Captions and CTA sit in platform UI zones; thicker outline on the corner tag; the bait card has a big empty box. 5) Merge the bait into the end card ("COMMENT: DRAW OR WIN?") and drop the separate slide.

**Next run priorities:** s05 (3 rounds) and s06 (2 rounds); s02, s03, s04 parked. Then build idea #11. Shared: a "hold the contact frame" freeze helper for head-on and cut scenes, and bait merged into `avatar_end`.

## Run 2026-11-21 19:02 (weekend task): s05 R4, s06 R3 reworked, s07 (idea #11 Things Only .io Kids Remember) new. No 7.
**Applied:** shared: end-card logo no longer clips at the top while slamming in (s01-s04 re-rendered). s05: take 2 preroll 8 steps (claim ~1.7 beats, cut ~3.3, winner ~5), take 2 now 6 beats, bait 1.2 beats. s06: stake caption "1 LOOP CAN TAKE THE MAP", CUT! stamp at 3.2, chart hidden under the winner stamp, reveal 1.5 beats, comment box moved down. s07: hook + 4 list cards (Wi-Fi lag, the name, teacher, one line = GAME OVER) + "NOW IT'S TURF LOOP. WITH FRIENDS." + avatar end card.

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s05 | R4 | 6 | 6 | 6 | 7 | 6 | 6 | 7 |
| s06 | R3 | 5 | 5 | 5 | 6 | 5 | 6 | 6 |
| s07 | R1 | 5 | 6 | 4 | 6 | 5 | 5 | 6 |

**s05 (R4, 6):** 1) Hook: show both avatars with full trails, centred and large, a beat from impact, VS between them; hold the clash to ~0.8 s, then K.O. x2. 2) Caption "HEAD-ON = BOTH OUT"; bigger shake on the burst. 3) Brighter rewind, YOU tag off the avatar, a big "TAKE 2: DON'T RACE" for 0.5 s+. 4) Zoom ~1.5x on take 2, K.O. pop at the cut point, +18 off the avatars. 5) Hold bait 1.2 s or fold into the end card; keep one CTA color.
**s06 (R3, 5):** 1) Hook is a vague claim over an empty grey board: open on a loop-close with a huge +88 or a CUT in progress. 2) Show the rules: "CROSS THEIR TRAIL = OUT" callout with an arrow, "LOOP HOME = CLAIM"; keep YOU on the trail. 3) Reveal to ~0.5 s, bigger color tiles with full names. 4) Bar chart 2x bigger and out of the bottom 20%; fix the "6 PLAYERS. 1 / MAP." wrap. 5) End-card incentive and bigger mini-match.
**s07 (R1, 5):** 1) No gameplay until the end card: add a 1.5 s loop-claim clip with +55 in place of the empty grid / GAME OVER slide. 2) Hook is static: animate a trail closing into a square with a pop in the first second; shorten the headline. 3) Caption plates are tall with dead space: shrink to fit, enlarge text ~30%, one color. 4) Each list item is a static 1.7 s slide: animate mid-beat or cut to 1 s. 5) Bigger end-card mini-match, CTA on screen 3 s+.

**Next run priorities:** s05 (4 rounds), s06 (3), s07 (1); s02, s03, s04 parked. Then idea #12 (Teacher's Coming).

## Run 2026-11-21 21:52 (weekend task): s05 R5, s06 R4, s07 R2 reworked, s08 (idea #12 Teacher's Coming) new. No 7.
**Applied (shared, `tools/video/hype.py`; all s-videos re-rendered):** `avatar_end(..., ask=...)` folds the comment bait into the end card as a line under the CTA (separate bait slides dropped in s05/s07/s08); `match_scene(focus=(cx, cy))` fixed camera to keep two actors in frame; `match_scene` skips preroll events, so no stale +N pop on a scene's first frame. s05: fixed camera between YOU and THEM with VS, grey crossed-out ghosts stay where they met, "TIE = BOTH OUT", take 2 zoomed (24 px cells), size-4 "TAKE 2: DON'T RACE", bait in the end card. s06: hook is RED's +88 loop at ~0.5 s, captions ONE LOOP HOME / MOST TURF WINS / CROWN = LEADER / CROSS A TRAIL = OUT, game 11.5 beats, bars relative to the leader and above the bottom 20%, winner tiles with full names, winner shirt in the winner color. s07: hook is a live board with a loop closing (+55) under "ONLY .IO KIDS REMEMBER THIS", captions use auto-fit plates, 4 animated list cards at 2 beats, payoff is real gameplay (skins, Fireworks, cut, crown), 6-beat end card with "COMMENT YOUR .IO NAME". s08: new, 108 BPM, ~11 s: live match, teacher slides in, hard cut to a BOOK1.XLS spreadsheet ("ALT+TAB!"), back in and cut a rival, teacher again, faster spreadsheet, then "IN TURF LOOP? NO TEACHER." with Fireworks and crown, end card "EVER GET CAUGHT?".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s05 | R5 | 6 | 7 | 5 | 7 | 5 | 6 | 7 |
| s06 | R4 | 5 | 6 | 4 | 7 | 5 | 6 | 7 |
| s07 | R2 | 6 | 7 | 5 | 6 | 6 | 6 | 8 |
| s08 | R1 | 6 | 6 | 5 | 7 | 7 | 6 | 6 |

**s05 (R5, 6; one round left):** 1) "TAKE 2: DON'T RACE" is hidden under the rewind: caption box from 1.94 s, rewind ~0.3 s, YOU tag clear of the rival. 2) The take-2 cut is never seen (only YOU + puff + K.O.!): show pink's trail ~0.4 s before and YOU crossing it. 3) Your turf (cyan/pink) and theirs (pink/white) both use pink: make YOU cyan/white, pink for THEM only; one claim fill. 4) Music peaks on the end card: full band from MINE! (2.94 s), lighter under the end card. 5) End card ~1.8 s; +55/+18 pops above-beside the avatar.
**s06 (R4, 5):** 1) Hero wears blue but claims red: shirt, trail and turf one color. 2) No lead change and only 2-3 of 6 colors on screen: script a lead swap (crown jumps), zoom out so all 6 show and bars reorder. 3) "CROSS A TRAIL = OUT" has no visible cut: show it with OUT! pop and the bar dropping to 0%; drop the repeated CROWN = LEADER. 4) Bigger board/chart into the empty bottom, labels inside bars, grey out 0%. 5) Winner card: crown overlaps "RED WON", use one phrase, hold COMMENT YOUR COLOR ~1 s longer, end card ~2 s.
**s07 (R2, 6, up from 5):** 1) Loop close and +N at ~0.3 s, 1.5x zoom on YOU. 2) Item 4 should be a 0.6 s board clip of an enemy cutting your trail, then GAME OVER. 3) The name joke: show it as a leaderboard row "#1 xX_PRO_Xx 98%". 4) Payoff: caption band above the board, K.O.! centred on the cut point, half the particles, a calmer skin. 5) "NOW IT'S / TURF LOOP" line break, logo slam on the downbeat; end card ~0.8 s shorter.
**s08 (R1, 6):** 1) Teacher in by ~0.2 s with a stake caption ("TEACHER INCOMING. ALT+TAB!"). 2) Hide the corner TURF LOOP tag during the spreadsheet; give "WE ALL DID THIS" 0.5 s+ and big. 3) Replace "COAST IS CLEAR..." with "LOOP HOME = CLAIM IT"; opaque caption box during the K.O. zoom; show pink's trail before the cut. 4) K.O.! on the victim inside the board; make the payoff the biggest claim (+100) with big fireworks. 5) End card ~2.2 s, "EVER GET CAUGHT?" above the CTA and bigger, yellow CTA with dark text from the start.

**Pattern (now 37 grades):** clarity stays at 4-5 because cuts happen off-camera or too fast to read in stills. Next run, shared first: a "show the cut" helper (camera holds the victim's trail ~0.4 s, YOU crosses, OUT! pop on the victim); end cards ~2 s with the ask above the CTA; hide the corner tag on fake-out screens. Then s05 (last round), s07, s08, then idea #13.

## Run 2026-11-22 00:53 (weekend task): s05 R6, s07 R3, s08 R2 reworked, s09 (idea #13 Hug the Wall) new. No 7.
**Applied (shared, `tools/video/hype.py`; s01-s09 re-rendered):** "show the cut" helper: `match_scene(mark=lambda tg: (rid, label))` pulses a red outline on a trail with a label chip, and `kopop=True` pops K.O.! on the victim inside the board; `match_scene(outfits=...)`; score pops sit higher above big avatars; `v.notag` hides the corner tag on fake-out screens; `avatar_end` puts the ask above a yellow CTA (dark text from the start, pulse = grow + white outline); end cards about 2 s; new `bigloop()` arena (+140 loop) and `arrow()` helper. s05: YOU in Cosmic Crystal (pink only for THEM), short rewind, THEIR TRAIL marked before the cut, lighter music under the end card. s07: hook zoomed 1.5x with the loop closing at ~0.3 s, the name as a leaderboard, item 4 is a real board clip of a rival cutting YOUR TRAIL, calmer Starfall payoff, "NOW: TURF LOOP". s08: teacher in from frame 0 with "TEACHER INCOMING. ALT+TAB!", WE ALL DID THIS big, no tag on the spreadsheet, THEIR TRAIL marked, +140 payoff with triple Fireworks. s09: new, 108 BPM, ~12 s: wall loop closes at 0.4 s, open-field take with 4 arrows and a K.O. on you, rewind, wall take with 1 arrow and "TOO LATE!", then a flip through the 4 legendaries, end card "COMMENT YOUR BEST TIP".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s05 | R6 | 6 | 7 | 5 | 7 | 6 | 6 | 6 |
| s07 | R3 | 6 | 7 | 5 | 7 | 6 | 6 | 7 |
| s08 | R2 | 6 | 7 | 5 | 7 | 7 | 5 | 7 |
| s09 | R1 | 6 | 6 | 6 | 7 | 6 | 6 | 7 |

**s05 (PARKED after 6 rounds, all 6):** hook 7 and style 7 hold; clarity stuck at 5. If reopened: the music dips under the payoff (move the thin part to the rewind, full band from the 2.94 s claim); the cut is still hidden: the follow camera jumps and the K.O. pop covers the rival, so lock the camera for take 2 and pop above the board; "FIRST HOME WINS" teaches the wrong lesson ("SAFE AT HOME = WIN"); hold WINNER 0.8 s; "DRAW OR WIN?" is ambiguous ("TIE OR WIN?") and should be bigger.
**s07 (R3, 6):** 1) TEACHER WALKS BY card: YOU avatar cut off at the left edge (stray "U"); keep it inside the frame. 2) YOUR TRAIL chip sits on YOU: place the chip away from the avatar; payoff should show the Turf Loop difference (own line does not kill you, if true in the game: check GDD) with a caption. 3) The name joke doesn't land as a leaderboard: show a name box typing a cringe name with key clicks. 4) Payoff: +55 covers the player, too many particles, K.O.! covers the victim; bigger board. 5) Hook board bigger, add a "4 THINGS" badge; item 4 beat lands late.
**s08 (R2, 6):** 1) +55 sits on the teacher's head: drop the hook pop or move the teacher lower/right. 2) +140 buried in confetti: pops above particles, fireworks 0.3 s later, half the particles. 3) THEIR TRAIL chip covers pink: put the chip above the trail; "= THEY'RE OUT!" reads like a typo. 4) "IN TURF LOOP? NO TEACHER." is confusing: "LOOP HOME = CLAIM IT ALL", move the joke to the end card. 5) Second spreadsheet too short (0.4 s): stretch to 0.6 s or cut; ask line 1.5x bigger.
**s09 (R1, 6):** 1) The wall doesn't read as a wall: a thick bright pulsing strip on the left edge only with a big WALL label. 2) YOUR TRAIL chip on YOU; YOU tag clipped at the board edge in take B. 3) Take A: all 4 arrows from outside the loop's box with an "x4"; a grey ghost of YOU under K.O.!. 4) Take B's loop runs into the open middle: keep it a tight rectangle flush to the wall, "x1" by the arrow, rewind ~0.5 s. 5) Skin flip is off-message: one 0.8 s flip with the card above the board, bigger end-card mini-match.

**Pattern (now 41 grades, still no 7):** label chips land on avatars (shared fix: the `mark_trail` chip should avoid the hero's cell, and pops should never cover a victim), and particles bury numbers (draw pops after effects, halve Fireworks). Next run: those two shared fixes, then s07 (R4), s08 (R3), s09 (R2); s02-s05 parked; s06 at R4. Then idea #14 (The Snipe).

## Run 2026-11-22 03:52 (weekend task): s07 R4, s08 R3, s09 R2 reworked, s10 (idea #14 The Snipe) new. No 7.
**Applied (shared, `tools/video/hype.py`; s01-s10 re-rendered):** the `mark_trail` chip now goes above or below the marked trail, whichever is farther from every avatar. The +N pop sits beside the hero, with its near edge clear of the avatar's body. The K.O.! pop sits 16 px higher. `match_scene(effects=...)` draws capture effects under the numbers. Fireworks are halved (3 bursts of 16 sparks). `avatar_end` shows asks of 13 characters or fewer at size 3.

Per video:
- **s07:** "4 THINGS" badge on the hook board. The name joke is now a name box typing xX_PRO_Xx with a key click per letter. On the teacher card, YOU stays fully in frame on the right while the teacher walks in from the left. The payoff board is 1.3x bigger with a follow camera, and the caption is now "YOUR OWN LINE IS SAFE" (GDD G2: own trail is harmless).
- **s08:** the teacher sits lower and further right, with the tag above his head. The caption reads "...AND THEY'RE OUT!". The second spreadsheet runs 0.6 s. Payoff captions are "LOOP HOME = CLAIM IT ALL" and "NO TEACHER. JUST LOOPS.". The fireworks fire 0.3 s after the +140. The end-card ask is "EVER CAUGHT?" at size 3.
- **s09:** the board moved right for a thick pulsing wall strip (drawn under the board) and a big "<WALL" label. Take A has a grey ghost of YOU where you died, an x4 badge, and all 4 arrows coming from outside the loop. Take B is a tight box flush to the wall (claim at ~2.6 s), with an x1 badge. The skin flip is now one flip to Prism Storm, and the end card comes ~1.4 s sooner.
- **s10:** new, 108 BPM, ~10.8 s. In the hook, YOU (Magma Surge) waits beside pink's marked trail with a crosshair on the strike cell, and the strike on the drop lands at 0.83 s with SNIPED!. After a rewind comes a 3-step replay: 1. FIND A GREEDY LOOP, 2. WAIT... DON'T MOVE (music thins, blip ticks), 3. STRIKE ON THE DROP (flash, SNIPED!). Then THEN LOOP HOME: claim with Lightning, crown, MAGMA SURGE card. End card ask: "SNIPER OR GREEDY?".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s07 | R4 | 6 | 7 | 5 | 7 | 6 | 6 | 7 |
| s08 | R3 | 6 | 7 | 5 | 7 | 7 | 6 | 6 |
| s09 | R2 | 6 | 5 | 6 | 7 | 6 | 6 | 6 |
| s10 | R1 | 6 | 6 | 7 | 8 | 6 | 6 | 7 |

**s07 (R4, 6):**
1. Items 1-3 run 3.3 s with no game on screen. Keep the board under each item and act the joke out on it, at ~0.8 s per item.
2. "YOUR OWN LINE IS SAFE" plays over a K.O. Either show YOU crossing its own trail (green flash, SAFE tag) first, or change the caption to "CROSS THEIRS = K.O.".
3. The teacher is a cropped half-body with no text payoff. Show him fully in frame and add an "ALT+TAB" sub-caption.
4. The board fills only the middle; move REMEMBER PAPER.IO? lower and bigger.
5. The end-card ask strip is small, and the +55 on the end mini-board covers it. Offset or shrink that +55 (shared `avatar_end`).

**s08 (R3, 6):**
1. The hook +55 still pulls focus from the teacher. Drop the hook pop or move it after 1.1 s, and make the teacher about 40% of the frame.
2. The cut/K.O. doesn't read. Use a big K.O.! stamp held 0.4 s+, and keep "...AND THEY'RE OUT!" 0.7 s after it; cut or enlarge the second teacher.
3. WE ALL DID THIS and ALT+TAB! compete on one 0.8 s shot. Pick one, upper third, solid backing.
4. The payoff runs long: trim to ~2.6 s, hold the +142 longer, and keep the particles inside the board.
5. Make EVER CAUGHT? the headline of the end card and drop the end-card +55.

**s09 (R2, 6):**
1. The hook opens on the payoff (+22). Open on take A's danger ("THIS LOOP DIES. WHY?").
2. Take A never shows red crossing the trail: add 2-3 frames of the crash and a freeze. The x4 badge is near the green bot.
3. The TOO LATE! stamp isn't seen in stills: hold it 0.5 s+ over the red player, with the +22 after it.
4. The Prism Storm swap is still off-topic: cut it.
5. The end card is 2.5 s with 3 text blocks: ~1.6 s, a bigger ask. The YOU label is clipped at the board top at 5.95 s.

**s10 (R1, 6; style 8 and clarity 7, the best start so far):**
1. "WAIT FOR IT..." is generic: name the stakes ("ONE STEP = K.O.").
2. The kill barely reads: hold pink in a hit pose 3-4 frames with a big K.O. on the strike cell.
3. The zoom-punch frame is muddy: solid caption panel during the zoom, centred on the strike cell; step 3 caption in white or yellow.
4. Step 2 holds 2.2 s with little change: cut to ~1.2 s and bring the end card ~1 s earlier.
5. The end-card +55 covers players (shared), and the ask bar is small.

**Pattern (now 45 grades, still no 7):** two things are now shared across every grader:
- **The end card.** The mini-match's +55 pop covers the players, and the ask strip is too small. Next run: pop off on the end mini-match, and make the ask the headline.
- **Kills.** They need a visible contact hold: 3-4 frames of the attacker on the trail plus a big K.O. stamp, not just particles. Build a `freeze`-style hold in `match_scene` (sim time pauses 0.25 s at a cut).

Next run: those two shared fixes, then s10 (R2), s07 (R5), s08 (R4); s09 at R2; s06 at R4. Then idea #15 (Stat Boosts).

## Run 2026-11-22 06:53 (weekend task): s07 R5, s08 R4, s10 R2 reworked, s11 (idea #15 Stat Boosts) new. No 7.
**Applied (shared, `tools/video/hype.py`; s01-s11 re-rendered):**
- `match_scene(freeze=0.3)` pauses the sim at a cut, keeps the victim on screen in a hit pose inside a flashing box, and shows a big K.O.! over it (opt-in; used in s07, s08, s10).
- `match_scene(pops_on=False)` turns off +N pops; the end-card mini-match uses it, so nothing covers the players or the ask.
- `avatar_end(ask=...)`: the ask is now the headline (size 4, 2 lines) under the logo, the mini-match sits under it, then one line COMING SOON TO ROBLOX, then the CTA. Asks shortened to fit: DRAW OR WIN?, YOUR .IO NAME?, YOUR BEST TIP?.

Per video:
- **s10:** hook caption "ONE STEP = K.O."; no K.O. zoom (the freeze replaces it); the wait cut from 4 to 2.5 beats, so the strike comes ~1.1 s sooner; step 3 caption in yellow; end card ~1 s earlier.
- **s07:** list items 1.5 beats each (were 2); teacher fully in frame with an "ALT+TAB!" line; "REMEMBER PAPER.IO?" bigger and lower; payoff caption "CROSS THEIRS = K.O." with the freeze on the cut.
- **s08:** no +N in the hook; the teacher further in; the ALT+TAB! stamp on the spreadsheet dropped (one message per shot); freeze on the cut; payoff trimmed to 4.8 beats.
- **s11:** new, 108 BPM, 12.8 s, numbers from Config.Upgrades / GDD G3.3. The hook is a 5x5 spawn that jumps to 11x11 on a LEVEL UP flash at 0.42 s. SPAWN SHIELD 3s > 5.5s: yellow runs through your trail, BLOCKED!. COIN BOOST x3 on a +142 loop. Then a stat sheet with 4 bars filling to max, and the end card "WHICH FIRST?".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s07 | R5 | 6 | 6 | 5 | 7 | 6 | 6 | 7 |
| s08 | R4 | 6 | 8 | 6 | 7 | 7 | 6 | 6 |
| s10 | R2 | 6 | 7 | 6 | 7 | 7 | 6 | 6 |
| s11 | R1 | 6 | 5 | 5 | 7 | 6 | 6 | 6 |

**s07 (R5, 6; one round left):**
1. The hook frame is crowded (title, 4 THINGS, +55, REMEMBER PAPER.IO?). Drop REMEMBER PAPER.IO?, fold the badge into the title ("ONLY .IO KIDS REMEMBER THESE 4"), and keep the +55 off the loop.
2. Items 1-3 still have no board. Keep a board behind each item.
3. The Neon Pulse navy-dot turf reads as holes. Use a bright skin.
4. The K.O. on "CROSS THEIRS = K.O." doesn't show in the sampled frames. Make it a big stamp plus shake, held longer.
5. The end-card YOU tag sits on the crown; COMING SOON is thin.

**s08 (R4, 6; hook 8, the best hook yet):**
1. WE ALL DID THIS sits over the spreadsheet header: solid panel or move it.
2. The teacher needs teacher cues (glasses, mug).
3. LOOP HOME = CLAIM IT ALL plays before the claim lands: close the loop inside that caption, and hold +142 big and centred.
4. End card: the logo reads into the ask ("TURF LOOP EVER CAUGHT?"). Add a gap below the logo.
5. The K.O.! panel and AGAIN?! tag are small and cramped by the teacher.

**s10 (R2, 6):**
1. The kill still doesn't read in the sampled frames. Hold longer (0.5 s), with a big K.O.! and the pink trail wiping cell by cell.
2. The SNIPED! stamp at 5.0 s runs under THEN LOOP HOME: end it at 5.8 s.
3. The GREEDY LOOP chip overlaps pink's home and runs past the board edge.
4. The +10 payoff is small and the MAGMA SURGE card covers the claim.
5. End card: gap between the logo and the ask, bigger mini-board.

**s11 (R1, 6):**
1. The 5x5 > 11x11 jump lands before the first sampled frame. Hold 5x5 ~0.4 s and jump on a downbeat, with a stake line ("SPAWN 5X BIGGER").
2. The core rule is never taught. Add "LOOP HOME = YOUR LAND" and a "without shield" K.O. flash before BLOCKED!.
3. The yellow runner overlaps YOU at the block. Hit the trail away from YOU, with BLOCKED! at the impact point.
4. The coin section has no "1X > 3X" line under the board.
5. The stat bars fill too slowly (two still empty at 9.05 s), and the end-card COMING SOON is thin.

**Pattern (now 49 grades, still no 7):**
- **The contact sheet only samples every ~0.8-1.1 s.** Short holds (0.3 s freeze, 0.4 s jumps) are invisible to graders, who flag "kill doesn't read" even when it is on screen. Next run, as a shared fix, either sample the sheet at the timeline's key moments (stamps and cut events) or hold every key moment 0.6 s or more.
- **End-card logo and ask collide.** Add 10-15 px between them, give COMING SOON a dark plate, and keep the YOU tag off the end mini-board.

Next run: those two shared fixes, then s07 (last round), s08 (R5), s10 (R3), s11 (R2). s06 is at R4, s09 at R2, s01 at R4. Then idea #16 (New Game+ / Rebirth).

## Run 2026-11-22 09:52 (weekend task): s07 R6, s08 R5, s10 R3 reworked, s12 (idea #16 Rebirth) new. FIRST 7: s10 passes.
**Applied (shared; s01-s12 re-rendered):**
- `engine.Video.keys`: stamps and `match_scene(freeze=...)` K.O. holds register key moments. Each one replaces the nearest even sample on the contact sheet, which stays 12 frames in time order, so graders see 0.3-0.5 s holds. The video itself is unchanged.
- `avatar_end`: the ask sits 14 px below the logo (it read as "TURF LOOP EVER CAUGHT?"). COMING SOON TO ROBLOX is on a full-width dark plate with a yellow outline. There is no crown on the end mini-board, so the YOU tag no longer sits on it. The CTA button is taller (326-396), so the 2-line text isn't clipped; this last change came after grading, from 3 of 4 graders.
- K.O. freezes are 0.5 s (were 0.3-0.35) in s07, s08 and s10.

Per video:
- **s07:** hook caption "4 THINGS ONLY .IO KIDS GET"; no badge, sub-line or +N on the hook; a dimmed live board behind every list item; Magma Surge instead of Starfall.
- **s08:** the teacher has glasses and a coffee mug and a bigger tag; WE ALL DID THIS sits mid-screen, off the spreadsheet header; the payoff shows a big centred +142 chip under the board for 1.6 s.
- **s10:** bigger payoff loop (+14); "GREEDY!" chip; the MAGMA SURGE card sits under the board; SNIPED! ends as THEN LOOP HOME starts.
- **s12:** new, 108 BPM, 12.2 s, numbers from Config.Rebirth / GDD G3.4 / Catalog crownSkins. The hook is a huge Prism Storm turf with a 150,000 coin chip; REBIRTH is pressed at 0.42 s, then crowns rain, +1 CROWN, +50 GEMS. 1. COINS + UPGRADES RESET: the coins roll to 0, the bar drains, BACK TO 5x5. 2. +25% COINS PER CROWN, FOREVER: a live claim while a crown counter steps x1.25 > x1.50 > x1.75 > x2.00. 3. CROWN-ONLY SKINS: Bronze (1), Silver (3), Gold (5), Diamond (10). End card ask: "REBIRTH OR GRIND?".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s07 | R6 | 6 | 7 | 5 | 7 | 7 | 5 | 6 |
| s08 | R5 | 6 | 7 | 5 | 7 | 6 | 6 | 6 |
| s10 | R3 | **7** | 8 | 7 | 8 | 8 | 6 | 7 |
| s12 | R1 | 6 | 6 | 5 | 7 | 7 | 6 | 7 |

**s10 (R3, 7: PASS).** Optional polish from the grader:
1. The K.O.! box sits on the crossing cell; move it above the board.
2. The CTA was clipped (fixed after grading).
3. Hold "ONE STEP = K.O." to 1.9 s.
4. Make the claim fill solid, with lightning under 50% opacity, and drop the MAGMA SURGE card.
5. Make the end mini-match bigger.

**s07 (PARKED after 6 rounds, all 6).** Clarity is stuck at 5: the list items read as in-jokes over a dim board, and the mechanic comes late. If reopened:
1. Bring back a big REMEMBER PAPER.IO? in the empty bottom third and scale the hook board up.
2. Hide the dim board's name tags during the skits; they collide with LAG! and the name box.
3. Move the CROSS THEIRS = K.O. caption above the board, clear of the K.O.! banner.
4. Show item 4 as a real cut with a crash flash.
5. Hold the payoff loop-close longer.

**s08 (R5, 6; one round left):**
1. Hook: the TEACHER! tag sits over the play; shrink the teacher ~30% and move the tag above his head.
2. "CUT THEIR TRAIL..." never shows on the sheet: merge into one caption "CUT THEIR TRAIL = K.O." held 1.94-3.6 s.
3. Drop the second spreadsheet (FASTER!) so the payoff starts at ~3.6 s.
4. The K.O.! covers the crossing: delay it 4 frames or move it up (shared with s10 #1).
5. The end card ask competes with the CTA.

**s12 (R1, 6):**
1. The CTA was clipped (fixed after grading).
2. The falling crowns cover the +1 CROWN stamp: draw the crowns under it. The +50 GEMS chip is never sampled: make it bigger or cut it.
3. The hook is meaningless before launch: lead with the payoff ("RESET EVERYTHING FOR x2 COINS FOREVER?") and add 0.5 s of the core loop before the cost.
4. Default yellow turf from the first reset frame; the coin drop should be ~0.3 s and red.
5. Make the caption 2 lines, keep +N off the avatar, make the multiplier counter bigger, and make the end mini-board 1.5x bigger.

**Pattern (now 53 grades, first 7):** the key-moment sampling helped s10 (clarity 7, pacing 8). The next shared fix: K.O.! boxes should sit above the board or appear 4 frames after the contact, not on the crossing cell (s08, s10). The end mini-board is "too small" in every grade: try 1.4x.

Next run: shared K.O. placement and a bigger end mini-board; then s08 (last round), s12 (R2), s11 (R2), s09 (R3). s06 is at R4. Then idea #17 (Rate My Trail).

## Run 2026-11-22 12:53 (weekend task): s08 R6, s11 R2, s12 R2 reworked, s13 (idea #17 Rate My Trail) new. No new 7.
**Applied (shared, `tools/video/hype.py`; s01-s13 re-rendered):**
- `avatar_end`: the end mini-board is 1.33x bigger (cell 8 px, was 6-7). COMING SOON and the CTA move down to follow it.
- `match_scene(freeze=...)`: the K.O.! box goes above or below the victim, whichever is farther from the attacker, so it no longer covers the crossing. Putting it above the board was tried first and dropped, because it hid behind the captions.

Per video:
- **s08:** the teacher is ~30% smaller. The TEACHER!/AGAIN?! tag sits under the board, left of him, off the play. The two captions became one, "CUT THEIR TRAIL = K.O.", held for the whole shot. The second spreadsheet is gone, so the payoff starts at ~3.6 s.
- **s11:** the 5x5 holds for a beat (0.56 s) before LEVEL UP. Captions: "LEVEL UP: 5X BIGGER SPAWN", then "LOOP HOME = YOUR LAND". On the shield shot, the caption reads "NO SHIELD = 1 TOUCH K.O." and yellow hits your trail 7 cells away from YOU, with BLOCKED! at the impact point and NO K.O.! under the board. The coin shot adds "1X > 3X". The stat bars all fill in ~1 s.
- **s12:** the hook caption is "RESET IT ALL FOR +25% COINS FOREVER?". The loop claims at ~0.4 s, then the REBIRTH press comes at 0.83 s. The crown rain stays above the +1 CROWN stamp, and the +50 GEMS chip is gone. The reset shows default turf, with the coins crashing to 0 in red in ~0.3 s. The multiplier panel has crowns and a name on top and a big x1.25-x2.00 under them.
- **s13:** new, 108 BPM, 12.2 s. The hook is the Prism Storm + Stardust combo claiming with Lightning at 0.4 s, under the caption "RATE MY TRAIL 1-10". Then one item every 3 beats on a live loop: Rainbow Streak trail, Stardust trail, Neon Pulse + Hearts, Magma Surge + Fireworks, then the full combo with a 10/10? stamp. A ?/10 chip sits on each board. End card ask: "YOUR RATING?".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s08 | R6 | 6 | 7 | 6 | 7 | 7 | 6 | 6 |
| s11 | R2 | 6 | 6 | 6 | 8 | 6 | 7 | 5 |
| s12 | R2 | 5 | 6 | 4 | 7 | 7 | 6 | 7 |
| s13 | R1 | 6 | 6 | 5 | 7 | 6 | 6 | 6 |

**s08 (PARKED after 6 rounds, all 6; clarity went up from 5 to 6).** If reopened:
1. The hook is busy: cut the caption to 2 lines and drop the tag (the caption already says TEACHER).
2. The spreadsheet is 0.8 s with no game: add a Turf Loop taskbar tab, and snap back on a downbeat with a swoosh.
3. The K.O. is small: zoom 1.5x on the cut, and move the THEIR TRAIL label off the trail.
4. The +142 box is clipped at the bottom of the frame: move it up. Start the payoff on the loop close.
5. End ask: "WHAT WAS YOUR ALT+TAB GAME?" instead of "EVER CAUGHT?".

**s11 (R2, 6; style 8):**
1. Open on the LEVEL UP burst at frame 0, and claim by 0.8 s. "5X" over-promises: 121/25 is 4.8x, so say "5x5 > 11x11 START".
2. "NO SHIELD = 1 TOUCH K.O." contradicts the picture, where the shield is on. Use "SPAWN SHIELD: THEY CAN'T CUT YOU", or show 0.5 s of a no-shield K.O. first.
3. The coin scene stalls: ~1.8 s, with a coin counter ticking 142 > 426 instead of the static 1X > 3X.
4. The stat sheet reads as pay-to-win: add "FREE, EARNED IN-GAME", drop SPEED (it's never shown), and cut the sheet to ~1.5 s.
5. "WHICH FIRST?" has no options: add A/B/C chips (BIG BASE / SHIELD / x3 COINS) and "COMMENT A, B OR C".

**s12 (R2, 5; down from 6):**
1. The 150,000 chip sits on an avatar and the +142 covers the claim. Move the chip under the board, and make REBIRTH 2x bigger with a visible tap.
2. Rebirth is late-game, so new viewers lack context. Open on the crown rain at 0.0 s, then the back-story; or add a "LOOP = LAND" tag.
3. Prove +25% in play: the +N should scale with the multiplier (+55 > +64 on the same claim). The x2.00 step should be a stamp on the beat.
4. The crown skins read as plain orange and yellow: add shimmer or sparkle and a lock-to-unlock pop, and show all 4 (hold DIAMOND as the reveal).
5. Drop the corner brand tag in mid scenes. Make the end mini-match avatars bigger.

**s13 (R1, 6):**
1. One ?/10 over five items is muddled: show a score under each item as it exits (4/10 ... 8/10), and keep ?/10 for the final combo only.
2. The hook payoff fades by 1.5 s: replay the lightning on beat 2 and add a +N. Drop the hook name card.
3. Items 1-2 (plain trails on default turf) are weak, and Stardust repeats the hook. Cut to 3 items at ~1.3 s, each closing with an effect.
4. Capture effects are too small: particles 3-4x bigger, burst from the claim centre, kept off the chip row, with a white flash on each claim.
5. End card: a bigger COMING SOON, "COMMENT YOUR SCORE 1-10", and one visible claim in the end mini-match.

**Pattern (now 57 grades; one 7 so far, s10).** Repeated across all four: the end card's COMING SOON line is too thin (it is now the main end-card complaint), and capture-effect particles are too small to read. Next run's shared fixes: COMING SOON at size 3 on its own row, and particles 2-3x bigger.

Next run: those two shared fixes, then s11 (R3), s13 (R2), s12 (R3), s09 (R3). s06 is at R4. Then idea #18.

## Run 2026-11-22 15:52 (weekend task): s11 R3, s12 R3, s13 R2 reworked, s14 (idea #18 Living Woodland) new. No new 7.
**Applied (shared, `tools/video/hype.py`; s01-s14 re-rendered):**
- `avatar_end` (with an ask): COMING SOON TO ROBLOX is now size 3 on two rows of its own, on the dark plate. To make room, the logo, the ask and the mini-board moved up 16 px.
- `Effects`: capture-effect particles are 2-2.5x bigger. Sparks are 10 px and fly faster, bubbles are 2x with thicker rings, lightning bolts are 2x as thick, and hearts are 2.25x (10 of them instead of 20).
- `tree(..., z=)` takes a scale. New `rock`, `mushroom`, `forest` and `draw_forest` helpers make props grow in on each claim.

Per video:
- **s11:** the LEVEL UP burst is on frame 0, and the loop starts 4 steps from home, so it claims at about 0.75 s. Captions: "LEVEL UP: 5x5 > 11x11 START" (no more "5X"), then "LOOP HOME = YOUR LAND". The shield shot has one true caption, "SHIELD: THEY CAN'T CUT YOU". The coin shot is 4 beats with a counter that ticks +142 > +426. The stat sheet is labelled A START / B SHIELD / C COINS with "FREE. EARNED IN-GAME.", and SPEED is gone. The end ask is "COMMENT A, B OR C".
- **s12:** a 0.4 s crown-rain teaser opens it. The REBIRTH button is 2x bigger, and a hand taps it. The 150,000 chip sits under the board, and there is no +N over the claim. The panel shows LOOP +69 > +110 as the crowns stack, and a "x2 COINS!" stamp lands on the top step. The crown skins go three quick ones with DIAMOND held, each with a lock that pops to UNLOCKED! and a shimmer band. The corner tag is gone in the mid scenes.
- **s13:** cut to the hook plus 3 items plus the combo (10.5 s). The hook has +N and its lightning replays on beat 2, with no name card. Items: NEON PULSE + RAINBOW + HEARTS, GALAXY SWIRL + BUBBLES (Starfall read as holes), MAGMA SURGE + FIREWORKS. Each one gets a white flash on the claim and a score that lands on its last beat (6/10, 7/10, 8/10). The end ask is "YOUR SCORE 1-10?".
- **s14:** new, 108 BPM, 12.2 s, Catalog `biome_woodland`. The hook is a huge loop on grass turf that closes at 0.4 s, and trees, rocks and mushrooms sprout in a wave from the closing point. Next, red runs at your open trail (red ring, DANGER!), you get home one step ahead, SAFE! lands and the forest grows. Then a close-up of the forest with props popping 2 per beat and the LIVING WOODLAND / LEGENDARY BIOME card. The end ask is "FOREST OR NEON?".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s11 | R3 | 6 | 5 | 5 | 7 | 6 | 6 | 6 |
| s12 | R3 | 6 | 6 | 5 | 8 | 6 | 6 | 6 |
| s13 | R2 | 6 | 6 | 4 | 7 | 6 | 6 | 6 |
| s14 | R1 | 5 | 6 | 5 | 7 | 5 | 6 | 6 |

**s11 (R3, 6):**
1. The hook is jargon. Say "START WITH 4X THE LAND", jump at 0.0 s, and run LOOP HOME = YOUR LAND from 0.0 s as a subtitle.
2. At 1.5 s, "5x5 > 11x11" under the board competes with the caption, and +42 is clipped at the right edge. Hide the label during the loop and centre the +N.
3. The counter reads "+142 > +142" before it ticks, which looks like a bug. Show +142, then "x3 = +426" on a beat. Clip the particles to the board.
4. The shield shot is too long (two nearly identical frames). Cut it to about 2 s with the hit by 0.6 s, and move BLOCKED! above the impact.
5. The end card should show A/B/C option chips. Fill the stat bars in sync with the chime.

**s12 (R3, 6; style 8):**
1. The hook is crowded and the tap lands late (1.25 s). Tap at about 0.5 s with a 1.5x centred button, and use a 2-line caption ("RESET EVERYTHING? / +25% FOREVER").
2. The +55 pop and LOOP +69 disagree. Show "+55 > +69", and make the panel side text 2x bigger.
3. The crown skins read as turf, not hats. Rename them "BRONZE TURF" etc., or change the hat too. Show all 4 as a fast strip and stamp "10 CROWNS = DIAMOND".
4. The reset section repeats itself. Cut it to about 1.3 s and add a 1 s core-loop shot early.
5. Shorten the end card to about 2 s and double the mini-board.

**s13 (R2, 6; clarity 4):**
1. The hook lightning crosses the player and the +46. Keep the bolts off the centre third, put the +N above the head, and add a small "PRISM STORM + STARDUST" line.
2. The loop mechanic is never shown, because each item starts with the loop already drawn. Show the last 0.5 s of the trail closing, and add "LOOP HOME = CLAIM" once.
3. Effects cover the player. Keep a clear circle around him, and cut the 7.75 s white flash to 3 frames.
4. Rarity labels should be 1.5x bigger. Shorten "3. MAGMA SURGE + FIREWORKS".
5. The scores rise predictably. Make one a surprise ("2/10??"), show the comment prompt at the 10/10? stamp, and raise the CTA above COMING SOON.

**s14 (R1, 5):**
1. The middle loop drags (the close lands at 5.1 s). Close by about 3.4 s and add a hit-stop on the near miss.
2. Drop the repeated "GET HOME!" under the board and use a +TREES counter instead.
3. In the hook, the forest is already grown by the first sampled frame. Start 0.5 s earlier on a visible trail, fire the wave at about 0.5 s, and fill the band under the board before 1.1 s.
4. The end card is 4 s, and "FOREST OR NEON?" names a biome the video never shows. Use about 2.5 s and "WHICH BIOME IS YOURS?", with woodland turf on the mini-match.
5. The name card shows twice. Keep only the close-up reveal, bigger, and put "LOOP = LAND" at 1.5 s.

**Pattern (now 61 grades; one 7, s10).** Three of the four say "a new viewer never sees how the game works" (clarity 4-5), and three call the end card too long. Next run's shared fixes:
- Every video teaches the loop once: show the trail being drawn and closed, with "LOOP HOME = YOUR LAND", inside the first 2 s.
- Cut end cards to about 2.5 s.
- Keep particles clear of the hero (a radius of about 1.5 cells).

Next run: s11 (R4), s12 (R4), s13 (R3), s14 (R2). s06 is at R4 and s09 at R3. Then idea #19 (30 Tiers in 30 Beats).

## Run 2026-11-22 18:52 (weekend task): s11 R4, s12 R4, s13 R3 reworked, s15 (idea #19 30 Tiers in 30 Beats) new. No new 7.
**Applied (shared, `tools/video/hype.py`):**
- `Effects.fire(..., avoid=(x, y, r))`: particles and bolt columns don't spawn inside that circle, and bolts are near-vertical when avoiding. Without `avoid` the output is unchanged, so the other videos were not re-rendered.
- `name_card(..., tier_size=)`: the rarity line can be bigger (s13 uses 3).
- End cards are now 2.5-2.8 s in s11, s12, s13 and s15.

Per video:
- **s11:** the hook caption is "LEVEL UP: START WITH 4X THE LAND", with LOOP HOME = YOUR LAND under the board from 0.0 s. The shield shot is 2.5 s, the hit lands at ~0.4 s, and BLOCKED! sits above the impact. The coin shot shows +142, then "x3 = +426" on the next beat. The stat chips are A: BIG LAND / B: SAFE SHIELD / C: COIN BOOST, and the end card keeps A LAND / B SAFE / C COINS option chips. 11.9 s.
- **s12:** there's no teaser now: the claim lands at 0.37 s and REBIRTH is tapped at 0.56 s. The caption is "RESET EVERYTHING? +25% FOREVER". The reset is 1.4 s. The panel reads "+55 > +69 ... +110" with a smaller multiplier. The crown skins come one per beat as "BRONZE/SILVER/GOLD/DIAMOND TURF" with "N CROWNS TO UNLOCK". 11.9 s.
- **s13:** the hook teaches "LOOP HOME = CLAIM" and names PRISM STORM + STARDUST. Effects stay ~2 cells clear of YOU, and the flash is softer and 2 frames long. Rarity is 1.5x bigger. Scores go 8/10, a red 3/10?? surprise, then 9/10. The last caption is "COMMENT YOUR SCORE!". 11.1 s.
- **s15:** new, 108 BPM, 15.3 s. The hook is a Prism Storm (tier 30) loop that claims +142 with Lightning at 0.37 s. Then the whole Season 1 Neon Rush track runs one tier per half beat (FREE/PREMIUM cards at 2x size, a 30-tier bar, NEXT LEGEND: TIER N). Tiers 1/10/20/30 hold on a full animated legendary swatch with your avatar and a name card, and a TIER 30! stamp lands. Captions: 30 TIERS. FREE + PREMIUM. / XP FROM DAILY MISSIONS / SEASON 1 AT LAUNCH. End ask: "WHICH LEGENDARY?".

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s11 | R4 | 6 | 6 | 5 | 7 | 7 | 6 | 8 |
| s12 | R4 | 6 | 7 | 5 | 7 | 7 | 6 | 6 |
| s13 | R3 | 6 | 7 | 5 | 8 | 7 | 6 | 7 |
| s15 | R1 | 5 | 4 | 4 | 7 | 6 | 6 | 6 |

**s11 (R4, 6; cta 8):**
1. The 5x5 "before" lasts only 0.42 s, so the 4X jump never registers. Hold a tagged 5x5 for ~0.8 s, then slam it to 11x11 on a downbeat with a shake and a big "5x5 > 11x11".
2. The shield save isn't visible: no BLOCKED! in the samples, and the yellow and blue trails tangle. Freeze 3-4 frames on the cross point with a big BLOCKED! stamp. Change "3S > 5.5S" to "SHIELD 3s > 5.5s".
3. Coin-boost particles land on the caption and the "+426". Clip them to the board, under the caption layer. The "C: COIN BOOST" label is cut by the meter.
4. In "B: SAFE SHIELD" the pips run into the text. Shorten it to "B: SHIELD".
5. Add a "LOOP = CLAIM LAND" ghost line over the hook board. Fill the stat bars within 0.3 s.

**s12 (R4, 6; hook 7):**
1. The x2 COINS! zoom punch crops the HUD ("{2.00 +11") and pushes the board under the caption. Keep the HUD and caption out of the zoom.
2. The core loop is never explained. Add a fast trail-loop-claim with +N before the tap, plus "LOOP TO CLAIM".
3. The crown skins only appear as swatches. Show them painting turf on a board. SILVER barely differs from the grey board. Put UNLOCKED! on a dark plate.
4. Make the multiplier 1.5x bigger with a gold flash on each step. Drop or shrink +69/+110.
5. The end ask needs options (chips). Hold the end card still for the last 1 s.

**s13 (R3, 6; style 8):**
1. "LOOP HOME = CLAIM" is too small: make it 1.5x, white on a panel. Move the combo name into a LEGENDARY rarity box.
2. The red 3/10?? chip is too wide and low-contrast. Use white with a red outline, the same width, and a "WHAT?!" pop.
3. The final combo has no rarity box (the layout jumps), and the claim flash washes out Prism Storm. Add a box and cap the flash.
4. The scores look random. Add a reason tag, or go low to high (3, 8, 9, 10?).
5. The bots never act. Have one cut try (or a CUT!) in one round to teach the danger.

**s15 (R1, 5):**
1. "THE WHOLE TURF PASS. GO!" means nothing to a stranger. Lead with a payoff ("FREE ANIMATED SKINS..."), and zoom and shake the +142.
2. The bottom ~35% of the pass frames is empty. Make the cards and swatches 1.4x bigger and lower, or put a looping gameplay strip there.
3. The reward cards are cryptic: label them "2X XP 15 MIN", "4,500 COINS", "20 GEMS", "CRATE KEY".
4. 11 s of menu is too long. Flash tiers 2-9 and 21-29, and spend the time on Prism Storm in a real match. Land TIER 30! by ~8 s.
5. End card: put space between COMING SOON and FOLLOW, and show the 4 legendaries as answer options.

**Pattern (now 65 grades; one 7, s10).** Every grader again scored clarity 4-5: "a new viewer never learns the game". A small "LOOP HOME = ..." line under the board isn't enough. The shared fix for the next run: a 1 s teaching beat (trail drawn, closes, fills) with a big plated "LOOP HOME = YOUR LAND" in the first 2 s of every video, and option chips on every end ask.

Next run: s11 (R5), s12 (R5), s13 (R4), s15 (R2). s14 is at R2, s06 at R4 and s09 at R3. Then idea #20 (Your Brain on Turf).

## Run 2026-11-22 21:53 (weekend task): s11 R5, s12 R5, s13 R4 reworked, s16 (idea #20 Your Brain on Turf) new. No new 7.
**Applied (shared, `tools/video/hype.py`):**
- New `teach(img, y, text)`: a big plated white rule ("LOOP HOME = YOUR LAND", size 3, wrapped to 2 lines) for the first seconds of a video. Used in s11, s12, s13 and s16.
- `avatar_end(..., opts=[(label, colour), ...])`: answer chips for the ask on the mini-board's bottom row (s11, s12, s13, s16). Without `opts` the output is unchanged, so the other videos were not re-rendered.

Per video:
- **s11:** a tagged 5x5 holds 0.83 s, then a "5x5 > 11x11" stamp slams (shake, flash) and the claim lands at ~1.6 s. The hook caption is "LEVEL UP = 4X THE LAND" on 2 lines. The shield shot holds 0.4 s on the contact with a big BLOCKED! stamp. Shorter labels: "B: SHIELD", "SHIELD 3s > 5.5s". The coin numbers sit on a dark plate, and the stat bar is narrower so "C: COIN BOOST" isn't cut. The stat bars all fill within ~0.3 s.
- **s12:** "LOOP = LAND" plate on the hook. The K.O. zoom in the multiplier scene is off (it cropped the panel). The multiplier is 1.5x bigger with a gold flash on each step, and x2 COINS! sits inside the panel, not as a stamp. The skins wipe across the swatch. UNLOCKED! is on a dark plate. End chips are REBIRTH / GRIND.
- **s13:** the teach plate on the hook, then a LEGENDARY COMBO name card. The scores run 3/10?? (white on a red chip, with a WHAT?! pop), then 8/10, then 9/10. The claim flash is capped at 15%. The final combo gets a rarity box, and 10/10? sits over the board. End chips are 1-3 / 4-7 / 8-10.
- **s16:** new, 108 BPM, 12.2 s. The hook is a Prism Storm loop that claims +142 with Lightning at ~0.4 s, captioned "WHY DOES THIS FEEL SO GOOD?". Under the board a pixel brain sits next to a FEEL-GOOD meter that jumps on every claim. Three reasons, each shown in play and lit as a chip: 1. CLOSURE (the trail is drawn and snaps shut), 2. RISK (red hunts your open trail, DANGER!, you get home one step ahead, SAFE!), 3. REWARD (Magma Surge + Rainbow Streak + Fireworks, the meter hits MAX!). End ask: "WHICH HOOKS YOU?" with CLOSURE / RISK / REWARD chips.

| Video | R | Overall | hook | clarity | style | pacing | readability | cta |
|---|---|---|---|---|---|---|---|---|
| s11 | R5 | 6 | 5 | 6 | 8 | 7 | 6 | 7 |
| s12 | R5 | 6 | 6 | 5 | 7 | 6 | 5 | 6 |
| s13 | R4 | 6 | 6 | 5 | 8 | 6 | 5 | 7 |
| s16 | R1 | 6 | 6 | 6 | 7 | 6 | 6 | 7 |

**s11 (R5, 6; clarity up from 5 to 6, one round left):**
1. The hook is abstract before the stamp, and two captions compete. Fire 5x5 > 11x11 at ~0.3 s, and hide the teach plate until 0.9 s.
2. The coin scene shows +142 twice, and grey and green particles read as glitches. Show the number once, on the plate only; make the particles yellow coins or drop them.
3. BLOCKED! covers the contact point. Put it above the contact, smaller, with a flash on the touch.
4. C COINS has no value at 7.4 s: land all three values by 7.6 s.
5. The end option chips are tiny, and "C COINS" is clipped. Use 2x buttons, with one primary ask.

**s12 (R5, 6; one round left):**
1. The hook top is crowded: drop LOOP = LAND, use a 2-line caption, and bring the crown rain to ~0.3 s.
2. x2 COINS! overlaps x2.00, and the ochre flash muddies the digits. Put the tag above the panel, keep navy, and make the crown pips 2x.
3. SILVER is grey on grey, and the DIAMOND hold is dead. Paint each skin on the real board with the avatar looping.
4. The teach card covers the loop it describes. Move it under the board, and add a clean 0.5 s close before the multiplier.
5. Make the REBIRTH/GRIND chips big filled buttons with "COMMENT ONE", and put COMING SOON on one line.

**s13 (R4, 6; style 8):**
1. Three text blocks compete in the hook: delay the teach plate, move +46 off the trail, make ?/10 big from frame 0.
2. "LEGENDARY COMBO" overflows its box: split it or shrink it.
3. The 1.35 s label says PRISM STORM over plain yellow turf. Make the shown skin match.
4. 3, 8, 9 still reads as predictable: try 8, 3?!, 9, at ~1.1 s each, plus one cut to show elimination.
5. Hide ?/10 under the 10/10? stamp, and make the end vote chips 2x taller.

**s16 (R1, 6):**
1. Lightning hides the loop closing: show the snap and fill for 0.3 s first, and tag YOU in the hook.
2. Ownership colours: YOU is blue but claims pink/cyan land, the same as the pink bot. Give the bots colours that never appear in YOU's land.
3. The RISK attacker looks orange with a red trail. Make it red, and move SAFE! off the closing point (≤0.4 s).
4. REWARD is crowded: add a 0.5 s close-up with a big name card. Cut the end card to ~1.8 s.
5. Make the meter label and chips 1.5x bigger, raise the contrast of inactive chips, add a % number, and make TURF LOOP as big as the ask.

**Pattern (now 69 grades; one 7, s10).** The teaching plate moved clarity up only in s11 and s16 (to 6). New repeated complaints: option chips on the end card are too small (all four), and stacked text blocks in the hook (three of four). Next run's shared fixes: 2x-tall filled option buttons in `avatar_end`, and never more than 2 text blocks in the first second (the teach plate comes in after 0.9 s).

Next run: s11 and s12 (last rounds), s13 (R5), s16 (R2). s15 is at R1, s14 at R1, s09 at R3 and s06 at R4. Then idea #21 (Pick a Colour, Get Your Playstyle).

## Promo codes (2026-11-22, owner request)
Every video now ends with a 3-beat code card: the code is typed in, REDEEM is pressed, the reward is shown, then "WORKS AT LAUNCH". The card comes from `code_card` in hype.py through `END_HOOKS`.
- One code per theme (`CODE_FOR`):
  - PAPERIO (nostalgia and cosmetic videos): Retro Lab skin + 1,000 coins.
  - NEONRUSH (pass and progression): Rush Hour trail + 25 gems.
  - KINGME (crown and fights): Royal Carpet skin + 25 gems.
  - BIGLOOP (strategy): 2,500 coins.
- New videos default to PAPERIO.
- `c01_launch_codes` is new: all four codes in one video. Not graded yet.
- The codes are NOT in the game yet. They are item 0 of the queue in docs/HANDOFF.md. Don't post anything until they work.

# Turf Loop shorts: grades

Running: 

Pass mark 7/10 overall from a fresh grader subagent (`GRADER_PROMPT.md`). Max 6 rework rounds per video (raised from 3 on 2026-11-20: all five plateaued at 6 and the owner asked for 7+), then parked with reasons.

| Video | Idea | R1 | R2 | R3 | Status |
|---|---|---|---|---|---|
| v01_computer_lab | #1 | 5 | 6 | 6 | rework |
| v02_zero_to_hundred | #2 | 5 | 6 | 6 | rework |
| v03_how_to_play | #3 | 5 | 6 | 6 | rework |
| v04_own_line | #4 | 5 | 6 | 6 | rework |
| v05_loop_math | #5 | 6 | 6 | 6 | rework |

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

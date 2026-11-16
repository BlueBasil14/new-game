# Hand-off: Turf Loop

_Rewritten 2026-11-16 by the lead session (Fable) for whichever model leads next. Read this, then the last 60 lines of `docs/PROGRESS.md`, then `docs/COORDINATION.md`. `CLAUDE.md` has the standing rules._

## 1. The game in one paragraph
A drop-in 16-player Roblox arena. You run out of your coloured turf leaving a trail, loop back, and everything you circled becomes yours. Anyone who crosses your trail while you are outside eliminates you; crossing your own trail is harmless. No rounds. Bots (wearing the joining player's friends' avatars) keep the server at about 10 runners. Coins buy upgrades and cosmetics; Rebirth gives Crowns. 160 × 160 grid of 4-stud cells; the server ticks at 20 Hz and reads character positions itself. Full design: `docs/GDD.md`; it is behind the code in the places listed in section 6.

## 2. Where it stands
**Built and seen working in Studio (solo):** the core loop; HUD, shop, upgrades, daily, quests, codes, rebirth, settings panels in the paper style; capture effects (fill sweep from the loop-close point, star burst, combo, big-capture banner); dark trail with pulsing rim; speed lines, hit-stop, elimination pop, wall fade; R15 friend-avatar bots; friend coin bonus and Invite button; streak bonuses at days 14/21/28; background music with no UI; Skip Music and 2x Speed passes (through the Studio test grant); neutral grey floor.
**Built, passes headless tests, not seen in Studio by the lead:** the Sky Chest (another session's work; its own solo test is described in `docs/SKY-CHEST.md`); the security fixes in section 3.
**Seen with two clients once (2026-11-12):** identical turf on both, a cut across clients. Not repeated since the bots, passes or Sky Chest were added.
**Never done:** a real purchase; two real accounts that are friends; a real phone; anyone listening to the sounds; a person judging how the effects feel at real speed.
**Not built:** real Roblox ids (all passes/products zero except the Sky Chest product), badges, group, icon, thumbnails, video, the week-two content, skin patterns (GAP-17), the three empty sounds.

## 3. Security review: read `docs/SECURITY_REVIEW.md`
Two read-only reviews found **four Critical** problems (free gamepasses by spoofing the purchase-finished signal; three ways to bypass the server's movement checks or get honest players kicked) plus High and Medium items. Fixes were in progress when this was written: the "Fix log" at the bottom of that file says what landed and what was tested. **Do not launch with any Critical or High item still open.** Items left open on purpose: M4/M5 (they trade against each other and need real-device data) and the Low items.

## 4. Decisions waiting on the owner: `docs/DECISIONS.md`
Paid Sky Chest spin, strength of 2x Speed, bot tag, Starter Pack repeats, week-two content, title, art briefs for the grey floor. Do not decide these for him; do apply his answers quickly.

## 5. Queue, in order
1. Finish and verify the security fixes (section 3). Then one solo Studio pass on the local build: walk, claim, get cut, respawn, press Reset during a death, try to stand outside the wall. Honest play must produce no snap-backs.
2. Apply the owner's answers from `docs/DECISIONS.md`.
3. Balance changes from `docs/BALANCE.md` that need no owner input: rebirth growth 2 → 1.5 through a new `Config.Rebirth.Growth`; playtime rewards and the gentle-bot window keyed to the profile instead of the session; Sky Chest free rate; rare price. Each is a Config value or a small server change with a spec line.
4. Two-player test again (`docs/STUDIO.md` explains how to start it), now covering: friend bot removed when the friend joins, friend chip, Sky Chest pickup race, players no longer colliding.
5. Phone layout pass on the 750x381 view: HUD buttons near the thumbstick, shop cards, daily panel, capture banner.
6. Capture moment, critic round two: the first round said "not yet better than Paper.io 2" and its fixes were applied but never re-judged. Fresh screenshots on the grey floor, then a critic subagent, then tune `Config.CaptureFx` / `Config.TurfFx`. Also still open from round one: the HUD does not react to a capture (pulse the territory percent and the coin chip).
7. Open bug: `No asset content representation` in Output for Arcade Commons images used as particle textures (economy_star, economy_energy, economy_coin). Stars still render. Cause unknown.
8. Money review of the Sky Chest purchase and save path (it was added after the money review).
9. Launch steps: `docs/LAUNCH_CHECKLIST.md`. Retention plan: `docs/ALGORITHM_PLAN.md`.

## 6. Where the code and the design disagree (code is right unless the owner says otherwise)
- GDD G4.4 "no purchase affects speed" and "no paid random items": the 2x Speed pass and the paid Sky Chest spin exist on the owner's and another session's initiative.
- GDD G8 pale floor `#EEF1F5`: the floor is neutral grey `#B4B5B8` with lower lighting, at the owner's request.
- GDD G3.6 item counts: one extra exclusive skin (`streak_month`).
- GDD G3.4 "later rebirths take 3–4 h": the formula doubles each time (see `docs/BALANCE.md`).
- `docs/TASKS.md`, `docs/GAPS.md`, `docs/PLAYTEST.md` and the two `REVIEW_*.md` files are historical; this file and `docs/PROGRESS.md` are current.

## 7. Traps that cost time
- **Other sessions edit this folder and this Studio.** A ChatGPT session and a terminal Claude session have added whole features overnight (icons, sound system, paper restyle, Sky Chest) without committing. Always `git status` first. Uncommitted files you did not touch are theirs. If they have been quiet for hours and the checks pass, the lead may commit them as a separate commit saying whose work it is; never mix them into your own commit.
- **Studio:** everything in `docs/STUDIO.md`. The short version: never edit scripts in Studio, automated clicks do not register (use the debug hooks), never teleport the test character, the cloud place is placeId 80441552680451, and Studio may have a completely different project open.
- **Python is `py`.** Git Bash is the shell for the Bash tool; PowerShell 5.1 for the other.
- **Usage limits** cut subagents off mid-edit. Their work so far stays on disk. Check `git status` and the checks, then resume the same agent rather than starting a new one.
- **The headless mock has no physics, no client and no rendering.** Passing headless means the server logic holds, nothing more.
- **Figma connector** is on a free plan and runs out of calls; view the file in Chrome instead (`https://www.figma.com/design/SBmxYlWaXA5TQZM2AQGIQL`). The uploaded icon ids are in `src/shared/ArcadeIcons.luau`.

## 8. Delegating
Lead = strongest model available. Opus: anything touching saves, money, the request router, `ArenaService`, `ArenaSim`, `TurfRenderer`, and cross-system bugs. Sonnet: one system with a clear spec (HUD, panels, feedback, camera, bots, rewards). Haiku: one file, exact inputs, exact acceptance check. Run agents in parallel only when their file sets do not overlap; `Config.luau` and the mock are shared, so tell each agent to re-read before every edit and add only its own block.

Every brief contains:
1. **Goal** in one or two sentences, with the finding or task id.
2. **Read only these**: exact files and GDD section ids.
3. **Evidence**: the Output lines, the failing check, or the owner's words quoted.
4. **Your files**: what it may edit; everything else read-only; which files other agents hold.
5. **Decisions already made** by the lead, so it does not redesign.
6. **Rules**: from `CLAUDE.md`, plus "no Studio tools, no commit, no rebuild of build/".
7. **Done means**: the three checks pass, plus the task's own assertion in a headless scenario or spec.
8. **Report**: files changed, what it did, anything it disagreed with, what needs Studio or real accounts.

The lead then reads the diff, reruns the checks, tests in Studio, logs in `docs/PROGRESS.md` and commits by path.

# Turf Loop: Roblox territory-capture game

You are working on a live project with a non-programmer owner. He reads results, not code. Several AI sessions share this folder.

## Start of every session
1. Read `docs/HANDOFF.md` (state, traps, task queue), then the last 60 lines of `docs/PROGRESS.md`, then `docs/COORDINATION.md`.
2. Run `git status -sb` and `git log --oneline -8`. **Uncommitted changes you did not make belong to another session**: do not edit, revert or commit those files; work elsewhere and say so.
3. Continue the next item in the hand-off queue. Never restart finished work.

## How to work
- **Lead and workers.** The main session leads on the strongest model available (Fable, else Opus). It decides, briefs, reviews and owns Studio. Give whole systems to Opus or Sonnet subagents and narrow, fully specified edits to Haiku. Anything touching saves, money or the client/server trust boundary goes to Opus or the lead. One writer per file. A subagent's "done" is a claim: rerun the checks and read the diff. Brief template: `docs/HANDOFF.md`.
- **Smallest change that works.** No rewrites of working systems, no speculative features, no new dependencies.
- **Verify, then say exactly what was verified.** Separate "seen in Studio", "passes headless checks only" and "not checked". Never call something working because it compiles. Never invent a result.
- **Work continuously.** Stop and ask only for: spending Robux or money, publishing the game, a broken tool or connection, or a design choice that reverses a logged decision. The owner has approved everything else, including uploads to his Roblox account.
- **Log as you go.** After each task append a dated section to `docs/PROGRESS.md`: what changed, what was seen live, what is unverified, decisions and why. Commit your own files by path (`git add <paths>`, never `-A`), `git pull --rebase`, push to `claude/hopeful-shannon-w2qsd8`.

## Checks (all must pass before a code task is done)
```
node tools/luau/check.mjs      # compiles every .luau, runs tests/*.spec.luau
py tools/xref.py               # cross-module references
node tools/luau/headless.mjs   # boots the real server on a mocked Roblox API
py tools/build_place.py        # writes build/TurfLoop.rbxlx (commit it only when the tree is clean)
```
On this PC Python is `py`, not `python`. First time only: `cd tools/luau && npm install`.

## Code rules
- `--!strict` first line, tabs.
- Every tunable number, price and id lives in `src/shared/Config.luau` (content tables in `Catalog.luau`). Never duplicate one in code.
- The server owns territory, movement limits, currency, items and pass ownership. The client only draws. Never trust a client value; validate type, range and rate on every request.
- Every Roblox web call (`DataStore`, `Marketplace`, friends, avatars) is wrapped in `pcall` and kept off the join path.
- Player-facing strings go in each file's `S` table. UI is built with `src/client/ui/UiKit.luau` in the current paper style (cream panels, dark navy 3 px outlines, Arcade Commons icons). Match what is there; do not restyle.

## Where things are
- Code: `src/shared` (pure logic, unit-tested), `src/server/services`, `src/client/controllers`. Tests: `tests/*.spec.luau`, `tests/headless/*.luau`.
- Design: `docs/GDD.md` (section ids G1–G14; read only the sections you need). Launch and retention plan: `docs/ALGORITHM_PLAN.md`, `docs/LAUNCH_CHECKLIST.md`. Open owner decisions: `docs/DECISIONS.md`. Economy numbers: `docs/BALANCE.md`. Security review: `docs/SECURITY_REVIEW.md`.
- Studio: **read `docs/STUDIO.md` before the first Studio call** (which place, how to sync, test hooks, known traps).

## Hard limits
- Do not publish the game, create paid assets or spend Robux without the owner saying so in chat.
- Do not fill `Config.Ids` with guessed ids. Zero means "not created yet" and the game handles it.
- Only use audio from Roblox-licensed libraries or clearly original sets.
- Bots never reach global leaderboards. Studio-only debug hooks must stay unreachable in a live server.

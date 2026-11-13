# Hand-off: Turf Loop (cloud → local Studio session)

_Written 2026-11-13 for the first session that runs on the owner's Windows PC with Roblox Studio. Read this first, then `docs/PROGRESS.md` and `docs/TASKS.md`. Details live in the linked docs; this page is the map._

## 1. The game in one paragraph
**Turf Loop** (working title) is a drop-in 16-player Roblox arena. You run out of your coloured turf leaving a trail, loop back to your own turf, and everything you circled becomes yours. Anyone who crosses your trail while you are outside eliminates you. There is no round end. Bots keep at least 10 runners in every server. Coins buy permanent upgrades and cosmetics; Rebirth gives Crowns and a permanent multiplier. Full design: `docs/GDD.md` (sections G0–G14). Market research behind the concept: `docs/research.md`.

## 2. Core rules (GDD G2)
- 160 × 160 grid, 4-stud cells, flat arena with walls; server ticks at 20 Hz and reads character positions itself.
- Spawn on a 5 × 5 patch with a 3 s shield. Leaving your turf draws a trail; returning claims trail + enclosed area (border flood fill), stealing enemy turf inside.
- Crossing an enemy trail eliminates its owner; head-on kills both. Crossing your **own** trail is harmless (kid-friendly, on purpose).
- Victim's turf goes neutral except the 25 % nearest the killer, who gets it. Respawn after 3 s.
- King = most cells (min 3 % of map), wears a crown, worth double kill reward. 100 % map pays 5,000 coins and resets that runner.

## 3. Economy and money (G3–G5)
- **Coins** (play), **Gems** (premium, cosmetics only), **Crowns** (rebirth only).
- Upgrades: Speed (capped +15 %, never sold for Robux), Start Size, Coin Boost, Spawn Shield.
- Passes: VIP 399, 2× Coins 249, Neon Pack 199. Products: Starter Pack 79, Second Chance 15, 15-min 2× boost 29, gem packs 49–999.
- No paid random items, no pay-for-power. All grants happen on the server in `ProcessReceipt`, idempotent.
- Retention: 7-day streak, playtime rewards, 3 daily quests, codes, group bonus, weekend ×2, badges, live and global leaderboards, "while you were away" panel.
- Every number lives in `src/shared/Config.luau`. Never duplicate one in code.

## 4. What exists
| Area | Where | State |
|---|---|---|
| Pure logic (grid, flood fill, arena sim, bots, formulas, catalogue, greedy mesh) | `src/shared` | Done, unit-tested (`tests/*.spec.luau`) |
| Server (11 services + `Main.server.luau` + `WorldBuilder.luau`) | `src/server` | Done; boots and plays on a mocked Roblox API, 10/10 headless scenarios pass |
| Client (renderer, camera, input, HUD, panels, feedback, tutorial) | `src/client` | Written and compiles, **never executed** |
| Place file | `build/TurfLoop.rbxlx` | Built by `tools/build_place.py`; open it in Studio |
| Rojo project | `default.project.json` | Alternative to the place file |
| API references | `docs/API_arena.md`, `docs/API_economy.md` | Current |
| Design-vs-code audit | `docs/GAPS.md` | 27 gaps, 19 closed, 3 partial, 5 open |
| Code reviews | `docs/REVIEW_server.md`, `docs/REVIEW_client.md` | Each ends with "Could not verify without Studio" |
| Asset/copy briefs for ChatGPT | `docs/CHATGPT_TASKS.md` → results in `assets/chatgpt/` | Owner to run |

Props are grey Part placeholders, the game is silent (`src/shared/SoundIds.luau` all zeros), and purchases say "Coming soon" (`Config.Ids` all zeros). All three are expected.

## 5. What to do next, in order
1. **T-INT-02, first solo playtest.** Open `build/TurfLoop.rbxlx`, press Play, read the Output window through the Studio MCP, fix every error, repeat until a 5-minute session is clean. Then walk the checklist in `docs/PLAYTEST.md` and the "Could not verify without Studio" lists in both REVIEW files. Expect the client to need the most fixes.
2. **T-INT-03, two-player test.** Test → Clients and Servers → 2 players. Both must see identical turf; cuts must work across clients.
3. **Open gaps that need Studio** (`docs/GAPS.md`): GAP-14 claim wave, GAP-17 pattern textures, GAP-19 ragdoll, GAP-20 speed lines, GAP-09 hit-stop, GAP-08 tutorial hand position.
4. **T-AUD-01 sounds**: pick Creator Store ids for every entry in `SoundIds.luau` (search phrases in `CHATGPT_TASKS.md` CG-044) and check each one plays.
5. **T-AST-01…11 models** if a Blender MCP is connected (G9.4 list, tris budgets).
6. **T-LCH-01** (owner): create passes, products, badges and the group on Roblox; paste ids into `Config.Ids`. Creating them is free; stop and ask before anything that spends Robux.
7. **T-LCH-02**: publish with icon, thumbnails and description.

## 6. Rules for the session
- Follow `CLAUDE.md`: `--!strict`, tabs, numbers only in Config, server-authoritative economy and territory, do not rewrite finished systems unless a playtest shows a bug.
- Before calling a code task done run `node tools/luau/check.mjs`, `python tools/xref.py`, `node tools/luau/headless.mjs`, `python tools/build_place.py`.
- Code edited in the repo reaches Studio only by rebuilding and reopening the place file, or live through `rojo serve`. Edits made directly in Studio must be copied back into `src/` or they are lost on the next rebuild.
- Update `docs/PROGRESS.md` after each task and log decisions there. Commit and push to `claude/hopeful-shannon-w2qsd8`.
- Stop and ask only for real Robux/money spend or a broken tool/connection.

## 7. Open decisions waiting on the owner
- Starter Pack: a repeat purchase currently grants its 300 gems again (coins and skin are once-only). Block repeats or leave it?
- Final game title (brainstorm in `CHATGPT_TASKS.md`).
- Whether bots are visibly tagged (default: not tagged, never on global boards).

# PROGRESS

_Resume rule: read this file and TASKS.md first, verify the last task's output exists, then continue. Never restart from scratch._

## Current phase
Phase 4 — Build (code only; Studio/Blender steps blocked, see Blockers)

## Completed
- Phase 1 `docs/research.md` (concept: territory-loop arena, working title **Turf Loop**), Phase 2 `docs/GDD.md`, Phase 3 `docs/TASKS.md` + `docs/HEAVY_QUEUE.md`, `docs/CHATGPT_TASKS.md` (45 entries)
- Foundation: T-FND-01..04 (saturation checker, Luau check harness, Config/Types/Remotes, `tools/build_place.py`)
- Pure logic: T-LOG-01 Grid, T-LOG-02 FloodFill (4.4 ms worst case), T-LOG-03 Formulas, T-LOG-04 Catalog, T-LOG-07 GreedyMesh — all specs pass
- Server: T-SRV-01 DataService, T-SRV-04 Economy/Upgrade, T-SRV-05 Shop/Monetization, T-SRV-06 Reward, T-SRV-07 Leaderboard/Badge/Analytics (`docs/API_economy.md`)
- Client/world: T-WLD-01 WorldBuilder, T-CLI-02 Camera/Input, UiKit
- Last completed task ID: T-SRV-07

## In progress
- Opus: T-LOG-05 ArenaSim (resumed after a usage-limit stop; 1 spec assertion was failing: "trail excludes the one own-turf cell crossed") then `docs/API_arena.md`
- Sonnet: T-CLI-03 HUD, T-CLI-04 panels, `src/client/ClientState.luau`

## Blockers
- **No Blender or Roblox Studio connection in this cloud session**, and no computer folder is shared with it. All 🖥 tasks in TASKS.md are blocked until a session has those connections. Workaround in place: `tools/build_place.py` produces a `.rbxlx` the owner opens in Studio.
- Downloading and running external binaries (Rojo, luau-analyze) was denied by the permission classifier. Using npm WASM packages instead; no type-checker, only compile checks + unit tests.
- Repo had no default branch, so no pull request can be opened until one exists.

## Next 5 tasks
1. When `docs/API_arena.md` exists: dispatch T-SRV-02 ArenaService + T-SRV-08 Main/router (Opus), T-LOG-06 BotBrain + T-SRV-03 BotService (Sonnet)
2. T-CLI-01 TurfRenderer + arena client (Opus), T-CLI-05 Feedback, T-CLI-06 Tutorial, T-CLI-07 client Main
3. T-INT-01 Fable cross-system review (contracts in Remotes.luau vs both sides)
4. `python3 tools/build_place.py` → hand `build/TurfLoop.rbxlx` to owner for T-INT-02 first Studio playtest
5. Owner: run CHATGPT_TASKS entries; create passes/products/badges (T-LCH-01)

## Decisions log (Fable)
- 2026-11-12: Allowlist extended with apis.roblox.com, games.roblox.com, www.roblox.com, rolimons.com for live CCU checks.
- 2026-11-12: User granted blanket approval for permissions and irreversible changes to the game. Remaining stop conditions: real Robux/money spend, broken tool/connection.
- 2026-11-12: `/brainstorming:brainstorming` skill is not installed; ran the brief directly.
- 2026-11-12: Concept = territory-loop arena (research.md R6). Rejected hole/roll-up (prop-heavy, adjacent incumbent) and snake (incumbent over 1k, low depth).
- 2026-11-12: Crossing your own trail is harmless (kid-friendly), unlike the genre norm.
- 2026-11-12: No paid random items; Speed upgrade capped at +15% and never sold for Robux.
- 2026-11-12: All game rules live in an engine-free `ArenaSim` so they can be unit-tested without Studio.
- 2026-11-12: Turf rendered as pooled greedy-meshed Parts for MVP; EditableImage renderer deferred to post-launch.
- 2026-11-12: Second Chance needs a pending-victim state in ArenaSim (turf held until prompt resolves).
- 2026-11-12: Default trail id is `default_trail` (catalogue ids must be unique); default skin `default`, default effect `sparkle`.
- 2026-11-12: Full-map bonus is multiplied like other income; a repeat Starter Pack purchase grants only gems; failed Second Chance refunds 20 gems (accepted as implemented).
- 2026-11-12: Client contract fixed in `Remotes.luau`: ProfileUpdate carries {profile, session}; added Death and Reward remotes and StarterOfferSeen / DeclineSecondChance requests.

# PROGRESS

_Resume rule: read this file and TASKS.md first, verify the last task's output exists, then continue. Never restart from scratch._

## Current phase
Phase 4 — Build (code only; Studio/Blender steps blocked, see Blockers)

## Completed
- Phase 1: `docs/research.md` — concept chosen: territory-loop arena, working title **Turf Loop**
- Phase 2: `docs/GDD.md`
- Phase 3: `docs/TASKS.md`, `docs/HEAVY_QUEUE.md`
- T-FND-01 saturation checker, T-FND-02 Luau check harness (`node tools/luau/check.mjs`, needs `npm install` in `tools/luau` first), T-FND-03 `src/shared/Config.luau`, `Types.luau`, `Remotes.luau`

## In progress (workers dispatched 2026-11-12)
- Opus: T-LOG-01, T-LOG-02, T-LOG-07, T-LOG-05 (Grid, FloodFill, GreedyMesh, ArenaSim + `docs/API_arena.md`)
- Sonnet: T-LOG-03, T-LOG-04 (Formulas, Catalog)
- Sonnet: T-FND-04 (`tools/build_place.py`, `default.project.json`, `docs/BUILD.md`)
- Opus: T-SRV-01 (ProfileTemplate, DataService)
- Sonnet: `docs/CHATGPT_TASKS.md`

## Blockers
- **No Blender or Roblox Studio connection in this cloud session**, and no computer folder is shared with it. All 🖥 tasks in TASKS.md are blocked until a session has those connections. Workaround in place: `tools/build_place.py` produces a `.rbxlx` the owner opens in Studio.
- Downloading and running external binaries (Rojo, luau-analyze) was denied by the permission classifier. Using npm WASM packages instead; no type-checker, only compile checks + unit tests.
- Repo had no default branch, so no pull request can be opened until one exists.

## Next 5 tasks
1. Review worker output for B (pure logic) against acceptance tests
2. Dispatch C (server services) and D (client controllers) once `docs/API_arena.md` exists
3. T-WLD-01 WorldBuilder with Part placeholders
4. T-INT-01 Fable cross-system review
5. Build `build/TurfLoop.rbxlx` and hand to owner for T-INT-02 (first Studio playtest)

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

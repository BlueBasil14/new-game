# PROGRESS

_Resume rule: read this file and TASKS.md first, verify the last task's output exists, then continue. Never restart from scratch._

## Current phase
Phase 4 — Build (code only; Studio/Blender steps blocked, see Blockers)

## Completed
- Phase 1 `docs/research.md` (concept: territory-loop arena, working title **Turf Loop**), Phase 2 `docs/GDD.md`, Phase 3 `docs/TASKS.md` + `docs/HEAVY_QUEUE.md`, `docs/CHATGPT_TASKS.md` (45 entries)
- **Every MVP code task in TASKS.md groups A–D plus T-WLD-01 is written** (38 Luau files in `src/`). All compile, all 10 specs pass, `tools/xref.py` reports 0 unresolved cross-module references.
- `python3 tools/build_place.py` produces `build/TurfLoop.rbxlx` (1 Script, 1 LocalScript, 36 ModuleScripts).
- API references: `docs/API_arena.md`, `docs/API_economy.md`
- Last completed task ID: T-CLI-07

## In progress
- Nothing. All work that can be done without Studio/Blender is complete.
- T-INT-01 done: 7 client + 6 server defects fixed (`docs/REVIEW_client.md`, `docs/REVIEW_server.md`). Last completed task ID: **T-INT-01**.

## Not started (cannot be done in a cloud session)
- **Nothing has been run in Roblox Studio.** T-INT-02 / T-INT-03 are the next real milestone.
- T-AST-01…11 Blender models (Part placeholders are in place), T-AUD-01 sound ids (`src/shared/SoundIds.luau` is all zeros → game is silent)
- T-LCH-01 create passes/products/badges/group and fill `Config.Ids` (all zero → purchases show "Coming soon")

## Blockers
- **No Blender or Roblox Studio connection in this cloud session**, and no computer folder is shared with it. All 🖥 tasks in TASKS.md are blocked until a session has those connections. Workaround in place: `tools/build_place.py` produces a `.rbxlx` the owner opens in Studio.
- Downloading and running external binaries (Rojo, luau-analyze) was denied by the permission classifier. Using npm WASM packages instead; no type-checker, only compile checks + unit tests.
- Repo had no default branch, so no pull request can be opened until one exists.

## Next 5 tasks
1. 🖥 T-INT-02: owner follows `docs/PLAYTEST.md` (open `build/TurfLoop.rbxlx`, press Play, paste Output errors back)
2. 🖥 T-INT-03: 2-player local server test
3. Owner: CHATGPT_TASKS entries (icons, thumbnails, copy, sound briefs); T-LCH-01 ids into `Config.Ids`
4. 🖥 T-AST / T-AUD: models and sounds once Blender/Studio connections exist
5. T-LCH-02 publish

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
- 2026-11-12: Snapshot is sent when the runner is added and re-sent on the client's first Request; RemoteEvents queue until the client connects, so no explicit Ready handshake.
- 2026-11-12: Spawn events sent to clients carry shieldUntil on workspace:GetServerTimeNow() time; the sim keeps os.clock.
- 2026-11-12: Bot rigs live in workspace.Bots named tostring(runnerId).
- 2026-11-12: Added `tools/xref.py` as a required check alongside `tools/luau/check.mjs`.
- 2026-11-12: `build/TurfLoop.rbxlx` is committed (not ignored) so the owner can download it without running the builder.

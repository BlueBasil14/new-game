# PROGRESS

_Resume rule: read this file and TASKS.md first, verify the last task's output exists, then continue. Never restart from scratch._

## Current phase
Phase 1 — Research (in progress)

## Last completed task
- P1-0: Built `tools/roblox_saturation.py` (live Roblox search + CCU per query). Verified working.

## In progress
- P1-1: Saturation sweep of candidate concepts (raw output in `docs/_sat*.txt`)
- P1-2: Haiku worker — Roblox 2026 market/trend facts
- P1-3: Haiku worker — off-Roblox hit games 2024–2026

## Blockers
- **No Blender or Roblox Studio connection in this session.** This is a cloud container; neither MCP server is attached. Phases 1–3 and all code/doc work proceed here. Studio/Blender build steps (Phase 4) need a session that has those connections.
- Figma connector failed to connect (not needed).

## Next 5 tasks
1. Finish saturation sweep, disqualify concepts with a >~1k CCU incumbent or clone flood
2. Score survivors, shortlist 3, pick 1 → `docs/research.md`
3. Write `docs/GDD.md`
4. Write `docs/TASKS.md` + `docs/CHATGPT_TASKS.md` + `docs/HEAVY_QUEUE.md`
5. Begin Phase 4 work that needs no Studio (Luau source in repo, Rojo layout)

## Decisions log (Fable)
- 2026-11-12: Environment allowlist extended with apis.roblox.com, games.roblox.com, www.roblox.com, rolimons.com so competition checks use live CCU instead of articles.
- 2026-11-12: User granted blanket approval for permissions and for irreversible changes to the game. Remaining stop conditions: real Robux/money spend, broken tool/connection.
- 2026-11-12: `/brainstorming:brainstorming` skill is not installed here; running the brief directly.

# Turf Loop — Roblox game project

## Resume protocol
1. Read `docs/HANDOFF.md`, then `docs/PROGRESS.md` and `docs/TASKS.md`. Verify the last completed task's output exists, then continue. Never restart from scratch.
2. Update `docs/PROGRESS.md` after every completed task. Log Fable's decisions there.
3. Work continuously. Only stop to ask when something would cost real Robux/money or a tool/connection is broken. The owner has approved irreversible changes to the game.

## Roles
Fable = lead and final decisions. Opus/Sonnet = sub-orchestrators per system. Haiku = narrow, fully specified tasks. Heavy tasks are queued in `docs/HEAVY_QUEUE.md`.

## Where things are
- Design: `docs/GDD.md` (section ids G1–G14). Tasks: `docs/TASKS.md`. Known gaps: `docs/GAPS.md`.
- Code: `src/shared` (pure logic, unit-tested), `src/server`, `src/client`. All numbers live in `src/shared/Config.luau`.
- API references: `docs/API_arena.md`, `docs/API_economy.md`.
- First-playtest checklist: `docs/PLAYTEST.md`, plus "Could not verify without Studio" in `docs/REVIEW_server.md` and `docs/REVIEW_client.md`.
- Owner hand-off tasks for ChatGPT: `docs/CHATGPT_TASKS.md`; results arrive in `assets/chatgpt/`.

## Checks to run before calling any code task done
```
cd tools/luau && npm install        # first time only
node tools/luau/check.mjs           # compiles every .luau, runs tests/*.spec.luau
python tools/xref.py                # cross-module reference check
node tools/luau/headless.mjs        # boots the real server on a mocked Roblox API (docs/HEADLESS.md)
python tools/build_place.py         # writes build/TurfLoop.rbxlx
```

## Studio
- The Roblox Studio MCP server is declared in `.mcp.json` (Windows, needs Studio open with the MCP plugin). In a cloud session it cannot start; that is expected.
- Sync code into Studio either by opening `build/TurfLoop.rbxlx` or with `rojo serve` (`default.project.json`).
- **As of 2026-11-12 nothing has been run in Studio.** The server passes a headless run on a mocked Roblox API; the client has never executed at all. The next milestone is T-INT-02 in `docs/TASKS.md`: press Play, read the Output window, fix errors, then walk `docs/PLAYTEST.md`.
- Playtest after every system change: start play, read the console, fix errors before moving on. Save the place after every system.

## Code rules
- `--!strict` first line, tabs, no numbers duplicated from Config, server-authoritative economy and territory.
- Do not rewrite finished systems unless a playtest shows a bug.

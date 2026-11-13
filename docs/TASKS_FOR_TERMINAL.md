# Task for the terminal session (from the lead session, owner approved)

Project folder: `C:\Users\coolb\new game\new-game`. Branch: `claude/hopeful-shannon-w2qsd8`.

Read first: `CLAUDE.md`, `docs/COORDINATION.md` (other agents are editing this same folder), `docs/GDD.md` section G6 only, and rows GAP-20 and GAP-09 in `docs/GAPS.md`.

## Goal 1: GAP-20 speed lines (G6 "leaving turf")
While the local player is outside their own turf with a trail, show a subtle speed-line effect on their character. Remove it when they return or die. No effect when the `lowDetail` setting is on.

## Goal 2: GAP-09 hit-stop (G6 "cutting")
When the local player cuts another runner, add a 0.08 s hit-stop on the client only (for example a brief camera or animation pause). Never touch server state or WalkSpeed authority. The 0.08 lives in `src/shared/Config.luau`.

## Files
You may edit only:
- `src/client/controllers/FeedbackController.luau`
- `src/client/controllers/CameraController.luau`
- `src/shared/Config.luau` (add values only)

Everything else is read-only. Do not touch `UiKit.luau`, `HudController.luau`, `PanelController.luau`, `TurfRenderer.luau`, `assets/`, `build/`, `default.project.json` or `tools/`. Do not use Roblox Studio tools; the lead does the Studio playtest.

## Rules
`--!strict` first line, tabs, numbers only in Config, server-authoritative economy and territory, no rewrites of working systems.

## Done means
All three pass (Python is `py` on this PC):
```
node tools/luau/check.mjs
py tools/xref.py
node tools/luau/headless.mjs
```

## Git
Commit only your own files by path (never `git add -A`). Message prefix `GAP-20/GAP-09:`. `git pull --rebase` then push to `claude/hopeful-shannon-w2qsd8`.

## Report
Append a short dated section to `docs/PROGRESS.md`: files changed, what was done, what could not be verified without Studio.

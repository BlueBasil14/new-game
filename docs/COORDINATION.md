# Who is working on what (read before editing)

_Several agents share this working folder. Two agents must never edit the same file at the same time. Written 2026-11-12 late evening by the lead session (Fable)._

| Area / files | Owner right now | Notes |
|---|---|---|
| `src/client/ui/UiKit.luau`, `src/client/controllers/HudController.luau`, `src/client/controllers/PanelController.luau`, `src/shared/ArcadeIcons.luau`, `assets/`, `default.project.json`, `tools/build_place.py` | The agent applying the Arcade Commons icons / UI kit and the RBLX Essentials sound system (ChatGPT session) | Uncommitted edits seen live at about 23:25. Lead will not touch these until they are committed or the owner says so. |
| `src/client/controllers/TurfRenderer.luau` | Lead's Opus subagent | GAP-14 claim wave |
| `src/client/controllers/FeedbackController.luau`, `src/client/controllers/CameraController.luau` | Terminal session `coolb-40` | GAP-20 speed lines, GAP-09 hit-stop |
| Roblox Studio (Play, Output, screenshots) | Lead session only | Check `list_roblox_studios` first; if another agent has a play session running, wait. |
| `docs/PROGRESS.md` | Everyone, append-only | Add a dated section at the end of the non-"Decisions" part; never rewrite other sections. |

## Lead log (kept here while `docs/PROGRESS.md` has another agent's uncommitted edits)
- 2026-11-12 23:50: GAP-14 claim wave committed (`TurfRenderer.luau`, `Config.ClaimFx.WaveTime`). Flash start is delayed by distance from the claim centroid so it sweeps from the trail edge inward. Checks pass (39 files compile, specs, xref 0, headless 10/10). **Not seen in Studio**: another agent had a play session running on a cloud-saved place ("BlazeHawks's Place: 11132026_2"), so the lead skipped Studio. To check live: wave direction on long or L-shaped claims, large claims that hit the 40-rectangle flash cap, phone frame rate. `TurfRenderer.luau` is free again.
- The terminal task (GAP-20/GAP-09) was not delivered by message; it is in `docs/TASKS_FOR_TERMINAL.md` and waits for the owner.

Rules:
- Commit only your own files (`git add <paths>`), never `git add -A`.
- Do not commit `build/TurfLoop.rbxlx` unless you rebuilt it yourself from a tree where all checks pass.
- Checks before calling code done: `node tools/luau/check.mjs`, `py tools/xref.py`, `node tools/luau/headless.mjs` (on this PC Python is `py`, not `python`).

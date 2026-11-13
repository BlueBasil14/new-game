# Who is working on what (read before editing)

_Several agents share this working folder. Two agents must never edit the same file at the same time. Written 2026-11-12 late evening by the lead session (Fable)._

| Area / files | Owner right now | Notes |
|---|---|---|
| `src/client/ui/UiKit.luau`, `src/client/controllers/HudController.luau`, `src/shared/ArcadeIcons.luau`, `assets/`, `default.project.json`, `tools/build_place.py` | The agent applying the Arcade Commons icons / UI kit and the RBLX Essentials sound system (ChatGPT session) | **Still uncommitted at 05:30 on 2026-11-13** (last edit 23:32). Lead has not edited or committed them. Owner: please have that session commit, or tell the lead to. |
| `src/client/controllers/TurfRenderer.luau`, `FeedbackController.luau`, `CameraController.luau`, `PanelController.luau`, `src/client/Main.client.luau` | Free (lead took them over on 2026-11-13 02:00; all committed) | The terminal task in `docs/TASKS_FOR_TERMINAL.md` was never started, so the lead did GAP-20/GAP-09 itself. That task file is obsolete. |
| Roblox Studio (Play, Output, screenshots) | Lead session only | Check `list_roblox_studios` first; if another agent has a play session running, wait. |
| `docs/PROGRESS.md` | Everyone, append-only | Add a dated section at the end of the non-"Decisions" part; never rewrite other sections. |

## Lead log (kept here while `docs/PROGRESS.md` has another agent's uncommitted edits)
- 2026-11-12 23:50: GAP-14 claim wave committed (`TurfRenderer.luau`, `Config.ClaimFx.WaveTime`). Flash start is delayed by distance from the claim centroid so it sweeps from the trail edge inward. Checks pass (39 files compile, specs, xref 0, headless 10/10). **Not seen in Studio**: another agent had a play session running on a cloud-saved place ("BlazeHawks's Place: 11132026_2"), so the lead skipped Studio. To check live: wave direction on long or L-shaped claims, large claims that hit the 40-rectangle flash cap, phone frame rate. `TurfRenderer.luau` is free again.
- The terminal task (GAP-20/GAP-09) was not delivered by message; it is in `docs/TASKS_FOR_TERMINAL.md` and waits for the owner.
- 2026-11-13 02:30 (scheduled overnight run): GAP-20 speed lines and GAP-09 hit-stop done and seen in Studio; shop tab text sizes made uniform; Debug hook gained `("cut")` and `("waveTime", "4")`. Studio testing used a second Studio window on `build/TurfLoop.rbxlx` (closed afterwards); the cloud place "11132026_2" was left untouched and still holds older scripts (no claim wave, no speed lines). Details in `docs/PROGRESS.md`. `build/TurfLoop.rbxlx` on disk was rebuilt from the working tree (includes the uncommitted Arcade Commons UI) and is **not** committed.
- 2026-11-13 05:30 (scheduled overnight run): GAP-28 south wall fade (`CameraController.luau`) and GAP-19 elimination pop (`FeedbackController.luau`) done, both client only, numbers in `Config.luau`. Tested in a second Studio window on `build/TurfLoop.rbxlx` (closed afterwards). Those files are free again. Details in `docs/PROGRESS.md`.

Rules:
- Commit only your own files (`git add <paths>`), never `git add -A`.
- Do not commit `build/TurfLoop.rbxlx` unless you rebuilt it yourself from a tree where all checks pass.
- Checks before calling code done: `node tools/luau/check.mjs`, `py tools/xref.py`, `node tools/luau/headless.mjs` (on this PC Python is `py`, not `python`).

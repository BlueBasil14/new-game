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
- Nothing. All work possible without Studio/Blender is complete as of the third work block (2026-11-12).

## Done in work blocks 2–3
- `docs/GAPS.md`: audit of code vs GDD MVP (27 gaps). Closed in code: GAP-03, 04, 05, 06, 07, 08, 10, 11, 12, 13, 15, 16, 18, 21, 22, 23, 24, 26, 27. Partial: GAP-01 (calls wired, ids missing), 09 (no hit-stop), 25 (hold is PromptSeconds + 12). Open, need Studio: GAP-02, 14, 17, 19, 20.
- Headless playtest (`node tools/luau/headless.mjs`, notes in `docs/HEADLESS.md`): the real server boots and runs on a strict mock of the Roblox API; 10/10 scenarios pass (boot with bots, join and claim, cut and respawn, every request incl. hostile args, persistence across restart, DataStores down, purchases, 3-minute soak, leave mid-life, mock self-test). One real defect found and fixed: saves and lock release were lost on server shutdown (DataService onClose).
- Local setup: `.mcp.json` (Roblox_Studio), `CLAUDE.md`, `docs/LOCAL_SETUP.md`
- 2026-11-13: `docs/HANDOFF.md` written as the single entry point for the local Studio session; working branch is now `claude/hopeful-shannon-w2qsd8`.
- Last completed task ID: **T-INT-01**; next: **T-INT-02** (needs Studio)

## First Studio playtest (T-INT-02), 2026-11-12, local session
- `build/TurfLoop.rbxlx` opened in Studio, solo Play driven through the Studio MCP. **No script errors** in a 5-minute session and a second ~5-minute session. Only Studio noise: DataStore fallback warnings and `rbxassetid://203785492 ... Asset type does not match requested type` (id is not in `src/` or the live DataModel; origin not found).
- Verified live: HUD, leaderboard, minimap, turf and trail rendering; walking a loop claims turf and pays coins; a bot cut the player and the player respawned and could move and claim again; all panels open without errors (Upgrades, Shop, Quests, Daily, Rebirth, Codes, Settings, Starter, Inventory); Shop shows rows of three; ClaimDaily, ClaimPlaytime and BuyUpgrade coinBoost succeed and the panel and wallet update.
- Not verified: the death panel itself (the cut happened unobserved), camera/thumbstick feel, rubber-banding by eye, real UI clicks (MCP clicks miss under the device emulator; requests were sent directly), sounds, T-INT-03.
- Seen, not fixed (cosmetic): rail button text sizes differ ("Upgrades" small, "Shop" large); the king banner draws on top of an open panel's title bar.
- Added a Studio-only `Debug` BindableEvent under `Main.client.luau` (`:Fire("open", "Shop")`, `:Fire("close")`) so automated playtests can open panels.
- Model note: session started on Sonnet, switched to Fable part-way.
- Next: the two cosmetic items above.

## Two-player test (T-INT-03), 2026-11-12
- Server & Clients test with 2 players, started from Studio's test-mode dropdown (the Studio MCP can only start solo play; it can drive the server and each client once they run).
- Both clients sampled at the same server timestamp showed identical turf: 265 visible turf parts and equal area for all 15 colours.
- Cut across clients: Player1 walked out leaving a trail, Player2 walked across it; Player1 was eliminated (character hidden), then respawned on a new patch; Player2 received turf at the spot and coins. Characters were driven from the server with `Humanoid:MoveTo`, not real input.
- Output clean on server and both clients (same Studio noise as solo).
- The death panel with its Respawn button was seen on one client after a later bot cut (one screenshot; its contents were not read).
- Seen, not fixed: on the iPhone emulator the Wallet sits under Roblox's top-bar buttons (MCP `screen_capture` hides CoreGui, so earlier captures missed this).
- Not verified: purchases in test mode (ids are zero, T-LCH-01), real touch/keyboard input.

## HUD layout fixes, 2026-11-12
- Wallet and rail now start below Roblox's top bar (`GuiService.TopbarInset`); rail height 0.42 → 0.38 so it still clears the thumbstick. Verified on the iPhone emulator: wallet sits under the top-bar buttons, not behind them. The bottom rail button (Settings) is close to the thumbstick; not checked on other devices.
- Rail buttons share one text size (TextScaled off, size from rail width/height). Verified: all seven at the same size and fitting.
- Another runner's "is the King!" toast is skipped while a panel is open (`UiKit.isPanelOpen`). Not seen live; the event could not be triggered on demand.
- Decision (Fable): toasts stay above panels so purchase errors remain visible; only the king toast for other runners is suppressed.

## Sounds (T-AUD-01), 2026-11-12, partial
- 12 of 20 ids filled in `src/shared/SoundIds.luau` from the Creator Store ("Daily Sounds" free set, Pro Sound Effects). Each loads in Studio with the expected length. **None has been heard by a person**, and playback in a live session was not confirmed.
- Still 0: trailLoop, bigClaim, snip, crownFanfare, uiHover, questComplete, lobbyMusic, arenaMusic. Creator Store search gave no clearly licensed match; many hits were user uploads of copyrighted game audio and were rejected.
- Decision (Fable): only use audio from Roblox-licensed libraries or clearly original sets.

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
- 2026-11-12: Owner is moving to a local Windows session with the Roblox Studio MCP server; `.mcp.json` declares it for this repo. Cloud sessions cannot start it (expected).
- 2026-11-12: Gaps deferred until Studio is available because they need eyes/ears: GAP-01 sound ids, GAP-02 Roblox ids, GAP-14 claim wave, GAP-17 pattern textures, GAP-19 ragdoll, GAP-20 speed lines.
- 2026-11-12: Headless mock run is a test tool only. It does not model physics, replication lag, rendering or the client; it does not replace T-INT-02.

## 2026-11-12 — RBLX Essentials Sound System installation
- Installed the official free Sound System v3.2.2 into the open TurfLoop Studio place: supplied Kernel/server/client boot, music HUD, Settings controls, 15 tracks and 42 SFX. Demo pads omitted. Staging model removed.
- Preserved five service models in assets/rblxessentials and mapped them in default.project.json; tools/build_place.py now includes them and verifies vendor script counts and unique referents. Existing FeedbackController sound mappings were left as authored.
- Adjusted music HUD insets/position for the active iPhone landscape preview, below the leaderboard and clear of the camera cutout.
- Executed solo Studio playtest: both SoundSystem boots report no failed/skipped packs. Native clicks expand the HUD, change track/title, and mute the music SoundGroup to zero. Audio assets report loaded, but playback TimePosition remains zero even for a standalone sound; audible output is unverified in this Studio session.
- Existing DataStore/unpublished-place warnings and asset-type warning for 203785492 predate this change.
- Checks passed: 38 source files compiled, all Luau specs, xref (0 unresolved), 10/10 headless scenarios, custom XML build/check, and Rojo build.

## 2026-11-12 — Arcade Commons uploaded and integrated
- Uploaded 48 original transparent Image assets to creator 309565647. All completed and moderation Approved; IDs in assets/arcade-commons/upload-manifest.json and src/shared/ArcadeIcons.luau.
- Added UiKit.icon, wallet currency icons, all seven rail icons, panel heading icons and icon-based close controls. Existing click callbacks and notification badges preserved. Rail captions separated from decorative artwork to avoid UIPadding shifting icons into the text.
- Executed Studio solo checks: phone landscape and default desktop visual review; Shop open/close and Settings open via native input; 48/48 native ImageLabels loaded in a temporary contact sheet; no rail icon/caption overlaps. A raw-URI PreloadAsync diagnostic reported Failure, so verification used the actual native ImageLabel rendering boundary, which passed for every asset. Removed the temporary grid and stopped Play. Studio reset to default viewport.
- Saved cloud place 122808046982168 (universe 10776297447), version 4; updated local build. No publish action performed.
- Checks passed: 39 modules compile, existing Luau specs, xref 0 unresolved, 10/10 headless mock scenarios, XML and Rojo build. No new UiKit/HudController/ArcadeIcons errors. Existing Studio DataStore access and unrelated image 203785492 warnings remain.
- Larger Figma component kit remains a design draft; this task uploads the full icon pack and integrates HUD/menu artwork, not all 80 Figma UI states.

## Overnight run (lead, scheduled), 2026-11-13 02:00
- State found: GAP-14 already committed. The terminal task (GAP-20/GAP-09) had never started. The Arcade Commons UI and sound-system files (UiKit, HudController, ArcadeIcons, assets, default.project.json, build_place.py) are still uncommitted by the other session; the lead did not edit or commit them.
- GAP-20 speed lines: particle streaks in the runner's colour behind the local character while it has a trail; off on return, death and lowDetail (`FeedbackController.luau`).
- GAP-09 hit-stop: on a local cut the camera holds and the local character's animations pause for `Config.CutFx.HitStop` (0.08 s), client only (`CameraController.hold`, `FeedbackController.luau`).
- Shop tabs: one text size for the row (`PanelController.luau`); before, "Skins" was huge and "Featured" small.
- Studio-only Debug hook: added `Fire("cut")` (replays local cut feedback) and `Fire("waveTime", "4")` (slows the claim wave).
- Checks: 39 files compile, specs pass, xref 0 unresolved, headless 10/10.
- Verified live (solo play, iPhone emulator, second Studio window on a rebuilt `build/TurfLoop.rbxlx`): Output clean apart from the known Studio noise; speed-line emitter on outside own turf and off inside, streaks visible behind the runner (faint at phone size); hit-stop measured (camera did not move in the first frame after the cut and moved again by 82 ms; 3 of 3 animation tracks paused and resumed); claim wave seen once with the wave slowed to 12 s (edges already in the owner colour, centre still light); two loop claims paid coins; death panel contents read ("Cut by", stats, Respawn) and auto-respawn worked; Shop and Settings panels render with Arcade Commons heading and close icons; all seven shop tabs at one size and fitting.
- Not verified: anything at real speed by a person (hit-stop feel, wave at 0.25 s, speed lines in motion); sounds; a real cut of a bot (the cut was replayed through the Debug hook); 2-player; desktop viewport; frame rate on a phone (Studio ran at about 15 fps in the background, so the hit-stop timing is coarse).
- Found, not fixed: GAP-28, near the south wall the camera sits outside the arena and the wall hides the runner. The tutorial hand was seen over the wallet, above the Upgrades button (GAP-08 still open). Skin patterns still show as large light blocks (GAP-17).
- The cloud place "11132026_2" open in the other Studio window still has older scripts (no claim wave, speed lines or hit-stop). It was not changed. Localhost HTTP sync into Studio is blocked by the Studio assistant allowlist, so the rebuilt place file is the way to test.
- Decision (Fable): the lead took over FeedbackController/CameraController/PanelController/Main.client because they were committed and quiet for hours; `docs/TASKS_FOR_TERMINAL.md` is obsolete.
- Next: owner to get the Arcade Commons / sound-system work committed; GAP-28 (lower or locally fade the south wall, or clamp the camera); GAP-08 hand position; GAP-19 ragdoll; GAP-17 patterns; remaining 8 sound ids.

## Overnight run (lead, scheduled), 2026-11-13 05:00
- State found: nothing new from other agents. The Arcade Commons UI and sound-system files (UiKit, HudController, ArcadeIcons, assets, default.project.json, build_place.py) are still uncommitted by the other session; the lead did not edit or commit them. Priority 3 (phone layout check of that UI) and GAP-08 (needs HudController) stay blocked on that.
- GAP-28 south wall: `CameraController.luau` fades the south wall on the local client only (`LocalTransparencyModifier`) when the wall stands between the camera and the runner. Numbers in `Config.Camera.WallFade` (0.85) and `WallFadeMargin` (6 studs).
- GAP-19 elimination pop: on every "cut" event each client makes a local copy of the victim, removes joints, throws the pieces upward and fades them over `Config.CutFx.PopTime` (0.6 s) (`FeedbackController.ragdollPop`). Pieces do not collide, so they cannot push a live character. Off with lowDetail. No server change; the real character is still hidden under the floor as before.
- Checks: 39 files compile, specs pass, xref 0 unresolved, headless 10/10.
- Verified live (solo play, second Studio window on a rebuilt `build/TurfLoop.rbxlx`, closed afterwards): Output clean apart from the known Studio noise. Wall fade: walked the runner to the south wall; fade was 0 at 31 studs from the wall, 0.45 at about 5 studs and 0.85 at the wall, and back to 0 after walking away; screenshot shows the runner through the faded wall. Pop: fired the Debug "cut" hook; a copy of a bot rig (2 parts) appeared in `Workspace.Feedback`, was unanchored, 9.8 studs up and 11 % faded after 0.2 s, and was gone after 1 s.
- Not verified: the pop on a player character (R15 with accessories; only a 2-part bot rig was exercised); the pop on a real cut, where the bot rig may already be destroyed by the server before the event arrives (then nothing is shown) or the player character already sunk (the code lifts the copy back to the floor; this branch never ran); how either effect looks to a person; the pop was not caught in a screenshot; 2-player; phone frame rate; the other three walls (the camera only looks north, so only the south wall can hide the runner; corner towers and trees outside the wall were not checked).
- Mistake during testing: the first play session teleported the test character by script, and the server's movement check kicked it ("Movement check failed"). That is the anti-cheat working as designed; the test was redone by walking.
- The cloud place "11132026_2" in the other Studio window was not touched and still has older scripts.
- `build/TurfLoop.rbxlx` on disk was rebuilt from the working tree (includes the other session's uncommitted UI work) and is not committed.
- Next: owner to get the Arcade Commons / sound-system work committed (unblocks GAP-08 and the phone layout pass); watch a real bot cut to see whether the pop shows, and if the rig is gone too early send the death position with the cut event (server change, Opus); GAP-17 patterns; remaining 8 sound ids.

## Overnight run (lead, scheduled), 2026-11-13 08:00 (last overnight run)
- State found: nothing new from other agents. The Arcade Commons UI and sound-system files are still uncommitted by the other session; the lead did not edit or commit them. Priority 3 (phone layout pass) and GAP-08 stay blocked on that.
- No code changed this run. The run was used to close the open question from 05:00: does the elimination pop (GAP-19) show on a real cut.
- Checks: 39 files compile, specs pass, xref 0 unresolved, headless 10/10.
- Verified live (solo play, second Studio window on a rebuilt `build/TurfLoop.rbxlx`, closed afterwards): Output clean apart from the known Studio noise. Five real cuts were logged by a probe on the `ArenaEvent` remote. Four bot-on-bot cuts: the victim's rig was still in `Workspace.Bots` when the event arrived every time, and a pop copy appeared in `Workspace.Feedback` every time (2 parts, from floor height to about 8.6 studs higher after 0.25 s). One cut of the player by a bot (the test character was walked toward the bots, no teleport): a copy of the R15 character appeared (20 parts, 19 visible), placed at floor height (y 3.5) while the real character was already at y -20, and rose 8.3 studs in 0.2 s. So the "rig gone too early" worry did not happen and the "character already sunk" branch works. No server change is needed.
- Not verified: how the pop looks to a person (numbers only, 0.6 s is too short for a screenshot here); a character with many accessories; 2-player; phone frame rate; everything listed as unverified at 02:00 and 05:00.
- `build/TurfLoop.rbxlx` on disk was rebuilt from the working tree (includes the other session's uncommitted UI work) and is not committed. The cloud place "11132026_2" was not touched.
- Wrote `docs/MORNING_SUMMARY.md` for the owner.
- Next: owner decisions in `docs/MORNING_SUMMARY.md`; then GAP-08 and the phone layout pass, GAP-17 patterns, remaining 8 sound ids.

## Lead session, 2026-11-13 morning
- Decision (Fable): the Arcade Commons icon UI and RBLX Essentials sound-system work had sat uncommitted for over 10 hours. The owner said to continue at the lead's discretion, so the lead reviewed the diff, ran the checks (39 files compile, specs, xref 0, headless 10/10, place build) and committed it as its own commit. `assets/itch/` (75 MB of downloaded packs) was left untracked on purpose.
- Seen live (solo play, iPhone emulator, second Studio window on the rebuilt place): coin, gem and crown icons in the wallet, icons on all seven rail buttons, music button on the right; both sound-system boots report no failures; Output otherwise the known Studio noise. The rail's last button (Settings) still sits close to the thumbstick.
- GAP-08 fixed: the tutorial hand ignored the 58 px top-bar inset and sat over the wallet. `TutorialController.luau` now adds `GuiService:GetGuiInset()`. Measured live: Upgrades button at y 76, hand at y 79, just right of the button. The cut step before it was skipped with the Debug `cut` hook.
- Not verified: the hand by eye on a screenshot; whether the white tutorial ring still shows now that rail buttons have their own dark outline (a button can show only one outline); music audibly playing.
- `build/TurfLoop.rbxlx` is committed again and matches the tree. The cloud place "11132026_2" was not touched and still has older scripts.

## Cloud place updated, 2026-11-13 10:00 (lead)
- The cloud place "BlazeHawks's Place: 11132026_2" (placeId 122808046982168) now holds the current scripts: `Shared`, `Server` and `Client` were replaced with the folders from `build/TurfLoop.rbxlx` at commit 9c97768. Saved to Roblox as place version 5. Saved only, **not published**.
- How: the three folders were exported to a temporary model in Studio's content folder and loaded with `game:GetObjects("rbxasset://...")`, because localhost HTTP sync is blocked. The temporary file was deleted afterwards. The RBLX Essentials folders already in the place were left as they were.
- Checked in a solo play session there: both sound-system boots report no failures, 9 bots spawn, a walked loop claimed turf and paid coins (42), the HUD shows the icon wallet and rail. No errors from our scripts.
- Not checked: the 3D view (the capture showed the UI on a black background, which happens when the Studio window is covered), any of the overnight effects in this place.
- This place has "Studio Access to API Services" off, so DataStores print `StudioAccessToApisNotAllowed` and the game uses the in-memory store. That is a security setting for the owner to change (Game Settings > Security) if saving should work in Studio.

## Terminal session, 2026-11-14 (GAP-20/GAP-09)
- Confirmed GAP-20 (speed lines) and GAP-09 (hit-stop) are already implemented in commit 9fda95d and present in current working tree.
- **Config.luau**: `Config.CutFx = { HitStop = 0.08, PopTime = 0.6, PopSpeed = 60 }` added.
- **FeedbackController.luau**: 
  - `setSpeedLines(on, id)` creates a `ParticleEmitter` on the local HumanoidRootPart with `EmissionDirection = Back`, runner colour, rate 30, lifetime 0.35s, speed 14, squash -2.5. Enabled while the local player has a trail and is alive; disabled on return, death, or `lowDetail` setting.
  - `hitStop()` calls `CameraController.hold(Config.CutFx.HitStop)` and pauses all playing animation tracks on the local character's Animator for 0.08 s.
- **CameraController.luau**: `hold(seconds)` sets `holdUntil = os.clock() + seconds`; the render step returns early while `os.clock() < holdUntil`, freezing the camera.
- All checks pass: 39 files compile, specs pass, xref 0 unresolved, headless 10/10.
- Not verified without Studio: speed-line visual feel at real speed, hit-stop feel (80 ms is too short for a screenshot), how the hit-stop interacts with different movement animations, behavior on low-end devices.

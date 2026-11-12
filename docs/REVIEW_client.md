# Client review (read-through playtest)

I traced the client code for scenarios 1 to 8 against the payloads that `Main.server.luau` and `ArenaService.luau` actually send.
After the fixes, `check.mjs` compiles 38 files with 0 failed and every spec passes. `xref.py` reports 0 unresolved.

## Defects fixed

| # | file:line | What would have happened | Fix |
|---|---|---|---|
| 1 | src/client/controllers/PanelController.luau:943 | Shop card rows are `Size (1,0)` with a `UIAspectRatioConstraint` left on the default `FitWithinMaxSize`, so every row was clamped to 0x0. No cards showed in any shop tab. | Set the row constraint to `AspectType.ScaleWithParentSize` and `DominantAxis.Width`, so the height comes from the canvas width. |
| 2 | src/client/controllers/PanelController.luau:625 | The shop canvas list used scale padding (`UDim 0.012`) inside an `AutomaticCanvasSize.Y` ScrollingFrame. The padding feeds back into the canvas height, so the canvas could keep growing or jitter. | Changed the padding to an 8 px offset. |
| 3 | src/client/controllers/ArenaClient.luau:177,191 | The snapshot lists pending runners (cut, waiting on Second Chance), and the server re-sends it on the client's first Request. That Request is often DeclineSecondChance or Respawn from the death panel. The snapshot then set `arena.alive = true` while the player was still dead, which closed the death panel early and could open the Starter offer while dead. | If our runner was cut (`alive[id] == false`) and the snapshot keeps the same id, it stays dead until a `spawn` event arrives. |
| 4 | src/client/Main.client.luau:4 | Every module indexes `Shared.Config` and the other shared modules directly after `WaitForChild("Shared")`. If the client script runs before initial replication finishes, the require throws outside `boot`'s pcall and the whole client is dead. | Wait for `game.Loaded` before booting. |
| 5 | src/client/controllers/FeedbackController.luau:516 | A full-map capture showed two toasts: the server sends `Toast:FireAllClients` and the client also toasted on the `fullMap` event. | Dropped the client-side toast. |
| 6 | src/client/Main.client.luau:39 | Every panel and rail button played uiClick twice: once from `UiKit.onClickSound` and again from `PanelController.sound("click")`. The doubled click is louder and phased once sound ids are uploaded. | `onSound` now ignores "click". |
| 7 | src/client/controllers/TutorialController.luau:91 | Before the character existed, the 12 tutorial guide dots sat stacked at the world origin, half inside the floor at arena centre, flashing. | The guide folder is parented only on the first placement. |

## Checked, no change needed
- **Boot:** no `WaitForChild` waits forever, because the server creates every remote. `ClientState.start` is guarded against double calls.
- **Snapshot and profile:** either can arrive first, and early remote events are queued. The `shieldUntil` on `GetServerTimeNow` time and the Death, Reward and RunnerInfo payloads match what the client reads.
- **Turf and trail geometry:** turf top is at FloorY+0.1, trail strips run from the floor to 0.6, and both are cell-centred on the origin.
- **Part pool:** when the pool is empty, new Parts are created.
- **Camera:** it re-forces `Scriptable` every frame, waits while there is no character (focus is nil), and nothing yields in the render callbacks.
- **Per-frame cost:** no tweens are created per frame, and transient instances are removed with `Debris` or `Destroy`.

## Not fixed, for the owner to decide
- **Unmapped error keys:** `not_dead`, `busy`, `not_in_arena`, `no_profile` and `server_error` all show "Something went wrong". A Respawn that loses a race to Second Chance or to the server's 30 s auto-respawn shows that toast.
- **G7.3 gap:** the first capture is not forced to the "oversized" celebration. Confetti only plays at 100 cells or more.
- **Two UIScales:** buttons that pulse (Daily claim, Starter buy) end up with both `ButtonScale` and `PulseScale`. Roblox applies only one UIScale, so either the hover/press scale or the pulse will not show.

## Could not verify without Studio (look here first)
1. **Shop layout after fix 1:** open each shop tab. Check that rows are full width with three cards each, that `ScaleWithParentSize` inside an AutomaticCanvasSize ScrollingFrame sizes from the canvas width, and that the page scrolls.
2. **Camera and touch controls:** a Scriptable camera driven at `RenderPriority.Camera+1`. On respawn, check that the engine's CameraModule does not flicker for a frame. On mobile, check that the thumbstick moves the character relative to the 55-degree camera.
3. **Death to respawn:** cut the player. Check that the character is anchored 20 studs under the floor and the camera stays above the floor. Check that the Respawn press blocks for about 3 s, the panel closes on the `spawn` event, and the Starter offer appears 0.6 s later when `session.starterOffer` is true.
4. **First snapshot timing:** the snapshot is fired from `addPlayerRunner`, possibly before the client's listeners connect. Confirm the queued events arrive and the turf builds over about 17 frames (100 chunks at 6 per frame).
5. **Claim flash and trails:** check that the claim flash wave lines up with the delta that arrives one tick later. Check that trail strips meet at corners and the danger blink (white trail, vignette) toggles.
6. **Particle presets and shields:** the `ParticleEmitter.Shape` and `Drag` values. Check that the ForceField ball shield follows remote players.

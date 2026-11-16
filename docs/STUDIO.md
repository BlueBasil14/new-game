# Working with Roblox Studio on this project

Learned the hard way over the first sessions. Read before the first Studio call.

## Which place
- **Current cloud place:** "BlazeHawks's Place: 11132026_2", **placeId 80441552680451** (universe 10776297454). Saved, never published.
- An older place with the same name, placeId 122808046982168, holds an old build. Do not use it.
- `build/TurfLoop.rbxlx` is the local build. It is committed and must match the tree.
- "Studio Access to API Services" is off in the cloud place, so DataStores are rejected in Studio and the game uses its in-memory store. That is the owner's setting to change.

## The loop
1. Edit code in `src/` only. Never edit scripts in Studio: the next sync overwrites them.
2. Run the checks (see `CLAUDE.md`), then `py tools/build_place.py`.
3. Test on the local build in a **second Studio window**: `Start-Process build\TurfLoop.rbxlx`, wait about 35 s, `list_roblox_studios`, play, test, stop, then close that window (`Stop-Process` on the process whose title contains `TurfLoop.rbxlx`).
4. When it is right, load it into the cloud place and save (below).

## Loading the build into the cloud place
Localhost HTTP is blocked in Studio, so sync goes through Studio's own content folder:
```
py tools/studio_export.py          # add --sounds only when the place has no SoundService.RBLXEssentials
```
Then in the cloud place, Edit mode, `execute_luau`:
```lua
local objs = game:GetObjects("rbxasset://turfloop_sync.rbxmx")
local targets = { Shared = game.ReplicatedStorage, Server = game.ServerScriptService, Client = game.StarterPlayer.StarterPlayerScripts }
for _, o in objs do
	local parent = targets[o.Name]
	if parent then
		local old = parent:FindFirstChild(o.Name)
		if old then old:Destroy() end
		o.Parent = parent
	end
end
```
Play once, read Output, stop, `save_place`, then `py tools/studio_export.py --clean`. Saving never publishes.

A new empty place also needs: the default Baseplate and SpawnLocation removed, `Workspace.StreamingEnabled = false`, and every child of Lighting removed (the template's Bloom, DepthOfField, Atmosphere, SunRays and Sky stack with the game's own lighting and wash out the turf).

## Driving the game without real input
- **Automated clicks do not register** on the game's buttons (device emulator). Use the Studio-only hooks instead.
- Client hook, a BindableEvent under the client `Main` script (`LocalPlayer.PlayerScripts.Client.Main.Debug`):
  `Fire("open", "Shop")`, `Fire("shopTab", "passes")`, `Fire("close")`, `Fire("cut")`, `Fire("capture", "7.5")`, `Fire("waveTime", "5")`.
- Server hook (`ServerScriptService.Server.Main.DebugGrantPass`): `Fire(player, "doubleSpeed")` runs the same path as a finished purchase.
- Requests can be sent directly from the Client datamodel: `ReplicatedStorage.Remotes.Request:InvokeServer("ClaimDaily")`.
- Move the character from the Server datamodel with `Humanoid:MoveTo` and `MoveToFinished:Wait()`. **Never teleport it**: the movement check kicks.
- The keyboard tool works for real key binds (M skips music for pass owners).
- `execute_luau` calls must stay under about 60 s; `task.spawn` long drivers and poll.

## Reading results
- `screen_capture` omits world-space BillboardGuis and Roblox's own top bar. Do not conclude they are missing. Use the computer-use screenshot of the Studio window to see the real frame.
- A black 3D view with UI drawn means the Studio window is covered or minimised.
- Effects shorter than about a second cannot be caught between tool calls: slow them with the debug hooks or fire them in a spawned loop, then capture.
- Expected Output noise: DataStore warnings, `AnalyticsService: ... event fired`, `rbxassetid://203785492 ... Asset type does not match` (origin unknown, not ours), asset warnings for items on friends' avatars. `No asset content representation` for Arcade Commons ids used as particle textures is an open problem.
- Two-player tests: the MCP can only start solo play. Start "Server & Clients" from Studio's test-mode dropdown (computer use), then drive each window by its studio id; stop from a client window's Stop button.
- Friends' real avatars load in Studio, so bots show the owner's real friends there.

## Other agents
Other sessions (ChatGPT, a terminal Claude) edit this same folder and sometimes the same Studio. Before any Studio call run `list_roblox_studios`; if a place is already in Play mode and you did not start it, leave it alone.

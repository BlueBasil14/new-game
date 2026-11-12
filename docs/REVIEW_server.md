# Server review (read-through playtest)

Scope: src/server/Main.server.luau, WorldBuilder.luau, services/*.luau. Checks after fixes: `node check.mjs` 0 failed / all PASS, `xref.py` 0 unresolved.

## Defects fixed

| # | file:line | What would have happened | Fix |
|---|-----------|--------------------------|-----|
| 1 | ArenaService.luau:443 (readPlayer speed check) | Each tick set `lastTime = now` even when the server's copy of the client position had not changed. After a normal 0.15-0.2 s replication stall the catch-up jump was measured against 0.05 s, so the check failed 3 ticks in a row: the player was snapped back and given a strike. 5 strikes in 60 s = kick, even for an honest player on ordinary wifi. | If the position has not changed, keep `lastTime` and write the cell. Cap the elapsed window at 1 s (`MAX_SPEED_WINDOW`). |
| 2 | ArenaService.luau:404 (readPlayer settle) | The settle check only ran after the 0.5 s exempt window and needed the player within 8 studs of the teleport target. A player who keeps moving after spawn, respawn, revive or a recycle has covered about 11-16 studs by then, so they were teleported back to the target, up to 5 times (about 2.5 s of rubber-banding every life). | During the exempt window, clear `settleTarget` once the player is seen within `SETTLE_RADIUS` of the target. |
| 3 | ArenaService.luau:241 (placeAtCell) | `hideCharacter` anchors the root part (HumanoidRootPart). Anchoring drops network ownership, and the code assumed unanchoring gives it back to the player. If it does not, the player cannot move after respawn or revive. | After unanchoring, call `hrp:SetNetworkOwner(player)` (inside pcall). |
| 4 | ArenaService.luau:136 (broadcast) | `Kick` inside the tick (anti-exploit) leaves the player in `states` until the deferred PlayerRemoving runs. A `FireClient` to that player could throw inside `pcall(tick)` and drop the rest of that tick's events and housekeeping. | Skip players whose `Parent` is nil. |
| 5 | DataService.luau:179 (write) | An autosave that started before `release` could commit after the release write and put the session lock back. The player's next server would then see a lock and, after retrying for about 30 s, kick them with "still being saved". | The transform cancels a non-release write once `session.released` is set. |
| 6 | AnalyticsService.luau:9 (log) | `LogCustomEvent` only accepts `Enum.AnalyticsCustomFieldKeys` names (CustomField01..03) as field keys. Keys like `id` or `cells` made every call with fields error, and the pcall hid it, so most analytics events were never logged. | Map the sorted field names to CustomField01..03. If that call still fails, log the event without fields. |

## Walked and found OK (no change)
- Boot: remotes are created before any `start()`. The DataStore probe in Studio falls back to an in-memory mock. Nothing blocks forever. There are no circular requires. Players who joined during boot are picked up by the `GetPlayers` loops.
- `DataService.load` is called concurrently by Main, Shop, Monetization and Reward. All callers share one load through `loading` and `sessions`. A player who leaves mid-load has their lock released.
- A character that exists before `join`, or one that spawns before the profile loads, is handled by `join` checking `player.Character`.
- Bots: player-only code paths are gated by `playerById`. A rig's id is kept through recycle and respawn. `botPositions` is filtered by `isBot`.
- Request router: name whitelist, arg types and lengths, NaN, Inf, fractional and negative indices are all rejected. A handler error returns `server_error`.

## Could not verify without Studio
1. PivotTo on a client-owned character really moves it on the owning client within 0.5 s, and SetNetworkOwner after unanchoring restores control after Respawn. Test: get cut, respawn, try to move.
2. Speed check thresholds under real replication: no snap-backs or strikes in 5 minutes of normal play. Watch the output for Kick and snapBack.
3. On the server, `hrp.Position` for a client-owned character stays exactly unchanged between replication packets (fix 1 assumes this). Fix 1's 1 s cap still bounds it if the engine interpolates instead.
4. The `LogCustomEvent` custom-field key format (fix 6). Check the analytics dashboard or the output for errors.
5. With no SpawnLocation, characters first spawn above the floor at the origin and do not fall before `placeAtCell` runs.
6. RemoteEvents fired before the client connects (ProfileUpdate, ArenaSnapshot) are queued, not dropped.
7. Known edge, not fixed: if the client still has not taken the teleport after 5 settle retries, its old position is accepted. The sim then draws a trail from the spawn cell to that position.
8. Known edge, not fixed: a player who rejoins the same server while their old session is still releasing can lose the new session's saves ("lock lost").

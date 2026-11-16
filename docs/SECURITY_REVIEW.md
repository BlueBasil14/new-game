# Security review before launch

_Read-only reviews run on 2026-11-15/16 on the strongest model. Findings come from reading the code paths; none was reproduced on a live server. Status is updated as fixes land._

## Part 1: money and saves (complete)

| # | Severity | Finding | Where | Status |
|---|---|---|---|---|
| 1 | **Critical** | Game passes are granted on an unverified `PromptGamePassPurchaseFinished`. A client can fire `SignalPromptGamePassPurchaseFinished(player, passId, true)`; the server then grants VIP, 2x Coins, 2x Speed for the session, and `ShopService.reconcile` writes the VIP and Neon Pack items into the profile for good. | `MonetizationService` purchase-finished handler → `markPassOwned`; `ShopService.reconcile` | See "Fix log" |
| 2 | High | Quick rejoin to the same server loads stale data while the old session's release write is still queued (a lock with our own JobId never blocks). Later saves hit "session lock lost" and are skipped, so the new session is lost. Likely at launch with one server. | `DataService` load / release / write | See "Fix log" |
| 3 | Medium | `DataService.save` returns true when its write was cancelled (player already released), so a receipt can be acknowledged to Roblox without being persisted. | `DataService.save`, used by `MonetizationService.processReceipt` | See "Fix log" |
| 4 | Medium | Pass ownership check at join has no retry; one failed `UserOwnsGamePassAsync` leaves a paying owner without the pass all session. | `MonetizationService` join check | See "Fix log" |
| 5 | Medium (design) | Starter Pack can be bought repeatedly: 300 gems for 79 R$ each time (3.8 gems per R$ against 2.0–2.6 for gem packs), so it undercuts every gem pack. | `MonetizationService` starter pack branch | Owner decision, `docs/DECISIONS.md` |
| 6 | Low | Second Chance bought after the hold window (4 s + 12 s) gives a 20 gem refund with no explanation in the UI. | `ArenaService` second-chance hold, `MonetizationService` | Open: add a toast |
| 7 | Low | Receipts are never trimmed; `Config.Data.ReceiptHistory` is unused. Unbounded growth is harmless at realistic volumes and safer than trimming. | `ProfileTemplate` | Leave; delete the dead Config value some time |
| 8 | Low | A server still running old code would drop new nested profile fields (`daily.run`, `daily.milestones`), making milestones claimable again. | `ProfileTemplate` | Process rule: always "Migrate to latest update" when publishing a schema change |
| 9 | Low | Items granted by a pass stay owned if the pass is later gone (refund, or finding 1). | `ShopService` | Open |

Design notes from the same review: playtime rewards are per session, so an AFK player earns gems indefinitely (see `docs/BALANCE.md`); the kills board can be farmed on bots or an alt; a bought boost keeps running while the player is offline; GDD G4.4 still says no purchase affects speed.

Clean: the rest of ProcessReceipt (receipt checked twice, grant and receipt in one update, save before PurchaseGranted, retries never grant twice, unknown player/product stay pending); the Studio-only debug grants (both behind `IsStudio()`); the Studio mock store; every request handler (type, range, ownership, affordability, no yield between check and write, NaN/inf/fractions rejected, once-only flags persisted); the multiplier stack; leaderboard budgets.

Could not be assessed without a live server: whether the pass spoof still works on current Roblox, how long `UserOwnsGamePassAsync` caches a false after a real purchase, real DataStore throttling, how Roblox schedules receipt retries.

**The Sky Chest purchase and save path (added after this review) has not had a money review; its pickup path is covered in Part 2.**

## Part 2: gameplay authority, requests, bots (complete)

Line numbers are for commit cc3899f. "Confirmed" means the server code path was confirmed by reading; none was run.

| # | Severity | Finding | Where | Status |
|---|---|---|---|---|
| C1 | **Critical** | Free teleport inside the 0.5 s post-teleport exempt window. An exploiter triggers an out-of-bounds teleport home (no strike), appears near the target for one tick, then moves anywhere for the rest of the window with no speed check. The sim then draws a straight trail line to the new cell, cutting every trail it crosses. Repeatable every 0.5 s. The same window opens after every spawn, respawn, revive and snap-back. | `ArenaService` 488-500, 452-472 | See "Fix log" |
| C2 | **Critical** | Ignoring a snap-back is accepted after 5 retries (about 3 s): the server gives up and takes the client's position, drawing a trail line of any length. | `ArenaService` 501-511 | See "Fix log" |
| C3 | **Critical** | Players still collide with each other, so a fling exploiter can throw an honest player; the victim's position jumps and the **victim** gets the strikes and the kick, or is pushed across trails. | `BotService` 719-720 (collision groups), `ArenaService` strikes | See "Fix log" |
| H1 | High | Speed slack is added per tick: the real limit is 1.5 × speed + 20 studs/s, about 53 studs/s for a free player (2.4× base), 86 with 2x Speed. | `ArenaService` 71, 537-538 | See "Fix log" |
| H2 | High | Going out of bounds is a free, unlimited escape from being cut: the trail is cleared and the player is put home with no strike and no death. | `ArenaService` 452-472, 512-520 | See "Fix log" |
| H3 | High | A NaN root position passes every comparison, then throws inside the sim every tick, stalling cuts and events for everyone while it lasts. | `ArenaService` 512-550, `ArenaSim` 502-505, `Grid` 165 | See "Fix log" |
| M1 | Medium | Sky Chest pickup reads the raw root position, and the landing spot is broadcast 3 s early: a teleporter takes every chest. | `SkyChestService` 92-97 | See "Fix log" |
| M2 | Medium | Pressing Reset skips the 3 s respawn delay, and during the Second Chance hold makes all the victim's turf neutral so the killer gets nothing. No exploit tool needed. | `ArenaService` 381-425 | See "Fix log" |
| M3 | Medium | Re-equipping the equipped item succeeds and broadcasts the full runner list to every client: one client can cause 10 broadcasts per second. | `ShopService` 137-139 | See "Fix log" |
| M4 | Medium | Banked time allows a legal blink: stand still 1 s, then move 8 cells in one tick. | `ArenaService` 73, 529-537 | Open (trades against M5) |
| M5 | Medium | Honest players on poor connections can collect strikes and be kicked after network stalls. Needs real-device testing. | `ArenaService` 537-545, 429-443 | Open |
| M6 | Medium | A friend's avatar can be R6 or very heavy: an R6 rig sinks into the floor and does not animate; a fallen rig is never recovered. | `BotService` 284, 260, 198 | See "Fix log" |
| L1 | Low | One failed avatar build marks that user id failed for the whole server lifetime. | `BotService` 287 | Open |
| L2 | Low | Bots carry a real friend's display name and avatar (policy and owner decision, `docs/DECISIONS.md` item 3). | `BotService` 330, 363 | Owner |
| L4 | Low | Sky Chest `busy` flag sticks if the handler throws, locking the player out for the session. | `SkyChestService` 29-59 | See "Fix log" |
| L5 | Low | `TutorialDone` and `StarterOfferSeen` log analytics on every call. | `Main.server` 320-338 | Open |
| L6–L8 | Low | Server-to-client remotes have no no-op `OnServerEvent`; two small connection leaks per respawn; a deleted root part freezes the runner. | various | Open |

Clean: the request router (allow-list, argument count, string length, no tables, per-player token bucket, handlers in pcall); replication sizes; the Studio-only hooks (`DebugGrantPass`, `DebugDrop`, client `Debug`) cannot exist in a live server; friend fetch off the join path, caches capped, scripts stripped; flood-fill and respawn spam are bounded.

Could not be assessed without running: whether NaN or fling positions replicate on the current engine; the false-kick rate on real mobile networks; R6 and heavy avatars in practice; real bandwidth in a 16-player server.

## Fix log

### 2026-11-16: Part 1 findings 1–4 fixed (Opus subagent, reviewed by the lead)
Headless only: 44 files compile, specs pass, xref 0, headless 15/15. Nothing run in Studio or on a live server.
- **1 (pass spoof):** the purchase-finished handler no longer grants. It maps the id to a known non-zero pass, then `verifyPass` grants through `markPassOwned` only when `UserOwnsGamePassAsync` returns true, retrying `Config.PassCheck.Attempts` (6) times `RetrySeconds` (5) apart, never on error or false, stopping if the player leaves; repeated signals start one loop. Test in `g_purchases`: a spoofed signal with ownership false grants nothing; ownership true grants; ownership turning true on a later attempt grants then. The Studio-only debug grant is unchanged.
- **2 (same-server rejoin):** `release` marks the key in `releasingKeys` around its final write (cleared even on error); `load` waits up to `Config.Data.ReleaseWaitSeconds` (30) and otherwise fails like a held foreign lock. An ordinary save that finds the lock lost now kicks the player instead of letting them play unsaved. Test: new `tests/headless/n_quick_rejoin.luau` (fails without the fix).
- **3 (save reporting success for a cancelled write):** `write` returns true only when it actually wrote this session's data. Tested in the same scenario.
- **4 (no retry at join):** each pass is verified separately off the join path; errors retry with growing delays, a clean false stops at once. Test in `g_purchases`.
- **Needs a live server:** whether the spoof works on current Roblox at all; how long ownership reads false after a real purchase and whether 6 × 5 s is enough (test with the 9 Robux Skip Music pass, `docs/LAUNCH_CHECKLIST.md` B); real DataStore timing on a quick rejoin.

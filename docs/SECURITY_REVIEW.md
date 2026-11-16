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

**The Sky Chest paid spin (added after this review) has not been reviewed.**

## Part 2: gameplay authority, requests, bots
Review was cut off by a usage limit and resumed; results are appended below when it finishes.

## Fix log

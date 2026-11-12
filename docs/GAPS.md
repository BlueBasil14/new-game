# GAPS: GDD MVP scope vs code

_Read-only audit by reading `docs/GDD.md` (G2-G13) against `src/shared`, `src/server`, `src/client`. Nothing was run in Studio. Post-launch and Cut items in G13 are ignored. Sizes: S under 30 lines, M 30-150, L more. "Studio" = needs Roblox Studio (or Creator Hub assets) to implement or verify._

**Totals: 11 Missing, 15 Partial, 1 Unverified (needs Studio).** Sorted by player impact, highest first.

| ID | GDD | Status | Evidence (file:line) | What is missing | Size | Studio |
|---|---|---|---|---|---|---|
| GAP-01 | G9.2, G6 (all SFX), G9.3 | Missing — PARTIAL: music player and uiHover/coinTick/questComplete/rebirthSwell wired; ids still 0; trailLoop and lobbyMusic not played | `shared/SoundIds.luau:4-23` all 0; `FeedbackController.luau:173` returns on id 0; keys `trailLoop`, `coinTick`, `uiHover`, `questComplete`, `rebirthSwell`, `lobbyMusic`, `arenaMusic` have no play call anywhere in `src/client` | The game is silent: no sound assets, no music player, and 7 of 20 sound keys are never played. | M | Yes (assets, hearing it) |
| GAP-02 | G4, G5 (passes, products, badges, group) | Partial | `shared/Config.luau:72-94` every id 0; `MonetizationService.luau:24-33,56`; `BadgeService.luau:13`; `ArenaService.luau:548` (Second Chance needs id) | Code paths exist but every pass, product, badge, the group reward and Second Chance are inert until ids are filled. `vip_gold`, `vip_gold_trail`, 5 `neon_*`, `neon_trail`, `team`, `starter_spark` cannot be obtained until then. | S (config) | Yes (create on Roblox) |
| GAP-03 | G5 global leaderboards "in lobby", G9.4 M8 | Missing | `Main.server.luau:126-128` empty handler; `WorldBuilder.luau:188-205` stand has an empty `Board` frame; `LeaderboardService.luau:147` `top()` never called; stand sits at z=HALF+50 behind the walls (`WorldBuilder.luau:72-93,176`); no client board UI | Boards are written and read from the OrderedDataStores but never shown anywhere, and there is no reachable lobby. | M | Yes **FIXED (server): Main fills stand "Board" (title + top 10 of cells, async names); stand moved north of the wall, raised, 48x24 studs, Placeholder M8 kept. Needs Studio view check.** |
| GAP-04 | G5 return hook | Missing — FIXED (client) | no "away" panel in `src/client`; only red dots on Daily/Quests `HudController.luau:439-465` | No "while you were away" panel on join showing streak status and unclaimed rewards. | M | No |
| GAP-05 | G9.3 HUD minimap | Missing — PARTIAL: round-robin refresh (100 blocks per 0.5 s), no changed-chunk feed from ArenaClient; look unverified | `HudController.luau:612-618` builds wallet, top chips, board, feed, rail, playtime only; no "minimap" anywhere in `src` | No minimap. | M | No (look needs Studio) |
| GAP-06 | G7.3 | Missing — FIXED (client) | `FeedbackController.luau:449-452` confetti only at >=100 cells; `TutorialController.luau:72-76` only flags the claim | First capture has no forced confetti or oversized "+25" popup. | S | No |
| GAP-07 | G7.4 | Partial | `TutorialController.luau:126-178` scissors tracks nearest enemy trail, not pulsing; `BotService.luau:161-191` spawns by farthest-spot rule; nothing steers a bot near the new player | No bot is guaranteed to wander near the new player leaving a trail; scissors icon does not pulse. | M | Yes (feel) **FIXED (server): BotService steers one idle bot toward a tutorial player in the gentle window with no bot within 25 cells until 15 cells (constants local to BotService).** |
| GAP-08 | G7.5 | Partial — FIXED (client; layout unverified in Studio) | `TutorialController.luau:198-215` hand at fixed `Position(0.09,0.3)`, pulses the hand not the button; rail buttons `HudController.luau:415-454` (Upgrades is at about y 0.20-0.25) | Upgrade button itself does not pulse, hand likely sits over Shop/Quests, tap does not open Upgrades; completion is "coinBoost > 0" or 45 s timeout. | S | Yes (layout) |
| GAP-09 | G6 cutting | Missing — PARTIAL: no hit-stop; cubes sample the victim's turf at event time (none spawn if the delta already cleared it) | `CameraController.luau:28-30` FOV punch only; `FeedbackController.luau:495-500` | No 0.08 s hit-stop; victim's turf does not shatter into cubes flying to the killer. | M | Yes |
| GAP-10 | G2 King, G6 becoming King, G9.4 M3 | Partial — FIXED (client) | beam `FeedbackController.luau:571-587`; fanfare+toast `505-514`; HUD mark `HudController.luau:266-283`; no crown part in `WorldBuilder.luau` | Gold beam and toast work and are seen by all, but no crown drops onto the King's head. | S | Yes |
| GAP-11 | G2 elimination "respawns after 3 s" | Partial | `ArenaService.luau:820-849` waits for a client `Respawn`; idle fallback 30 s `:79,653`; death panel `PanelController.luau:1454-1461` | Non-eligible deaths wait for a button press instead of auto-respawning after 3 s. | S | No **FIXED (server): non-eligible deaths auto-respawn after Config.Arena.RespawnDelay; Respawn request still valid.** |
| GAP-12 | G4 "Surfaced" column | Partial — FIXED (client; banner/boost button show only once Config.Ids are non-zero) | 2x pass pulse only in Upgrades `PanelController.luau:417-425,463,477`; unaffordable shop item only toasts `766-779`; no boost prompt in Quests `1080-1161`; no Neon banner (`845-869` passes tab only); VIP not top slot | Missing: 15-min boost prompt when a quest needs coins; 2x Coins prompt after other unaffordable buys; Neon Pack banner in Skins; VIP top-slot placement. | S | No |
| GAP-13 | G4.2 / G4.3 Starter Pack | Partial — PARTIAL: client badge + offer only when starterOfferSeenAt == 0; server must keep setting starterOfferSeenAt | offer after respawn when `starterOffer` `PanelController.luau:1590-1607`; `EconomyRules.luau:13-22`; no badge in `HudController.luau:415-454` | No shop badge until bought or 48 h; offer can re-show on the first death of every later session inside the 48 h window (`starterShown` is per session), GDD says once. | S | No **FIXED (server): confirmed StarterOfferSeen sets starterOfferSeenAt once and shouldOfferStarter only offers inside the window afterwards.** |
| GAP-14 | G6 claim | Partial | `TurfRenderer.luau:221-232,481-518` | Fill is a whole-chunk 0.25 s flash, not a wave travelling from the trail inward. | S-M | Yes |
| GAP-15 | G6 stealing | Missing — FIXED (client) | `TurfRenderer.luau:221-232` flashes the new owner's lightened colour; only the crunch SFX `FeedbackController.luau:438-440` | Stolen area does not flash the victim's colour before flipping. | S | Yes |
| GAP-16 | G3.6 capture effect | Partial — FIXED (client) | `FeedbackController.luau:491-494` only `ev.id == myId` | Other players never see a capture effect (cosmetic is replicated in `RunnerInfo` but not played for others). | S | No |
| GAP-17 | G3.6 pattern, trail cosmetic, G9.1 | Partial | `TurfRenderer.luau:20-21` `patternImages` empty; `189-197` pattern faked by chunk parity; trail uses only `colorA` `173-176` | Skin patterns are crude 64-stud blocks; trail cosmetics are a tint only (no pattern/particles). | M | Yes (textures) |
| GAP-18 | G4.1 VIP gold name tag | Missing — PARTIAL: client gold name in board and kill feed; server must add RunnerInfo.vip | no tag code; `ArenaService.luau:301` name is DisplayName only | VIP gold name tag does not exist. | S | No **FIXED (server): RunnerInfo.vip set by ArenaService (join, equip, pass bought via MonetizationService.onPassOwned); gold BillboardGui "VipTag" on Head.** |
| GAP-19 | G6 eliminated | Partial | `ArenaService.luau:256-267` character is anchored and moved under the floor; desaturate ok `FeedbackController.luau:345-363` | No ragdoll pop. | M | Yes |
| GAP-20 | G6 leaving turf | Missing | only `trailStart` SFX `FeedbackController.luau:389-391` | No speed-line effect on the character; no trail loop sound. | S | Yes |
| GAP-21 | G6 buying | Missing — FIXED (client) | `PanelController.luau:469-472` squash + sound only | No coin shower from wallet. | S | No |
| GAP-22 | G9.3 Settings | Partial — FIXED (client; music toggle starts/stops arenaMusic) | sfx `FeedbackController.luau:177`; shake `FeedbackController.luau:442,670`, `CameraController.luau:33`; lowDetail `Main.client.luau:53-62`, `TurfRenderer.luau:584-603`; music toggle stored `Main.server.luau:196-207` but nothing reads it | Music toggle has no effect (no music exists). | S | No |
| GAP-23 | G12 analytics | Partial | present: `session_start`, `first_capture`, `capture`, `cut`, `death`, `upgrade_buy`, `item_buy`, `rebirth`, `daily_claim`, `quest_claim`, `code_redeem`, `session_end` (`Main.server.luau:139-309`, `ArenaService.luau:504-560`); `offer_shown` only for the Starter Pack `Main.server.luau:219`; `AnalyticsService.luau:39` `funnel` never called | No log for `tutorial_step{n}`, `offer_bought`, `product_bought`; no funnel steps. `MonetizationService.luau` does not import AnalyticsService. | S | No **FIXED (server): tutorial_step, product_bought, offer_bought (via MonetizationService.onProductBought), offer_shown, funnel steps 1-6 via AnalyticsService.funnelOnce.** |
| GAP-24 | G11.6 out-of-bounds | Partial | `ArenaService.luau:427-435` -> `snapBack :384-387` | Runner is teleported to its last cell, not "their turf", and its trail is not cleared. | S | No **FIXED (server): out of bounds teleports to nearest own-turf cell, clears trail (new sim:clearTrail).** |
| GAP-25 | G4.2 Second Chance | Partial | `ArenaService.luau:77,562` holds the victim 4 + 20 s | Victim's turf (and killer's 25 % share) is held up to 24 s though the prompt is 4 s; only matters once the product id exists. | S | Yes (purchase flow) **PARTIAL: hold shortened to PromptSeconds + 12 s; in-flight purchase cannot be detected server-side (client opens the dialog).** |
| GAP-26 | G13 placeholder props, G9.4 | Missing | `WorldBuilder.luau:171-214` has kiosk, stand, chest only | No placeholders for M3 crown, M9 coin, M10 gem (HUD uses letters). Kiosk and chest are decor with no interaction. | S | No **FIXED (server): kiosk (M7) and chest (M11) carry Placeholder attributes, no interaction.** |
| GAP-27 | G11.4 snapshot | Unverified — FIXED (client; needs server Ready handler) | snapshot sent at runner creation `ArenaService.luau:317`; resend only on first client Request `Main.server.luau:270-274`; client sends no Request at startup (`ClientState.request` callers only fire on user actions) | If remote events fired before the client script connects are dropped rather than queued, the arena would not render until the first button press. `docs/REVIEW_*.md` assume queuing. | S (add startup ping) | Yes **FIXED (server): Ready request added; first Request (including Ready) re-sends the snapshot, safe before the runner exists.** |

## Other findings

**Numbers in code that contradict the GDD**
- `ArenaService.luau:79` `IDLE_RESPAWN = 30` vs "respawns after 3 s" (see GAP-11).
- `ArenaService.luau:77` `SECOND_CHANCE_GRACE = 20` on top of the 4 s prompt (GAP-25).
- `Catalog.luau:154` day-7 skin `streak_week` has rarity "exclusive", GDD says "rare skin".
- `Config.luau:10` `Arena.MaxPlayers = 16` is never read; the 16-player cap must be set in the place settings in Studio.
- Every other Config table value was compared to the GDD (arena, income, upgrades, rebirth, prices, products, bots, security, leaderboards, Robux display prices in `PanelController.luau:187-190`) and matches.

**Remotes**
- All 8 RemoteEvents are fired by the server and connected by the client. All 13 `Requests` have a server handler (`Main.server.luau:134-222`) and a client caller (`TutorialDone` is sent as a string literal, `TutorialController.luau:234`). No orphan remote or request found.
- Deviation, not a gap: GDD says `Request` is event+id, code uses a RemoteFunction (`Remotes.luau:25`).

**Catalog items that can never be obtained**
- Until `Config.Ids` is filled (GAP-02): `vip_gold`, `vip_gold_trail`, `neon_pink/cyan/lime/purple/orange`, `neon_trail`, `team`, `starter_spark`.
- `streak_week` only comes from the day-7 claim on the first loop (`RewardService.luau:86-89`), by design.
- Crown skins: the shop "Claim" button (`PanelController.luau:717-740`) calls `BuyItem`, which returns `not_for_sale` for crown items (`ShopService.luau:90-94`, `Catalog.isPurchasable`). Harmless because `ShopService.reconcile` already grants them on rebirth (`UpgradeService.luau:90`), but the path is dead.
- Post-launch: weekend themed skin does not exist (out of MVP scope).

**Dead code (never called from `src`)**
`AnalyticsService.funnel` (`AnalyticsService.luau:39`), `ArenaService.runnerIdOf` (`:903`), `EconomyService.activateBoost` (`:191`), `UiKit.showPanel` (`UiKit.luau:307`), `PanelController.close` (`:1648`), `UpgradeService.rebirthed` listeners (`:12`, nobody connects), `LeaderboardService.top` (`:147`), `Main.server.luau:127` `updateLeaderboardStand` no-op, `Config.Arena.MaxPlayers`, 7 SoundIds keys (GAP-01). Test-only: `Catalog.badges` (`Catalog.luau:272`), `ArenaSim.trailOwnerAt` (`:594`), `Grid.recount/encodeDelta/decodeDelta` (`Grid.luau:135,231,256`), `GreedyMesh.buildAll` (`:56`), `TrailRuns.chunkOf/markCells` (`:65,72`). `Players.PlayerRemoving` calls `ArenaService.leave` twice (`Main.server.luau:306`, `ArenaService.luau:941`); harmless because `leave` is idempotent.

## Implemented and verified by reading

**G2 rules table (ArenaSim + ArenaService)**
- Grid 160x160, cell 4, flat, wall clamp, no wall death: `Config.luau:6-23`, `ArenaSim.luau:502-503`.
- 20 Hz tick with line stepping over crossed cells: `ArenaService.luau:944-964`, `ArenaSim.luau:505-508`.
- Spawn 5x5 (upgradable) at the free spot farthest from other runners, 3 s shield (cannot cut, cannot be cut): `ArenaSim.luau:222-290,436-442`.
- Trail on any non-own cell: `ArenaSim.luau:466-493`.
- Claim with border flood fill and enemy-turf steal: `FloodFill.luau:34-171`, `ArenaSim.luau:444-464`.
- Cut, head-on double kill, own trail harmless, enclosed runner not killed: `ArenaSim.luau:466-531`.
- Elimination: 25 % of victim cells nearest the killer, rest neutral, trail cleared: `ArenaSim.luau:346-408`; Second Chance revive `:411-421`.
- Leaving: neutral after 5 s: `ArenaService.luau:781-817`.
- King (min 3 %, ties keep the holder): `ArenaSim.luau:181-200`; double kill reward `Formulas.luau:88-95`.
- 100 % map: 5,000 coins, server-wide Toast, reset to start patch: `ArenaSim.luau:459-463`, `ArenaService.luau:568-577`.
- Base WalkSpeed 22, jump disabled: `Config.luau:14`, `ArenaService.luau:350-351`, `InputController.luau:5-14`. Camera pitch 55, distance 45 to 70, FOV 70: `CameraController.luau:46-81`.

**G3 economy**
- All income sources and all seven multipliers (upgrade, rebirth, VIP, 2x pass, boost, group, weekend) reach `EconomyService.multiplier` (`EconomyService.luau:68-83`, `Formulas.luau:52-72`). Capture, kill, passive (10 s) and full-map payouts go through `addCoins` (`EconomyService.luau:171-184,200-216`). Pass, group and boost state is set by `MonetizationService.luau:35-68` and `EconomyService.luau:187-198`.
- Upgrades: speed live on the runner via `refreshWalkSpeed` (`ArenaService.luau:886-901`, `Main.server.luau:138`); start size and shield applied at spawn and respawn (`ArenaService.luau:308,600`); coin boost in the multiplier. Costs and caps match G3.3 (`Formulas.luau:34-50`).
- Rebirth: requirement, reset of coins and upgrades, +1 Crown, 50 gems, walk speed refresh, crown-tier skins granted (`UpgradeService.luau:71-95`, `Main.server.luau:180-189`).
- Cosmetic counts: 12/8/6/3/4 skins, 8 trails (2/3/2/1 plus 3 rare as spec'd), 5 capture effects (`Catalog.luau:56-151`). Prices, featured 6 at -20 % by day (`Catalog.luau:192-206`, `ShopService.luau:96-97`, `Formulas.luau:125-135`). Equip is replicated to others through `RunnerInfo` (`ArenaService.luau:928-939`) and drawn by `TurfRenderer.luau:155-187` (colour for everyone).

**G4 grant paths**
- ProcessReceipt with receipt stored before grant, duplicate check, save before returning granted (`MonetizationService.luau:97-157`). Starter Pack, Second Chance (with gem refund if not applied), boost and four gem packs are handled. VIP daily gems x2 `RewardService.luau:74-76`. Second Chance on death screen with 4 s countdown and >=3 % rule `ArenaService.luau:548-562`, `PanelController.luau:1427-1524`. 2x Coins footer in Upgrades, gems tab opens when an epic/legendary is unaffordable (`PanelController.luau:775-777`).

**G5 retention**
- Daily streak (7-day table, reset on a missed day, UTC) `RewardService.luau:63-91`, `Formulas.luau:114-122`, UI `PanelController.luau:966-1076`.
- Playtime rewards 2/5/10/20/30 min `RewardService.luau:93-116`, bar `HudController.luau:472-601`.
- Daily quests: 3 distinct kinds from the pool; progress is fed for all six kinds: cells, bigCapture, mapPct (`ArenaService.luau:479-481`), kills (`:522`), kingSeconds (`:639`), playMinutes (`RewardService.luau:199-210`); claim and UI `RewardService.luau:118-149`, `PanelController.luau:1080-1161`.
- Live server leaderboard `HudController.luau:243-339`; global boards written for players only, never bots (`ArenaService.luau:494-495,529`, `Main.server.luau:184`).
- Codes `RELEASE`, `TURF` (`RewardService.luau:151-172`, `Catalog.luau:267-270`); group +10 % and `team` skin (needs id); weekend x2 with HUD chip `HudController.luau:199-226`.
- All 8 badges have an award call: firstLoop `ArenaService.luau:497`, firstCut `:531`, king `:588`, map10/map50 `:498-501`, map100 `:573`, firstRebirth `Main.server.luau:185`, streak7 `:158`.

**G6 present**: danger pulse/heartbeat/red vignette (`FeedbackController.luau:383-430,565-568,603-633`), pop ladder capped at 12 (`:432-437`), coin number pop at centroid (`:528-549`), camera shake scaled 0-0.6 (`:441-444`), confetti at >=100 cells, steal crunch, snip, FOV punch, death desaturate, shield bubble, king beam, wallet roll-up, button hover 1.05 / press 0.95 (`UiKit.luau:162-175`), trail as raised bright strip (`TurfRenderer.luau:313-319`).

**G7 present**: spawn on patch with no lobby; dotted loop guide until first claim (`TutorialController.luau:51-107`); scissors hint up to 60 s; upgrade hint at 100 coins; tutorial flag via `TutorialDone`; bots within 2 min are slower and never enter a new player's trail (`BotService.luau:258-281`, `Config.luau:115-116`).

**G9.3 screens present**: HUD (wallet, map %, boost and weekend chips, live board, kill feed), Upgrades, Shop (Featured/Skins/Trails/Effects/Gems/Passes plus Owned toggle as inventory/equip), Death, Daily, Quests, Playtime bar, Rebirth, Codes, Settings, Starter offer, toast layer, tutorial overlay.

**G10 bots**: Expand/Return/Hunt with 8-cell threat, 6-cell hunt and "closer than home" rule, three tiers with 0.6/0.35/0.15 s reaction and loop sizes 4-12 (`BotBrain.luau:304-416`, `Config.luau:107-117`); bot count `max(0, 10 - players)` (`BotService.luau:206`); fixed names, no chat, normal kill rewards, not on global boards.

**G11.6 anti-exploit present**: server-only territory and coins; 1.5x speed over 3 ticks snaps back and ignores, 5 strikes in 60 s kicks (`ArenaService.luau:368-466`); Y and bounds check (partial, GAP-24); every request type-checked, arg-limited and rate limited to 10/s (`Main.server.luau:227-281`); currency only in `EconomyService` (grep of all `coins/gems` writes); receipts before grant; DataService session lock, 60 s autosave, BindToClose (`DataService.luau:143-208,315-367`).

**G12 events with a log call**: listed in GAP-23 (12 of 16 present; `offer_shown` only for the starter pack).

# Turf Loop — Game Design Doc

_Owner: Fable. Section IDs (G1…G14) are stable; workers are given section IDs, not the whole file. All numbers live in `src/shared/Config.luau`; this doc is the source they are copied from._

## G0. One-line pitch
Run out of your coloured turf leaving a trail, loop back to claim everything you circled, and cut other players' trails to wipe them out. Drop-in, 16-player, always-on arena.

## G1. Loops

**G1.1 Core loop (5–20 s).** Leave turf → trail extends behind you → return to your own turf → trail plus everything enclosed becomes yours → coins pop. Risk: while you are outside your turf, anyone who crosses your trail eliminates you.

**G1.2 Session loop (5–15 min).** Spawn with a small patch → grow → climb the server leaderboard → get eliminated or become King (#1) → spend banked coins on upgrades and skins between lives → respawn stronger. Daily quests and playtime rewards give a reason to stay for "one more life".

**G1.3 Long-term loop (days/weeks).** Permanent upgrades → Rebirth for Crowns and a permanent multiplier → Crown-gated cosmetics → global leaderboards → daily streak, weekly event, codes.

## G2. Arena rules (authoritative spec)

| Rule | Value |
|---|---|
| Grid | 160 × 160 cells, cell = 4 studs (arena 640 × 640 studs), flat |
| Server size | 16 players; bots fill so there are always ≥ 10 runners |
| Tick | Server simulation 20 Hz; each tick maps every runner's HumanoidRootPart XZ to a cell (and all cells crossed since last tick, by line stepping) |
| Spawn | 5 × 5 patch (upgradable, G3.2) at the free spot farthest from other runners; 3 s spawn shield (cannot be cut, cannot cut) |
| Trail | Any cell entered that is not your own turf while alive is added to your trail |
| Claim | Entering your own turf with a non-empty trail: trail cells become yours, then every cell not reachable from the arena border without crossing your turf becomes yours (border flood fill). Enemy turf inside is stolen. |
| Cut | A runner entering a cell that holds another runner's trail eliminates the trail's owner. Head-on (both enter each other's trail the same tick): both eliminated. |
| Own trail | Crossing your own trail is harmless (kid-friendly; differs from the genre norm on purpose) |
| Wall | Arena edge is a solid wall; no death by wall |
| Enclosed | A runner standing in cells that get claimed by someone else is not killed; they just stand on enemy turf |
| Elimination | All of the victim's turf and trail become neutral, except the killer receives the 25% of victim cells nearest the killer. Victim respawns after 3 s (new patch). |
| Leaving | Player leaves → their turf turns neutral after 5 s |
| King | Runner with most cells (min 3% of map) wears the crown; cutting the King pays double kill reward |
| Win state | None — endless. A "100% map" capture pays 5,000 coins, announces server-wide and resets that runner to a start patch. |

Movement is the normal Roblox character on a flat plane. Base WalkSpeed 22. Jump disabled in the arena. Camera: fixed-angle chase camera, 55° pitch, distance 45 studs growing to 70 as turf grows (client only).

## G3. Progression

**G3.1 Currencies**
- **Coins** (soft): earned by playing. Spent on upgrades and common/rare skins.
- **Gems** (premium): from dev products, daily streak, quests, rebirth. Spent on epic/legendary cosmetics and boosts. Never spent on power.
- **Crowns** (prestige): from Rebirth only. Gate cosmetics and give a permanent coin multiplier.

**G3.2 Coin income**
| Source | Amount |
|---|---|
| Cell claimed (neutral) | 1 |
| Cell claimed (stolen from enemy) | 2 |
| Elimination | 25 + 10% of victim's cell count (×2 if victim was King) |
| Passive | every 10 s: floor(own cells / 20) |
| Capture size bonus | single capture ≥ 100 cells: +10%; ≥ 400: +25%; ≥ 1,000: +50% |
| Multipliers (multiply together) | upgrade (G3.3), rebirth +25% per Crown, VIP ×1.2, 2× Coins pass ×2, boost ×2, group +10%, weekend event ×2 |

Coins bank instantly; dying never loses coins. Expected raw income for a new player: ~150–250 coins/min; an engaged mid player with multipliers: ~1,500/min.

**G3.3 Permanent upgrades (coins)** — cost = base × growth^level, rounded to nearest 5.
| Upgrade | Effect per level | Max lvl | Base | Growth |
|---|---|---|---|---|
| Speed | +1.5% WalkSpeed (cap +15%) | 10 | 150 | 1.75 |
| Start Size | patch side +2 cells (5→7→9→11) | 3 | 1,000 | 5.0 |
| Coin Boost | +10% coins | 20 | 100 | 1.45 |
| Spawn Shield | +0.5 s shield (3 s → 5.5 s) | 5 | 300 | 2.0 |

Speed is deliberately capped at +15% and is never sold for Robux, so paying players cannot outrun free players.

**G3.4 Rebirth.** Requires 150,000 × 2^(crowns) lifetime-since-rebirth coins earned (not held). Resets coins and upgrades. Grants +1 Crown, +25% permanent coin multiplier, 50 Gems. Target pacing: first rebirth ≈ 2.5–3 h of play, later ones ≈ 3–4 h each thanks to the multiplier.

**G3.5 Pacing targets (first session)**
| Minute | Player should have |
|---|---|
| 0:15 | first capture |
| 1:00 | ~60 coins, first Coin Boost purchase prompt (cost 100 → reached by ~1:30) |
| 3:00 | first elimination given or received; 2–3 upgrades bought |
| 5:00 | first common skin affordable (500 coins) |
| 10:00 | playtime reward 2 claimed, 1 daily quest done, Starter Pack offer seen |

**G3.6 Cosmetics** (no gameplay effect)
- **Turf skins**: colour + pattern on your land. Common 500 coins, Rare 5,000 coins, Epic 150 Gems, Legendary 400 Gems, Crown-tier (free, need 1/3/5/10 Crowns). MVP: 12 common, 8 rare, 6 epic, 3 legendary, 4 crown.
- **Trails**: effect on your trail line. MVP: 8 (2 common, 3 rare, 2 epic, 1 legendary).
- **Capture effects**: VFX+SFX when a claim completes. MVP: 5.
- Shop shows a daily rotation of 6 featured items at −20%; everything is also always available in the full catalogue. No random boxes.

## G4. Monetization (Robux)

**G4.1 Gamepasses**
| Pass | Price | Effect | Surfaced |
|---|---|---|---|
| VIP | 399 | ×1.2 coins, gold name tag, VIP turf skin + trail, daily gems ×2 | Shop top slot; lobby VIP arch |
| 2× Coins | 249 | ×2 coins forever | Upgrade panel footer; after any purchase the player cannot afford |
| Neon Pack | 199 | 5 neon turf skins + neon trail | Skin catalogue banner |
| Radio | 99 | play a moderated music-ID boombox in the lobby area | Post-launch |

**G4.2 Developer products**
| Product | Price | Effect | Surfaced |
|---|---|---|---|
| Starter Pack (once per account) | 79 | 300 Gems + exclusive "Starter Spark" skin + 2,500 coins | Offer panel at first death after minute 4; shop badge until bought or 48 h |
| Second Chance | 15 | On elimination: keep turf, respawn on it with 3 s shield. Max once per life. | 4-second prompt on the death screen when the player owned ≥ 3% of the map |
| 2× Coins, 15 min | 29 | boost | Shop; prompt when a quest needs coins |
| Gems S / M / L / XL | 49 / 199 / 449 / 999 | 80 / 400 / 1,000 / 2,600 Gems | Shop gems tab; when an epic/legendary is unaffordable |

**G4.3 First-purchase hook (inside 10 min).** The Starter Pack at 79 R$ is priced as the obvious first buy: its Gems alone would cost ~150 R$. It appears once, at an emotional low (first death after minute 4), then waits quietly in the shop. Second Chance at 15 R$ is the impulse fallback.

**G4.4 Rules.** No paid random items. No Robux purchase affects speed, cut rules or shield. Second Chance is the only purchase that touches a live round and is capped at one per life. All purchases are granted by the server in `ProcessReceipt` and are idempotent (G11.4).

## G5. Retention

| System | Spec |
|---|---|
| Daily streak | 7-day calendar, loops. Day 1–7: 250 c, 500 c, 20 g, 1,000 c, 40 g, 2,500 c, 100 g + rare skin (first loop only). Miss a day → streak resets to day 1. Resets at 00:00 UTC. |
| Playtime rewards | Per session at 2 / 5 / 10 / 20 / 30 min: 100 c, 250 c, 10 g, 1,000 c, 30 g |
| Daily quests | 3 per day from a pool: claim N cells (500/1,500/4,000), eliminate N runners (3/8), single capture ≥ N cells (100/300), reach N% of map (5/10), be King for N s (30/120), play N min (10/20). Reward 300–1,500 c or 10–25 g. |
| Leaderboards | Live server board (cells %). Global OrderedDataStore boards in lobby: lifetime cells, eliminations, best map %, Crowns. Refresh 2 min. |
| Codes | `RELEASE` 1,000 c; `TURF` 25 g; like-goal codes added at 1k / 5k / 10k likes |
| Group reward | Join group → +10% coins and "Team" skin |
| Weekly event | Sat–Sun UTC: ×2 coins; themed limited skin in the shop |
| Badges | First Loop, First Cut, King, 10% Map, 50% Map, 100% Map, First Rebirth, 7-Day Streak |
| Return hook | On join, a "while you were away" panel shows streak status and unclaimed rewards |

## G6. Game feel checklist

| Action | Feedback |
|---|---|
| Leaving turf | Trail starts with a soft "zip" loop sound; character gets a faint speed-line effect; trail drawn as a raised bright strip of the player's colour |
| Trail in danger (enemy within 6 cells of your trail) | Trail pulses white, heartbeat SFX, red vignette edge |
| Claim | Fill animates as a wave from the trail inward over 0.25 s; rising-pitch "pop" per 20 cells capped at 12 notes; coin number pops (+124) at capture centroid; camera shake scaled 0–0.6 by capture size; confetti burst ≥ 100 cells; capture effect cosmetic plays |
| Stealing enemy turf | Extra "crunch" SFX and the stolen area flashes the victim's colour before flipping |
| Cutting a trail | 0.08 s hit-stop on the killer's camera (FOV punch 70→62→70), "snip" SFX, victim's turf shatters into cubes that fly to the killer, kill-feed entry, +coins popup |
| Being eliminated | Screen desaturates 0.3 s, "pop" ragdoll, death panel shows life stats (cells, coins earned, kills) with a big Respawn button and Second Chance when eligible |
| Becoming King | Crown drops onto head with fanfare, server-wide toast, gold beam marker others can see |
| Buying | Button squash, coin shower from wallet, "cha-ching" |
| UI | Every button: hover scale 1.05, press 0.95, click SFX |
| Coins | Wallet counter rolls up, never snaps |

## G7. Onboarding (first 60 s, no text required)

1. Player spawns already standing on their coloured patch in the arena — no lobby wall, no menu.
2. A dotted ghost arrow draws a loop out of the patch and back in; it repeats until the first capture.
3. First capture: oversized celebration (forced confetti + "+25" popup), arrow disappears.
4. A bot wanders nearby leaving an obvious trail; a pulsing scissors icon hovers over that trail until the player's first cut or 60 s passes.
5. At 100 coins the Upgrade button pulses with a hand pointer; one tap on Coin Boost completes the tutorial flag.
6. Bots near a new player (first 2 min) are slower and never cut them.

## G8. Visual direction

- **Style**: clean toy-board look. Flat saturated turf colours on a pale neutral ground, chunky low-poly props, soft shadows, no textures beyond simple patterns.
- **Palette**: ground `#EEF1F5`, grid lines `#DDE2EA`, arena wall `#2B2F3A`, UI dark `#1E2230`, UI light `#FFFFFF`, accent yellow `#FFC83D`, accent pink `#FF4F8B`, gem cyan `#3DDCFF`, success green `#4ADE80`, danger red `#FF4D4D`.
- **Player colours (16)**: `#FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A`.
- **Lighting**: Future technology, ClockTime 14, Brightness 2.5, Ambient `#8A93A8`, OutdoorAmbient `#B8C0D0`, soft shadows, ColorCorrection saturation +0.15 contrast +0.05, light Bloom (intensity 0.4, threshold 1.2), Atmosphere density 0.25 with pale-blue haze.
- **Reference description**: a bright board game seen from above at an angle; coloured felt territories spreading over a white table; rounded plastic player pieces.

## G9. Lists

**G9.1 VFX**: trail strip, trail danger pulse, claim wave, confetti burst, coin popup, stolen-turf flash, cut shatter cubes, death pop, crown drop + beam, spawn shield bubble, speed lines, purchase coin shower, 5 capture-effect cosmetics (Sparkle, Fireworks, Bubbles, Lightning, Hearts), 8 trail cosmetics.

**G9.2 SFX**: trail start, trail loop (subtle), heartbeat, claim pop (pitch ladder), big-claim fanfare, steal crunch, snip, death pop, respawn whoosh, crown fanfare, coin tick, purchase cha-ching, UI hover, UI click, UI error, reward claim, quest complete, rebirth swell, lobby music loop, arena music loop.

**G9.3 UI screens**: HUD (wallet, map %, minimap, live leaderboard, kill feed, boost timers), Upgrade panel, Shop (Featured / Skins / Trails / Effects / Gems / Passes), Inventory/equip, Death panel, Daily streak calendar, Quests panel, Playtime rewards bar, Rebirth panel, Codes entry, Settings (music, SFX, shake, low-detail), Starter Pack offer, toast/notification layer, tutorial overlay.

**G9.4 Models (Blender)** — all single material or vertex-colour, applied transforms, 1 unit = 1 stud.
| ID | Model | Tris budget | Priority |
|---|---|---|---|
| M1 | Arena wall segment (tiling, 16 studs) | 60 | MVP |
| M2 | Corner tower | 300 | MVP |
| M3 | King crown (accessory) | 250 | MVP |
| M4 | Low-poly tree ×3 variants | 200 each | MVP |
| M5 | Rock ×3 variants | 80 each | MVP |
| M6 | Cloud ×2 | 120 each | MVP |
| M7 | Shop kiosk | 500 | MVP |
| M8 | Leaderboard stand | 300 | MVP |
| M9 | Coin | 80 | MVP |
| M10 | Gem | 60 | MVP |
| M11 | Daily-reward chest | 400 | MVP |
| M12 | VIP arch | 400 | Post-launch |
| M13 | Seasonal prop set | 1,500 total | Post-launch |

Until Blender models exist, every model has a Part-built placeholder generated by script so the game is playable without them.

## G10. Bots

Server-side runners with no Roblox character physics cost beyond a simple rig moved by the server. State machine: `Expand` (walk a rectangular loop 4–12 cells out and back) → `Return` (if an enemy is within 8 cells of its trail) → `Hunt` (if an enemy trail is within 6 cells and closer than the bot's own way home). Three skill tiers alter loop size and reaction delay (0.6 / 0.35 / 0.15 s). Bots use plausible names from a fixed list, pay normal kill rewards, never use chat. Bot count = max(0, 10 − players).

## G11. Technical architecture

**G11.1 Layout (Rojo)**
```
src/shared/        → ReplicatedStorage.Shared    (Config, Grid, FloodFill, Types, Formulas, Catalog)
src/server/        → ServerScriptService.Server  (Main.server, services/*.luau)
src/client/        → StarterPlayerScripts.Client (Main.client, controllers/*.luau)
src/ui/            → StarterGui                  (built by script from UI spec)
```

**G11.2 Server services**: `ArenaService` (grid state, tick, claims, cuts, spawns), `BotService`, `DataService` (profiles, session lock, autosave 60 s, BindToClose), `EconomyService` (all coin/gem grants and spends, multipliers), `UpgradeService`, `ShopService` (catalogue, equip, featured rotation), `MonetizationService` (ProcessReceipt, pass ownership), `RewardService` (daily, playtime, quests, codes, group), `LeaderboardService`, `BadgeService`, `AnalyticsService`.

**G11.3 Client controllers**: `TurfRenderer` (greedy-meshed rectangles of pooled Parts per owner; trails as strips), `CameraController`, `HudController`, `PanelController` (all panels), `FeedbackController` (VFX/SFX/shake/popups), `TutorialController`, `InputController`.

**G11.4 Networking** (one RemoteEvent per direction-purpose, in `ReplicatedStorage.Remotes`)
| Remote | Direction | Payload |
|---|---|---|
| `ArenaSnapshot` | S→C | full grid as run-length-encoded buffer + runner table (on join / resync) |
| `ArenaDelta` | S→C, 10 Hz unreliable-safe batches | list of {cells changed → owner}, trail appends, trail clears |
| `ArenaEvent` | S→C | claim {runner, count, centroid, stolen}, cut {killer, victim}, king {runner}, spawn, despawn |
| `ProfileUpdate` | S→C | changed profile fields |
| `Request` (RemoteFunction-style via event + id) | C→S | `BuyUpgrade`, `BuyItem`, `Equip`, `ClaimDaily`, `ClaimPlaytime`, `ClaimQuest`, `RedeemCode`, `Rebirth`, `Respawn`, `SetSetting` |
| `Toast` | S→C | message key + args |

Clients send **no movement or territory data**. The server reads character positions itself.

**G11.5 DataStore schema** (`PlayerData_v1`, key `u_<userId>`)
```
{ v=1, coins, gems, crowns, lifetimeCoinsSinceRebirth,
  upgrades={speed,startSize,coinBoost,shield},
  owned={skins={id=true}, trails={}, effects={}}, equipped={skin,trail,effect},
  stats={cells,kills,deaths,bestPct,captures,playSeconds,kingSeconds},
  daily={streak,lastClaimDay}, quests={day,list={{id,progress,claimed}}},
  codes={code=true}, starterPackBought, starterOfferSeenAt, tutorialDone,
  receipts={ last 50 purchaseIds }, settings={music,sfx,shake,lowDetail},
  firstJoin, lastJoin }
```
Global boards: OrderedDataStores `LB_cells_v1`, `LB_kills_v1`, `LB_bestPct_v1`, `LB_crowns_v1`.

**G11.6 Anti-exploit**
- Territory, trails, cuts, coins: computed only on the server from server-read positions.
- Per-tick displacement check: movement above 1.5× allowed speed for 3 consecutive ticks → runner is snapped back and that movement is ignored; 5 strikes in 60 s → kick.
- Y-axis and out-of-bounds check: runner outside arena volume is teleported to their turf and their trail is cleared.
- Every `Request` is validated (type, range, ownership, affordability) and rate-limited to 10/s per player; over-limit requests are dropped.
- Currency only changes through `EconomyService`; receipts are recorded before granting and checked for duplicates.
- Session locking in `DataService` prevents duplication across servers.

## G12. Analytics events
`session_start`, `tutorial_step{n}`, `first_capture{seconds}`, `capture{cells,stolen}`, `cut{victimWasBot}`, `death{cells,lifeSeconds,killerWasBot}`, `upgrade_buy{id,level}`, `item_buy{id,currency}`, `rebirth{count}`, `offer_shown{id}`, `offer_bought{id}`, `product_bought{id,robux}`, `daily_claim{day}`, `quest_claim{id}`, `code_redeem{code}`, `session_end{seconds,coinsEarned}`. Funnel: join → first capture → first upgrade → first death → respawn → minute 10.

## G13. Scope

**MVP (shippable)**: G2 arena rules, bots, G3.2–G3.3 coins and upgrades, G3.4 rebirth, turf skins + trails (cosmetic catalogue at MVP counts), VIP + 2× Coins + Neon Pack, Starter Pack + Second Chance + Gems + boost, daily streak, playtime rewards, daily quests, live + global leaderboards, codes, group reward, 8 badges, all G6 feedback, G7 onboarding, placeholder props, data saving, anti-exploit, analytics.

**Post-launch**: Blender prop pass replacing placeholders, capture-effect cosmetics beyond 5, Radio pass, weekly themed events, VIP arch, team mode (2v2v2…), private-server custom rules, second map shape, EditableImage turf renderer, seasonal battle pass.

**Cut on purpose**: pets, trading, text-chat features, paid random boxes, any Robux-for-speed.

## G14. Open decisions (Fable to resolve during build)
- Final title (working title "Turf Loop"; name brainstorm is in CHATGPT_TASKS).
- Whether bots should be visibly tagged as bots. Default: not tagged, never counted on global boards.

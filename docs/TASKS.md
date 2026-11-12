# TASKS

_Atomic tasks from `GDD.md`. Tiers: **F** Fable, **O** Opus, **S** Sonnet, **H** Haiku. "GDD" column lists the only sections a worker needs. Status: TODO / WIP / DONE / BLOCKED._

**Acceptance baseline for every code task:** `node tools/luau/check.mjs` exits 0 (all files compile, all specs pass), file starts with `--!strict`, no numbers hard-coded that exist in `Config`.

**Environment note:** tasks marked 🖥 need a live Roblox Studio or Blender connection and cannot run in a cloud session. Everything else can.

## A. Foundation
| ID | Tier | Deps | GDD | Output | Acceptance | Status |
|---|---|---|---|---|---|---|
| T-FND-01 | F | — | — | `tools/roblox_saturation.py` | Live CCU printed for a query | DONE |
| T-FND-02 | F | — | — | `tools/luau/check.mjs` (compile + spec runner) | Fails on a syntax error, fails on a failing spec, passes otherwise | DONE |
| T-FND-03 | F | — | G2–G5, G11 | `src/shared/Config.luau`, `Types.luau`, `Remotes.luau` — every tunable number and the remote/request names | Compiles; values match GDD tables | DONE (compile + specs; 🖥 part untested) |
| T-FND-04 | S | T-FND-03 | G11.1 | `tools/build_place.py` → `build/TurfLoop.rbxlx` from `src/` (no external binaries) + `default.project.json` for Rojo users | Output is well-formed XML; every `src` file appears once with the right class (`.server.luau` Script, `.client.luau` LocalScript, else ModuleScript) | DONE (compile + specs; 🖥 part untested) |

## B. Pure logic (unit-tested here)
| ID | Tier | Deps | GDD | Output | Acceptance | Status |
|---|---|---|---|---|---|---|
| T-LOG-01 | O | T-FND-03 | G2 | `src/shared/Grid.luau` — buffer-backed owner grid, cell↔world mapping, line stepping, RLE encode/decode | `tests/grid.spec.luau`: round-trip RLE, world↔cell edges, line stepping hits every crossed cell | DONE (compile + specs; 🖥 part untested) |
| T-LOG-02 | O | T-LOG-01 | G2 | `src/shared/FloodFill.luau` — claim(trail, owner) returns changed cells, counts neutral vs stolen | `tests/floodfill.spec.luau`: square loop, loop against wall, loop enclosing enemy turf, concave turf, trail with no enclosure, 160×160 worst case under 30 ms | DONE (compile + specs; 🖥 part untested) |
| T-LOG-03 | S | T-FND-03 | G3 | `src/shared/Formulas.luau` — upgrade cost, coin multiplier stack, capture bonus, rebirth requirement, kill reward | `tests/formulas.spec.luau`: spot values from GDD G3.2–G3.4 | DONE (compile + specs; 🖥 part untested) |
| T-LOG-04 | S | T-FND-03 | G3.6, G5 | `src/shared/Catalog.luau` — skins/trails/effects (MVP counts), quests pool, daily table, playtime table, codes, badges | Counts match G3.6; every id unique; spec asserts counts | DONE (compile + specs; 🖥 part untested) |
| T-LOG-05 | O | T-LOG-01, T-LOG-02 | G2 | `src/shared/ArenaSim.luau` — engine-free arena state machine: runners, trails, claims, cuts, head-on, elimination split (25% nearest to killer), king, spawn placement. Takes positions in, emits events out. | `tests/arenasim.spec.luau`: every row of the G2 rules table has a test | DONE (compile + specs; 🖥 part untested) |
| T-LOG-06 | S | T-LOG-05 | G10 | `src/shared/BotBrain.luau` — pure decision function (state, grid view) → desired direction | Spec: bot completes a loop; returns home when threatened; never leaves the grid | DONE (compile + specs; 🖥 part untested) |
| T-LOG-07 | S | T-LOG-01 | G11.3 | `src/shared/GreedyMesh.luau` — owner grid region → minimal rectangles | Spec: rectangles cover exactly the owned cells, no overlap; full-map single owner → 1 rectangle | DONE (compile + specs; 🖥 part untested) |

## C. Server
| ID | Tier | Deps | GDD | Output | Acceptance | Status |
|---|---|---|---|---|---|---|
| T-SRV-01 | O | T-FND-03 | G11.5, G11.6 | `services/DataService.luau` — profile load/save, defaults + migration, session lock, autosave, BindToClose, Studio fallback when DataStores are off | Compiles; 🖥 two joins in Studio keep data | DONE (compile + specs; 🖥 part untested) |
| T-SRV-02 | O | T-LOG-05, T-SRV-01 | G2, G11.4, G11.6 | `services/ArenaService.luau` — 20 Hz tick over `ArenaSim`, reads character positions, speed/bounds checks, snapshot + delta replication, respawn | Compiles; 🖥 two clients see identical turf | DONE (compile + specs; 🖥 part untested) |
| T-SRV-03 | S | T-LOG-06, T-SRV-02 | G10 | `services/BotService.luau` — bot rigs, fill to 10 runners, tutorial-gentle bots | Compiles; 🖥 solo server shows 9 bots looping | DONE (compile + specs; 🖥 part untested) |
| T-SRV-04 | S | T-LOG-03, T-SRV-01 | G3, G11.6 | `services/EconomyService.luau` + `UpgradeService.luau` — sole owner of currency changes, multipliers, passive income, rebirth | Compiles; spec-level tests for pure parts | DONE (compile + specs; 🖥 part untested) |
| T-SRV-05 | S | T-LOG-04, T-SRV-04 | G3.6, G4 | `services/ShopService.luau` + `MonetizationService.luau` — catalogue buy/equip, featured rotation, pass checks, idempotent `ProcessReceipt`, Second Chance, Starter Pack | Compiles; receipts de-duplicated by purchaseId | DONE (compile + specs; 🖥 part untested) |
| T-SRV-06 | S | T-SRV-04 | G5 | `services/RewardService.luau` — daily streak, playtime, quests, codes, group reward | Compiles; day-rollover logic unit-tested as a pure function | DONE (compile + specs; 🖥 part untested) |
| T-SRV-07 | H | T-SRV-01 | G5, G12 | `services/LeaderboardService.luau`, `BadgeService.luau`, `AnalyticsService.luau` | Compiles; all calls wrapped in pcall with budget checks | DONE (compile + specs; 🖥 part untested) |
| T-SRV-08 | O | all C | G11.2, G11.4 | `server/Main.server.luau` — boot order, request router with validation + rate limit | Compiles; unknown/oversized requests dropped | DONE (compile + specs; 🖥 part untested) |

## D. Client
| ID | Tier | Deps | GDD | Output | Acceptance | Status |
|---|---|---|---|---|---|---|
| T-CLI-01 | O | T-LOG-07, T-SRV-02 | G8, G11.3 | `controllers/TurfRenderer.luau` — pooled Parts from greedy mesh, trail strips, claim wave | Compiles; 🖥 60 fps with full map on a mid phone profile | DONE (compile + specs; 🖥 part untested) |
| T-CLI-02 | S | T-FND-03 | G2 | `controllers/CameraController.luau`, `InputController.luau` | Compiles; 🖥 camera matches G2 | DONE (compile + specs; 🖥 part untested) |
| T-CLI-03 | S | T-FND-03 | G8, G9.3 | `ui/UiKit.luau` (buttons, panels, tweens) + `controllers/HudController.luau` | Compiles; 🖥 HUD readable on 720p phone | DONE (compile + specs; 🖥 part untested) |
| T-CLI-04 | S | T-CLI-03 | G9.3 | `controllers/PanelController.luau` — upgrade, shop, inventory, death, daily, quests, playtime, rebirth, codes, settings, starter offer | Compiles; every Request name used exists in `Remotes` | DONE (compile + specs; 🖥 part untested) |
| T-CLI-05 | S | T-CLI-01 | G6 | `controllers/FeedbackController.luau` — every row of the G6 table | Compiles; 🖥 checklist walk-through | DONE (compile + specs; 🖥 part untested) |
| T-CLI-06 | H | T-CLI-03 | G7 | `controllers/TutorialController.luau` | Compiles; 🖥 new profile reaches first capture unaided | DONE (compile + specs; 🖥 part untested) |
| T-CLI-07 | S | all D | G11.3 | `client/Main.client.luau` | Compiles | DONE (compile + specs; 🖥 part untested) |

## E. World, assets, audio
| ID | Tier | Deps | GDD | Output | Acceptance | Status |
|---|---|---|---|---|---|---|
| T-WLD-01 | S | T-FND-03 | G8, G9.4 | `server/WorldBuilder.luau` — builds arena floor, walls, lighting preset and Part placeholders for M1–M11 at runtime | Compiles; 🖥 screenshot matches G8 | DONE (compile + specs; 🖥 part untested) |
| T-AST-01…11 | H | — | G9.4 | 🖥 Blender models M1–M11 → `/assets/models/*.fbx` → Studio | Under tris budget, applied transforms, screenshot verified | BLOCKED (no Blender/Studio connection) |
| T-AUD-01 | H | T-AUDIO-01 | G9.2 | `src/shared/SoundIds.luau` filled from Creator Store | 🖥 every id plays | BLOCKED (needs Studio) |
| T-ART-01…08, T-COPY-01…06, T-AUDIO-01, T-BAL-01 | owner + ChatGPT | — | — | see `CHATGPT_TASKS.md` | file present in `/assets/chatgpt/` | TODO |

## F. Integration and launch
| ID | Tier | Deps | Output | Acceptance | Status |
|---|---|---|---|---|---|
| T-INT-01 | F | B, C, D | Code review of every system against GDD | Findings fixed or queued | DONE (13 defects fixed; see REVIEW_server.md, REVIEW_client.md) |
| T-INT-02 | F | T-FND-04 | 🖥 Open `build/TurfLoop.rbxlx` (or Rojo sync), play solo, fix console errors | Zero errors in output for a 5-minute session | BLOCKED (needs Studio) |
| T-INT-03 | F | T-INT-02 | 🖥 2-client test server: sync, cuts, purchases in test mode | G2 rules observed by both clients | BLOCKED (needs Studio) |
| T-LCH-01 | owner | T-INT-03 | Create gamepasses, products, badges, group on Roblox; paste ids into `Config.Ids` | Ids non-zero | TODO (costs nothing but needs the owner's account) |
| T-LCH-02 | F | T-LCH-01 | Publish, set icon/thumbnails/description | Live place | TODO |

## Order of work
A → B (T-LOG-01/03/04/07 in parallel, then 02, 05, 06) → C and D in parallel → E → F.

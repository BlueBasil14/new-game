# Headless server playtest

The real, unmodified server code (`src/server/**`, `src/shared/**`) runs in the luau-web VM on a
strict mock of the Roblox server API. No Studio needed.

## How to run

```
node tools/luau/headless.mjs              # every scenario in tests/headless/
node tools/luau/headless.mjs boot soak    # only files whose name contains one of the words
node tools/luau/headless.mjs -v soak      # echo server print/warn and thread errors live
```

Exit code 1 on any failure. Failures print the Luau error and traceback with bundle lines mapped
to `file:line` (e.g. `src/server/services/ArenaService.luau:412`). Whole suite: about 12 s real time.
Also run `node tools/luau/check.mjs` and `python3 tools/xref.py` (both green after these changes).

## Status (all PASS)

| scenario | what it proves |
|---|---|
| a_boot | Main boots with 0 players; Remotes folder has every Remotes.luau name; World and Bots built; 10 runners within 5 s; bots claim turf over 120 s (250 -> ~11k cells); no thread error, misuse or error-looking warn |
| b_join_and_play | player gets ProfileUpdate (receipts stripped) and ArenaSnapshot; RLE decoded with the real Grid shows their patch under the HRP; walking a 6x5 loop out and back gives a `claim` event, Reward coins = captureCoins x multiplier, profile coin delta = granted coins, quest progress moves, stats.captures = 1 |
| c_cut_and_respawn | player B crosses player A's trail: `cut` event, Death payload has exactly {coins, cells, lifeSeconds, kills, canSecondChance, killerName}, killer gets killCoins x multiplier, victim anchored with WalkSpeed 0 and cannot move; Respawn request returns after exactly RespawnDelay; `spawn` event; HRP on the new patch, unanchored, WalkSpeed > 0, network owner = player, can walk |
| d_requests | every Request name with valid args on a fresh profile returns the documented result / error key; hostile args (unknown name, table name, nil, wrong types, 100k-char string, NaN, inf, 1.5, 5 args, unknown setting key, too-long code, embedded NUL) all rejected; Coin Boost bought with granted coins, deducted by upgradeCost; 90 of 100 rapid calls rate_limited |
| e_persistence | coins, gems, upgrades, codes, firstJoin survive a server restart (distinct JobIds, same DataStore backing); session lock released by leave AND by shutdown (BindToClose) for a player still in game; rejoin is not kicked |
| f_datastore_down | every DataStore request errors: Studio falls back to the in-memory store, player joins, claims daily, earns coins, leaves; only the expected degrade warnings |
| g_purchases | test product ids injected into Config.Ids before boot; every gems product grants; repeated PurchaseId granted once; starter pack coins+skin once; boost15 activates x2 multiplier; secondChance while alive refunds 20 gems; unknown player / unknown product -> NotProcessedYet; receipt saved to the store before PurchaseGranted |
| h_soak | 4 random-walking players + 6 bots for 180 virtual s (shortened from 10 min): no errors, no kicks, no anti-cheat snap-backs against honest walkers (per-frame teleport detector), grid counts equal a full recount every 10 s. Server heartbeat cost about 0.25 ms per 60 Hz frame, about 0.75 ms per 20 Hz arena tick (incl. bots and replication) in the WASM VM |
| i_leave_mid_life | player with turf and trail leaves: runner stays for LeaveNeutralDelay, then despawn broadcast and turf neutral; ticks afterwards are clean |
| z_mock_selftest | proves the mock rejects unknown properties/methods/classes/enums, wrong property types, read-only writes, callback reads, mixed/gapped/function remote payloads, and reports an infinite WaitForChild |

## Defects found in the game

| # | file:line | symptom | fix |
|---|-----------|---------|-----|
| 1 | src/server/services/DataService.luau `onClose` (~line 340) | On server shutdown, players are removed first; their PlayerRemoving `release` is already in flight, so `onClose` saw `released = true`, waited for nothing and returned. The server stops as soon as BindToClose returns, so the last save and lock release of every player still in the server at shutdown was lost (e_persistence: stored coins 0, lock still held by the old JobId -> rejoin blocked for LOCK_TIMEOUT). | Module counter `releasing` around the write in `release`; `onClose` waits (max CLOSE_CAP) while it is > 0. |

Only one real defect surfaced. The server had been reviewed carefully; the strict mock found no
API misuse (wrong members, types, enums, remote payload shapes, analytics shapes) in any scenario.

## Mock fixes (mock was wrong, not the game)

- `Players:GetNameFromUserIdAsync` / `GetUserIdFromNameAsync` were missing; added when the new
  leaderboard stand in Main.server.luau started calling them (real Roblox APIs).

## What the mock models (tools/luau/mock/roblox.luau)

- Instances as userdata proxies with a per-class property/method/event/callback table and an
  inheritance chain (Instance > PVInstance > BasePart > Part, Model, GuiObject > Frame/TextLabel,
  LayerCollector > BillboardGui/SurfaceGui, PostEffect > Bloom/ColorCorrection, Atmosphere,
  Humanoid, Player, remotes, services). Unknown member read/write, wrong property type, read-only
  write, callback read, unknown class/enum/service all `error` AND are recorded in `S.misuse`, so
  misuse inside a `pcall` still fails the scenario. Child access by name (`Shared.Config`) works.
- Parent/ChildAdded/ChildRemoved/DescendantAdded/AncestryChanged/Destroying, Destroy locks Parent,
  circular-parent check, WaitForChild (resolved on parenting/rename, timeout, and an "Infinite
  yield" error after 5 virtual s), attributes with type validation, GetPropertyChangedSignal,
  Clone, IsA, PivotTo/GetPivot (moves all parts), network ownership (errors when anchored or not
  in Workspace; anchoring hands ownership to the server).
- Datatypes: Vector3, Vector2, CFrame (full rotation math), Color3 (fromHex validates), UDim/UDim2,
  strict Enum, deterministic Random (Park-Miller), `typeof`.
- Deterministic scheduler with a virtual clock: task.wait/spawn/defer/delay/cancel, signals
  run handlers in new coroutines, Heartbeat at 60 Hz; `os.clock`, `os.time`, `os.date`,
  `GetServerTimeNow`, `tick` read the virtual clock (os.time starts Wed 2026-01-07 12:00 UTC so
  no weekend multiplier and no day rollover). Thread errors are captured with tracebacks.
- Players with fake characters (Model + HumanoidRootPart + Head + Humanoid, PrimaryPart set);
  CharacterAdded fires before the character is parented (exercises the server's wait loop);
  Died -> respawn after Players.RespawnTime; Kick records and removes; harness walks a player
  along waypoints at Humanoid.WalkSpeed, honouring Anchored and Health.
- Remotes: FireClient/FireAllClients validate payloads (no functions, mixed tables, numeric gaps,
  non-string keys, cycles; buffers deep-copied) and log every send per player; the Request
  RemoteFunction is invoked as a fake client (`H.invoke`), return values validated too.
- DataStores: in-memory backing persisting across restarts within a run, 50 ms latency, key and
  value validation (UTF-8, no userdata, NaN), UpdateAsync transform must not yield, ordered stores
  with GetSortedAsync pages, `M.dsDown = "requests" | "all"` to make every call fail.
- MarketplaceService (ProcessReceipt invocable, decision must be the enum), BadgeService,
  AnalyticsService (LogCustomEvent field keys must be CustomField01..03 with string values),
  BindToClose + shutdown (players leave, handlers get 30 s, then the server is killed).

## What it does NOT model

Physics (gravity, collisions, falling parts), replication latency and client-side position lag
(the anti-cheat's lag allowances are not stressed), real character spawning/animation/avatar
loading, rendering and GUIs (properties only), DataStore throttling/budgets and the 4 MB limit,
UpdateAsync retries on conflict (transform runs once), real network ownership auto-assignment,
`type()` of datatypes (Vector3 etc. are userdata proxies, not native vectors; they are not
value-equal as table keys), client scripts (not loaded at all).

## Harness API (tests/headless/*.luau get `H`)

`H.boot{jobId, beforeMain=fn(S)}`, `H.run(s)`, `H.runUntil(pred, timeout, what)`, `H.call(fn)`,
`H.addPlayer{userId,name}`, `H.removePlayer`, `H.walkCells(p, {{cx,cy},...})`, `H.walking`,
`H.pos/hrp/humanoid/anchored/networkOwner/cellOf`, `H.sent(p, name)`, `H.last(p, name)`,
`H.invoke(p, requestName, ...)`, `H.processReceipt(info)`, `H.shutdown()`, `H.svc(name)`,
`H.shared(name)`, `H.check/eq/say`, `H.allow = {allowWarn = {patterns}}`, `H.M.dsDown`,
`H.M.dsBacking`, `H.S.frameHooks`.

## Suspicious / unsettled

- Starter pack bought a second time grants its 300 gems again (coins and skin only once). The
  code does this deliberately (a paid product must deliver something); confirm it is the design.
- `Remotes.Requests.Ready` existed before its handler did (another programmer was adding it while
  this ran); d_requests now reports `Ready -> true`.
- Soak is 3 virtual minutes, not 10; bots only become non-gentle after 120 s, so player-vs-bot
  cuts were exercised only briefly.
- The anti-cheat was only tested against perfectly honest, zero-latency movement. Replication
  jitter (late positions, catch-up bursts) is not modelled; Studio playtest still needed for that.

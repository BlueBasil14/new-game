# Arena core API (src/shared)

Cells are 0-based, `index = y * size + x`; owner 0 = neutral, 1..255 = runner id. World X -> grid x, world Z -> grid y.

## Grid
- `Grid.new(size?: number) -> Grid` (default `Config.Arena.GridSize`, max 255)
- `g:get(x, y) -> owner`, `g:set(x, y, owner) -> prevOwner`, `g:getIndex(i)`, `g:setIndex(i, owner) -> prevOwner`
- `g:index(x, y) -> i`, `g:fromIndex(i) -> x, y`, `g:inBounds(x, y) -> boolean`
- `g:worldToCell(wx, wz) -> x, y` (clamped), `g:cellToWorld(x, y) -> wx, wz` (cell centre; arena centred on origin)
- `g:line(x0, y0, x1, y1) -> {i}`: every cell crossed, start excluded, 4-connected, length = |dx| + |dy|
- `g:count(owner)` O(1); `g:bounds(owner) -> x0, y0, x1, y1 | nil` (conservative box, may be loose); `g:recount()` (tests)
- `g:encodeRLE() -> buffer`, `Grid.decodeRLE(buffer) -> Grid` (full snapshot for joiners)
- `Grid.encodeDelta({ {index, owner} }) -> buffer`, `g:encodeIndices({i}) -> buffer` (owners read from `g`),
  `Grid.decodeDelta(buffer) -> { {index, owner} }`, `g:applyDelta(buffer) -> {i}` (applies in place)

Formats. RLE: `u8 size`, then runs `[u8 owner][u16 length]` to end of buffer.
Delta: `u16 count`, then `count` x `[u16 index][u8 owner]` (3 bytes per cell). Owners are final values, so
applying a delta is idempotent and order inside one batch does not matter.

## FloodFill
- `FloodFill.claim(grid, owner, trailCells: {i}) -> { changed: {i}, neutral: n, stolen: n, cx, cy }`
  Trail cells first become `owner`, then every cell not 4-reachable from the border without crossing owner's
  turf. Flood is limited to owner's box + 1. `cx, cy` = centroid of changed cells (last trail cell if none).

## GreedyMesh
- `GreedyMesh.build(grid, owner, x0, y0, x1, y1) -> { {x, y, w, h} }` (inclusive region, exact cover, no overlap)
- `GreedyMesh.buildAll(grid) -> { [owner]: { {x, y, w, h} } }` (one pass, neutral omitted)

## ArenaSim
- `ArenaSim.new({ size: number?, rng: (() -> number)? }) -> sim` (rng only breaks spawn ties)
- `sim:allocateId() -> id` (lowest free 1..255)
- `sim:addRunner(info: RunnerInfo, startPatch, shieldSeconds, now) -> id` (`info.id == 0` allocates and writes back)
- `sim:removeRunner(id, now)`: trail cleared, turf neutral now, id freed, emits `despawn`. Caller applies the 5 s leave delay.
- `sim:step(now, positions: { [id]: {x, y} })`: target cells; walks `Grid.line` from the runner's cell. Absent/dead runners stay.
- `sim:releaseVictim(id) -> (givenToKiller, madeNeutral)`; `sim:revive(id, shieldSeconds, now) -> boolean`
- `sim:respawn(id, startPatch, shieldSeconds, now)`: dead runner only; releases first if still pending.
- `sim:clearTrail(id)`: drops the runner's trail (overlay + `clear` trail delta); no-op for unknown ids. Does not move the runner.
- `sim:drainEvents() -> {ArenaEvent}`, `sim:drainCellChanges() -> {i}` (deduped; feed to `grid:encodeIndices`),
  `sim:drainTrailDeltas() -> {TrailDelta}` (sorted by id)
- Getters: `cellsOf(id)`, `share(id)`, `kingId()`, `runner(id) -> Runner?`, `runners() -> {Runner}` (id order),
  `isAlive(id)`, `trailOwnerAt(x, y)` (primary owner or 0), `trailOwnersAt(i) -> {id}`. `sim.grid` is readable.
- Runner: `{ id, info, alive, pending, killer, x, y, trail: {i}, shieldUntil, startPatch }`. Treat as read-only.

### Behaviour
- Spawn: candidate centres every 4 cells; prefers patches that are fully neutral and trail-free, then the largest
  min squared distance to other alive/pending runners. Patch is clipped to bounds and overwrites existing turf.
- Trail: each entered cell that is not own turf and not already in own trail is appended. Own trail is harmless.
- Claim: entering own turf with a non-empty trail runs `FloodFill.claim`, clears the trail, emits `claim`.
  If the runner then owns every cell: emits `fullMap`, all its cells go neutral and a `startPatch` is stamped
  centred on its current cell (no teleport, no shield change). The caller pays the bonus.
- Cut: entering a cell holding another alive runner's trail cuts it unless either runner is shielded
  (`now < shieldUntil`). Cuts are collected during the step and resolved at its end, so head-on = both die.
  A runner cut earlier in the same step still moves and can cut, but cannot claim or grow its trail.
  Shields can leave two trails in one cell; `trailOwnersAt` lists both, and a later crossing cuts both.
- Pending-victim flow: on a cut the victim is `alive = false, pending = true`, trail cleared, turf KEPT (others
  can still steal it). The server then either calls `releaseVictim(id)` (bots, ineligible players, prompt
  timeout) or `revive(id, shield, now)` (Second Chance; keeps turf, stays at its death cell, emits `spawn`).
  Release: `floor(n * Config.Arena.KillerShare)` victim cells nearest the killer's current cell (squared
  distance, quickselect) go to the killer if it is alive, never cells under the killer's own trail; the rest
  become neutral. Killer dead or removed = all neutral. `victimCells` in the `cut` event is the count at the cut.
- King: alive runner with most cells and share >= `KingMinShare`; ties keep the current king, else lowest id.
  Recomputed after every mutating call; emits `king` (id 0 = nobody) only on change.
- A runner alive with 0 turf (all stolen) keeps playing; its trail still cuts and can be cut, but it can never
  claim until it dies and respawns. The server may choose to treat it as dead.
- Event order within one `step`: per runner in ascending id, `claim` (then `fullMap`) as they happen while
  walking; then `cut` events in ascending victim id; then at most one `king`.
  `addRunner`/`revive` emit `spawn` then maybe `king`; `removeRunner` emits `despawn` then maybe `king`.
- Trail deltas: `clear = true` means drop the client's copy of that trail before appending `append`
  (in walk order). Trail cells are not reported as cell changes.

## Server runtime
`ArenaService` (src/server/services) drives one `ArenaSim` at `TickRate` on Heartbeat; `now` = `os.clock()` everywhere in the sim.
- Fields: `sim`, `now()`, `botPositions: {[id]: {x, y}}` (cell units, merged into each step), `preStep: ((now, dt) -> ())?`
  (one hook, run at the start of every tick; BotService), `onEvent:Connect(fn(ev))` (sync, after ArenaService handled the event).
- Functions: `start()`, `join(player)` (after profile load), `leave(player)`, `clientReady(player)`, `respawn(player)`,
  `declineSecondChance(player)`, `secondChance(player) -> boolean` (= `MonetizationService.onSecondChance`),
  `refreshWalkSpeed(player)`, `refreshVip(player)` (re-reads the VIP pass into `RunnerInfo.vip`, refreshes the gold name tag, re-broadcasts), `freeColorIndex()`, `gentleRunnerIds(now)`, `runnerIdOf(player)`.
- Players have a runner only while their character is alive; Humanoid death = `removeRunner`, re-added on the next character
  (new snapshot). A cut player's character is anchored 20 studs under the floor at its XZ until respawn/revive.

Join / snapshot sequence (per client):
1. Profile loads → `ProfileUpdate` (full) → character spawns → runner added → `ArenaSnapshot(rle, runners, yourRunnerId)`
   immediately followed by `ArenaDelta(emptyCells, trails)` where every alive/pending runner has `clear = true, append = full trail`.
2. Only after that does the client receive `ArenaEvent` / `ArenaDelta` / `RunnerInfo` broadcasts (sent per ready client).
3. The snapshot pair is re-sent on the client's first `Request` and every time the player gets a new runner (after a character
   death), so treat it as a full reset. A `spawn` for a runner already in the snapshot may follow; handle it idempotently.
4. `spawn.shieldUntil` sent to clients is on `workspace:GetServerTimeNow()` time, not the sim clock.
- `Death` goes to the victim only; `Reward` after the player's own claim (`cx, cy` = claim centroid in cells) or kill.
- Added remote `RunnerInfo(runners: {RunnerInfo})`: full list of alive + pending runners after any equipped-cosmetic change.
- Bot rigs: `workspace.Bots[tostring(id)]` Model, PrimaryPart = body.

- Out of bounds (G11.6): runner moved to its nearest own-turf cell (sim `r.x/r.y` set directly), trail cleared via `sim:clearTrail`.
- Dead players without a Second Chance offer are respawned automatically after `Config.Arena.RespawnDelay`.

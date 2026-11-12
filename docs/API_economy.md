# Economy services API (server)
Handlers are `(player, ...any) -> (boolean, any)`: `true, result` or `false, "error_key"`.
Signals: `sig:Connect(fn)` returns `{Disconnect}`; callbacks run via task.spawn.

## EconomyService (only module that changes coins/gems)
- `start()`; `cellsProvider: ((Player) -> number)?` (passive payout every Config.Income.PassiveInterval)
- `multiplier(player) -> number`
- `addCoins(player, baseAmount, reason, applyMultiplier) -> granted` (also lifetimeCoinsSinceRebirth)
- `addGems(player, amount, reason)`; `spend(player, "coins"|"gems", amount) -> boolean` (atomic)
- `onCapture(player, neutral, stolen) -> coins`; `onKill(player, victimCells, victimWasKing) -> coins`; `onFullMap(player)` (5000, multiplied)
- `setPassOwned(player, passKey, owned)`, `hasPass(player, passKey)`, `setInGroup(player, bool)`, `isInGroup(player)`
- `activateBoost(player, seconds)`
- In-update helpers: `creditInProfile(player, profile, currency, amount, reason)` (flat, no lifetime count), `extendBoostInProfile(profile, seconds)`
- `resetCoins(player)` (rebirth only)
- Signal `granted(player, currency: "coins"|"gems", amount, reason)`
  reasons: capture, kill, fullMap, passive, rebirth, daily, playtime, quest, code, + product keys

## UpgradeService
- `buy(player, upgradeId)` -> `{id, level, cost}`; errors: unknown_upgrade, max_level, insufficient_funds
- `rebirth(player)` -> `{crowns}`; error not_enough_coins
- `walkSpeed(player)` (studs/s, BaseWalkSpeed x speed), `startPatch(player)` (side cells), `shieldSeconds(player)`
- Signal `rebirthed(player, crowns)`

## ShopService
- `start()`; `buyItem(player, itemId)` -> `{id, currency, amount}`; errors: unknown_item, already_owned, crowns_required, not_for_sale, insufficient_funds
- `equip(player, itemId)` -> itemId; error not_owned
- `grantItem(player, itemId) -> boolean` (true if newly added); `owns(player, itemId)`; `reconcile(player)` (idempotent entitlements)
- Signal `equippedChanged(player, equipped: {skin, trail, effect})`

## MonetizationService
- `start()` (sets ProcessReceipt, pass/group checks on join)
- `onSecondChance: ((Player) -> boolean)?` (false => 20 gem refund)
- `shouldOfferStarter(player) -> boolean`; `markStarterOfferSeen(player)`

## RewardService
- `start()` (loads quests, 60 s playtime loop)
- `claimDaily(player)` -> `{streak, currency, amount, skin?}`; errors already_claimed
- `claimPlaytime(player, index)`; errors bad_args, already_claimed, too_early
- `claimQuest(player, index)`; errors quests_refreshed, not_complete, already_claimed
- `redeemCode(player, code)`; errors invalid_code, already_used
- `progress(player, kind, amount, mode: "add"|"max")` kinds: cells, kills, bigCapture, mapPct, kingSeconds, playMinutes

Shared pure logic: `Shared/EconomyRules` (`shouldOfferStarter`, `applyQuestProgress`).

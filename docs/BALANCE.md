# Economy balance check

_Read-only analysis, 2026-11-16, on the strongest model. Player behaviour is **assumed**, not measured: every per-minute figure scales with the assumptions below. Nothing here has been changed in the game yet; the ranked changes at the end are proposals._

## Verdict
The first session is on the design's targets. Four things are wrong by the numbers: **2x Speed at 79 R$**, the **rebirth curve** after the first Crown, **free gem inflow** (playtime rewards plus the Sky Chest), and the **paid Sky Chest spin at 39 R$**.

## Assumptions
- Speed 22 studs/s over 4-stud cells = 5.5 cells/s; map 25,600 cells; respawn 3 s.
- Cautious: 50-cell loop every 17.5 s, dies every 150 s, no kills. Average: 80-cell loop every 15 s, 25 % stolen, holds about 400 cells, 0.3 kills/min. Strong: 200-cell loop every 15 s, 40 % stolen, holds 4 % of the map, 1 kill/min.
- Flat first-hour rewards (never multiplied): daily 250, code RELEASE 1,000, playtime 100/250/1,000, about 990 coins of quests.

## Coins per minute, first session, no multipliers
| Type | Capture | Kills | Passive | Total/min |
|---|---|---|---|---|
| Cautious | 168 | 0 | 71 | **239** |
| Average | 395 | 12 | 119 | **525** |
| Strong | 1,226 | 45 | 304 | **1,575** |

The cautious figure matches the GDD's 150–250 per minute.

## Upgrades
| Track | Total to max | Minutes at base income (cautious / average / strong) |
|---|---|---|
| Shield (5 levels) | 9,300 | 39 / 18 / 6 |
| Start Size (3) | 31,000 | 129 / 59 / 20 |
| Speed (10) | 53,680 | 224 / 102 / 34 |
| Coin Boost (20) | 374,885 | 1,566 / 713 / 238 |

Coin Boost past about level 12 never pays back before the first rebirth; fine as a later sink.

## Rebirth (hours each, no passes)
| Type | 1st | 2nd | 3rd | 4th | 5th | 6th | 7th |
|---|---|---|---|---|---|---|---|
| Cautious | 4.9 | 7.4 | 11.3 | 18.0 | 30.2 | 50.0 | 89.6 |
| Average | 2.2 | 3.4 | 5.2 | 8.2 | 13.7 | 22.8 | 40.8 |
| Strong | 0.7 | 1.1 | 1.7 | 2.7 | 4.6 | 7.6 | 13.6 |

**Wrong against the GDD**, which says later rebirths take 3–4 h each: the requirement doubles while each Crown adds only 25 %. The Gold Crown skin (5 Crowns) is about 33 h for an average free player; Diamond (10) is effectively unreachable.

First rebirth by multiplier stack (average player): free 2.1 h; weekend or 2x Coins 1.1 h; VIP + 2x Coins 0.9 h; all passes + group + friend + weekend 0.4 h; plus the 15-minute boost 0.2 h. Anything with the weekend on top of 2x Coins puts the first rebirth under 30 minutes.

## Cosmetics and gems
- Common (500 coins): 1–2 minutes. Rare (5,000): 10–21 minutes. All 27 coin cosmetics: about 2.3 h average. **Rares are too cheap to be a goal.**
- Free gems: streak 160 per week plus 150/250/500 at days 14/21/28; playtime 40 per session; quests about 22 per day; 50 per rebirth.
- A daily 30-minute player affords an Epic on day 2, a Legendary on day 6 and **every gem item by day 29**, before counting the Sky Chest. Gem packs have little to sell.

## Robux value
| Item | Price | Verdict |
|---|---|---|
| 2x Speed | 79 | **Badly under-priced and pay-to-win.** Loop area grows with speed squared: about 4 times the area per risky run, so 2–4 times the coins of the 249 R$ coin pass plus half the cut risk, at a third of the price. |
| VIP | 399 | High for +20 % coins; typical is 199–299. |
| 2x Coins | 249 | Fine. |
| Neon Pack | 199 | Slightly high; 149 is safer. |
| Starter Pack | 79 | Good value (see `docs/DECISIONS.md` on repeats). |
| 15-minute boost | 29 | Poor; 15–19 is typical. |
| Second Chance 15, Skip Music 9 | | Fine. |
| Gem packs | 49–999 | Curve is fine; the problem is demand. |

## Sky Chest
- Expected value per spin: about 475 coins and 14 gems.
- 12 chests per hour per server. **Alone in a server that is up to 165 gems per hour**, four times every other free gem source combined; a solo server is a gem farm. In a full server it is about 10 gems per hour each.
- Paid spin at 39 R$ returns about 14 gems, where 39 R$ of the smallest gem pack buys 64. A fair price for this table is 15–19 R$. It is also a paid random item (`docs/DECISIONS.md` item 1).

## First session
No dead zone in the first hour. The start is, if anything, too generous: the daily (250) and the release code (1,000) buy five or six Coin Boost levels in the first 30 seconds. Dead zones come later: after the coin cosmetics are bought (2–5 h) and from the 4th rebirth on.

## Exploits by design
- **Playtime rewards reset on rejoin** (held in memory per session): rejoining every 30 minutes yields about 80 gems and 2,700 coins per hour while idle.
- **The bots' gentle window is also per session**: every rejoin gives 120 s in which bots never cut you.
- Bot kills, the 100 % map bonus, quests and idle passive income are all fine.

## Proposed changes, ranked (none applied yet)
1. **2x Speed**: `Config.Passes.doubleSpeed.SpeedMultiplier` 2 → 1.25 and price 79 → 299 (price is set on Roblox). Owner's call: `docs/DECISIONS.md` item 2.
2. **Rebirth growth**: add `Config.Rebirth.Growth = 1.5` and use it in `Formulas.rebirthRequirement` instead of the hard-coded 2. Average free rebirths become about 2.2 / 2.6 / 3.3 / 4.2 / 5.6 h; Gold Crown about 18 h instead of 33.
3. **Sky Chest free rate**: interval 300 → 600 s; gem prizes 25 → 15 and 75 → 40. Solo gem income falls from 165 to about 46 per hour.
4. **Sky Chest paid spin**: 39 → 19 R$, or remove it.
5. **Playtime rewards**: store claims per UTC day in the profile instead of per session; key the gentle-bot window to total play seconds the same way. (Code change in `RewardService` and `ArenaService`.)
6. **Weekend multiplier**: 2 → 1.5.
7. **Rare price**: `Config.Prices.rare.Amount` 5,000 → 12,000.
8. **Small prices**: VIP 399 → 299; boost 29 → 19 and Neon Pack 199 → 149 (set on Roblox).

## Not determinable from the code
Real loop sizes, death rates and turf erosion (no playtest data); whether live Roblox prices match Config; whether Roblox's idle kick blunts the rejoin farm; the group bonus is inactive while the group id is 0.

# Battle Pass: "Turf Pass" design (Season 1: Neon Rush)

Owner direction (2026-11-17): a horizontal battle pass, free + premium tracks, XP from daily missions,
premium cheaper than buying its skins, animated skins live in premium, lots of animation and pop.
Owner answers: Premium 399 R$, Premium+ 799 R$ (Premium + 10 tiers), **14-day seasons, 30 tiers**.

## Season
- `Config.BattlePass`: Season = 1, Name = "Neon Rush", Start (unix; 0 = hidden in live servers, shown in Studio),
  Days = 14, Tiers = 30, XpPerTier = 1000 (30,000 XP to finish).
- Countdown shown in the header ("12d 4h left"). When a season ends, unclaimed reached rewards are granted
  automatically on the player's next join ("Season rewards delivered!" toast). Nothing earned is ever lost.

## XP (finish in ~11-12 active days of a 14-day season)
| Source | XP | Notes |
|---|---|---|
| Daily missions, 5 per day | 300, 300, 300, 500, 800 = 2,200/day | Existing Daily Quests become missions: 3 easy + 1 medium + 1 hard, XP on top of their coins/gems. Refresh daily (UTC). |
| Catch-up | missions give 2x XP while the player is 3+ tiers behind schedule (schedule = 30 tiers by day 12) | Shown as a "2x CATCH-UP XP" chip. |
| Play XP | 1 XP per 5 cells captured, 25 XP per elimination | Capped at 400 XP per day; a "Daily play XP maxed" chip when hit. |
| Premium+ | +10 tiers (10,000 XP) at purchase | |
| Tier skip | +1 tier, 49 R$ developer product | Offered when 1-3 tiers short of a Legendary or in the last 3 days. |
| After tier 30 | every 1,000 XP = 1 bonus Sky Chest Key | Dedicated players keep earning. |

## Tracks (30 tiers). "Sky Chest Key" = one free Sky Chest spin (the existing loot box, odds shown in its UI).
"2x Coins" = the existing coin boost timer.
| Tier | Free | Premium |
|---|---|---|
| 1 | 2,500 coins | **Neon Pulse** (Legendary, animated) + matching trail + 100 gems |
| 2 | 3,000 coins | 6,000 coins |
| 3 | Sky Chest Key | 2 Sky Chest Keys |
| 4 | 2x Coins 15 min | 2x Coins 30 min |
| 5 | **Zigzag Rookie** (Rare skin) | **Sour Blast** (Rare skin) |
| 6 | 3,500 coins | 8,000 coins |
| 7 | 10 gems | 2 Sky Chest Keys |
| 8 | Sky Chest Key | 20 gems |
| 9 | 4,000 coins | 10,000 coins |
| 10 | 2x Coins 15 min | **Magma Surge** (Legendary, animated) + matching trail |
| 11 | 4,500 coins | 2x Coins 60 min |
| 12 | 15 gems | **Frost Bite** (Rare skin) |
| 13 | Sky Chest Key | 2 Sky Chest Keys |
| 14 | **Pebble Dash** (free trail) | 12,000 coins |
| 15 | 2x Coins 30 min | 3 Sky Chest Keys |
| 16 | 5,500 coins | 20 gems |
| 17 | 20 gems | 14,000 coins |
| 18 | Sky Chest Key | **Bubble Pop** (Rare skin) |
| 19 | 6,000 coins | 2x Coins 60 min |
| 20 | 2x Coins 30 min | **Starfall** (Legendary, animated) + matching trail |
| 21 | 7,000 coins | 16,000 coins |
| 22 | **Turbo Tide** (Rare skin) | 3 Sky Chest Keys |
| 23 | Sky Chest Key | 20 gems |
| 24 | 8,000 coins | 18,000 coins |
| 25 | 25 gems | 3 Sky Chest Keys |
| 26 | 9,000 coins | **Sunset Riot** (Rare skin) |
| 27 | Sky Chest Key | 2x Coins 60 min |
| 28 | 10,000 coins | 20,000 coins |
| 29 | 30 gems | 40 gems |
| 30 | **Neon Streak** (Rare trail) + 2 Sky Chest Keys | **Prism Storm** (Legendary, animated finale) + matching trail + 100 gems |

Totals: Free = 83k coins, 100 gems, 9 keys, 2 boosts x15 + 2 x30 min, 2 Rare skins, 1 Rare trail.
Premium = 4 animated Legendaries, 4 Rare skins, 104k coins, 300 gems (kept low so the pass does not
undercut gem packs), 17 keys, 4 boosts. Shop value of premium: 4 x 400 gems + 4 x 12,000 coins + 300 gems
= "Worth 1,900+ gems" (badge), and the animated skins exist nowhere else.
Policy: XP can be bought (Premium+, tier skip), so for players where paid random items are restricted
(PolicyService) every Sky Chest Key from the pass (any track, bonus keys too) becomes 3,000 coins instead.
2x Coins rewards add to the existing boost timer.

## Animated skins (new, premium-only this season)
Built on the pattern textures (`Config.ShopArt.Patterns`); TurfRenderer animates the Texture of every rect an
animated owner holds (~20 updates/s, shared clock, so the whole territory moves together):
- **Neon Pulse** (#FF2E9A / #00F0FF, stripes): stripes slide and the stripe colour pulses cyan-to-white, 1 s.
- **Magma Surge** (#E8361A / #FFC83D, waves): molten waves flow across the turf and glow brighter in pulses.
- **Starfall** (#1B1F5E / #FFE88A, stars): stars drift diagonally and twinkle.
- **Prism Storm** (#7C5CFF / rainbow, hex): hexes flow and cycle through the rainbow, the trail matches; finale.
Performance: one shared clock, ~15 updates/s, only textures of animated owners are touched; low-detail mode
freezes the animation.
Catalog: rarity "legendary", `source = "pass"`, `anim = "pulse"|"flow"|"drift"|"rainbow"`, season 1.
Shop shows them with "Battle Pass" as the unlock source. Cards animate the same way in the shop and pass.
Season Rares: rarity "rare", `source = "pass"`, static patterns in colours the shop does not sell.

## Purchase
- Developer products `battlePass` (399 R$) and `battlePassPlus` (799 R$), rebuyable each season.
  Receipt: premium = true for the current season (Plus also +10,000 XP). The client never prompts Premium
  or Premium+ when owned (owners only see the quiet "+1 tier 49 R$" button; no automatic sell popups);
  a stale-prompt receipt while premium grants 400 gems. Plus while premium: grants the 10 tiers.
  `battlePassTier` (49 R$): +1,000 XP. Receipts are keyed to the season active when processed.
  Last 48 h of a season: Premium+ is hidden and the UNLOCK button shows the countdown.
- Ids live in `Config.Ids.Products`; 0 = "Coming soon" (owner creates them on the dashboard or approves creation).

## Screen (horizontal, landscape-first; phone-safe)
- **Entry:** HUD rail button "Pass" with a gold ticket icon, shimmering; red dot + count when rewards are claimable;
  bounces when a tier is reached mid-game ("TIER 7!" toast with the badge popping).
- **Header:** season name in a gold ribbon, countdown chip, big tier badge (hexagon, number), XP bar with
  "640 / 1,000 XP" and a glow that sweeps when XP lands, "Missions" button with a red count.
- **Left rail (fixed):** two big tickets, FREE (blue) and PREMIUM (gold, shimmering, crown). Under PREMIUM
  when not owned: "UNLOCK 399 R$" green button pulsing + "Worth 1,900+ gems", and a small "+10 tiers 799 R$".
- **Track (horizontal ScrollingFrame):** one column per tier: premium card on top, tier node on a progress
  rail in the middle (filled gold up to the current tier, glowing current node), free card below.
  Cards: rounded tiles, reward art large, amount label, rarity colour frame for skins (animated preview for
  animated skins), lock badge on premium when not owned, bouncing green "GET" when claimable, check when claimed.
  Opens scrolled so the current tier is in view. "Claim All" button floats bottom-right when 2+ are claimable.
- **Finale card:** pinned at the right edge: big animated preview of Prism Storm with "TIER 30" so the chase
  is always visible.
- **Missions sheet:** slides up over the track: 5 mission rows (icon, text, progress bar, XP + coins, Claim).
  Shows "Next missions in 7h 12m".
- **Left rail under UNLOCK (free players):** "Premium earned so far: 1 Legendary, 2 Rares, 300 gems" counter
  that grows as they level; when a free player reaches tier 10 or 20 a one-time popup shows the Legendary
  they just passed with "Unlock it now".
- **Round feedback:** "+120 Pass XP" floats in the HUD when XP lands; the end-of-round (Eliminated) panel shows
  a Pass XP row with the bar filling and "2 tiers to Starfall!".
- **Phones:** the left rail collapses to two small ticket tabs; the finale card shrinks to a tab.
- **Juice:** claim = card punches (scale 1.2 -> 1), coins/gems fly to the wallet, confetti burst, sound;
  tier up = badge pop + rail fill sweep + toast; premium unlock = full-screen gold flash, premium row unlocks
  tile by tile left to right, each lock pops off; legendary claim = full-screen reveal (rays spin behind the
  animated skin card, "LEGENDARY" ribbon, Equip now button).

## Rules (server-owned)
- Pass state per profile: `{ season, xp, premium, free = bitmask, prem = bitmask, playDay, playXp, bonus, seen10, seen20 }`;
  when `season` differs: grant every reached unclaimed reward of the old season, then reset. Claims validated: tier reached, not claimed, premium owned for premium track.
- XP only from server events (quest claims, captures, eliminations, receipts). Remote: `BattlePass` with
  actions `status`, `claim(track, tier)`, `claimAll`.

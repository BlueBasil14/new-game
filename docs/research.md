# Phase 1 — Research

_Date: 2026-11-12. Live player counts (CCU) are from Roblox's own search API, sampled once on a Thursday ~04:00–05:00 UTC (US evening). Raw output: `docs/_sat1.txt`, `_sat2.txt`, `_sat3.txt`. Re-run with `python3 tools/roblox_saturation.py "<query>" ...`._

## R1. Method and limits

- 145 search queries across ~24 concepts, several phrasings each. For each query the script lists the top results by live CCU with like ratio and vote count.
- Roblox search is fuzzy: when nothing matches it returns unrelated popular games. A query whose top results are all off-topic is itself evidence of a gap.
- Disqualification bar: a relevant incumbent above ~1k CCU, or a clone flood.
- **What this cannot show:** Roblox internal analytics, games that were tried and died, and off-peak/peak swings. One sample, one time of day. "No incumbent" means "nothing visible in search", not "nobody ever tried".
- Market context came from two Haiku web-research workers. Their sources were mostly search snippets and third-party blogs; anything marked UNVERIFIED there is not relied on below.

## R2. Market context (2026)

- The charts are dominated by "Steal a/an X" and "Grow a X" collect-tycoons, brainrot-themed clones, "+1 X" incrementals, fishing, and 99-Nights-style survival. All are clone floods (visible directly in the sweep: Steal An Egg ~530k CCU, dozens of "+1 …" titles).
- Roblox launched Incubator and Jumpstart programs in March 2026 to fund novel genres and mechanics ([Roblox newsroom](https://about.roblox.com/newsroom/2026/03/roblox-announces-incubator-jumpstart-creator-programs)).
- Paid Random Items rules were tightened in May 2026 (odds disclosure, every outcome must give a benefit) — reported via snippet only, so the design avoids paid random items entirely rather than depend on the details.
- Chat requires an age check since January 2026 ([Roblox newsroom](https://about.roblox.com/newsroom/2026/02/moving-beyond-self-reported-age)), so the design must be fully playable and social without text chat.
- Off-Roblox demand signal: the top hypercasual mobile downloads of 2025 were Hole.io (~121M), Snake Clash (~104M) and Paper.io 2 (~102M), per an AppMagic-based roundup ([Udonis](https://www.blog.udonis.co/mobile-marketing/mobile-games/most-downloaded-mobile-games)). These are third-party estimates.

## R3. Candidates and saturation result

| # | Concept (off-Roblox reference) | Closest Roblox games found (live CCU) | Verdict |
|---|---|---|---|
| 1 | Territory-loop arena (Paper.io) | None across 9 phrasings. "Paint and Hide" 6.5k is hide-and-seek; "Paint Wars" 0.5k; "Mini War" 5.3k is army RTS | **Survives — clear gap** |
| 2 | Swallow-and-grow hole (Hole.io) | Eat the World 1.4k (eat terrain, 1.17M votes), Be a Hole 0.2k, BlackHole Rush 0.6k | Survives, borderline |
| 3 | Roll-up ball (Katamari) | roll the world 1.0k, Grow And Build Giants 1.6k | Survives, borderline |
| 4 | Snake arena (Slither / Snake Clash) | worm odyssey 1.2k at 46% likes, Become Hungry Worm 0.6k, Be a Snake 0.2k | Borderline — weak incumbent |
| 5 | Merge-drop puzzle (Suika) | None. Merge a Nuke 1.4k and Merge Shop 1.4k are merge tycoons | Survives |
| 6 | Marble race / marble run | Marble Race Creator 0.08k, Huge Marble Slide 0.4k | Survives |
| 7 | Arcade coin pusher / claw | Claw Machine Hub 0.6k, Tokyo Claw Machine 0.6k | Survives on competition, policy risk |
| 8 | Block puzzle (Block Blast / Tetris) | None relevant | Survives |
| 9 | Delivery sim | Ship The Cargo 0.9k, Deliver Packages 0.4k | Survives, weak demand |
| 10 | Launch-and-upgrade (Learn to Fly) | "+1 …" incremental flood (dozens) | DQ — clone flood |
| 11 | Horde survivor (Vampire Survivors / Megabonk) | Survive Your Ideas 41k, Bug Evolution 12k, Zombie Rush 3.6k | DQ |
| 12 | Power washing | Clean the Moon 4.4k, Wash the Car 2.6k, Clean all the Leaves 2.2k, Clean a Painting 1.8k | DQ — flood |
| 13 | Checkpoint inspection (Papers, Please) | Airport Security 2.7k, Say Cheese 3.2k | DQ |
| 14 | Co-op cooking (Overcooked) | Make a Pancake 3.6k, Bake or Die 3.2k, Run a Restaurant 3.0k | DQ |
| 15 | Storage auction / card shop | Storage Hunters 10.6k, My Small Business 6.0k, My Trading Card Shop 2.3k | DQ |
| 16 | Fishing / dive-and-sell | Fish It 59k, Fisch 44k, Net a Fish 19k | DQ — flood |
| 17 | Lane defense (Plants vs Zombies) | Garden Tower Defense 3.5k, Toilet TD 10k | DQ |
| 18 | Bridge building (Poly Bridge) | Build a Bridge 5.9k | DQ |
| 19 | Draw and guess (skribbl) | Draw My Prompt 5.8k, Draw the Other Half 3.8k + several more | DQ — flood |
| 20 | Bomber arena (Bomberman) | Timebomb Duels 4.4k | DQ |
| 21 | Paint-to-hide prop hunt (Meccha Chameleon) | Paint and Hide 6.5k | DQ |
| 22 | Ant colony | Bug Evolution 12k, Ant Wars 1.4k, Build An Ant Empire 1.3k | DQ |
| 23 | Storm chasing | Twisted 1.0k (247k votes, established) | DQ |
| 24 | Deck-builder roguelike (Balatro / Spire) | Anime Card Clash 4.3k, Breach the Bastion 2.3k | DQ |

## R4. Scores for survivors (1–5 each)

| Concept | Gap | 30-sec fun | Session | Depth | Monetization | Social | Buildable | Total /35 |
|---|---|---|---|---|---|---|---|---|
| **Territory-loop arena** | 5 | 5 | 3 | 3 | 4 | 5 | 5 | **30** |
| Swallow-and-grow hole | 3 | 5 | 3 | 3 | 4 | 4 | 3 | 25 |
| Roll-up ball | 4 | 5 | 3 | 3 | 4 | 3 | 3 | 25 |
| Snake arena | 3 | 5 | 3 | 2 | 4 | 4 | 4 | 25 |
| Merge-drop puzzle | 5 | 4 | 3 | 2 | 2 | 1 | 4 | 21 |
| Marble race | 5 | 3 | 2 | 2 | 3 | 3 | 3 | 21 |
| Arcade coin pusher | 5 | 4 | 3 | 3 | 1 | 2 | 3 | 21 |
| Block puzzle | 5 | 4 | 3 | 2 | 2 | 1 | 4 | 21 |
| Delivery sim | 4 | 2 | 3 | 3 | 3 | 2 | 3 | 20 |

Scoring notes: "Buildable" weighs how much of the game is code versus bespoke 3D models, because this pipeline is strongest at code. Hole and roll-up games need hundreds of swallowable props; territory and snake games need almost none.

## R5. Shortlist

1. **Territory-loop arena.** Run out of your coloured land leaving a trail, loop back to claim everything inside, cut another player's trail to eliminate them. Widest gap in the sweep, a proven 100M-download mechanic, natively multiplayer, and almost all code. Weakness: raw .io loops have shallow retention, so the meta (upgrades, rebirth, cosmetics, quests) has to carry days 2–30.
2. **Swallow-and-grow hole.** Strongest off-Roblox number, very readable. But Eat the World already occupies "eat to grow" at 1.4k with 1.17M votes, two direct attempts sit under 1k, and it needs a large prop library.
3. **Snake arena.** Simple and social, with a poorly rated incumbent (46% likes) that could be beaten on quality. But that incumbent is already over the 1k bar and the progression ceiling is the lowest of the three.

## R6. Decision (Fable)

**Chosen: the territory-loop arena, working title "Turf Loop".** It is the only candidate where nine differently worded live searches returned no relevant Roblox game at any player count, while the same mechanic drew roughly 100M mobile downloads in 2025, so the demand is proven and the shelf is empty. The loop is understood in seconds without text, creates the shareable moments Roblox rewards (a huge capture, cutting the server leader's trail), and works with zero chat. Honest cosmetics — turf colours, patterns, trails, capture effects — are the natural thing to sell, so monetization does not need pay-to-win or paid random items. It is also about 90% code, which fits this pipeline and keeps the Blender dependency to a handful of border props. The main risk is that an empty shelf can mean "tried and failed" rather than "untried"; the mitigations are bots so a server never feels empty, a persistent progression layer that .io clones lack, and a session-based economy that pays out even on a bad run.

**Exit criterion met:** one concept chosen, with live evidence it is not already established on Roblox.

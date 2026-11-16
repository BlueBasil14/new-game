# Launch checklist

_Written 2026-11-16. "Owner" steps need your Roblox account. "Lead" steps are for whichever AI session is leading. Nothing here has been done unless ticked. Roblox's menus change; if a menu name differs, look for the nearest equivalent rather than guessing._

## A. Before anyone outside plays
- [ ] **Lead:** all Critical and High items in `docs/SECURITY_REVIEW.md` fixed and their tests passing.
- [ ] **Owner:** answer `docs/DECISIONS.md` items 1–4 (paid spin, 2x Speed, bot tag, Starter Pack).
- [ ] **Lead:** apply those answers; rerun all checks; load into the cloud place (`docs/STUDIO.md`).
- [ ] **Owner:** play 10 minutes with sound on. Say what feels wrong: capture effects, camera shake, sounds, speed, brightness.
- [ ] **Owner + one friend:** two real accounts in the cloud place via Studio "Server & Clients" or a private test. Check: both see the same turf; a cut works; the friend's bot disappears when the friend joins; the "+10% FRIEND" chip shows; the Invite button opens Roblox's invite prompt.
- [ ] **Lead:** phone layout pass on the 750x381 emulator view (HUD buttons near the thumbstick, shop cards, daily panel).

## B. Check the passes and products (Owner)
**Update 2026-11-16:** another session already created all five passes and the products; their ids are in `Config.Ids`. What is left is to open the Creator Dashboard for "TurfLoop Main" (universe 10776297454) and confirm each one exists, is on sale, and has the name, icon and price you want. Prices in `Config.Passes` are only what the shop displays; the dashboard price is what players pay, and the two must match.
- [ ] Game passes: VIP (399), 2x Coins (249), Neon Pack (199), Skip Music (9), 2x Speed (**399**, owner decision 2 on 2026-11-16; the dashboard price must be raised from 79).
- [ ] Developer products: Starter Pack (79), Second Chance (15), 15-minute 2x boost (29), gem packs, Sky Chest Spin (already created: 3732125306, 39; the owner kept the paid spin).
- [ ] Badges listed in `src/shared/Catalog.luau` (badge creation may cost Robux beyond a free daily allowance: **check the price shown before confirming**).
- [ ] A group for the group bonus, if wanted.
- [ ] Paste every id into `Config.Ids` in `src/shared/Config.luau` (or give them to the lead). Zero means "not created" and shows "Coming soon".
- [ ] **Lead:** after ids are in, one real purchase of the cheapest pass (Skip Music, 9 Robux) on a live server **with the owner's go-ahead**, to confirm the pass is granted within about 30 s and survives a rejoin. This is the only way to test finding 1's fix for real.

## C. Settings (Owner)
- [ ] Game Settings → Security → "Studio Access to API Services": on, if you want saving to work in Studio tests.
- [ ] Maturity & Compliance questionnaire: answer honestly. **Declare paid random items**: the owner kept the Sky Chest paid spin. This decides who can see the game.
- [ ] Experience name, description (copy briefs in `docs/CHATGPT_TASKS.md`), genre, supported devices (phone, tablet, computer), max players 16.
- [ ] Private servers: allow them (free or cheap). Playing with friends counts for discovery.
- [ ] When publishing any later update that changes saved data: choose "Migrate to latest update" so no old server keeps running.

## D. Store page (Owner, art from the ChatGPT briefs)
- [ ] Icon and thumbnail 1 show a runner closing a loop and the area filling, on the **grey** floor. The first minute of play must match the thumbnail.
- [ ] Gameplay video, 20–30 s of real play: leave turf, close a loop, the fill sweeps, cut a bot, coins. No voice-over, no lyrics, no cinematic cuts.
- [ ] 3–5 thumbnails in total.

## E. Publish and the first 28 days
- [ ] **Owner:** publish (the lead never publishes on its own).
- [ ] **Lead:** watch the first sessions' Output/analytics for errors; fix and republish with migration.
- [ ] Day 1: check day-1 retention and how many players leave in under 60 s and between 1 and 3 minutes (`docs/ALGORITHM_PLAN.md`).
- [ ] From day 3: small daily ad budget only if day-1 retention looks healthy (your money, your call).
- [ ] Day 5: announce the week-two update in game (not built: post it in the group and the game description for now).
- [ ] **Lead, days 8–10:** the week-two update is already in the code and switched off. Set `Config.WeekTwo.Start` (unix time, 00:00 UTC of the ship day) and `Config.CrownRush.Start`/`End` (the weekend), run the checks and republish with migration. That shows Tide Pool, Sunset Grid and Comet Tail in the Featured row, opens the CROWNRUSH code (50 gems), and starts Crown Rush (King earns 2x; 5 minutes as King in total wins the Crown Rush Trail).
- [ ] **Owner:** post the CROWNRUSH code in the group on update day.
- [ ] Once there is a video and real numbers: nominate the game through Roblox's standout-games form.

## Things that are not ready and are not blockers
Three sounds are empty on purpose (music comes from the pack; no quiet trail loop found). Props are grey-box parts. Skin patterns are plain blocks (GAP-17). The floating "+X%" text and camera shake have never been seen by a person.

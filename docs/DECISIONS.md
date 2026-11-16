# Decisions waiting on the owner

_Written 2026-11-16 by the lead. Each item has what is built now, the risk, and a recommendation. Answer in chat with the number and your choice; the lead logs it in `docs/PROGRESS.md` and changes the code._

## 1. Sky Chest paid spin (39 Robux): keep, or make it free-only?
- **Built now** (by another session): a chest drops every 5 minutes; the first player to reach it gets a free wheel spin; extra spins cost 39 Robux (product id 3732125306 already exists). Odds are shown on the wheel.
- **Risk:** this is a paid random item. It reverses the project's earlier rule "no paid random items". Roblox requires it to be declared in the experience's Maturity & Compliance questionnaire and restricts it by country and age; the code already blocks paid spins when Roblox's policy check says no. The questionnaire has **not** been submitted. A game aimed at under-16s with paid random items may also be kept out of Roblox Kids.
- **Recommendation:** keep the free chest (it is a good reason to stay in a session), and turn the paid spin off for launch. Decide again once the game has real numbers.

## 2. 2x Speed pass (79 Robux): how strong?
- **Built now:** owners move at twice the speed, permanently.
- **Risk:** in this game speed decides who gets cut, so this is pay-to-win, and it reverses the earlier "speed is never sold" rule. Non-payers who keep losing to faster players tend to leave. At 79 Robux it is also the cheapest strong advantage in the shop.
- **Recommendation:** lower it to +25 % and keep the price, or keep 2x and price it with VIP (399). See `docs/BALANCE.md` for numbers once the analysis lands.

## 3. Bots that look like the player's friends: tag them or not?
- **Built now:** bots wear your Roblox friends' real avatars and display names, with nothing marking them as bots.
- **Risk:** players may believe their friends are online and feel tricked when they find out; a friend may not like their avatar and name being used. It is not a known rule violation, but it is the kind of thing players complain about.
- **Recommendation:** keep the avatars (it looks great) and add a small "BOT" tag on the nameplate and leaderboard row.

## 4. Starter Pack: allow repeat purchases?
- **Built now:** every repeat purchase gives 300 gems for 79 Robux, which is a far better rate than any gem pack.
- **Recommendation:** make it once per account (the Buy button disappears after purchase). One-line server change plus a UI state.

## 5. Week-two update
- **Plan:** `docs/ALGORITHM_PLAN.md` lists a "Crown Rush" weekend event, two skins, a trail and a code for days 8–10 after launch. Streak bonuses for days 14/21/28 are already built.
- **Decision needed:** yes or no on that content, so it can be built before launch day.

## 6. Final game title
- "Turf Loop" is a working title. The cloud place is now named "TurfLoop Main". Confirm or pick another before the icon and thumbnails are made.

## 7. Floor colour and art briefs
- The floor is now neutral grey at your request. The ChatGPT art briefs for the icon and thumbnails still describe a pale, near-white board. Regenerate them for the grey floor, or accept that marketing art is lighter than the game?
- **Recommendation:** regenerate; the first minute must match the thumbnail.

## Already decided (for reference)
- No pay-for-power **except** the 2x Speed pass you asked for (item 2).
- Crossing your own trail is harmless.
- Only licensed or original audio.
- Bots never appear on global leaderboards.
- Neutral grey floor, toned-down lighting.

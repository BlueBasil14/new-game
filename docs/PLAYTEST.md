# First playtest (T-INT-02) — what the owner does

Nothing in this repo has been run in Roblox Studio yet. The code compiles with the real Luau compiler, 10 unit specs pass on the game rules, and two read-through reviews fixed 13 defects, but the first Play press will still surface problems. This page is the shortest path to finding them.

## 1. Open the game
- Download `build/TurfLoop.rbxlx` from the repo and open it in Roblox Studio (File → Open from File).
- Or, with Rojo 7 installed: `rojo serve` in the repo root, connect the Studio plugin to a new Baseplate-free place.
- Game Settings → Security → enable "Studio Access to API Services" if you want saving to work in Studio. Without it the game runs on an in-memory store and prints one warning.

## 2. Press Play (solo) and watch the Output window
Expected: you stand on a 5×5 coloured patch on a pale floor with dark walls, 9 bots are looping around, a HUD shows coins and a leaderboard.

Copy **every red or orange line** from the Output window and paste it into a Claude session with: "Resume the Roblox project from /docs/PROGRESS.md. Here is the first playtest output: …".

## 3. Check these first (from the two reviews)
1. You can walk, and walking out and back claims the area you circled.
2. Getting cut by a bot → death panel → Respawn works and **you can move again afterwards**.
3. No rubber-banding or "snap back" while walking normally for 5 minutes.
4. Camera: angled top-down, no flicker on respawn; on a phone emulator the thumbstick moves relative to the camera.
5. Shop: every tab shows rows of three cards and scrolls.
6. Turf appears within about a second of joining; trails meet cleanly at corners.
7. Upgrades panel: buying Coin Boost at 100 coins works and the wallet counter rolls down.

Full lists: `docs/REVIEW_server.md` and `docs/REVIEW_client.md`, section "Could not verify without Studio".

## 4. Two-player test (T-INT-03)
Test tab → Clients and Servers → 2 players → Start. Both screens must show the same turf; one player crossing the other's trail must eliminate the trail's owner.

## Known gaps on purpose
- Silent: `src/shared/SoundIds.luau` is all zeros until sounds are picked (CHATGPT_TASKS CG-044 gives the search phrases).
- Props are grey-box Parts until the Blender models exist.
- Purchases say "Coming soon" until passes/products are created and their ids are pasted into `Config.Ids` in `src/shared/Config.luau`.

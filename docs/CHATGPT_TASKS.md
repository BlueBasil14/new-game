# ChatGPT Task Queue

A queue of self-contained tasks for the project owner to run in ChatGPT (which has no access to our files, Roblox Studio or Blender). Every prompt carries all the context it needs. Game: working title "Turf Loop" (see docs/GDD.md for the design source).

## How to use

1. Pick an entry whose Status is TODO. Copy everything inside its code block (the Prompt) and paste it into ChatGPT.
2. Save ChatGPT's output to the path in **Destination** (create the folders under `/assets/chatgpt/` as needed). Resize images to the exact size in **Output spec** before uploading anywhere.
3. When the file is saved, change the entry's **Status** from TODO to DONE (use IN REVIEW or REDO if you need to).
4. Do the Studio / Creator Hub step named in Destination, or tell the build agent the file is ready.

Practical notes:
- Generated images often miss exact pixel sizes. Always resize/crop to the stated size before upload (any image editor works). Transparent PNGs: if ChatGPT cannot give real transparency, remove the plain background in an editor.
- Do all icons of one set (gamepass icons, product icons, badge icons, UI art) in ONE ChatGPT conversation so the style stays consistent. Entries marked "SAME CONVERSATION NOTE" belong to a set.
- Roblox crops icons to a circle, so icon prompts ask for the subject centred with about 15% padding.
- Copy and data outputs (CSV, text) are drafts: read them, keep or reword, and check that nothing contradicts docs/GDD.md.

## ART DIRECTION BLOCK

This block is pasted in full inside every image prompt below (ChatGPT cannot see this file), restating GDD G8. If the art direction changes, update the block here and in every image prompt.

```
ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.
```

## Index

| ID | Title | Linked task | Priority | Status |
|---|---|---|---|---|
| CG-001 | Game icon | T-ART-01 | MVP | TODO |
| CG-002 | Thumbnail 1: core loop capture | T-ART-02 | MVP | TODO |
| CG-003 | Thumbnail 2: cutting a trail | T-ART-02 | MVP | TODO |
| CG-004 | Thumbnail 3: crowded arena with the King | T-ART-02 | MVP | TODO |
| CG-005 | Thumbnail 4: progression and skins | T-ART-02 | MVP | TODO |
| CG-006 | Gamepass icon: VIP | T-ART-03 | MVP | TODO |
| CG-007 | Gamepass icon: 2x Coins | T-ART-03 | MVP | TODO |
| CG-008 | Gamepass icon: Neon Pack | T-ART-03 | MVP | TODO |
| CG-009 | Gamepass icon: Radio | T-ART-03 | post-launch | TODO |
| CG-010 | Product icon: Starter Pack | T-ART-04 | MVP | TODO |
| CG-011 | Product icon: Second Chance | T-ART-04 | MVP | TODO |
| CG-012 | Product icon: 2x Coins, 15 min | T-ART-04 | MVP | TODO |
| CG-013 | Product icons: Gems S / M / L / XL (4 variants) | T-ART-04 | MVP | TODO |
| CG-014 | Badge icon: First Loop | T-ART-05 | MVP | TODO |
| CG-015 | Badge icon: First Cut | T-ART-05 | MVP | TODO |
| CG-016 | Badge icon: King | T-ART-05 | MVP | TODO |
| CG-017 | Badge icon: 10% Map | T-ART-05 | MVP | TODO |
| CG-018 | Badge icon: 50% Map | T-ART-05 | MVP | TODO |
| CG-019 | Badge icon: 100% Map | T-ART-05 | MVP | TODO |
| CG-020 | Badge icon: First Rebirth | T-ART-05 | MVP | TODO |
| CG-021 | Badge icon: 7-Day Streak | T-ART-05 | MVP | TODO |
| CG-022 | UI: Coin icon | T-ART-06 | MVP | TODO |
| CG-023 | UI: Gem icon | T-ART-06 | MVP | TODO |
| CG-024 | UI: Crown icon | T-ART-06 | MVP | TODO |
| CG-025 | UI: Scissors icon | T-ART-06 | MVP | TODO |
| CG-026 | UI: Hand-pointer icon | T-ART-06 | MVP | TODO |
| CG-027 | UI: Button background (9-slice) | T-ART-06 | MVP | TODO |
| CG-028 | UI: Panel frame (9-slice) | T-ART-06 | MVP | TODO |
| CG-029 | Turf pattern: Stripes | T-ART-07 | MVP | TODO |
| CG-030 | Turf pattern: Dots | T-ART-07 | MVP | TODO |
| CG-031 | Turf pattern: Checker | T-ART-07 | MVP | TODO |
| CG-032 | Turf pattern: Waves | T-ART-07 | MVP | TODO |
| CG-033 | Turf pattern: Stars | T-ART-07 | MVP | TODO |
| CG-034 | Turf pattern: Hex | T-ART-07 | MVP | TODO |
| CG-035 | Loading screen | T-ART-08 | MVP | TODO |
| CG-036 | Lobby banner | T-ART-08 | MVP | TODO |
| CG-037 | Game description for the Roblox page | T-COPY-01 | MVP | TODO |
| CG-038 | Names and one-line descriptions for every gamepass and developer product | T-COPY-01 | MVP | TODO |
| CG-039 | Game title brainstorm (30 options) | T-COPY-02 | MVP | TODO |
| CG-040 | Cosmetic names CSV (skins, trails, capture effects) | T-COPY-03 | MVP | TODO |
| CG-041 | UI string sheet (all screens) | T-COPY-04 | MVP | TODO |
| CG-042 | Launch update log and 3 launch social posts | T-COPY-05 | MVP | TODO |
| CG-043 | 40 bot usernames | T-COPY-06 | MVP | TODO |
| CG-044 | Sound-design briefs for all SFX | T-AUDIO-01 | MVP | TODO |
| CG-045 | Economy sanity check (coins per minute, time to first rebirth) | T-BAL-01 | MVP | TODO |

## Game icon and thumbnails

### CG-001 - Game icon

- **ID:** CG-001
- **Linked task:** T-ART-01
- **Priority:** MVP
- **Prompt:**

```
Create a game icon for a territory-capture arena game. Centre: one rounded yellow (#FFC83D) plastic player piece standing on a square patch of yellow felt, with a bright dotted trail strip looping out and back to the patch, and the area inside the loop being filled with yellow in a quick wave. Small coin and sparkle accents. Pale ground (#EEF1F5) with faint grid lines. Bold, simple, high contrast, instantly readable at small size.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background (no transparency), background fills the full square. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque background, flat toy-board style, subject centred with ~15% padding, no text.
- **Destination:** /assets/chatgpt/icons/game-icon.png. Studio/Creator Hub: Game Settings > Icon (upload, then set as the experience icon).
- **Status:** TODO

### CG-002 - Thumbnail 1: core loop capture

- **ID:** CG-002
- **Linked task:** T-ART-02
- **Priority:** MVP
- **Prompt:**

```
Create a wide game thumbnail showing the core loop of capturing territory. Angled top-down view of a pale board. A rounded blue (#4F8BFF) plastic player piece has just completed a loop: a raised bright blue trail strip curves around and back to its blue felt turf, and the circled area is being filled blue in a bright wave from the edges inward. Floating gold coin shapes, confetti burst, soft glow. The blue piece is large and clear on the left third; leave calm space on the right.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 1920x1080 pixels, 16:9 landscape (if you cannot output exactly this, use the closest 16:9 size). Opaque background filling the whole frame. Keep the main subject away from the extreme edges. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 1920x1080 px, PNG, opaque, 16:9, toy-board style, no text.
- **Destination:** /assets/chatgpt/thumbnails/thumb-1-capture.png. Creator Hub: Game Settings > Thumbnails (upload; drag into order, thumbnail 1 first).
- **Status:** TODO

### CG-003 - Thumbnail 2: cutting a trail

- **ID:** CG-003
- **Linked task:** T-ART-02
- **Priority:** MVP
- **Prompt:**

```
Create a wide game thumbnail showing a trail being cut. Angled top-down view of a pale board. A rounded pink (#FF4F8B) plastic piece dashes across a glowing orange (#FF8A3D) trail strip. A large chunky pair of scissors snips the orange trail in two with a bright flash. The orange piece pops into cartoon-style chunky cubes (no gore, friendly) and the orange turf shatters into small cubes that fly towards the pink piece. Dynamic diagonal composition, motion streaks.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 1920x1080 pixels, 16:9 landscape (if you cannot output exactly this, use the closest 16:9 size). Opaque background filling the whole frame. Keep the main subject away from the extreme edges. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 1920x1080 px, PNG, opaque, 16:9, toy-board style, no text.
- **Destination:** /assets/chatgpt/thumbnails/thumb-2-cut.png. Creator Hub: Game Settings > Thumbnails (upload; drag into order, thumbnail 1 first).
- **Status:** TODO

### CG-004 - Thumbnail 3: crowded arena with the King

- **ID:** CG-004
- **Linked task:** T-ART-02
- **Priority:** MVP
- **Prompt:**

```
Create a wide game thumbnail showing a crowded multiplayer arena. Angled top-down view of a large pale board with many coloured territories (at least 10 different player colours) and about 12 rounded plastic pieces running with trails. The biggest territory belongs to one gold-crowned piece, the King, with a tall translucent golden beam rising above it and a simple low-poly gold crown. Dark arena wall (#2B2F3A) visible at the edges. Energetic, busy but readable.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 1920x1080 pixels, 16:9 landscape (if you cannot output exactly this, use the closest 16:9 size). Opaque background filling the whole frame. Keep the main subject away from the extreme edges. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 1920x1080 px, PNG, opaque, 16:9, toy-board style, no text.
- **Destination:** /assets/chatgpt/thumbnails/thumb-3-king.png. Creator Hub: Game Settings > Thumbnails (upload; drag into order, thumbnail 1 first).
- **Status:** TODO

### CG-005 - Thumbnail 4: progression and skins

- **ID:** CG-005
- **Linked task:** T-ART-02
- **Priority:** MVP
- **Prompt:**

```
Create a wide game thumbnail about progression and customisation. A neat showcase on a pale table: six square turf tiles side by side, each a different pattern (stripes, dots, checker, waves, stars, hexagons) in different bright player colours, with glowing trail lines and sparkle effects beside them, a floating cyan (#3DDCFF) gem, a stack of gold coins and a gold crown above the centre. Rounded plastic player pieces stand on the tiles.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 1920x1080 pixels, 16:9 landscape (if you cannot output exactly this, use the closest 16:9 size). Opaque background filling the whole frame. Keep the main subject away from the extreme edges. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 1920x1080 px, PNG, opaque, 16:9, toy-board style, no text.
- **Destination:** /assets/chatgpt/thumbnails/thumb-4-skins.png. Creator Hub: Game Settings > Thumbnails (upload; drag into order, thumbnail 1 first).
- **Status:** TODO

## Gamepass icons

### CG-006 - Gamepass icon: VIP

- **ID:** CG-006
- **Linked task:** T-ART-03
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: generate every gamepass icon in the same ChatGPT conversation so the set matches in style; if this is the first one, state the style you used so later icons can copy it.

Create a gamepass icon for 'VIP'. A shiny gold (#FFC83D) badge-shaped name tag with a ribbon and a small star, a tiny gold crown-like sparkle above it, and a soft glow. Premium and friendly. Dark rounded backdrop #1E2230 as a circle behind the subject.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, consistent set with the other gamepass icons (same lighting, outline weight, backdrop), no text.
- **Destination:** /assets/chatgpt/gamepasses/gamepass-vip.png. Creator Hub: Monetization > Passes > 'VIP' > Icon. Gamepass: VIP. Surfaced: Shop top slot; lobby VIP arch.
- **Status:** TODO

### CG-007 - Gamepass icon: 2x Coins

- **ID:** CG-007
- **Linked task:** T-ART-03
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: generate every gamepass icon in the same ChatGPT conversation so the set matches in style; if this is the first one, state the style you used so later icons can copy it.

Create a gamepass icon for '2x Coins'. Two identical stacks of chunky gold coins side by side, the second slightly larger, with sparkles and two small upward arrows to suggest doubling. No numerals. Dark rounded backdrop #1E2230 as a circle behind the subject.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, consistent set with the other gamepass icons (same lighting, outline weight, backdrop), no text.
- **Destination:** /assets/chatgpt/gamepasses/gamepass-2x-coins.png. Creator Hub: Monetization > Passes > '2x Coins' > Icon. Gamepass: 2x Coins. Surfaced: Upgrade panel footer.
- **Status:** TODO

### CG-008 - Gamepass icon: Neon Pack

- **ID:** CG-008
- **Linked task:** T-ART-03
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: generate every gamepass icon in the same ChatGPT conversation so the set matches in style; if this is the first one, state the style you used so later icons can copy it.

Create a gamepass icon for 'Neon Pack'. Five small square turf tiles fanned out like cards, each glowing with a different bright neon edge (cyan #3DDCFF, pink #FF4F8B, green #4ADE80, yellow #FFC83D, purple #7C5CFF), with a glowing neon trail line swooping under them. Dark rounded backdrop #1E2230 as a circle behind the subject so the glow pops.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, consistent set with the other gamepass icons (same lighting, outline weight, backdrop), no text.
- **Destination:** /assets/chatgpt/gamepasses/gamepass-neon-pack.png. Creator Hub: Monetization > Passes > 'Neon Pack' > Icon. Gamepass: Neon Pack. Surfaced: Skin catalogue banner.
- **Status:** TODO

### CG-009 - Gamepass icon: Radio

- **ID:** CG-009
- **Linked task:** T-ART-03
- **Priority:** post-launch
- **Prompt:**

```
SAME CONVERSATION NOTE: generate every gamepass icon in the same ChatGPT conversation so the set matches in style; if this is the first one, state the style you used so later icons can copy it.

Create a gamepass icon for 'Radio'. A chunky retro boombox with two round speakers and a handle, in pink (#FF4F8B) and white, with floating music notes and small sound-wave arcs. Dark rounded backdrop #1E2230 as a circle behind the subject.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, consistent set with the other gamepass icons (same lighting, outline weight, backdrop), no text.
- **Destination:** /assets/chatgpt/gamepasses/gamepass-radio.png. Creator Hub: Monetization > Passes > 'Radio' > Icon. Gamepass: Radio. Surfaced: Post-launch; lobby area.
- **Status:** TODO

## Developer product icons

### CG-010 - Product icon: Starter Pack

- **ID:** CG-010
- **Linked task:** T-ART-04
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: generate all developer product icons in one ChatGPT conversation so the set matches.

Create a developer-product icon for 'Starter Pack'. A cheerful gift box with a pink (#FF4F8B) ribbon bursting open, with a cyan (#3DDCFF) gem, a small gold coin bag and a bright spark star floating out of it. Dark rounded backdrop #1E2230 as a circle behind the subject.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text.
- **Destination:** /assets/chatgpt/products/product-starter-pack.png. Creator Hub: Monetization > Developer Products > 'Starter Pack' > Icon. Product: Starter Pack.
- **Status:** TODO

### CG-011 - Product icon: Second Chance

- **ID:** CG-011
- **Linked task:** T-ART-04
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: generate all developer product icons in one ChatGPT conversation so the set matches.

Create a developer-product icon for 'Second Chance'. A square coloured turf patch protected by a glowing green (#4ADE80) heart-shaped shield, with a circular return arrow wrapping around it. Reassuring and friendly. Dark rounded backdrop #1E2230 as a circle behind the subject.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text.
- **Destination:** /assets/chatgpt/products/product-second-chance.png. Creator Hub: Monetization > Developer Products > 'Second Chance' > Icon. Product: Second Chance.
- **Status:** TODO

### CG-012 - Product icon: 2x Coins, 15 min

- **ID:** CG-012
- **Linked task:** T-ART-04
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: generate all developer product icons in one ChatGPT conversation so the set matches.

Create a developer-product icon for '2x Coins boost, 15 minutes'. A gold coin with a bright lightning bolt, next to a simple round clock face with no numbers or hands text, and small speed sparkles. Dark rounded backdrop #1E2230 as a circle behind the subject.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text.
- **Destination:** /assets/chatgpt/products/product-2x-coins-15min.png. Creator Hub: Monetization > Developer Products > '2x Coins, 15 min' > Icon. Product: 2x Coins, 15 min.
- **Status:** TODO

### CG-013 - Product icons: Gems S / M / L / XL (4 variants)

- **ID:** CG-013
- **Linked task:** T-ART-04
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do this in the same ChatGPT conversation as the other product icons.

Create FOUR separate developer-product icons for gem packs, as four separate square images, all with identical style, camera angle and backdrop, differing only in quantity. Variant S: one single faceted cyan (#3DDCFF) gem. Variant M: a small cluster of 3 gems. Variant L: a pile of about 8 gems on a small gold-trimmed tray. Variant XL: a big overflowing treasure chest full of gems with a large gem on top and sparkles. Each gem is a chunky low-poly faceted shape with white highlights. Dark rounded backdrop #1E2230 as a circle behind the subject. Name the four images S, M, L, XL in order.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels each, square, four images. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 4 images, each 512x512 px, PNG, opaque, no text; increasing in size S < M < L < XL.
- **Destination:** /assets/chatgpt/products/gems-s.png, gems-m.png, gems-l.png, gems-xl.png. Creator Hub: Monetization > Developer Products > Gems S (49 R$ / 80 Gems), Gems M (199 R$ / 400 Gems), Gems L (449 R$ / 1,000 Gems), Gems XL (999 R$ / 2,600 Gems) > Icon.
- **Status:** TODO

## Badge icons

### CG-014 - Badge icon: First Loop

- **ID:** CG-014
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named 'First Loop': A neat closed loop of bright green (#4ADE80) trail strip with the enclosed square filled in solid green and a small white sparkle. Simple and satisfying. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-first-loop.png. Creator Hub: Engagement > Badges > 'First Loop' (create the badge with this image). Badge: First Loop.
- **Status:** TODO

### CG-015 - Badge icon: First Cut

- **ID:** CG-015
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named 'First Cut': A chunky pair of scissors snipping a red-orange (#FF4D4D) trail line in two, with a small bright snip flash. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-first-cut.png. Creator Hub: Engagement > Badges > 'First Cut' (create the badge with this image). Badge: First Cut.
- **Status:** TODO

### CG-016 - Badge icon: King

- **ID:** CG-016
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named 'King': A simple chunky low-poly gold (#FFC83D) crown with three points and a pink (#FF4F8B) gem in the centre, with a faint golden beam of light behind it. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-king.png. Creator Hub: Engagement > Badges > 'King' (create the badge with this image). Badge: King.
- **Status:** TODO

### CG-017 - Badge icon: 10% Map

- **ID:** CG-017
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named '10% Map': A top-down square board grid (about 10x10 cells) with roughly one tenth of the cells filled in solid cyan (#3DDCFF) in one corner. No numerals. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-map-10.png. Creator Hub: Engagement > Badges > '10% Map' (create the badge with this image). Badge: 10% Map.
- **Status:** TODO

### CG-018 - Badge icon: 50% Map

- **ID:** CG-018
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named '50% Map': A top-down square board grid (about 10x10 cells) with exactly half of the cells filled in solid purple (#7C5CFF) in one connected block. No numerals. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-map-50.png. Creator Hub: Engagement > Badges > '50% Map' (create the badge with this image). Badge: 50% Map.
- **Status:** TODO

### CG-019 - Badge icon: 100% Map

- **ID:** CG-019
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named '100% Map': A top-down square board grid (about 10x10 cells) completely filled in solid gold (#FFC83D) with a shiny sheen, a burst of confetti and a sparkle. No numerals. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-map-100.png. Creator Hub: Engagement > Badges > '100% Map' (create the badge with this image). Badge: 100% Map.
- **Status:** TODO

### CG-020 - Badge icon: First Rebirth

- **ID:** CG-020
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named 'First Rebirth': Two curved arrows forming a circle around a small gold crown that is rising and glowing cyan (#3DDCFF), suggesting a fresh start. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-first-rebirth.png. Creator Hub: Engagement > Badges > 'First Rebirth' (create the badge with this image). Badge: First Rebirth.
- **Status:** TODO

### CG-021 - Badge icon: 7-Day Streak

- **ID:** CG-021
- **Linked task:** T-ART-05
- **Priority:** MVP
- **Prompt:**

```
SAME CONVERSATION NOTE: do all 8 badge icons in one ChatGPT conversation so the set matches.

Create a badge icon named '7-Day Streak': A friendly orange (#FF8A3D) flame with a row of seven small glowing dots beneath it, all lit. No numerals. Place it on a round dark (#1E2230) disc with a thin bright rim.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels, square. Opaque background, full-bleed. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, opaque, no text; consistent set.
- **Destination:** /assets/chatgpt/badges/badge-7-day-streak.png. Creator Hub: Engagement > Badges > '7-Day Streak' (create the badge with this image). Badge: 7-Day Streak.
- **Status:** TODO

## UI art (transparent PNG)

### CG-022 - UI: Coin icon

- **ID:** CG-022
- **Linked task:** T-ART-06
- **Priority:** MVP
- **Prompt:**

```
Create a UI icon of a single chunky gold (#FFC83D) coin seen at a slight angle, with a simple raised rim and a plain embossed star in the centre, glossy highlight, soft darker-gold edge shading. Single object only, no background.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure magenta #FF00FF background that is easy to remove. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, transparent background, glossy flat toy style, no text.
- **Destination:** /assets/chatgpt/ui/ui-coin.png. Studio: upload via Asset Manager, then ImageLabel in StarterGui. Used by: Wallet in HUD (G9.3); coin popups; shop prices.
- **Status:** TODO

### CG-023 - UI: Gem icon

- **ID:** CG-023
- **Linked task:** T-ART-06
- **Priority:** MVP
- **Prompt:**

```
Create a UI icon of a single chunky faceted cyan (#3DDCFF) gem, low-poly look, white highlights on the top facets, slightly darker blue-cyan on the lower facets. Single object only, no background.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure magenta #FF00FF background that is easy to remove. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, transparent background, glossy flat toy style, no text.
- **Destination:** /assets/chatgpt/ui/ui-gem.png. Studio: upload via Asset Manager, then ImageLabel in StarterGui. Used by: Wallet in HUD (G9.3); shop prices; rewards.
- **Status:** TODO

### CG-024 - UI: Crown icon

- **ID:** CG-024
- **Linked task:** T-ART-06
- **Priority:** MVP
- **Prompt:**

```
Create a UI icon of a chunky gold (#FFC83D) crown with three points, small round pearls on the tips and a pink (#FF4F8B) gem in the centre, glossy highlight. Single object only, no background.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure magenta #FF00FF background that is easy to remove. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, transparent background, glossy flat toy style, no text.
- **Destination:** /assets/chatgpt/ui/ui-crown.png. Studio: upload via Asset Manager, then ImageLabel in StarterGui. Used by: Crowns currency (Rebirth panel), King marker, leaderboard.
- **Status:** TODO

### CG-025 - UI: Scissors icon

- **ID:** CG-025
- **Linked task:** T-ART-06
- **Priority:** MVP
- **Prompt:**

```
Create a UI icon of a chunky pair of scissors with red (#FF4D4D) handles and silver blades, slightly open, friendly rounded shapes, white highlight. Single object only, no background.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure magenta #FF00FF background that is easy to remove. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, transparent background, glossy flat toy style, no text.
- **Destination:** /assets/chatgpt/ui/ui-scissors.png. Studio: upload via Asset Manager, then ImageLabel in StarterGui. Used by: Tutorial overlay: pulsing scissors over a bot's trail (G7 step 4).
- **Status:** TODO

### CG-026 - UI: Hand-pointer icon

- **ID:** CG-026
- **Linked task:** T-ART-06
- **Priority:** MVP
- **Prompt:**

```
Create a UI icon of a friendly cartoon white glove pointing hand with the index finger out, thick dark (#1E2230) outline, soft shadow. Plain generic glove, no character resemblance. Single object only, no background.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure magenta #FF00FF background that is easy to remove. Keep the main subject centred with about 15% empty padding on every side, because Roblox crops this image to a circle. The subject must stay readable when shrunk to 64x64 pixels. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, transparent background, glossy flat toy style, no text.
- **Destination:** /assets/chatgpt/ui/ui-hand-pointer.png. Studio: upload via Asset Manager, then ImageLabel in StarterGui. Used by: Tutorial overlay: pointer on the Upgrade button (G7 step 5).
- **Status:** TODO

### CG-027 - UI: Button background (9-slice)

- **ID:** CG-027
- **Linked task:** T-ART-06
- **Priority:** MVP
- **Prompt:**

```
Create a game UI button background, a plain horizontal rounded rectangle for 9-slice scaling: fully rounded corners with a 24-pixel radius, a solid flat white (#FFFFFF) fill (white so it can be tinted in engine), a subtle slightly darker bottom edge for depth and a 3-pixel soft inner highlight at the top. The centre must be completely flat and uniform with no pattern so it stretches cleanly. Edges symmetrical.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x96 pixels. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure magenta #FF00FF background that is easy to remove. Leave no empty margin around the shape; the shape touches the image edges. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x96 px, PNG, transparent, white tintable fill, 9-slice with 24 px corners. Resize exactly before upload.
- **Destination:** /assets/chatgpt/ui/ui-button-9slice.png. Studio: ImageButton.Image, ScaleType = Slice, SliceCenter = (24,24,232,72), tint with ImageColor3. Used by every button (G6 UI row).
- **Status:** TODO

### CG-028 - UI: Panel frame (9-slice)

- **ID:** CG-028
- **Linked task:** T-ART-06
- **Priority:** MVP
- **Prompt:**

```
Create a game UI panel frame texture for 9-slice scaling: a large rounded square, corner radius 48 pixels, dark (#1E2230) flat fill, a lighter (#FFFFFF at 15% opacity) 4-pixel inner border line, a soft darker outer edge. The centre must be completely flat and uniform with no pattern so it stretches cleanly. Edges symmetrical.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 512x512 pixels. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure magenta #FF00FF background that is easy to remove. The shape touches the image edges. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 512x512 px, PNG, transparent, 9-slice with 48 px corners. Resize exactly before upload.
- **Destination:** /assets/chatgpt/ui/ui-panel-9slice.png. Studio: ImageLabel.Image, ScaleType = Slice, SliceCenter = (48,48,464,464). Used by all panels in G9.3.
- **Status:** TODO

## Turf pattern tiles

### CG-029 - Turf pattern: Stripes

- **ID:** CG-029
- **Linked task:** T-ART-07
- **Priority:** MVP
- **Prompt:**

```
Create a seamless tileable texture tile showing diagonal parallel stripes at 45 degrees, each stripe 32 px wide with 32 px gaps. The pattern marks are light grey (#E0E0E0) to white, the rest of the tile is fully transparent. It must repeat seamlessly: whatever leaves the right edge re-enters the left edge, and whatever leaves the top re-enters the bottom, with no seams or cut-off marks at the borders. Pure greyscale only, no colour, so the game can tint it with any player colour. Flat, no shading, no outline, no drop shadow. The palette block below is overridden: greyscale only.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure black #000000 background and tell me, so I can convert it to alpha. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, greyscale marks on transparent, seamless tile. After download, test by tiling 3x3 in an image editor.
- **Destination:** /assets/chatgpt/turf/turf-stripes.png. Studio: Texture/Decal on turf Parts (TurfRenderer), Color3 tinted per player; matches pattern 'stripes' in the cosmetics CSV (CG cosmetics entry).
- **Status:** TODO

### CG-030 - Turf pattern: Dots

- **ID:** CG-030
- **Linked task:** T-ART-07
- **Priority:** MVP
- **Prompt:**

```
Create a seamless tileable texture tile showing a regular offset grid of round dots, each dot 40 px across, evenly spaced. The pattern marks are light grey (#E0E0E0) to white, the rest of the tile is fully transparent. It must repeat seamlessly: whatever leaves the right edge re-enters the left edge, and whatever leaves the top re-enters the bottom, with no seams or cut-off marks at the borders. Pure greyscale only, no colour, so the game can tint it with any player colour. Flat, no shading, no outline, no drop shadow. The palette block below is overridden: greyscale only.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure black #000000 background and tell me, so I can convert it to alpha. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, greyscale marks on transparent, seamless tile. After download, test by tiling 3x3 in an image editor.
- **Destination:** /assets/chatgpt/turf/turf-dots.png. Studio: Texture/Decal on turf Parts (TurfRenderer), Color3 tinted per player; matches pattern 'dots' in the cosmetics CSV (CG cosmetics entry).
- **Status:** TODO

### CG-031 - Turf pattern: Checker

- **ID:** CG-031
- **Linked task:** T-ART-07
- **Priority:** MVP
- **Prompt:**

```
Create a seamless tileable texture tile showing a checkerboard of 64 px squares, alternate squares filled. The pattern marks are light grey (#E0E0E0) to white, the rest of the tile is fully transparent. It must repeat seamlessly: whatever leaves the right edge re-enters the left edge, and whatever leaves the top re-enters the bottom, with no seams or cut-off marks at the borders. Pure greyscale only, no colour, so the game can tint it with any player colour. Flat, no shading, no outline, no drop shadow. The palette block below is overridden: greyscale only.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure black #000000 background and tell me, so I can convert it to alpha. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, greyscale marks on transparent, seamless tile. After download, test by tiling 3x3 in an image editor.
- **Destination:** /assets/chatgpt/turf/turf-checker.png. Studio: Texture/Decal on turf Parts (TurfRenderer), Color3 tinted per player; matches pattern 'checker' in the cosmetics CSV (CG cosmetics entry).
- **Status:** TODO

### CG-032 - Turf pattern: Waves

- **ID:** CG-032
- **Linked task:** T-ART-07
- **Priority:** MVP
- **Prompt:**

```
Create a seamless tileable texture tile showing smooth horizontal wavy lines, each line 20 px thick, repeating every 64 px vertically. The pattern marks are light grey (#E0E0E0) to white, the rest of the tile is fully transparent. It must repeat seamlessly: whatever leaves the right edge re-enters the left edge, and whatever leaves the top re-enters the bottom, with no seams or cut-off marks at the borders. Pure greyscale only, no colour, so the game can tint it with any player colour. Flat, no shading, no outline, no drop shadow. The palette block below is overridden: greyscale only.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure black #000000 background and tell me, so I can convert it to alpha. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, greyscale marks on transparent, seamless tile. After download, test by tiling 3x3 in an image editor.
- **Destination:** /assets/chatgpt/turf/turf-waves.png. Studio: Texture/Decal on turf Parts (TurfRenderer), Color3 tinted per player; matches pattern 'waves' in the cosmetics CSV (CG cosmetics entry).
- **Status:** TODO

### CG-033 - Turf pattern: Stars

- **ID:** CG-033
- **Linked task:** T-ART-07
- **Priority:** MVP
- **Prompt:**

```
Create a seamless tileable texture tile showing small five-pointed stars, 48 px across, arranged in an offset grid. The pattern marks are light grey (#E0E0E0) to white, the rest of the tile is fully transparent. It must repeat seamlessly: whatever leaves the right edge re-enters the left edge, and whatever leaves the top re-enters the bottom, with no seams or cut-off marks at the borders. Pure greyscale only, no colour, so the game can tint it with any player colour. Flat, no shading, no outline, no drop shadow. The palette block below is overridden: greyscale only.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure black #000000 background and tell me, so I can convert it to alpha. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, greyscale marks on transparent, seamless tile. After download, test by tiling 3x3 in an image editor.
- **Destination:** /assets/chatgpt/turf/turf-stars.png. Studio: Texture/Decal on turf Parts (TurfRenderer), Color3 tinted per player; matches pattern 'stars' in the cosmetics CSV (CG cosmetics entry).
- **Status:** TODO

### CG-034 - Turf pattern: Hex

- **ID:** CG-034
- **Linked task:** T-ART-07
- **Priority:** MVP
- **Prompt:**

```
Create a seamless tileable texture tile showing a honeycomb of regular hexagons drawn as filled hexagons with thin gaps between them. The pattern marks are light grey (#E0E0E0) to white, the rest of the tile is fully transparent. It must repeat seamlessly: whatever leaves the right edge re-enters the left edge, and whatever leaves the top re-enters the bottom, with no seams or cut-off marks at the borders. Pure greyscale only, no colour, so the game can tint it with any player colour. Flat, no shading, no outline, no drop shadow. The palette block below is overridden: greyscale only.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 256x256 pixels, square. Transparent background (real alpha PNG). If you cannot produce transparency, use a flat pure black #000000 background and tell me, so I can convert it to alpha. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 256x256 px, PNG, greyscale marks on transparent, seamless tile. After download, test by tiling 3x3 in an image editor.
- **Destination:** /assets/chatgpt/turf/turf-hex.png. Studio: Texture/Decal on turf Parts (TurfRenderer), Color3 tinted per player; matches pattern 'hex' in the cosmetics CSV (CG cosmetics entry).
- **Status:** TODO

## Loading screen and lobby banner

### CG-035 - Loading screen

- **ID:** CG-035
- **Linked task:** T-ART-08
- **Priority:** MVP
- **Prompt:**

```
Create a loading-screen background for a territory-capture arena game. Wide angled top-down view of a pale board with colourful turf patches of many player colours, several rounded plastic pieces mid-run with trails, a dark low-poly arena wall at the far edge, small clouds drifting. The lower third must be calm and mostly empty pale ground so a progress bar can be placed there. A bright, welcoming composition. Soft vignette.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 1920x1080 pixels, 16:9 landscape. Opaque background filling the whole frame. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 1920x1080 px, PNG, opaque, no text, lower third calm.
- **Destination:** /assets/chatgpt/screens/loading-screen.png. Studio: ReplicatedFirst custom loading ScreenGui, ImageLabel full-screen.
- **Status:** TODO

### CG-036 - Lobby banner

- **ID:** CG-036
- **Linked task:** T-ART-08
- **Priority:** MVP
- **Prompt:**

```
Create a wide lobby banner for a territory-capture arena game. Side view of a bright board-game tabletop with a row of rounded plastic pieces in different player colours running toward the right, coloured turf patches behind them, a gold crown floating over the biggest piece, sparkles. Keep the centre clear and soft so a Roblox SurfaceGui or title can be overlaid later. Symmetrical edges so the banner can sit on a sign.

ART DIRECTION BLOCK: Style: clean toy-board look, like a bright board game seen from above at an angle. Flat saturated coloured-felt territories spreading over a pale white table, rounded plastic player pieces, chunky low-poly props, soft shadows, no textures beyond simple patterns. Palette (use only these): ground #EEF1F5, grid lines #DDE2EA, dark arena wall #2B2F3A, UI dark #1E2230, UI light #FFFFFF, accent yellow #FFC83D, accent pink #FF4F8B, gem cyan #3DDCFF, success green #4ADE80, danger red #FF4D4D. Player colours: #FF4D4D #FF8A3D #FFC83D #B6E33B #4ADE80 #2DD4BF #3DDCFF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #FF4F8B #A0704A #6B7A99 #F5F5F5 #2B2F3A. Lighting: bright daytime (about 2 pm), soft shadows, slightly boosted saturation and a touch of contrast, gentle bloom glow on highlights, faint pale-blue atmospheric haze, cool grey-blue ambient light (#8A93A8 / #B8C0D0). Mood: cheerful, friendly, kid-safe, competitive but never violent. No gore, no weapons, no blood.

Output requirements: one image, 1024x512 pixels, 2:1. Opaque background filling the whole frame. No text, letters, numbers or watermarks anywhere in the image. Do not include any copyrighted characters, logos or real brands.
```

- **Output spec:** 1024x512 px, PNG, opaque, no text.
- **Destination:** /assets/chatgpt/screens/lobby-banner.png. Studio: Workspace.Lobby sign, SurfaceGui > ImageLabel.
- **Status:** TODO

## Store copy

### CG-037 - Game description for the Roblox page

- **ID:** CG-037
- **Linked task:** T-COPY-01
- **Priority:** MVP
- **Prompt:**

```
You are a copywriter for a Roblox game. Write the description for the game's Roblox experience page.

Game facts (use only these, do not invent features):
- Working title: Turf Loop. Territory-capture arena. Run out of your coloured turf leaving a trail, loop back to claim everything you circled, and cut other players' trails to wipe them out.
- Drop-in, 16-player, always-on arena. Servers add computer-controlled bots so the arena always has at least 10 runners. Do not claim every opponent is a real player.
- Crossing your own trail is harmless. The arena edge is a solid wall. No win state, the match is endless; capturing 100% of the map pays a big bonus and restarts you.
- The runner with the most turf becomes the King, wears a crown, and cutting the King pays double.
- Earn coins by playing, buy permanent upgrades (Speed, Start Size, Coin Boost, Spawn Shield), Rebirth for Crowns and a permanent coin bonus.
- Cosmetic turf skins, trails and capture effects. Daily streak rewards, playtime rewards, daily quests, leaderboards, codes.
- Optional purchases (VIP, 2x Coins, Neon Pack) never change speed or the cutting rules.

Rules for the copy:
- Under 1000 characters in total (count them and tell me the count).
- Roblox-safe: no promises of free Robux, no "official", no references to other games or brands, no misleading claims, no asking players to leave Roblox, no mention of real money outside Robux.
- Friendly tone for ages 9+, short paragraphs, a one-line hook first, then a short feature list using plain hyphens (no emoji), then a closing line telling players to try the codes RELEASE and TURF.
- Output only the description text, then on a new line "Character count: N".
```

- **Output spec:** Plain text, under 1000 characters, no emoji, ends with the character count line.
- **Destination:** /assets/chatgpt/copy/game-description.txt. Creator Hub: Game Settings > Description.
- **Status:** TODO

### CG-038 - Names and one-line descriptions for every gamepass and developer product

- **ID:** CG-038
- **Linked task:** T-COPY-01
- **Priority:** MVP
- **Prompt:**

```
You are a copywriter for a Roblox game called Turf Loop (a territory-capture arena). Write store names and descriptions for each gamepass and developer product below.

Items (Name | Price in Robux | Effect, which the description must match exactly and must not exaggerate):
Gamepasses
- VIP | 399 | x1.2 coins, gold name tag, VIP turf skin and trail, daily gems doubled
- 2x Coins | 249 | x2 coins forever
- Neon Pack | 199 | 5 neon turf skins and a neon trail
- Radio | 99 | play a moderated music-ID boombox in the lobby area (post-launch)
Developer products
- Starter Pack (once per account) | 79 | 300 Gems, the exclusive "Starter Spark" skin and 2,500 coins
- Second Chance | 15 | when eliminated, keep your turf and respawn on it with a 3-second shield; max once per life
- 2x Coins, 15 min | 29 | doubles coins for 15 minutes
- Gems S | 49 | 80 Gems
- Gems M | 199 | 400 Gems
- Gems L | 449 | 1,000 Gems
- Gems XL | 999 | 2,600 Gems

Rules:
- Store name: max 40 characters; you may keep the name above or propose a punchier one that clearly says what it is.
- Description: one line, max 120 characters, plain English, kid-safe, no emoji, no claims beyond the effect listed, no mention of speed advantage.
- Output as CSV with the header: type,item,price_robux,store_name,store_description (put any field containing a comma in double quotes). Output only the CSV.
```

- **Output spec:** CSV, 11 data rows plus header, no emoji.
- **Destination:** /assets/chatgpt/copy/store-names.csv. Creator Hub: Monetization > Passes (VIP, 2x Coins, Neon Pack, Radio) and Developer Products (Starter Pack, Second Chance, 2x Coins 15 min, Gems S/M/L/XL) > Name and Description.
- **Status:** TODO

## Naming

### CG-039 - Game title brainstorm (30 options)

- **ID:** CG-039
- **Linked task:** T-COPY-02
- **Priority:** MVP
- **Prompt:**

```
I am making a Roblox game currently called "Turf Loop". It is a territory-capture arena: you run out of your coloured turf leaving a trail, loop back to claim everything you circled, and cut other players' trails to eliminate them. Cheerful toy-board look, 16 players, ages 9+.

Give me 30 alternative game titles in the current Roblox naming style: short (1 to 3 words, max 25 characters), punchy, easy to say, easy to read as a small thumbnail label, often a playful verb or noun, no tags like [NEW] or [UPDATE], no emoji.

Rules:
- Do not copy or closely imitate the name of any existing well-known game or brand.
- No trademarked words.
- Group them under 5 mini-headings of 6 titles each: Action words, Territory words, Cute/silly, Competitive, Simple nouns.
- After the list, name your top 5 and give a one-line reason for each.
Do not include "Turf Loop" itself.
```

- **Output spec:** Plain text list, 30 titles under 5 headings, then top 5 with reasons.
- **Destination:** /assets/chatgpt/copy/title-brainstorm.txt. Owner picks one; then Creator Hub: Game Settings > Basic Info > Name. Check the name is unused on Roblox before adopting.
- **Status:** TODO

## Cosmetics data

### CG-040 - Cosmetic names CSV (skins, trails, capture effects)

- **ID:** CG-040
- **Linked task:** T-COPY-03
- **Priority:** MVP
- **Prompt:**

```
You are a content designer for a Roblox territory-capture game with a bright toy-board look. Give names to the cosmetics below and output them as one CSV.

CSV header exactly: id,name,rarity,type,colorHexA,colorHexB,pattern

Rules for each column:
- id: lowercase snake_case, unique. Skins: skin_common_01 ... ; trails: trail_common_01 ...; effects: effect_01 ...
- name: 1 to 3 words, max 22 characters, cheerful and kid-safe, no brands, no copyrighted names, no real people. Each name unique.
- rarity: common, rare, epic, legendary, crown, special or none (see lists).
- type: skin, trail or effect.
- colorHexA, colorHexB: two hex codes taken ONLY from this palette: #FFC83D #FF4F8B #3DDCFF #4ADE80 #FF4D4D #FF8A3D #B6E33B #2DD4BF #4F8BFF #7C5CFF #C45CFF #FF5CD6 #A0704A #6B7A99 #F5F5F5 #2B2F3A. Names should suit their colours (e.g. a #FF8A3D + #FFC83D skin might be "Sunset Toast").
- pattern: one of plain, stripes, dots, checker, waves, stars, hex (trails and effects: use none).

Rows needed (exact counts):
A. Turf skins, 33 rows: 12 common (simple patterns, plain/stripes/dots mostly), 8 rare, 6 epic, 3 legendary (most elaborate, strongest colour contrast), 4 crown-tier. List the 4 crown-tier rows in order of crowns required (1, 3, 5, 10 Crowns); these are prestige skins, make them feel regal.
B. Trails, 8 rows: 2 common, 3 rare, 2 epic, 1 legendary. type=trail.
C. Capture effects, 5 rows, type=effect, rarity=none. The names are fixed in this order: Sparkle, Fireworks, Bubbles, Lightning, Hearts. Use them exactly as the name column; choose colours that suit each.
D. Special items tied to passes and promos, 10 rows, rarity=special:
   - 1 VIP turf skin (gold-themed), 1 VIP trail (gold-themed)
   - 5 Neon Pack turf skins (bright glowing colour pairs) and 1 neon trail
   - 1 "Team" turf skin (group reward)
   - 1 skin whose name is fixed as: Starter Spark

Total 56 rows. Output ONLY the CSV in a code block, nothing else. Wrap any field containing a comma in double quotes.
```

- **Output spec:** CSV, header + 56 rows, in a code block.
- **Destination:** /assets/chatgpt/copy/cosmetics.csv. Used by src/shared Catalog (Studio/Rojo; imported by the build agent). Rows A/B/C are the MVP counts of GDD G3.6; rows D are the pass/promo items from G4/G5.
- **Status:** TODO

## UI strings

### CG-041 - UI string sheet (all screens)

- **ID:** CG-041
- **Linked task:** T-COPY-04
- **Priority:** MVP
- **Prompt:**

```
You are a UX writer for a Roblox territory-capture arena game ("Turf Loop"). Produce the full English UI string sheet as CSV with the header exactly: key,english

Style: short, friendly, kid-safe (ages 9+), sentence case, no emoji, no slang that does not translate. Button labels max 14 characters. Toast messages max 50 characters. Use {name}-style placeholders (curly braces) for numbers and names, e.g. "+{coins} coins". Wrap any field containing a comma in double quotes.

Key naming: lowercase dot.case, prefix = screen, e.g. hud.coins, upgrade.speed.name. Cover EVERY screen below; about 160 to 220 rows total.

Game facts you may need:
- Currencies: Coins, Gems, Crowns.
- Upgrades: Speed (+1.5% speed per level, max 10), Start Size (bigger starting patch, max 3), Coin Boost (+10% coins per level, max 20), Spawn Shield (+0.5 s shield per level, max 5).
- Rebirth: costs lifetime coins earned (it needs {needed} coins), resets coins and upgrades, gives +1 Crown, +25% permanent coin bonus and 50 Gems.
- Shop tabs: Featured, Skins, Trails, Effects, Gems, Passes. Featured items are -20% with a daily rotation. No random boxes.
- Passes: VIP, 2x Coins, Neon Pack (Radio is post-launch). Offers: Starter Pack (once per account), Second Chance (keep your turf, 3 s shield, once per life), 2x Coins for 15 min.
- Rewards: 7-day daily streak (resets if a day is missed), playtime rewards at 2/5/10/20/30 min, 3 daily quests, codes, group reward (+10% coins and Team skin).
- Quest types: claim N cells, eliminate N runners, single capture of N cells, reach N% of map, be King for N seconds, play N minutes.
- Death panel shows cells, coins earned, kills; buttons Respawn and Second Chance.
- Events/toasts: you became King, {name} is King, 100% map announced server-wide, spawn shield active, trail in danger, purchase success, not enough coins/gems, code invalid/already used/redeemed, reward claimed, quest complete, settings saved.

Screens to cover (every one):
1 HUD (wallet, map %, minimap label, live leaderboard title, kill feed lines like "{killer} cut {victim}", boost timers)
2 Upgrade panel (title, each upgrade name and description, level, cost, max, buy button, footer pitch for 2x Coins)
3 Shop (title, all six tab names, price labels, owned/equipped/locked states, "needs {n} Crowns", featured -20% tag, Neon Pack banner)
4 Inventory/equip (title, equip, equipped, unequip, empty-state)
5 Death panel (title, stat labels, Respawn, Second Chance prompt with countdown)
6 Daily streak calendar (title, Day {n}, claim, claimed, come back tomorrow, streak lost)
7 Quests panel (title, each of the six quest-type sentences with {n}, claim, done, resets in {time})
8 Playtime rewards bar (title, claim, next reward in {time})
9 Rebirth panel (title, explanation, requirement, button, confirm dialog, reward summary)
10 Codes entry (title, placeholder, redeem, success/errors)
11 Settings (title, Music, SFX, Camera shake, Low detail, close)
12 Starter Pack offer (title, contents line, buy, no thanks, one-time-only note)
13 Toast/notification layer (all toasts listed above)
14 Tutorial overlay (very short labels only; the tutorial is mostly wordless: e.g. "Loop back to claim!", "Cut their trail!", "Tap to upgrade!")
15 "While you were away" return panel (title, streak status, unclaimed rewards, collect all)

Output ONLY the CSV in a code block.
```

- **Output spec:** CSV, header + ~160-220 rows, in a code block, UTF-8.
- **Destination:** /assets/chatgpt/copy/ui-strings.csv. Used by the build agent to create a Strings module for StarterGui (screens listed in GDD G9.3).
- **Status:** TODO

## Marketing text

### CG-042 - Launch update log and 3 launch social posts

- **ID:** CG-042
- **Linked task:** T-COPY-05
- **Priority:** MVP
- **Prompt:**

```
You are a community manager for a Roblox game called Turf Loop (working title; use this name). Write launch text.

Game facts (use only these): territory-capture arena for up to 16 players; run out of your coloured turf leaving a trail, loop back to claim everything you circled, cut other players' trails to eliminate them; the player with the most turf is the King; coins, permanent upgrades, Rebirth with Crowns; cosmetic turf skins, trails and capture effects; daily streak, daily quests, playtime rewards; leaderboards; codes RELEASE (1,000 coins) and TURF (25 gems); join the group for +10% coins and a Team skin; weekends double coins; optional purchases never affect speed or cutting.

Write:
1. UPDATE LOG: a launch update log for the Roblox game page "Updates" tab. Max 700 characters. Title line "Launch update", then 5 to 7 short bullet lines with plain hyphens, then the two codes.
2. SOCIAL POST 1: short and punchy for a short-form social platform, max 240 characters, 1 or 2 hashtags max, no emoji overload (max 2 emoji).
3. SOCIAL POST 2: a Discord announcement, max 500 characters, friendly, mention the codes, with a placeholder [GAME LINK].
4. SOCIAL POST 3: a Roblox group wall post, max 300 characters, ends with a call to like and favourite the game and a placeholder [GAME LINK].

Rules: kid-safe, no hype claims like "best", "#1" or "free Robux", no mention of other games or brands, no fake numbers (do not invent player counts or ratings). Output the four texts under clear labels with the character count after each.
```

- **Output spec:** Plain text, four labelled blocks with character counts.
- **Destination:** /assets/chatgpt/copy/launch-text.txt. Update log: Creator Hub > Game page > Updates. Social posts: owner posts manually.
- **Status:** TODO

## Bot usernames

### CG-043 - 40 bot usernames

- **ID:** CG-043
- **Linked task:** T-COPY-06
- **Priority:** MVP
- **Prompt:**

```
Give me a plain list of 40 plausible Roblox-style usernames for computer-controlled players in a kid-friendly game.

Rules:
- One username per line, no numbering, no bullets, no commentary.
- 6 to 16 characters, letters and digits and single underscores only, no spaces.
- Realistic mix: some word+word (BlueFalcon), some with digits (Mia_Plays7), some lowercase, some with a number at the end, some with an underscore.
- Kid-safe: no swearing, no hate, no romance, no drugs, no violence words, no politics.
- No real people, no celebrities, no streamers, no brand names, no names of existing games or characters.
- All 40 must be different and should not look like staff names (avoid "admin", "mod", "dev", "roblox").
```

- **Output spec:** Plain list, 40 lines, no extra text.
- **Destination:** /assets/chatgpt/copy/bot-names.txt. Studio: src/server BotService name list (build agent imports it).
- **Status:** TODO

## Audio briefs

### CG-044 - Sound-design briefs for all SFX

- **ID:** CG-044
- **Linked task:** T-AUDIO-01
- **Priority:** MVP
- **Prompt:**

```
You are a sound designer helping me find sounds on the Roblox Creator Store (audio marketplace) for a bright toy-board territory-capture game. The tone is cheerful, soft and chunky, like plastic game pieces and bubbly pops; nothing harsh, nothing scary, kid-safe.

For each of the 20 sounds below, output one line of CSV with the header: sfx,description,search1,search2,search3
- description: one sentence describing the sound (character, length in seconds, pitch behaviour, loop or one-shot).
- search1..search3: three different short search phrases (2 to 4 words each) I can type into the Creator Store audio search. Prefer generic descriptive words, not brand or song names.
Wrap any field containing a comma in double quotes. Output only the CSV in a code block.

The sounds and where they play:
1 trail start: soft "zip" when leaving your turf
2 trail loop (subtle): very quiet loop while the trail is extending
3 heartbeat: when an enemy is close to your trail, tense but gentle
4 claim pop (pitch ladder): rising-pitch pop per 20 cells captured, up to 12 notes
5 big-claim fanfare: short celebration for a large capture
6 steal crunch: extra punchy crunch when capturing enemy turf
7 snip: scissors snip when you cut a trail
8 death pop: comic pop when eliminated (not scary)
9 respawn whoosh: coming back into the arena
10 crown fanfare: becoming the King
11 coin tick: each coin counter tick
12 purchase cha-ching: buying something
13 UI hover: tiny button hover blip
14 UI click: button press click
15 UI error: gentle not-allowed buzz
16 reward claim: claiming a daily or playtime reward
17 quest complete: quest finished jingle
18 rebirth swell: big rising swell for Rebirth
19 lobby music loop: relaxed upbeat loop, seamless
20 arena music loop: upbeat focused loop, seamless, not distracting
```

- **Output spec:** CSV, header + 20 rows, in a code block.
- **Destination:** /assets/chatgpt/audio/sfx-briefs.csv. Owner searches Creator Store, copies chosen asset IDs into src/shared/Config.luau SFX table (GDD G9.2). Check each sound's licence/moderation status in the Creator Store before use.
- **Status:** TODO

## Balance check

### CG-045 - Economy sanity check (coins per minute, time to first rebirth)

- **ID:** CG-045
- **Linked task:** T-BAL-01
- **Priority:** MVP
- **Prompt:**

```
FLAGGED: output is to be reviewed by Fable before use. Do not treat results as final.

I am designing the economy of a Roblox territory-capture arena game. Please build a simple simulation and give me CSV output. Here are the rules (all numbers are design values):

COIN INCOME (raw, before multipliers)
- Cell claimed (neutral): 1 coin. Cell claimed (stolen from an enemy): 2 coins.
- Elimination: 25 coins + 10% of the victim's cell count (x2 if the victim was King).
- Passive: every 10 s, floor(own cells / 20) coins.
- Capture size bonus on a single capture: >= 100 cells +10%, >= 400 cells +25%, >= 1,000 cells +50%.
- Multipliers multiply together: Coin Boost upgrade (+10% per level, max level 20), Rebirth (+25% per Crown), VIP x1.2, 2x Coins pass x2, boost x2, group +10%, weekend event x2.
- Expected raw income for a brand-new player is about 150 to 250 coins/min; an engaged mid-level player with multipliers about 1,500 coins/min (these are targets, not facts; tell me if your simulation disagrees).

UPGRADES (cost = base x growth^level, rounded to nearest 5; level starts at 0 for the first purchase)
- Speed: +1.5% WalkSpeed per level, max 10, base 150, growth 1.75
- Start Size: patch side +2 cells per level, max 3, base 1,000, growth 5.0
- Coin Boost: +10% coins per level, max 20, base 100, growth 1.45
- Spawn Shield: +0.5 s shield per level, max 5, base 300, growth 2.0

REBIRTH
- Requires 150,000 x 2^(crowns) coins earned since the last rebirth (earned, not held). For the first rebirth crowns = 0.
- Resets coins and upgrades. Grants +1 Crown, +25% permanent coin multiplier (assume rebirth multiplier = 1 + 0.25 x crowns), 50 Gems.
- Design target: first rebirth about 2.5 to 3 hours of play; later ones about 3 to 4 hours each.

TASK
Simulate three player profiles with these assumptions (state any other assumptions you make in the CSV):
- casual: raw 150 coins/min at the start, grows with average turf size, plays 20-minute sessions
- average: raw 250 coins/min at the start, buys the best affordable upgrade value first (Coin Boost priority), plays continuous sessions
- engaged: raw 400 coins/min at the start, buys Coin Boost whenever affordable, owns VIP and the group bonus, no 2x Coins pass
For each profile, assume the player spends coins on upgrades whenever cheap and does not spend on cosmetics.

Output TWO CSV blocks and nothing else except a short list of assumptions at the end:
CSV 1 header: profile,raw_coins_per_min_start,coin_boost_level_at_rebirth,effective_coins_per_min_at_rebirth,minutes_to_first_rebirth,hours_to_first_rebirth,minutes_to_second_rebirth,hours_to_second_rebirth,meets_target_2_5_to_3_hours
CSV 2 header (one row per 15 simulated minutes per profile, up to the first rebirth): profile,minute,total_coins_earned_since_rebirth,coin_boost_level,speed_level,start_size_level,shield_level,effective_coins_per_min
Also flag any place where the numbers look broken (for example, upgrade costs that become unreachable or rebirth that is too fast or slow) in the assumptions list.
```

- **Output spec:** Two CSV blocks + short assumption list. TO BE REVIEWED BY FABLE BEFORE USE.
- **Destination:** /assets/chatgpt/balance/economy-sim.csv (save both CSVs as economy-sim-summary.csv and economy-sim-timeline.csv). Used by Fable for review against GDD G3.2-G3.4 / Config.luau; do not apply directly.
- **Status:** TODO

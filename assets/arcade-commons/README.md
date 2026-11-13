# Arcade Commons for Roblox

All 48 original icons are uploaded as Image assets owned by Roblox user 309565647.
Every upload completed and received Approved moderation status. See
upload-manifest.json for stable asset IDs, operation paths and source PNGs.

Copy ArcadeIcons.luau into ReplicatedStorage/Shared in another game and use its
rbxassetid URLs in ImageLabel/ImageButton.Image. Sharing with a different creator
may require Roblox asset permissions. This is not a Creator Store listing.

TurfLoop integration is saved to Roblox place 122808046982168, version 4.
Source project: C:/Users/coolb/new game/new-game.
- src/shared/ArcadeIcons.luau: all 48 image URLs.
- src/client/ui/UiKit.luau: icon helper and panel header/close artwork.
- src/client/controllers/HudController.luau: wallet and menu rail artwork.

Studio verification: 48/48 native ImageLabels rendered and loaded; wallet and
all seven rail icons loaded; Shop and Settings navigation worked; phone landscape
and desktop screenshots checked. Rail icon/caption geometry has no overlap.
Temporary verification UI removed; Play stopped; Studio reset to default viewport.

Checks passed: 39 source modules compile, existing Luau specs, xref, 10/10 mock
server scenarios, XML and Rojo builds. Existing Studio DataStore-access and
unrelated asset 203785492 warnings remain outside this change.

The larger Figma UI components remain design drafts. Their complete conversion
to native Roblox controls is separate from this icon upload and HUD integration.

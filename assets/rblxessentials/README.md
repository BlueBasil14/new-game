# RBLX Essentials Sound System 3.2.2

Downloaded from the creator: https://rblx-essentials.itch.io/sound-system
Direct official download: https://rblxessentials.com/download/free/SoundSystem
Documentation: https://rblxessentials.com/ai/SoundSystem.md

Only `SoundService.rbxmx` (15 music tracks in the `Music` SoundGroup, 42 SFX in `SFX`) is used.
tools/build_place.py includes only that file. The pack's music player UI (`StarterGui.rbxmx`) and
its Kernel boot scripts (`ServerScriptService.rbxmx`, `StarterPlayerScripts.rbxmx`,
`ReplicatedStorage.rbxmx`) are kept here unchanged for reference but are NOT installed (2026-11-15):
background music is played by `src/client/controllers/MusicController.luau` (shuffle, no UI;
skipping is the Skip Music game pass). `default.project.json` must map only `SoundService.rbxmx`.

Game sound effects remain in FeedbackController (`SoundIds.arenaMusic` must stay 0 so two music
players never overlap).

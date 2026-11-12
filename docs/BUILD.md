# Building TurfLoop

## Without Rojo (stdlib Python 3 only)

    python3 tools/build_place.py          # writes build/TurfLoop.rbxlx
    python3 tools/build_place.py --check  # build to a temp path, validate only

Open `build/TurfLoop.rbxlx` in Roblox Studio (File > Open from File). The
builder re-parses the output, prints Script/LocalScript/ModuleScript/Folder
counts, and exits non-zero if any `src/` file was not emitted exactly once.

Mapping: `src/shared` -> ReplicatedStorage/Shared, `src/server` ->
ServerScriptService/Server, `src/client` -> StarterPlayer/StarterPlayerScripts/Client.
`X.server.luau` = Script, `X.client.luau` = LocalScript, other `X.luau` =
ModuleScript; a directory with `init*.luau` becomes that script type.

## With Rojo 7

    rojo build -o build/TurfLoop.rbxlx   # or: rojo serve, then connect the Studio plugin

The tree is described in `default.project.json`.

## Static checks

    cd tools/luau && npm install   # first time only
    node tools/luau/check.mjs      # run from the repo root

## Before launch

Game ids in `src/shared/Config.luau` (`Config.Ids`: GroupId, Passes, Products,
Badges) are 0 placeholders. Create the passes, developer products and badges
on Roblox, then fill in the real ids and rebuild.

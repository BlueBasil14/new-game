# Running this project on your Windows PC

The cloud session cannot reach Roblox Studio or Blender. A Claude Code session on your own PC can. Everything it needs is in this repo.

## One-time setup
1. Install Git, Node.js (18+) and Python 3 if you do not have them.
2. In a terminal (PowerShell is fine):
   ```
   git clone https://github.com/BlueBasil14/new-game
   cd new-game
   git checkout claude/hopeful-shannon-w2qsd8
   cd tools\luau
   npm install
   cd ..\..
   ```
3. Open Roblox Studio and make sure its MCP server is installed (the file `%LOCALAPPDATA%\Roblox\mcp.bat` must exist).

## Start working
1. Open `build\TurfLoop.rbxlx` in Roblox Studio and leave Studio open.
2. In the `new-game` folder run `claude` (or open the folder in the Claude Desktop app).
3. Claude Code will ask to approve the `Roblox_Studio` server from `.mcp.json` — approve it. (You no longer need the `claude mcp add` command; `.mcp.json` does the same thing for this folder.)
4. Say: **Resume the Roblox project from docs/PROGRESS.md.**

`CLAUDE.md` tells that session the rules, where everything is, and that the next step is the first Studio playtest (`docs/PLAYTEST.md`).

## Blender
Add your Blender MCP server the same way you normally do (`claude mcp add …`) from inside this folder before starting the session. Model tasks are T-AST-01…11 in `docs/TASKS.md`.

## Keeping cloud and local in sync
Both push to the branch `claude/hopeful-shannon-w2qsd8`. Run `git pull` before starting a local session.

# Claude Dungeon

[![License](https://img.shields.io/github/license/punt-labs/dungeon)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/punt-labs/dungeon/docs.yml?label=CI)](https://github.com/punt-labs/dungeon/actions/workflows/docs.yml)
[![Working Backwards](https://img.shields.io/badge/Working_Backwards-hypothesis-lightgrey)](./prfaq.pdf)

A text adventure engine for [Claude Code](https://claude.ai/code). Claude is the game master — no code runs, only prompts. Players type natural language commands and Claude interprets them, manages game state, and narrates the story.

> This is a clickable prototype. It demonstrates the concept but is not yet a game.

## How It Works

The entire game engine is a single markdown file (`skills/dungeon/SKILL.md`) containing instructions that Claude follows. Adventure scripts are structured markdown files in `scripts/`. Game state is persisted as YAML frontmatter in `.claude/dungeon.local.md`.

```
Player types: /dungeon attack the goblin
                       │
                       ▼
              Claude reads game state
              Claude reads adventure script
              Claude matches "attack the goblin" → fight action
              Claude applies effects (health, inventory, scene change)
              Claude writes updated state
              Claude narrates the outcome
```

No parser. No runtime. Claude's natural language understanding *is* the parser.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/punt-labs/dungeon/a22fab7/install.sh | sh
```

<details>
<summary>Manual install</summary>

```bash
claude plugin marketplace add punt-labs/claude-plugins
claude plugin install dungeon@punt-labs
```

</details>

<details>
<summary>Verify before running</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/punt-labs/dungeon/a22fab7/install.sh -o install.sh
shasum -a 256 install.sh
cat install.sh
sh install.sh
```

</details>

Then restart Claude Code and type `/dungeon` to start.

## Bundled Adventures

| Script | Theme | Key Mechanic |
|--------|-------|-------------|
| The Depths of Grimhold | Classic fantasy dungeon crawl | Branching paths, inventory gating, boss fight |
| The UNIX Catacombs | UNIX system internals | Meta-humor, technical puzzles, process combat |
| The Haunted Library of Ashworth | Gothic horror | Noise/stealth mechanic, NPC relationship, moral choice |

## Commands

```
/dungeon <action>     Perform an action (describe what you want to do)
/dungeon look         Re-read the current scene
/dungeon inventory    Check your inventory and health
/dungeon new          Start a new adventure
/dungeon help         Show available commands
```

## Future Directions

We are considering the following ideas for expanding the engine beyond static scripts:

| Tier | Addition | What It Unlocks |
|------|----------|----------------|
| 1 | Local MCP server | Deterministic game logic (dice rolls, damage formulas), efficient scene loading, non-intrusive I/O |
| 2 | Backend service | Persistence across devices, save slots, leaderboards, content updates without reinstall |
| 3 | Spatial map engine | Procedural generation, fog of war, minimap, enemy pathfinding |
| 4 | Multiplayer | Co-op dungeon crawling, shared world state, PvP, DM mode, persistent worlds |

Each tier adds a runtime dependency but unlocks gameplay that is structurally impossible in the previous tier.

## Project Structure

```
.claude-plugin/
  plugin.json              Plugin manifest
skills/
  dungeon/SKILL.md         Game engine (Claude's instructions)
scripts/
  classic-fantasy-dungeon.md   ~10 scenes, fantasy dungeon crawl
  unix-catacombs.md            ~8 scenes, UNIX-themed meta adventure
  haunted-library.md           ~8 scenes, stealth/horror
assets/
  ascii-art.md             Shared ASCII art (title, game over, victory)
install.sh                 Installer
```

## License

MIT

# Claude Dungeon Design Decision Log

This file is the authoritative record of design decisions, prior approaches, and their outcomes. **Every design change must be logged here before implementation.**

## Rules

1. Before proposing ANY design change, consult this log for prior decisions on the same topic.
2. Do not revisit a settled decision without new evidence.
3. Log the decision, alternatives considered, and outcome.

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Claude Code UI                            │
│                                                                  │
│  User types: /dungeon attack the goblin                          │
│              ─────────┬───────────────                           │
│                       │                                          │
│              $ARGUMENTS = "attack the goblin"                    │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                  SKILL.md (Game Engine)                           │
│                  skills/dungeon/SKILL.md                          │
│                                                                  │
│  Claude receives the skill prompt + $ARGUMENTS.                  │
│  The prompt instructs Claude to:                                 │
│                                                                  │
│  1. load → game state                                             │
│  2. read_script → adventure script                                │
│  3. Find the current scene                                       │
│  4. Semantically match the player's input to an action           │
│  5. Apply effects (health, inventory, flags, scene change)       │
│  6. save → updated state                                          │
│  7. Render the new scene with ASCII art and options              │
│                                                                  │
│  No game logic code runs. Claude IS the game engine.             │
└───────────────────────────┬────────────────────────────────────┘
                            │ MCP (stdio)
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                   MCP Server (mcp/server.mjs)                     │
│                   Dumb I/O — no game logic                        │
│                                                                  │
│  load / save                    →  .claude/dungeon.local.md      │
│  read_script                    →  scripts/<name>.md             │
│  list_scripts                   →  scripts/*.md frontmatter      │
│  read_assets                    →  assets/ascii-art.md           │
│  delete_save                    →  rm .claude/dungeon.local.md   │
└───────┬───────────────────────────────┬──────────────────────────┘
        │                               │
        ▼                               ▼
┌───────────────────┐     ┌──────────────────────────────┐
│  Game State        │     │  Adventure Script             │
│  .claude/          │     │  scripts/<name>.md            │
│  dungeon.local.md  │     │                              │
│                    │     │  ## Scene: entrance           │
│  ---               │     │  [narration, ASCII art]       │
│  script: classic.. │     │                              │
│  scene: goblin-rm  │     │  #### Action: fight           │
│  turn: 3           │     │  - matches: ["fight", ...]    │
│  health: 75        │     │  - requires_item: rusty_sword │
│  inventory: [..]   │     │  - health_change: -25         │
│  flags: {..}       │     │  - next_scene: fork           │
│  ---               │     │  - narration: "You swing..."  │
│                    │     │                              │
│  # Adventure Log   │     │  ## Scene: fork               │
│  Turn 1: Entered.. │     │  ...                          │
│  Turn 2: Fought..  │     │                              │
└────────────────────┘     └──────────────────────────────┘
```

### Data Flow Per Turn

```
Player                 Claude (via SKILL.md)              MCP Server
  │                          │                               │
  │  /dungeon attack goblin  │                               │
  ├─────────────────────────►│                               │
  │                          │  load                          │
  │                          ├──────────────────────────────►│
  │                          │◄──────────────────────────────┤
  │                          │                               │
  │                          │  read_script                   │
  │                          ├──────────────────────────────►│
  │                          │◄──────────────────────────────┤
  │                          │                               │
  │                          │  [semantic match: "attack     │
  │                          │   goblin" → Action: fight]    │
  │                          │                               │
  │                          │  [check: has rusty_sword? ✓]  │
  │                          │  [apply: health -25]          │
  │                          │  [apply: next_scene = fork]   │
  │                          │                               │
  │                          │  save                          │
  │                          ├──────────────────────────────►│
  │                          │                               │
  │  Scene: The Forking Path │                               │
  │  HP: [██████░░░░] 75/100 │                               │
  │  "The corridor splits.." │                               │
  │◄─────────────────────────┤                               │
```

---

## DES-001: No Code, Only Prompts

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** The game engine is a prompt, not a program

### Design

The entire game engine is a single SKILL.md file containing instructions that Claude follows. No TypeScript, no Python, no WASM. Claude reads structured adventure scripts (markdown with YAML-like action definitions), manages state by reading/writing a markdown file, and narrates the game.

### Why

- **Simplicity:** A plugin with zero runtime dependencies. No build step, no package.json, no virtual environments.
- **Leverage:** Claude is already excellent at interpreting natural language, following structured instructions, narrating stories, and reading/writing files. These are exactly the skills a text adventure engine needs.
- **Portability:** Works anywhere Claude Code works. No platform-specific binaries.
- **Hackability:** Anyone who can write markdown can create a new adventure. The barrier to content creation is as low as possible.

### Trade-offs Accepted

- **Non-determinism:** Claude may interpret edge cases differently across runs. A traditional parser would be deterministic. We accept this because the semantic matching UX (say anything natural) is worth the occasional inconsistency.
- **No computed state:** Can't do complex math, random number generation, or procedural generation. All content is pre-authored in scripts. This is fine for a static demo — the scripts ARE the game.
- **Token cost:** Each turn requires Claude to read the full game state + relevant script section. This is a few thousand tokens per turn — acceptable for a game played at human pace.

---

## DES-002: Plugin Architecture — Skill, Not Command

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** How the game engine registers with Claude Code

### Design

The game engine is an **Agent Skill** at `skills/dungeon/SKILL.md`, not a command in `commands/`. The plugin name in `plugin.json` is `dungeon`. Users invoke it as `/dungeon`.

### Prior Approach (Abandoned)

Initially designed with a `commands` array in `plugin.json`:

```json
{
  "commands": [
    { "name": "dungeon", "path": "commands/d.md" },
    { "name": "d", "path": "commands/d.md" }
  ]
}
```

This was based on incorrect assumptions about the plugin manifest schema. The `commands` array is not a valid `plugin.json` field. Claude Code discovers components by **convention from directory structure**, not by manifest declaration.

### What We Learned

From the [official plugin docs](https://code.claude.com/docs/en/plugins) and examining existing plugins (prfaq, biff, commit-commands):

1. **`plugin.json`** only contains `name`, `description`, `version`, `author`. No component declarations.
2. **`commands/`** files auto-discover as `/plugin-name:command-name` (namespaced).
3. **`skills/<name>/SKILL.md`** auto-discovers as `/plugin-name:skill-name`.
4. When the skill folder name **matches the plugin name**, it registers as just `/plugin-name` (no duplication). This is how `/prfaq` works — the plugin is named `prfaq` and the skill is in `skills/prfaq/`.

### Why Skill Over Command

- A skill named `dungeon` in a plugin named `dungeon` registers as `/dungeon` — clean, no namespace prefix.
- Skills support `$ARGUMENTS` for capturing player input.
- Skills have YAML frontmatter with a `description` field that helps Claude auto-invoke them in context.

### `/d` Shorthand

**Status:** REVISITED — original conclusion was wrong.

The plan originally called for both `/d` and `/dungeon`. The original analysis assumed `/d` was impossible within the plugin, but playtest showed `Unknown skill: d` when a player tried it — `/d` is expected UX for a game. A custom command within the plugin should map `/d` to `/dungeon`. See issue `claude-dungeon-45w`.

---

## DES-003: Game State Format — YAML Frontmatter in Markdown

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** How game state is stored between turns

### Design

Game state lives at `.claude/dungeon.local.md`. The `.local.md` extension is a Claude Code convention for files that are gitignored. The file has two parts:

1. **YAML frontmatter** — structured state (script, scene, turn, health, inventory, flags)
2. **Markdown body** — human-readable adventure log

```markdown
---
script: classic-fantasy-dungeon
scene: fork
turn: 5
health: 75
max_health: 100
inventory: [rusty_sword, health_potion]
flags: {read_sign: true}
---

# Adventure Log

*A new adventure begins...*

Turn 1: Picked up the rusty sword at the dungeon entrance.
Turn 2: Sneaked past the goblins undetected.
...
```

### Why This Format

- **Claude can parse it.** YAML frontmatter in markdown is a format Claude encounters constantly. No custom parser needed.
- **Human-readable.** A player can open the file and see their exact state. Debugging is trivial.
- **The adventure log is a feature.** Players get a narrative record of their playthrough. This costs almost nothing to maintain (Claude appends one line per turn) and adds flavor.

### Rejected: JSON State File

A `.json` file would be more precisely structured but loses the adventure log narrative and is less pleasant to read. Since Claude is both the reader and writer, markdown with frontmatter plays to its strengths.

---

## DES-004: Adventure Script Format — Structured Markdown

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** How adventure content is authored

### Design

Each adventure script is a self-contained markdown file in `scripts/`. Structure:

- **YAML frontmatter:** `title`, `description`, `author`, `starting_scene`
- **`## Scene: <id>` sections:** Each scene has narration text, optional ASCII art, and one or more actions
- **`#### Action: <id>` subsections:** Each action has `matches` (semantic match phrases), optional conditions (`requires_item`, `requires_flag`), effects (`add_item`, `remove_item`, `set_flag`, `health_change`, `next_scene`), and `narration`

### Semantic Action Matching

The key UX decision: actions have `matches: ["fight", "attack", "swing sword"]` as **examples**, not an exhaustive list. Claude is instructed to use semantic matching — "I hit it with my axe" should match an action with `matches: ["fight", "attack"]` because the intent is clearly combat.

This is the fundamental advantage over traditional text adventure parsers. The player never needs to guess the magic verb.

### Why Markdown (Not YAML, JSON, or a DSL)

- **Readable as a document.** Open any script and you can read it like a story. Scene narrations, ASCII art, and action descriptions all render as formatted markdown.
- **Easy to author.** No special tooling. Any text editor works.
- **Claude parses it naturally.** Claude reads markdown all day. The heading hierarchy (`##` for scenes, `####` for actions) gives clear structure without requiring a format parser.

### Trade-off: Loose Structure

The action fields (`matches`, `requires_item`, etc.) look like YAML bullet points but aren't strictly parsed as YAML — Claude interprets them semantically from the markdown. This means a script author could format things slightly differently and Claude would still understand. We accept this flexibility over strict validation because:
1. Scripts are static, authored content — not user input
2. Claude's tolerance for formatting variation is a feature, not a bug
3. Adding a validator would require code, violating DES-001

---

## DES-005: Plugin Installation — Git Clone + Marketplace Registration

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** How users install the plugin

### Design

`install.sh` does three things:
1. **Git clone** the repo to `~/.claude/plugins/local-plugins/plugins/dungeon/`
2. **Register** the plugin in `~/.claude/plugins/local-plugins/.claude-plugin/marketplace.json`
3. **Clear** the plugin cache at `~/.claude/plugins/cache/local/dungeon/`

### Prior Approach (Abandoned)

Initial installer used `curl` to download individual files from `raw.githubusercontent.com`:

```bash
curl -fsSL "$BASE_URL/commands/d.md" -o "$PLUGIN_DIR/commands/d.md"
```

This was naive — it put files in the wrong directory (`~/.claude/plugins/claude-dungeon/` instead of the local-plugins structure), didn't register in the marketplace, and didn't handle updates.

### What We Learned From prfaq

The prfaq installer established the pattern:
- Install path: `$HOME/.claude/plugins/local-plugins/plugins/<name>/`
- Marketplace: `$HOME/.claude/plugins/local-plugins/.claude-plugin/marketplace.json`
- Use `git clone` for initial install, `git pull` for updates
- Resolve latest release tag via `git ls-remote --tags`
- Clear cache after install so changes are picked up
- For development: `ln -sf /path/to/repo ~/.claude/plugins/local-plugins/plugins/<name>` (symlink mode)

---

## DES-006: Three Bundled Adventures

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** Which adventures to include in the demo

### Design

Three scripts that demonstrate different mechanics:

| Script | Theme | Key Mechanic | Scenes |
|--------|-------|--------------|--------|
| `classic-fantasy-dungeon.md` | D&D dungeon crawl | Branching paths, inventory gating, boss fight | ~10 |
| `unix-catacombs.md` | UNIX system internals | Meta-humor, technical puzzles, process combat | ~8 |
| `haunted-library.md` | Gothic horror | Noise/stealth mechanic, NPC relationship, moral choice | ~8 |

### Why These Three

- **Classic Fantasy** is the control — proves the engine works for traditional text adventure gameplay (combat, inventory, exploration).
- **UNIX Catacombs** targets the audience — developers using Claude Code. The meta-humor (fighting segfaults, seeking root access) demonstrates that scripts can be tailored to specific communities.
- **Haunted Library** shows advanced mechanics — the noise tracking system (quiet → moderate → loud → ghost appears) proves that the engine supports stateful mechanics beyond simple inventory checks. The moral ending (free Eleanor or become the new keeper) demonstrates branching narrative consequences.

### Adding New Adventures

Adding a new adventure requires only creating a new `.md` file in `scripts/` following the established format. No code changes, no registration, no build step. The game engine discovers scripts by reading the `scripts/` directory.

---

## DES-007: Plugin Enablement — Three-Step Activation

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** Why a newly installed plugin doesn't appear after restart

### The Problem

After symlinking the plugin to `~/.claude/plugins/local-plugins/plugins/dungeon/` and adding its marketplace entry, `/dungeon` did not appear in the available skills list after restarting Claude Code.

### Root Cause

Plugin activation requires **three** steps, not two:

1. **Plugin files** exist at `~/.claude/plugins/local-plugins/plugins/<name>/` (symlink or git clone)
2. **Marketplace entry** in `~/.claude/plugins/local-plugins/.claude-plugin/marketplace.json`
3. **`enabledPlugins` entry** in `~/.claude/settings.json`: `"dungeon@local": true`

Step 3 was missing. The marketplace makes the plugin *discoverable*, but `enabledPlugins` is the actual on/off switch. Without it, Claude Code sees the plugin but doesn't load it.

### The Fix

Added `"dungeon@local": true` to the `enabledPlugins` map in `~/.claude/settings.json`. Plugin appeared on next restart.

### Implication for install.sh

The installer currently handles steps 1 and 2 but not step 3. Modifying `settings.json` programmatically is risky (it contains permissions, hooks, and other user config). For now, the installer should document the manual step. A future improvement could use `jq` to add the enabledPlugins entry if not present.

---

## DES-008: MCP Server for Non-Intrusive Game I/O

**Date:** 2026-02-16
**Status:** SETTLED
**Topic:** Replacing Read/Write tools with a dedicated MCP server for game state

### The Problem

Playtest revealed that using Claude Code's generic `Write` tool for game state is intrusive. Every save triggers a permission prompt and displays the full file content in the UI. For a game that saves every turn, this destroys immersion — the player sees tool approval dialogs instead of game narration.

The `Read` tool is less disruptive but still displays file contents in collapsible tool-use blocks that clutter the game output.

### Design

A Node.js MCP server (`mcp/server.mjs`) exposes six tools for all game I/O:

| Tool | Purpose |
|------|---------|
| `load` | Read game state (returns content or `"NO_SAVE_FILE"`) |
| `save` | Write game state (full content as input) |
| `delete_save` | Delete save file (for new game) |
| `read_script` | Read adventure script by name |
| `list_scripts` | List available scripts with metadata |
| `read_assets` | Read shared ASCII art |

The server uses `@modelcontextprotocol/sdk` with stdio transport. Claude Code spawns it as a subprocess and communicates via JSON-RPC over stdin/stdout.

### Path Resolution

- **State file:** `process.cwd() + "/.claude/dungeon.local.md"` — resolves relative to the project where Claude Code is running, so each project gets its own save.
- **Scripts and assets:** Resolved relative to `import.meta.url` → the plugin installation directory. This works whether the plugin is git-cloned or symlinked for development.

### Why MCP (Not Hooks, Not a Custom Tool)

- **MCP tools execute silently.** No permission prompts, no file content displayed in UI. The player sees only game narration.
- **Scoped access.** The server only touches game files — it can't read arbitrary files or execute commands. This is safer than granting broad Write permissions.
- **Plugin-native.** Claude Code's `.mcp.json` in a plugin is the standard way to add tools. No hacks, no workarounds.

### Trade-off: DES-001 Tension

DES-001 says "no code, only prompts." This MCP server is ~90 lines of JavaScript. We accept this because:

1. **The game logic is still entirely in the prompt.** The MCP server is dumb I/O — it reads files, writes files, lists directories. Zero game logic.
2. **The alternative (Write tool prompts every turn) makes the game unplayable.** DES-001's spirit is simplicity and leverage; requiring players to approve file writes every turn is neither simple nor leveraging Claude Code well.
3. **The dependency is minimal.** Node.js + one npm package. The installer checks for `node` and warns if missing.

### What Changed

- `SKILL.md` now references `load`, `save`, etc. instead of Read/Write tools
- `plugin.json` registers the MCP server inline via `mcpServers` field
- `install.sh` runs `npm install` in `mcp/` after cloning

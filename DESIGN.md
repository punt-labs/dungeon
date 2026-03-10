# Claude Dungeon Design Decision Log

This file is the authoritative record of design decisions, prior approaches, and their outcomes. **Every design change must be logged here before implementation.**

## Rules

1. Before proposing ANY design change, consult this log for prior decisions on the same topic.
2. Do not revisit a settled decision without new evidence.
3. Log the decision, alternatives considered, and outcome.

---

## System Architecture

### Original Architecture (DES-001 through DES-008)

The initial system is a pure-prompt text adventure — Claude is the parser, rules engine,
narrator, and state machine. The architecture below reflects this baseline. DES-009 onward
documents the evolution to a proper engine with a Go core, Lux display, and three play modes.

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
**Status:** SUPERSEDED by DES-009
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
**Status:** SUPERSEDED by DES-017
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
**Status:** SUPERSEDED by DES-016
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
**Status:** SUPERSEDED by DES-009
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

---

## Evolved Architecture (DES-009 onward)

```text
┌───────────────────────────────────────────────────────────────────────────┐
│                           PLAY MODES                                      │
│                                                                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐  │
│  │  dm             │  │  solo           │  │  headless               │  │
│  │  ─────────────  │  │  ─────────────  │  │  ──────────────────────  │  │
│  │  Interpreter:   │  │  Interpreter:   │  │  Interpreter:           │  │
│  │    LLM (Claude) │  │    SLM (ollama) │  │    SLM or rules-based   │  │
│  │  Narrator:      │  │  Narrator:      │  │  Narrator:              │  │
│  │    LLM (Claude) │  │    SLM (ollama) │  │    template             │  │
│  │  Renderer:      │  │  Renderer:      │  │  Renderer:              │  │
│  │    Lux          │  │    Lux or CLI   │  │    CLI / stdout         │  │
│  │  Engine:        │  │  Engine:        │  │  Engine:                │  │
│  │    daemon       │  │    embedded     │  │    embedded             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
        │ dm mode                                 │ solo / headless
        ▼                                         ▼
┌─────────────────────────┐     ┌──────────────────────────────────────────┐
│  mcp-proxy (per session)│     │  Engine in-process (embedded)            │
│  <10ms, <10MB Go shim   │     │  No daemon, no proxy, no network         │
│  injects session identity     └──────────────────────────────────────────┘
└────────────┬────────────┘
             │ WebSocket / NDJSON Unix socket
             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  GAME ENGINE DAEMON  (dungeon serve)                    │
│  ─────────────────────────────────────────────────────────────────────  │
│  GameState · Character · DungeonMap · Combat · Inventory · Save/Load    │
│  Session-aware: knows which connection is DM vs. player                 │
│  Push: tools/list_changed to DM when player acts                        │
│  Deterministic. No LLM calls. No orchestration.                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                              reads/writes
                                    ▼
                    ┌───────────────────────────┐
                    │  .dungeon/                │
                    │  ├── saves/<slot>.json    │
                    │  └── scenarios/<n>.yaml   │
                    └───────────────────────────┘
```

---

## DES-009: Architecture Evolution — LLM as DM, Go Engine as L1

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** Replacing the pure-prompt engine with a proper separation of concerns
**Supersedes:** DES-001, DES-008

### Design

Separate the game into bounded layers by responsibility:

- **L4 — LLM (Claude):** Dungeon Master. Narrates rooms and events, generates scenario
  YAML before play starts, interprets free-text commands, provides item lore on examine.
  Does not enforce rules or manage state — it calls engine tools and narrates their results.
- **L1 — Go engine:** Deterministic rules. State transitions, combat resolution, inventory
  limits, fog-of-war, save/load. Exposes a stable MCP tool interface. No LLM calls.
- **L1 — Lux:** Display surface. Native ImGui window rendering map canvas, HP bars, combat
  UI, narration log. Driven by the engine via Lux MCP tools.

The Node.js MCP server (DES-008) is replaced by the Go engine. The SKILL.md prompt is
rewritten: instead of being the rules engine, it is now the DM.

### Why

**DES-001 ("no code, only prompts") served its purpose as a prototype.** The pure-prompt
approach validated that Claude can run a text adventure engine. Its known trade-offs — listed
explicitly in DES-001 — become unacceptable for a real game:

- **Non-determinism** means rules enforcement is probabilistic. A player can die
  inconsistently, items behave differently across runs, conditions don't resolve reliably.
- **No computed state** means no dice rolls, no XP curves, no real combat math.
- **Token cost per turn** compounds as adventures grow — the full state + script must be
  re-read every turn.
- **No multi-player path** — there is no way to add a second player to a pure-prompt
  architecture without a shared state store and a proper game loop.

The LLM's actual strengths are narrative generation, semantic command parsing, and creative
world-building — none of which require it to be a rules engine. Moving rules to Go gives
both determinism and performance; leaving narration with the LLM gives richness no
rules-based system can match.

### Rejected: Keeping Pure Prompts, Adding State Store

An intermediate design would keep the SKILL.md engine but replace the markdown save file
with a proper JSON state store and add a dice-rolling MCP tool. This was rejected because:

1. Rules are still enforced by prompting, not code — non-determinism remains.
2. Complex combat (initiative, conditions, multiple enemies) requires many tool calls per
   turn with a prompt-based engine, each a round-trip.
3. Multi-player is still impossible without a true game loop outside the LLM.

### Rejected: Python Engine

Python is the Punt Labs standard for CLI/MCP tools. However, for a game engine:

1. The Go binary embeds the SLM call path (ollama) for solo mode — keeping it all in one
   compiled binary simplifies distribution and avoids Python startup overhead.
2. Go produces a single static binary for macOS/Linux. Python requires a runtime, uv,
   and a virtual environment.
3. The mcp-proxy project (the daemon transport layer) is already Go — shared idioms.

Python remains the language for any thin adapters or CLI wrappers needed at the plugin layer.

---

## DES-010: Play Mode as First-Class Concept

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** How the game accommodates LLM, SLM, and headless operation

### Design

A **play mode** is a named combination of three interface implementations. All modes use
the same engine, the same save files, and the same scenario format. Switching modes
mid-adventure is valid.

| Mode | Interpreter | Narrator | Renderer | Engine deployment |
|---|---|---|---|---|
| `dm` | LLM (Claude) | LLM (Claude) | Lux | daemon |
| `solo` | SLM (ollama) | SLM (ollama) | Lux or CLI | embedded |
| `headless` | SLM or rules | template | CLI / stdout | embedded |

The mode is recorded in the save file (`"play_mode"`) as advisory context for the next
session. A `--mode` override on resume is always accepted.

### Why Play Mode, Not Fallback

The SLM path was initially considered a fallback for when the DM (LLM) is unavailable.
This framing was rejected because it implies the SLM mode is degraded — it is not. It is
a different, fully intentional way to play:

- `dm` mode: rich, generative, requires Claude Code session
- `solo` mode: fast, offline-capable, SLM generates atmospheric narration
- `headless` mode: scriptable, SSH-friendly, minimal output

Designing SLM as a fallback would have deferred its interface design to Phase 2, creating
a risk that the engine API would be shaped only for the LLM path. Building all three modes
in Phase 1 forces the engine API to be neutral.

### Rejected: Single "DM Optional" Flag

An earlier sketch had a single `--no-dm` flag that switched from LLM to template narration.
This collapsed `solo` and `headless` into one mode, omitting SLM narration entirely.
Rejected because SLM narration for solo play is qualitatively different from template
strings — worth exposing as a distinct mode.

---

## DES-011: Three Engine Interfaces

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** How the engine decouples from LLMs, SLMs, and display

### Design

Three Go interfaces that the engine calls, never implements:

```go
type CommandInterpreter interface {
    Interpret(ctx context.Context, input string, state GameState) (Action, error)
}

type Narrator interface {
    Narrate(ctx context.Context, event GameEvent, state GameState) (string, error)
}

type Renderer interface {
    Show(scene Scene) error
    Update(patches []Patch) error
    RecvInput(timeout time.Duration) (Input, bool)
}
```

Implementations:

| Interface | `dm` | `solo` | `headless` |
|---|---|---|---|
| `CommandInterpreter` | `LLMInterpreter` | `SLMInterpreter` | `RulesInterpreter` |
| `Narrator` | `LLMNarrator` | `SLMNarrator` | `TemplateNarrator` |
| `Renderer` | `LuxRenderer` | `LuxRenderer` or `CLIRenderer` | `CLIRenderer` |

### Why Three Separate Interfaces (Not One)

The three concerns have different call frequency and latency budgets:

- `CommandInterpreter` is called only on free-text input (infrequent, high latency OK)
- `Narrator` is called after each state-changing event (moderate frequency)
- `Renderer` is called after every state change, including button-driven ones
  (high frequency — must be non-blocking for LuxRenderer)

Combining them into one interface would force every implementation to satisfy all three
contracts, coupling concerns that are independently replaceable.

---

## DES-012: Engine Implementation Language — Go

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** Language choice for the game engine binary

### Design

The game engine (state machine, combat resolver, map, inventory, save/load, daemon transport)
is written in Go. It is distributed as a compiled static binary per platform.

### Why Go

- **Single static binary.** No runtime, no package manager, no virtual environment. The
  binary ships with the plugin and `install.sh` places it on PATH.
- **Performance.** Combat simulation, dice rolls, and map operations are trivially fast in
  Go. No per-invocation startup cost when running as a daemon.
- **mcp-proxy alignment.** The transport layer (`dungeon serve` daemon) shares idioms and
  potentially code with the mcp-proxy project, which is also Go.
- **Concurrency model.** Go goroutines handle multiple simultaneous player connections
  (Biff multi-player extension) cleanly without callback hell.

### Rejected: Python

See DES-009 rejected alternatives. Python startup cost (~300ms) rules it out for the
embedded solo path. Static binary distribution is simpler.

### Rejected: Node.js

The existing Node.js MCP server (DES-008) handles file I/O well but is not suited for
a game engine. Node.js startup (~100ms) and per-session memory (~30MB) are acceptable
costs for a file I/O shim but not for a persistent game daemon. No static binary.

### Accepted: Go MCP SDK

`github.com/mark3labs/mcp-go` for the MCP server surface in daemon mode. Minimal stdio
JSON-RPC is an acceptable alternative if the SDK proves too heavy.

---

## DES-013: Engine Deployment — Daemon vs. Embedded

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** Whether the engine runs as a daemon or embedded in the CLI process

### Design

Two deployment modes, selected by play mode:

- **Daemon mode** (`dm`, future multi-player): `dungeon serve` starts a persistent background
  process. The engine holds all game state, accepts connections from mcp-proxy shims (one
  per Claude Code session), and can push events to specific sessions. Auto-start option:
  if the daemon is not running when `dungeon dm` is invoked, start it automatically.

- **Embedded mode** (`solo`, `headless`): The engine runs in-process as part of the CLI
  binary. No network, no IPC. The SLMInterpreter/SLMNarrator call ollama over localhost
  HTTP, but the engine itself is in-process.

The engine code is identical in both deployments. The daemon adds a connection handler and
session-aware push routing on top.

### Why Not Always a Daemon

The beads project (Go CLI, 92.9% Go) deleted their daemon in v0.51.0 after it accumulated
~70K lines. Their lesson: "Keep it small." Running the engine embedded for solo/headless
avoids all the complexity of daemon lifecycle management (auto-start, liveness, cleanup)
for the common single-player case.

The daemon is only justified when its unique capabilities are needed: shared state across
multiple connections (multi-player) and server push to specific sessions (DM notification
on player action). Solo mode needs neither.

### Daemon Transport: NDJSON over Unix Domain Socket

Following SageOx's pattern: newline-delimited JSON over a Unix domain socket. Chosen over
WebSocket for the daemon-to-proxy leg because:

- No third-party Go dependency (stdlib `net.Listen("unix", ...)`)
- Debuggable: `echo '{"type":"ping"}' | socat - UNIX:/path/sock`
- Local-only: no port conflicts, owner-only socket permissions (mode 0600)

The mcp-proxy README leans toward WebSocket for the proxy-to-daemon transport to gain
built-in keepalive and framing (RFC 6455). When mcp-proxy ships, the daemon transport
will align with whatever the proxy implements.

### Daemon Scope

The daemon does exactly two things:

1. Game logic resolution (state transitions, combat, inventory)
2. Session-aware push routing (`tools/list_changed` to DM when player acts)

No LLM calls. No SLM calls. No orchestration. No business logic beyond the game rules.
The beads lesson is taken seriously.

---

## DES-014: mcp-proxy for DM Mode Session Multiplexing

**Date:** 2026-03-10
**Status:** OPEN — depends on mcp-proxy shipping
**Topic:** How Claude Code sessions connect to the shared game engine daemon

### Design

In `dm` mode, each Claude Code session (DM or future player) spawns `mcp-proxy` as its
MCP server instead of the game engine binary directly. The proxy is a near-zero-cost Go shim
(<10ms, <10MB) that:

1. Resolves session identity: walks the process tree to find the topmost `claude` ancestor
   PID and sends `{"type": "register", "session_key": "19147", "pid": 83201}` to the daemon
2. Forwards all MCP JSON-RPC between the Claude session and the daemon unchanged
3. Maintains a persistent bidirectional connection enabling server push

The daemon uses session identity to:
- Scope tool visibility: DM session sees DM-privileged tools, player sessions see
  player-scoped tools
- Route push notifications: `tools/list_changed` to the DM session when a player acts

```text
DM Claude Code ←──── stdio ────► mcp-proxy ──► dungeon daemon
 (SKILL.md)                      session: 19147     │
                                                    │ (future multi-player)
Player Claude Code ←── stdio ──► mcp-proxy ─────────┘
                                 session: 28305
```

### Why mcp-proxy (Not Direct stdio to Daemon)

Claude Code can only spawn one MCP server process per registered server. Without a proxy,
the DM's Claude session owns the daemon process — a second connection (second player) is
impossible.

The proxy pattern (one shim per session, one shared daemon) is also how Quarry, Biff, Vox,
and Lux are heading. The dungeon engine follows the same pattern rather than inventing a
bespoke multi-client solution.

### Status: OPEN

The mcp-proxy binary does not yet exist — the project is design-stage only. DM mode Phase 2
can start with direct stdio MCP (single-session only, no push routing) and migrate to the
proxy pattern when mcp-proxy ships. The engine daemon API is identical either way — the
transport layer changes, not the tool interface.

### Rejected: HTTP Long-Polling for Multi-Player

A simpler multi-player sketch had each player poll an HTTP endpoint for game state changes.
Rejected because:
- Polling latency (typically 1-5s) is unacceptable for a turn-based game where the DM's
  narration should appear promptly after a player acts
- The push-on-state-change model (daemon → proxy → Claude session) is far cleaner
- HTTP long-polling reimplements a fraction of what persistent connections give for free

---

## DES-015: SLM Integration — ollama over localhost HTTP

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** How the solo mode SLM is invoked

### Design

`SLMInterpreter` and `SLMNarrator` call a locally-running ollama instance via its HTTP API
(`http://localhost:11434/api/generate`). The model (default: phi-3-mini) must be pulled by
the user before solo mode works. `dungeon doctor` checks for ollama and model availability.

The system prompt for `SLMInterpreter` is compact: map free-text input to one of a fixed
set of structured actions (`{action: "move", direction: "north"}`, etc.). The output schema
is validated by the engine; malformed responses fall through to `RulesInterpreter`.

`SLMNarrator` receives the room description seed from the scenario YAML plus the event
(entered room, picked up item, defeated enemy) and generates 2-4 sentences of atmospheric
narration.

### Why ollama (Not Embedded llama.cpp)

- **No CGo.** Embedding llama.cpp via CGo makes the Go build dramatically more complex:
  cross-compilation is nearly impossible, build times increase, the binary grows by hundreds
  of MB.
- **User model management.** Players may already have ollama installed with a preferred
  model. Not re-packaging what the ecosystem already provides.
- **Swappable.** ollama's API supports any model it hosts — players can substitute
  mistral-7b or smolLM without recompiling the engine.

### Rejected: OpenAI-Compatible Local Servers (LM Studio, llama.cpp server)

ollama is the de facto standard for local model serving on macOS. Supporting only ollama
keeps the integration simple. A future `--slm-endpoint` flag could generalize this.

### Graceful Degradation

If ollama is not running or the model is unavailable, `SLMInterpreter` falls back to
`RulesInterpreter` and `SLMNarrator` falls back to `TemplateNarrator` with a one-time
warning. Solo mode is playable without SLM; it just loses atmospheric narration.

---

## DES-016: Scenario Format — YAML

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** How adventure content is defined
**Supersedes:** DES-004

### Design

Each scenario is a `.yaml` file in `scenarios/` (previously `scripts/`). The schema
defines rooms, connections, items, encounters, loot tables, and character class availability.
Existing `.md` scripts are migrated; a compatibility shim reads old formats during transition.

```yaml
scenario:
  title: "The Depths of Grimhold"
  starting_room: entrance
  death: respawn      # permadeath | respawn

rooms:
  entrance:
    name: "Dungeon Entrance"
    description_seed: "Crumbling stone arch. Torchlight flickers."
    connections:
      north: {room: corridor_a, type: open}
      down:  {room: level_2,   type: stairway}
    items: [{id: torch, quantity: 2}]
    encounter: null

items:
  rusty_sword: {name: "Rusty Sword", type: weapon, damage: 1d6, weight: 3, value: 5}
```

The `description_seed` field is a brief prompt seed; the DM (LLM) expands it into full
narration. The SLMNarrator uses it directly as a generation seed. The TemplateNarrator
uses it verbatim.

### Why YAML (Not Structured Markdown, Not JSON)

DES-004 chose structured markdown because "Claude reads it naturally." With a Go engine,
the engine — not Claude — parses scenarios. The engine needs structured, machine-parseable
data. YAML is:

- More readable than JSON for humans authoring content (no quoting everything)
- Strictly parseable by Go's `gopkg.in/yaml.v3`
- Already the format used by scenario frontmatter in the old markdown scripts

### Rejected: Keep Structured Markdown

Markdown with embedded action blocks (the DES-004 format) works when Claude is both reader
and enforcer. Once a Go engine parses the scenario, markdown's loose structure becomes a
liability — the engine needs deterministic field parsing, not semantic interpretation.

---

## DES-017: Save File Format — JSON

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** How game state is persisted between sessions
**Supersedes:** DES-003

### Design

Game state is saved as `.dungeon/saves/<slot>.json`. The Go engine serializes/deserializes
using `encoding/json`. The file contains character state, dungeon progress (visited rooms,
room-level state), and the adventure log as a JSON array.

```json
{
  "schema_version": "1.0",
  "play_mode": "dm",
  "scenario": "grimhold",
  "timestamp": "2026-03-10T18:00:00Z",
  "character": {
    "name": "Aldric", "class": "fighter", "level": 3,
    "hp": 45, "max_hp": 60, "xp": 1240, "gold": 48,
    "inventory": [], "equipped": {"weapon": "rusty_sword"}, "conditions": []
  },
  "party": [],
  "dungeon": {
    "current_room": "goblin_lair",
    "visited_rooms": ["entrance", "corridor_a", "goblin_lair"],
    "room_state": {"goblin_lair": {"cleared": true}}
  },
  "adventure_log": []
}
```

`party` is present but empty for single-player. `play_mode` is advisory — `--mode` on
resume overrides it. Multiple named slots are supported; default slot is `"autosave"`.

### Why JSON (Not YAML Frontmatter Markdown)

DES-003 chose YAML frontmatter in markdown because "Claude can parse it." With a Go engine,
the engine — not Claude — reads and writes saves. JSON is:

- The natural serialization format for Go structs (`encoding/json` is stdlib)
- Schema-versionable: `schema_version` field enables migration logic
- Easier to diff in git (if a player commits their save) than YAML

The adventure log loses its narrative markdown rendering and becomes a JSON array of
strings. This is an acceptable trade — the log is visible in the Lux narration panel
during play regardless.

### Rejected: SQLite

SQLite would handle concurrent writes (Biff multi-player) better. Rejected for Phase 1
because single-player has no concurrent writers. JSON files are trivially readable,
debuggable, and portable. Revisit if Biff multi-player requires write contention handling.

---

## DES-018: Lux as Primary Display Surface

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** How the game is rendered to the player

### Design

The `LuxRenderer` calls Lux MCP tools (`show`, `update`, `recv`) to maintain a persistent
native ImGui window alongside the Claude Code terminal. The window layout uses multiple
floating `window` elements:

- Map canvas (`draw` element): grid rooms, corridors, fog of war, player position
- Stats panel: HP/MP progress bars, class, level, XP
- Navigation buttons: directional exits as Lux `button` elements (no LLM round-trip)
- Narration log: scrolling `markdown` element
- Combat panel (when active): enemy HP bars, action buttons (Attack, Defend, Item, Flee)

`show()` is called on scene transitions (new room, enter/exit combat). `update()` is called
for incremental changes (HP change, log entry, fog reveal). Navigation and combat buttons
feed directly to the engine via `recv()` — no LLM round-trip for mechanical actions.

### Why Lux (Not ASCII Art in Terminal, Not a Web UI)

- **Persistent, live state.** The map and HP bars update in real time without the narration
  terminal being cluttered. A terminal renderer would require re-printing the full state
  after every action.
- **Native performance.** ImGui at 60fps means the UI never lags even during engine
  computation. No HTML rendering pipeline.
- **Separation of concerns.** The LLM narrates in the Claude Code terminal; the engine
  state is visible in Lux. Players don't have to scroll back through narration to check HP.
- **Already installed.** Lux is a Punt Labs building block. Players using the Punt Labs
  ecosystem likely have it; it ships as a dependency via `install.sh`.

### CLIRenderer as Fallback

`CLIRenderer` (ANSI terminal) is implemented for `headless` mode and as a fallback when
Lux is not available. The `LuxRenderer` checks liveness with `ping()` on startup and falls
back to `CLIRenderer` automatically.

---

## DES-019: Hybrid Input Model

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** How player input reaches the engine

### Design

Two input paths, selected by action type:

- **Structured actions (navigation, combat):** Lux buttons. Player clicks `[↑ North]` or
  `[⚔ Attack]`. The engine receives the action directly via `recv()` on the `LuxRenderer`.
  No LLM involvement. Latency: ~50ms (Lux round-trip).

- **Free text (exploration, interaction, conversation):** Player types in the Claude Code
  terminal. The `CommandInterpreter` parses intent and calls the corresponding engine tool.
  `LLMInterpreter` in `dm` mode: Claude interprets "I search the walls for a hidden door"
  and calls `engine.search("walls", hint="secret door")`. Latency: ~3-5s (LLM round-trip).

In `solo` mode, free text goes to `SLMInterpreter`. In `headless`, to `RulesInterpreter`.

### Why Hybrid (Not All-Buttons, Not All-Text)

- **All-buttons (pure Wizardry):** Removes the richness that makes the LLM DM worth having.
  "Examine the strange inscription" doesn't fit in a button grid. Navigation and combat are
  mechanical enough that buttons are strictly better (faster, no parsing errors).
- **All-text (pure Zork):** Every navigation move requires an LLM round-trip (~3-5s).
  Moving through a dungeon corridor by corridor becomes tedious. Buttons for movement and
  combat preserve pace while keeping free text for the moments that matter.

### Performance Implication

Navigation button → engine → Lux update: ~50ms total. The LLM is not in this path.
This is the critical performance boundary: a game that requires LLM confirmation for
every step is not playable at human pace.

---

## DES-020: Map Pre-Generated by DM Before Play Starts

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** When and how the dungeon map is created

### Design

Before a new game begins, the DM (LLM) generates a complete scenario YAML: all rooms,
connections, encounter specifications, item placements, and loot tables. This is written
to `scenarios/<name>.yaml` and remains static for the duration of the adventure. The
engine loads it once at game start.

The DM generates scenarios interactively via `/dungeon:create`: the player describes the
adventure they want, the DM produces the YAML, and the player reviews it before play begins.

### Why Pre-Generated (Not Procedural Room-by-Room)

- **Consistency.** A room the player visited ten turns ago should look the same when they
  return. Procedural on-the-fly generation cannot guarantee this without caching generated
  content — at which point it is effectively pre-generation with extra steps.
- **Engine simplicity.** The engine loads a fully defined map at startup. No mid-game
  requests to the LLM for new rooms. No risk of inconsistent geometry (a corridor that
  goes north from Room A but south from Room A doesn't connect to Room B properly).
- **DM creative intent.** A pre-generated map lets the DM design a coherent dungeon with
  intentional flow — the difficulty curve, the locked-door/key placement, the boss at the
  end — rather than hoping procedural generation produces something playable.

### Rejected: Procedural Generation on Explore

An early design had the DM generate each new room as the player walked into it. Rejected:

1. ~3-5s latency on every move into unexplored territory is unacceptable
2. Backtracking inconsistency (the DM may generate a different room on re-entry)
3. Global dungeon coherence (keys, locks, quest items) is very hard to maintain without
   seeing the whole map at once

---

## DES-021: Single Player First, Party as Biff Extension

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** Multi-player scope and timing

### Design

Phase 1-4 is single-player: one character, one save file, one Claude Code session (or none
for solo/headless). The engine is designed party-ready from day one:

- `GameState.Party []Character` — always present, length 1 in single-player
- `move`, `attack`, `flee`, `defend` all accept an optional `character_id` parameter
- Combat turn order handles N actors
- Save file has a `party` array

When Biff multi-player is added (Phase 5):
- Each Biff participant controls one character
- Session identity (from mcp-proxy) maps Claude sessions to characters
- `PostToolUse` hook notifies party members of state changes
- DM narrates for the full party
- Turn tokens passed via Biff `/write`

### Why Defer Multi-Player

Building multi-player requires Biff (presence, messaging) and mcp-proxy (session routing),
neither of which are this project's dependencies to implement. Designing the engine as
party-ready costs almost nothing; deferring the Biff integration until those projects are
stable is the correct sequencing.

---

## DES-022: Mechanics Inspiration — Wizardry I and Zork I

**Date:** 2026-03-10
**Status:** SETTLED
**Topic:** Which game mechanics and aesthetic to target

### Design

The game takes mechanical inspiration from two 1981 classics:

**From Wizardry: Proving Grounds of the Mad Overlord (1981):**
- Grid-based dungeon map (20×20 per floor)
- Character classes: Fighter, Mage, Thief, Priest
- Stats: STR, INT, DEX, CON, WIS, CHA
- Turn-based combat with initiative rolls
- Equipment slots: weapon, armor, ring, amulet
- Conditions: poisoned, asleep, paralyzed, confused
- Permadeath option (configurable per scenario)
- XP thresholds and stat-based leveling

**From Zork I (1980):**
- Rich room descriptions with atmosphere
- Free-text command input (implemented via LLM/SLM command interpretation)
- Dark rooms requiring a light source
- Item weight limits
- Puzzle-gated progression (locked doors, hidden passages)
- Witty, flavored narration

### What We Don't Take From Either

- **Wizardry's party of six:** Deferred to Biff multi-player.
- **Wizardry's wireframe 3D view:** The Lux map canvas uses a top-down grid view instead.
- **Zork's maze of twisty passages:** Grid-based map makes this unnecessary and frustrating.
- **Zork's verb-noun parser:** The LLM/SLM handles natural language; no magic verbs.

### Why These Two

Both games define what a dungeon crawl IS for players of a certain era. Choosing them
as reference points gives the design team a shared vocabulary ("this room should feel
Zork-ish") and a known quality bar. Neither is being reproduced — they are taste references.

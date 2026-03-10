# Dungeon — Codebase Review

_Reviewed against punt-kit standards and public-website positioning. March 2026._

---

## What the Project Is

**Claude Dungeon** is a text-adventure game engine that runs entirely inside Claude Code as a
marketplace plugin. There is no application runtime — Claude's natural language understanding _is_
the parser and game engine. The whole engine is a single markdown skill prompt (`skills/dungeon/SKILL.md`).

On the public website, Dungeon is categorized under **Applications** and described as an
_"L4 game engine test bed"_ — meaning it is also a proof-of-concept for using an LLM as an
L4 orchestrator over L1 deterministic tools (the MCP server), validating the
`building-l1-tools-for-l4-agents` architecture pattern.

### Architecture

```
Player types: /dungeon attack the goblin
                    │
              SKILL.md (Claude = the engine)
                    │
        mcp/server.mjs  (dumb I/O only)
       ┌──────┬──────────────┬──────────┐
    recall  inscribe   unfurl_scroll  quest_board
       │                     │
  .claude/dungeon.local.md   scripts/<name>.md
  (YAML frontmatter + log)   (scene + action defs)
```

### Components

| Component | Role |
|---|---|
| `skills/dungeon/SKILL.md` | The game engine — a Claude Code skill prompt |
| `mcp/server.mjs` | Node.js MCP server; 6 pure I/O tools, zero game logic |
| `scripts/*.md` | Three self-contained adventure scripts (markdown + YAML) |
| `.claude/dungeon.local.md` | Live save file (YAML frontmatter + adventure log) |
| `hooks/` | SessionStart (setup/deploy) + PostToolUse (output suppression) |
| `commands/d.md` | `/d` shorthand, deployed to `~/.claude/commands/` by hook |
| `assets/ascii-art.md` | Shared ASCII art (title, game over, victory) |

### Adventure Scripts

| Script | Title | Notable Mechanic |
|---|---|---|
| `classic-fantasy-dungeon.md` | The Depths of Grimhold | Inventory gating, branching paths, dragon boss |
| `unix-catacombs.md` | The UNIX Catacombs | UNIX-flavored meta-humor, navigate pipes, Root Shell |
| `haunted-library.md` | The Haunted Library of Ashworth | `quiet→moderate→loud` noise flag, moral choices |

---

## Compliance Review Against Punt Labs Standards

### ✅ Correct

- **Hooks architecture** — Three-layer dispatch (hooks.json → shell → handler) is present and
  follows the pattern. PostToolUse suppression hook correctly collapses MCP output in the UI.
- **MCP server** — Pure I/O, zero game logic. Correct use of `McpServer` + `StdioServerTransport`.
  ES modules (`.mjs`). Zod schema validation on tool inputs.
- **Plugin structure** — `.claude-plugin/plugin.json` present. MCP server declared via `command`
  field (not `uv run`).
- **Save file convention** — `.claude/dungeon.local.md` uses `.local.md` (gitignored), correct for
  user state files.
- **SessionStart hook** — Installs npm deps, deploys `/d` shorthand, patches
  `~/.claude/settings.json` to auto-allow MCP tools. Migrates stale permissions from the old
  server name.
- **DESIGN.md** — Present at repo root with numbered, reasoned decisions. Design decisions are
  logged.
- **CHANGELOG.md** — Present and follows Keep a Changelog format.
- **markdownlint config** — `.markdownlint.jsonc` and `.markdownlint-cli2.jsonc` both present.
- **GitHub CI** — `docs.yml` present (correct for a plugin-only repo; no Python = no lint/test
  workflows needed).
- **prfaq.tex / prfaq.pdf** — PR/FAQ document present.

---

### ⚠️ Gaps and Defects

#### `install.sh` — Several Required Elements Missing

Per `distribution.md`:

- **No VERSION pin** — `install.sh` must declare `VERSION="X.Y.Z"` and pass
  `--force "$PACKAGE==$VERSION"` to `uv tool install`. Without this, installs are
  non-deterministic and version-downgrade bugs have occurred in production.
- **No `doctor` command** — Every installer must end with `<tool> doctor` to verify the
  installation succeeded. Dungeon has no `doctor` subcommand.
- **No trust tier block in README** — The README must expose all three trust tiers
  (Convenience `curl | sh`, Inspect, Verify with `shasum`).
- **Idempotency** — `install.sh` must be safe to re-run. Not verified.
- **No `install.ps1`** — Every `install.sh` must have a Windows PowerShell companion
  (`$ErrorActionPreference = 'Stop'`). Absent entirely.
- **Stdin protection** — Any `claude` commands inside `install.sh` must use `< /dev/null`
  to prevent silent pipe truncation when running via `curl | sh` (DES-006).

#### `plugin.json` — Missing `version` Field and Dev/Prod Isolation

Per `plugins.md`:

- **`version` field** — `plugin.json` must declare `version`. Omitting it is a defect.
- **Dev/prod namespace isolation** — The working-tree `plugin.json` should use
  `name: "dungeon-dev"` so both dev and prod installations coexist. The `-dev` suffix
  must prefix everything: commands, MCP tools, skills, hooks. This is not yet in place.

#### `mcp/package.json` — Missing `version` Field

Per `node.md`:

- `package.json` must declare `version` matching `plugin.json`. Not verified as present.

#### README — Does Not Follow the Required Structure

Per `readme.md`, the required section order is: Title + Tagline → Badges → Description →
Quick Start → Features (optional) → Commands → Development → License.

Known gaps (to verify):

- **Badges** — Should have License and CI badges in the standard order (max 2 for plugins,
  plus optionally Working Backwards).
- **Quick Start** — Must include a `<details>` block for manual install and a verify step
  (`shasum`).
- **Development section** — Must list quality gate commands matching `CLAUDE.md` exactly
  (`npx markdownlint-cli2 "**/*.md" "#node_modules"`).
- **Forbidden language** — README must not use "Unlock", "Unleash", "Supercharge",
  anthropomorphizing language, or unverifiable value claims. Verify current copy.

#### No `uninstall` Path

Per `distribution.md`:

> Every project with `install` must have `uninstall` that cleans all side effects: deployed
> commands, MCP permissions, marketplace registration, orphaned directories.

No `uninstall.sh` or `claude plugin uninstall` instructions exist.

#### Shell Scripts — No `shellcheck` CI Gate

Per `shell.md`, any repo with `.sh` files must run `shellcheck` in CI. The current `lint.yml`
(if any) or `docs.yml` does not include a `shellcheck` step. A `lint.yml` workflow should be
added for `hooks/*.sh` and `install.sh`.

#### Build Artifacts Committed to Git

`prfaq.aux`, `prfaq.bbl`, `prfaq.bcf`, `prfaq.bib`, `prfaq.blg`, `prfaq.log`, `prfaq.out`,
`prfaq.pdf`, `prfaq.run.xml` are all committed. Per `makefile.md`, the `prfaq` target should
clean intermediate artifacts. The `.pdf` itself is debatable (useful for readers) but the
`.aux`, `.log`, `.blg`, `.bbl`, `.bcf`, `.out`, `.run.xml` files are clearly build artifacts
and should be gitignored.

#### `CLAUDE.md.tmp` Committed

`CLAUDE.md.tmp` appears in the repo root. Scratch/temp files belong in `.tmp/` (gitignored),
not committed.

#### Permissions — `mcp__plugin_dungeon_game__*` Migration in Hook, Not Removed from `settings.json`

The `session-start.sh` hook migrates stale `mcp__plugin_dungeon_game__*` permissions to the
current server name. This implies old permission entries may persist in users'
`~/.claude/settings.json` indefinitely if they never re-run the hook. The migration logic
should be verified to be idempotent and complete.

---

## Positioning Notes

From the public website `projects.json`, Dungeon is listed as:

- **Category**: Applications
- **Stage**: (check current value — should be `alpha` or `beta` given it is described as a
  "clickable prototype")
- **builtAt / designedFor levels**: L4/L1 per the `building-l1-tools-for-l4-agents` post

The project's stated purpose is dual: (1) a playable text adventure, and (2) a demonstration
of the L4-orchestrator-over-L1-tools architecture pattern. This dual purpose should be reflected
in the README description and in the PR/FAQ positioning.

---

## Priority Order for Remediation

| Priority | Item | Standard |
|---|---|---|
| P1 | Add `version` to `plugin.json` | `plugins.md` |
| P1 | Pin `VERSION` in `install.sh`; pass to `claude plugin install` | `distribution.md` |
| P1 | Add `< /dev/null` guard to any `claude` calls in `install.sh` | `shell.md` (DES-006) |
| P1 | Gitignore LaTeX build artifacts (`.aux`, `.log`, etc.) | `makefile.md` |
| P1 | Remove `CLAUDE.md.tmp` from repo | general hygiene |
| P2 | Add dev/prod namespace isolation (`dungeon-dev`) | `plugins.md` |
| P2 | Add `shellcheck` step to CI | `shell.md` |
| P2 | Add `uninstall.sh` | `distribution.md` |
| P2 | Add `doctor` command (even minimal) | `distribution.md` |
| P2 | Add `install.ps1` | `distribution.md` |
| P3 | Fix README structure (badges, Quick Start, trust tiers, Dev section) | `readme.md` |
| P3 | Verify `mcp/package.json` has `version` matching `plugin.json` | `node.md` |
| P3 | Verify `install.sh` idempotency | `distribution.md` |
| P3 | Verify README copy against forbidden language rules | `readme.md` |

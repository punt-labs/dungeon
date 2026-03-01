# Agent Instructions

This is a prompt-only Claude Code plugin — no application code, no runtime. The game engine is a skill prompt (`skills/dungeon/SKILL.md`) and adventure scripts are structured markdown files in `scripts/`.

This project follows [Punt Labs standards](https://github.com/punt-labs/punt-kit).

## Quality Gates

```bash
npx markdownlint-cli2 "**/*.md" "#node_modules"
```

All markdown must pass markdownlint before commit. CI enforces this via `docs.yml`.

## What NOT to Change Without Care

- **`skills/dungeon/SKILL.md`** — the game engine. Changes affect all gameplay. Test by running `/dungeon` after any edit.
- **`scripts/*.md`** — adventure scripts. Each is a self-contained game world. Follow the existing structure (YAML frontmatter + rooms + encounters).
- **`mcp/`** — MCP tools for game state persistence. Changes affect save/load behavior.

## Issue Tracking

This project uses **beads** (`bd`) for issue tracking. If an issue discovered here affects multiple repos or requires a standards change, escalate to a [punt-kit bead](https://github.com/punt-labs/punt-kit) instead (see [bead placement scheme](../CLAUDE.md#where-to-create-a-bead)).

## Standards References

- [GitHub](https://github.com/punt-labs/punt-kit/blob/main/standards/github.md)
- [Workflow](https://github.com/punt-labs/punt-kit/blob/main/standards/workflow.md)
- [Plugins](https://github.com/punt-labs/punt-kit/blob/main/standards/plugins.md)

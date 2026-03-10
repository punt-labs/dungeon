# Agent Instructions

This is a prompt-only Claude Code plugin — no application code, no runtime. The game engine is a skill prompt (`skills/dungeon/SKILL.md`) and adventure scripts are structured markdown files in `scripts/`.

This project follows [Punt Labs standards](https://github.com/punt-labs/punt-kit).

## No "Pre-existing" Excuse

There is no such thing as a "pre-existing" issue. If you see a problem — in code you wrote, code a reviewer flagged, or code you happen to be reading — you fix it. Do not classify issues as "pre-existing" to justify ignoring them. Do not suggest that something is "outside the scope of this change." If it is broken and you can see it, it is your problem now.

## Scratch Files

Use `.tmp/` at the project root for scratch and temporary files — never `/tmp`. The `TMPDIR` environment variable is set via `.envrc` so that `tempfile` and subprocesses automatically use it. Contents are gitignored; only `.gitkeep` is tracked.

## Quality Gates

```bash
npx markdownlint-cli2 "**/*.md" "#node_modules"
```

All markdown must pass markdownlint before commit. CI enforces this via `docs.yml`.

## What NOT to Change Without Care

- **`skills/dungeon/SKILL.md`** — the game engine. Changes affect all gameplay. Test by running `/dungeon` after any edit.
- **`scripts/*.md`** — adventure scripts. Each is a self-contained game world. Follow the existing structure (YAML frontmatter + rooms + encounters).
- **`mcp/`** — MCP tools for game state persistence. Changes affect save/load behavior.

## Documentation Discipline

### CHANGELOG

Entries are written in the PR branch, before merge — not retroactively on main. If a PR changes user-facing behavior and the diff does not include a CHANGELOG entry, the PR is not ready to merge. Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format under `## [Unreleased]`. Categories: Added, Changed, Deprecated, Removed, Fixed, Security.

### README

Update `README.md` when user-facing behavior changes — new commands, game mechanics, flags, defaults, or configuration.

### PR/FAQ

Update `prfaq.tex` when the change shifts product direction or validates/invalidates a risk assumption.

## Pre-PR Checklist

- [ ] **CHANGELOG entry** included in the PR diff under `## [Unreleased]` (PR is not merge-ready without it if behavior changed)
- [ ] **README updated** if user-facing behavior changed (commands, mechanics, flags, defaults, config)
- [ ] **PR/FAQ updated** if the change shifts product direction or validates/invalidates a risk assumption
- [ ] **Quality gates pass** — `npx markdownlint-cli2 "**/*.md" "#node_modules"`

### Code Review Flow

Do **not** merge immediately after creating a PR. Expect **2–6 review cycles** before merging.

1. **Create PR** — push branch, open PR via `mcp__github__create_pull_request`. Prefer MCP GitHub tools over `gh` CLI.
2. **Request Copilot review** — use `mcp__github__request_copilot_review`.
3. **Watch for feedback in the background** — `gh pr checks <number> --watch` in a background task or separate session. Do not stop waiting. Copilot and Bugbot may take 1–3 minutes after CI completes.
4. **Read all feedback** via MCP: `mcp__github__pull_request_read` with `get_reviews` and `get_review_comments`.
5. **Take every comment seriously.** There is no such thing as "pre-existing" or "unrelated to this change" — if you can see it, you own it. If you disagree, explain why in a reply.
6. **Fix and re-push** — commit fixes, push, re-run quality gates.
7. **Repeat steps 3–6** until the latest review is **uneventful** — zero new comments, all checks green.
8. **Merge only when the last review was clean** — use `mcp__github__merge_pull_request` (not `gh pr merge`).

## Issue Tracking

This project uses **beads** (`bd`) for issue tracking. If an issue discovered here affects multiple repos or requires a standards change, escalate to a [punt-kit bead](https://github.com/punt-labs/punt-kit) instead (see [bead placement scheme](../CLAUDE.md#where-to-create-a-bead)).

## Standards References

- [GitHub](https://github.com/punt-labs/punt-kit/blob/main/standards/github.md)
- [Workflow](https://github.com/punt-labs/punt-kit/blob/main/standards/workflow.md)
- [Plugins](https://github.com/punt-labs/punt-kit/blob/main/standards/plugins.md)

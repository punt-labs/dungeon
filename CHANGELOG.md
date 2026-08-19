# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed

- **The shippable plugin surface moved to `plugin/`, so a marketplace install
  fetches only the plugin.** `.claude-plugin/`, `skills/`, `hooks/`, `mcp/`,
  `assets/`, and the three adventure scripts now live under one `plugin/`
  directory, which lets the marketplace entry use Claude Code's `git-subdir`
  source (`"source": "git-subdir"`, `"path": "plugin"`). That source is a
  blobless partial clone plus `git sparse-checkout set --cone plugin`, so an
  install stops fetching whole directories: `docs/` (including a 239 KB
  `architecture.pdf`), `.github/`, `.beads/`, `.lux/`, `.vox/`, and the release
  tooling in the repo-root `scripts/` are all absent. Measured against this
  branch: 30 files / 540 KB of working tree versus 46 files / 976 KB for an
  equivalent shallow full clone, with `plugin/` itself only 172 KB. The
  adventures and `assets/` had to move too,
  and are part of the shipped surface rather than repo data, because
  `mcp/server.mjs` resolves them relative to its own location — leaving either
  behind would have left `quest_board`, `unfurl_scroll`, and `scry` reading
  paths a sparse install never materializes. `${CLAUDE_PLUGIN_ROOT}` is now
  `plugin/`, so `hooks.json`'s `${CLAUDE_PLUGIN_ROOT}/hooks/*.sh` and
  `plugin.json`'s `${CLAUDE_PLUGIN_ROOT}/mcp/server.mjs` both stay correct: the
  whole surface moved together and nothing in it reaches outside itself. Note
  that cone mode always materializes the files sitting in the *repo root*, so
  `DESIGN.md`, `prfaq.pdf`, `prfaq.tex`, `playtest-1.md`, `README.md`, and
  `install.sh` still travel with an install; shrinking that remainder means
  moving root documents into a subdirectory, which this change does not
  attempt. One consequence for anyone working in this repo: there are now two
  directories named `scripts/` — `plugin/scripts/` is adventures, the repo-root
  `scripts/` is release tooling. No user-visible behavior change; existing
  installs are unaffected until the marketplace entry is repointed. See
  DES-023.

### Fixed

- **A failed MCP dependency install left the player with no game tools and no
  explanation.** `node_modules` is untracked and a `git-subdir` install
  materializes exactly what git tracks, so the SessionStart hook's `npm install`
  is the only path by which the grimoire server's dependencies reach a player's
  machine. The hook sent npm's diagnostics to `/dev/null` and let a non-zero
  exit trip `set -e` before the assignment that would have reported it.
  Reproduced against 63cfc5d with a `package.json` naming a nonexistent
  dependency: exit 1, empty stdout, empty stderr, and `.permissions.allow` left
  at `[]` — the permissions block never ran either. The install's outcome is now
  branched on explicitly (npm missing and npm failing are distinguished), npm's
  output goes to stderr where the hook log shows it, and the failure is reported
  to the model as `additionalContext` with a remedy that matches the actual
  failure. Same case after the fix: exit 0, npm's E404 on stderr, JSON naming the
  failure, permissions applied, and the *next* session reports it again rather
  than falling silent. `--production` is also replaced with its supported
  spelling `--omit=dev`, and `--no-audit --no-fund` drops two network
  round-trips from first-run latency.
- **A half-installed dependency tree was never retried.** The readiness test was
  `[[ -d node_modules ]]`, and a directory is not a success signal: an install
  interrupted partway — Ctrl-C, a killed session, a full disk — leaves the
  directory behind with unmet dependencies, so every later session read it as
  done, skipped the install, skipped the error report, and left the player with
  broken game tools permanently. Demonstrated by deleting one package from a
  healthy tree: `node_modules` still present, `npm ls` exits 1 naming the missing
  dependency. The test is now `npm ls --omit=dev` (about 160 ms per session
  start), so the same case self-heals — observed re-installing the one missing
  package and reporting success. Found by Cursor Bugbot on #64.
- **A missing `jq` was two silent no-ops.** `jq` is a hard requirement of the
  shipped surface, not just of the SessionStart hook's permissions block:
  `suppress-output.sh` pipes every grimoire tool result through it, so without
  `jq` the game's file I/O stops being collapsed in the UI *and* the MCP tools
  are never auto-allowed — both without a word to anyone. The hook now
  distinguishes "jq absent" from "settings.json absent" and reports the former.
  Verified with a `PATH` carrying `npm` but not `jq`: exit 0, valid JSON naming
  the consequence, and the four cases that must not regress (first run, steady
  state, stale `mcp__plugin_dungeon_game__` permission migration, absent
  `settings.json`) all unchanged.
- **The MCP server announced the wrong version.** `server.mjs` hardcoded
  `version: "0.1.2"` in its `serverInfo`, so every client was told 0.1.2 while
  the plugin shipped as 0.1.6. It now reads the version from
  `plugin/.claude-plugin/plugin.json`, which the `plugin/` move makes a
  guaranteed sibling and which is the one file a release bumps. If the manifest
  is unreadable the server warns on stderr and reports `0.0.0` rather than
  refusing to start — verified by moving the manifest aside: the warning
  appeared on stderr, `serverInfo.version` was `0.0.0`, and all six tools still
  worked.
- **`markdownlint` no longer lints `.tmp/`.** `.tmp/` is gitignored scratch, so
  CI never saw it, but a local `npx markdownlint-cli2 "**/*.md"` did — a scratch
  file or a throwaway clone under `.tmp/` would fail the gate for reasons that
  have nothing to do with the change under test. Observed while verifying this
  branch: a sparse-checkout test clone took the local run from 17 files to 46.
- **`shellcheck` now runs in CI.** The repo ships four shell scripts, two of
  them inside the plugin surface, and CI linted only markdown. The gap had let a
  real defect sit in `scripts/release-plugin.sh`: an unquoted `${REPO_ROOT}`
  inside `${f#...}` (SC2295), where a glob character in the repo path would
  silently mis-strip the prefix. Both are fixed here.

### Removed

- The SessionStart hook's `/d` shorthand deploy block. It copied
  `$PLUGIN_ROOT/commands/d.md`, and `commands/d.md` was deleted in 0.1.5, so the
  guard had been unsatisfiable ever since and the message branch announcing the
  deploy was unreachable.

## [0.1.6] - 2026-08-15

### Fixed

- Removed the SSH `.punt-labs/ethos` git submodule that broke keyless
  `git clone --recurse-submodules` plugin installs. Claude Code clones this
  plugin with submodules; the `git@github.com:punt-labs/team.git` URL aborted
  the clone with `Permission denied (publickey)` for any user without a GitHub
  SSH key. All ethos config (`.gitmodules`, the submodule, `.punt-labs/ethos.yaml`)
  is removed and `.punt-labs/` is now gitignored — agents resolve identity from
  the global `~/.punt-labs/ethos/` instead.

## [0.1.5] - 2026-05-13

### Removed

- `/d` shorthand command — use `/dungeon` instead

## [0.1.4] - 2026-05-13

### Added

- Release infrastructure: `scripts/release-plugin.sh` and `scripts/restore-dev-plugin.sh`

### Security

- Upgrade `hono` to 4.12.18 (fixes cache Vary leakage, CSS injection in JSX SSR, JWT NumericDate bypass)
- Upgrade `@hono/node-server` to 1.19.13 (fixes static middleware bypass via inconsistent repeated-slash handling)
- Upgrade `express-rate-limit` to 8.5.1 and `ip-address` to 10.2.0
- Upgrade `fast-uri` to 3.1.2 (fixes malformed fragment decoding — 2 CVEs)
- Upgrade `path-to-regexp` to 8.4.1 (fixes ReDoS via sequential optional groups)

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
  branch on GitHub: 30 files / ~540 KB of working tree versus 46 files / ~980 KB
  for an equivalent shallow full clone, with `plugin/` itself only ~175 KB. The
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
- **A machine with `node` but no `npm` got a false alarm every session.** Making
  the readiness check unconditional meant a missing `npm` was reported as "game
  tools will not work" even when the dependency tree was already complete — and
  the grimoire server is launched with `node`, so it works fine there. Verified:
  with all 93 packages present and `npm` removed from `PATH` entirely, all six
  tools serve normally over stdio. Without `npm` there is no authoritative
  readiness answer and nothing to be done about a bad tree anyway, so that
  branch now reports only when the tree is plainly absent. Found by Cursor
  Bugbot on #64.
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
  refusing to start. A manifest that *parses* but declares no usable `version`
  needs its own warning, because that path reaches the fallback without throwing
  and the `catch` never sees it — and the obvious `?? version` would have
  reported a `null` or a numeric `16` verbatim as the server version. Only a
  non-empty string is accepted now. Seven manifest states were exercised, each
  with its own diagnostic and all six tools serving throughout: version present,
  no `version` key, `null`, empty string, a number, a file that is not valid
  JSON, and a missing file.
- **The output-suppression hook could hand the model a fabricated game state.**
  `suppress-output.sh` read `.tool_response[0].text` with `jq -r`, which renders
  a missing path as the literal text `null` and prints nothing when the shape
  makes indexing an error — neither distinguishable from real content by looking
  at the result. So `tool_response` of `null`, of `[]`, or of an element without
  `.text` all published the four-character string `"null"` to the model as
  `additionalContext`, and a FastMCP-shaped `{"result": ...}` object (the form
  this file's own comment anticipates) published `""`; in every case the panel
  summary still read "state recalled". A recalled save file that reads `null` is
  worse than an unsuppressed one, so the status of that `jq` is now load-bearing
  (`-re`) and no override is emitted at all unless there is a real result to put
  behind it — otherwise the default panel shows, the model receives the genuine
  tool result, and a named diagnostic goes to stderr distinguishing "no text at
  that path" (status 1) from "not an MCP content array" (status 5). An empty text
  is a jq success, so status alone does not catch it and it is now checked
  separately: `quest_board` returns `""` when it finds no adventures, and a panel
  reading "quests listed" over nothing is the same lie in miniature. The tool
  name is read with `-re` too and checked *before* `tool_response` is probed,
  against one authoritative suffix list, so an unrelated tool's response is never
  indexed into. The script also gained `set -euo pipefail`, matching
  `session-start.sh`, and every `echo "$INPUT"` is now `printf '%s'` — game state
  is full of backslashes and `echo` is not required to leave them alone. Fourteen
  shapes exercised: the eight response shapes, an empty text, a missing
  `tool_name`, input that is not JSON, an unfurl with and without a name, the
  legacy `mcp__plugin_dungeon_game__` server name (still suppressed), and a
  backslash-heavy save file confirmed byte-identical through the hook with `od`.
- **A release could silently ship with the `-dev` command surface intact.**
  `release-plugin.sh` ran `find "$COMMANDS_DIR" ... 2>/dev/null || true` inside a
  process substitution, which is silent twice over: `set -e` does not inspect a
  process substitution's exit status, and the redirect hid find's message. A
  wrong `COMMANDS_DIR` — a typo, or the `plugin/` move having been done only
  halfway — was therefore indistinguishable from "no `-dev` commands to strip",
  and the release completed reporting success. The directory's absence is now
  announced, and find writes to a regular file so it is a simple command that
  `set -e` does police, meaning a genuine I/O error aborts the release instead of
  reading as an empty result. Exercised on three throwaway repos: no
  `plugin/commands` at all (dungeon's own case — Note printed, name swapped), a
  plugin that does have `-dev` commands (stripped), and the half-moved
  regression (Note printed, and the still-tracked `-dev` file is now attributable
  instead of mysterious).
- **`markdownlint` no longer lints `.tmp/`.** `.tmp/` is gitignored scratch, so
  CI never saw it, but a local `npx markdownlint-cli2 "**/*.md"` did — a scratch
  file or a throwaway clone under `.tmp/` would fail the gate for reasons that
  have nothing to do with the change under test. Observed while verifying this
  branch: a sparse-checkout test clone took the local run from 17 files to 46.
- **`shellcheck` now runs in CI.** The repo ships five shell scripts, two of
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

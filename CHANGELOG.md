# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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

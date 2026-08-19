#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$HOME/.claude/settings.json"
TOOL_PATTERN="mcp__plugin_dungeon_grimoire__"

# ── Install MCP dependencies if missing ──────────────────────────────────
# node_modules is not tracked in git, and the marketplace installs this
# directory straight out of the repo, so this is the *only* place the
# grimoire server's dependencies ever get installed. A failure here leaves
# every game tool missing, so report it instead of dying quietly: the old
# form sent npm's stderr to /dev/null and let `set -e` kill the hook on a
# non-zero exit, which also skipped the permissions block below.
#
# The readiness test is `npm ls`, not `[[ -d node_modules ]]`. A directory is
# not a success signal: an install interrupted partway — Ctrl-C, a killed
# session, a full disk — leaves a tree behind with unmet dependencies, and a
# directory test reads that as done, so the install would never be retried and
# the failure would never be reported. Demonstrated: deleting one package from
# a healthy tree leaves node_modules in place while `npm ls` exits 1 naming the
# missing dependency. `npm ls` costs about 160 ms per session start.
MCP_DIR="$PLUGIN_ROOT/mcp"
mcp_deps_ok() { (cd "$MCP_DIR" && npm ls --omit=dev) >/dev/null 2>&1; }
if [[ -f "$MCP_DIR/package.json" ]]; then
  if ! command -v npm &>/dev/null; then
    MCP_SETUP_FAILED="npm was not found"
    MCP_SETUP_REMEDY="Install Node.js 20+ and restart Claude Code."
  elif ! mcp_deps_ok; then
    if ! (cd "$MCP_DIR" && npm install --omit=dev --no-audit --no-fund --quiet) >&2; then
      MCP_SETUP_FAILED="npm install failed"
      MCP_SETUP_REMEDY="npm's error is in the hook output above; the next session will retry."
    elif ! mcp_deps_ok; then
      MCP_SETUP_FAILED="npm install exited 0 but dependencies are still unmet"
      # The path goes to stderr, not into MSG: MSG is interpolated into an
      # unescaped heredoc and $HOME can contain a quote or a backslash.
      echo "dungeon: dependencies still unmet after install in $MCP_DIR" >&2
      MCP_SETUP_REMEDY="Delete the plugin's mcp/node_modules directory and restart Claude Code to force a clean install; the path is in the hook output above."
    else
      NPM_INSTALLED=true
    fi
  fi
fi

# ── Allow MCP tools in user settings if not already allowed ──────────────
# jq is a hard requirement of the shipped surface, not just of this block:
# suppress-output.sh pipes every grimoire tool result through it, so without
# jq the permission grant below never happens *and* the game's file I/O stops
# being collapsed in the UI. That used to be two silent no-ops.
OLD_PATTERN="mcp__plugin_dungeon_game__"
if ! command -v jq &>/dev/null; then
  JQ_MISSING=true
elif [[ -f "$SETTINGS" ]]; then
  NEEDS_UPDATE=false

  # Remove stale permission from old server name (game → grimoire)
  if jq -e ".permissions.allow // [] | map(select(contains(\"$OLD_PATTERN\"))) | length > 0" "$SETTINGS" >/dev/null 2>&1; then
    TMPFILE="$(mktemp)"
    jq '.permissions.allow = [.permissions.allow[] | select(contains("mcp__plugin_dungeon_game__") | not)]' "$SETTINGS" > "$TMPFILE"
    mv "$TMPFILE" "$SETTINGS"
    NEEDS_UPDATE=true
  fi

  # Add new permission if missing
  if ! jq -e ".permissions.allow // [] | map(select(contains(\"$TOOL_PATTERN\"))) | length > 0" "$SETTINGS" >/dev/null 2>&1; then
    TMPFILE="$(mktemp)"
    jq '.permissions.allow = (.permissions.allow // []) + ["mcp__plugin_dungeon_grimoire__*"]' "$SETTINGS" > "$TMPFILE"
    mv "$TMPFILE" "$SETTINGS"
    NEEDS_UPDATE=true
  fi

  [[ "$NEEDS_UPDATE" == "true" ]] && TOOLS_ALLOWED=true
fi

# ── Notify Claude if anything was set up ─────────────────────────────────
# MSG is assembled from fixed strings only. It is interpolated into an
# unescaped heredoc, so anything carrying a quote, a newline, or a backslash
# would produce invalid JSON — npm's output is deliberately kept out of it.
if [[ -n "${MCP_SETUP_FAILED:-}" || "${JQ_MISSING:-}" == "true" || "${NPM_INSTALLED:-}" == "true" || "${TOOLS_ALLOWED:-}" == "true" ]]; then
  if [[ -n "${MCP_SETUP_FAILED:-}" ]]; then
    MSG="Dungeon plugin setup could not install the grimoire MCP server dependencies: ${MCP_SETUP_FAILED}. Game tools will not work until this is resolved. ${MCP_SETUP_REMEDY}"
  else
    # Not "first-run": this same branch reports a repaired dependency tree and
    # a migrated permission entry, neither of which is a first run.
    MSG="Dungeon plugin setup complete."
  fi
  [[ "${JQ_MISSING:-}" == "true" ]] && MSG="$MSG jq was not found, so game tools were not auto-allowed and their file I/O will not be collapsed in the UI — install jq and restart Claude Code."
  [[ "${TOOLS_ALLOWED:-}" == "true" ]] && MSG="$MSG Game tools were auto-allowed in permissions."
  cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$MSG"
  }
}
ENDJSON
fi

exit 0

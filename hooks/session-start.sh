#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── Install MCP dependencies if missing ──────────────────────────────────
MCP_DIR="$PLUGIN_ROOT/mcp"
if [[ -d "$MCP_DIR" && -f "$MCP_DIR/package.json" && ! -d "$MCP_DIR/node_modules" ]]; then
  if command -v npm &>/dev/null; then
    (cd "$MCP_DIR" && npm install --production --quiet 2>/dev/null)
    NPM_INSTALLED=true
  fi
fi

# ── Deploy /d shorthand if missing ───────────────────────────────────────
COMMANDS_DIR="$HOME/.claude/commands"
D_CMD="$COMMANDS_DIR/d.md"
if [[ ! -f "$D_CMD" && -f "$PLUGIN_ROOT/commands/d.md" ]]; then
  mkdir -p "$COMMANDS_DIR"
  cp "$PLUGIN_ROOT/commands/d.md" "$D_CMD"
  D_DEPLOYED=true
fi

# ── Notify Claude if anything was set up ─────────────────────────────────
if [[ "${NPM_INSTALLED:-}" == "true" || "${D_DEPLOYED:-}" == "true" ]]; then
  MSG="Dungeon plugin first-run setup complete."
  [[ "${D_DEPLOYED:-}" == "true" ]] && MSG="$MSG The /d shorthand was deployed — it will activate after restart."
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

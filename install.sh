#!/usr/bin/env bash
set -euo pipefail

# Claude Dungeon Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/punt-labs/dungeon/main/install.sh | bash

REPO="https://github.com/punt-labs/dungeon.git"
PLUGIN_NAME="dungeon"
PLUGINS_DIR="$HOME/.claude/plugins/local-plugins/plugins"
MARKETPLACE="$HOME/.claude/plugins/local-plugins/.claude-plugin/marketplace.json"
INSTALL_DIR="$PLUGINS_DIR/$PLUGIN_NAME"

# Resolve the latest release tag (vX.Y.Z) via git ls-remote
resolve_latest_tag() {
  git ls-remote --tags --sort=-v:refname "$REPO" 'v*' 2>/dev/null \
    | head -1 \
    | sed 's|.*refs/tags/||; s|\^{}||'
}

LATEST_TAG=$(resolve_latest_tag)

info()   { printf '\033[0;34m%s\033[0m\n' "$*"; }
ok()     { printf '\033[0;32m  ✓ %s\033[0m\n' "$*"; }
warn()   { printf '\033[0;33m  ⚠ %s\033[0m\n' "$*"; }
fail()   { printf '\033[0;31m  ✗ %s\033[0m\n' "$*"; }
header() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# ── Preflight ───────────────────────────────────────────────────────────────

header "Prerequisites"

if command -v git &>/dev/null; then
  ok "git $(git --version | sed 's/git version //')"
else
  fail "git not found — install git first"
  exit 1
fi

if command -v claude &>/dev/null; then
  ok "claude CLI"
else
  warn "claude CLI not found in PATH"
fi

# ── Install plugin ──────────────────────────────────────────────────────────

header "Plugin"

if [[ -d "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
  if [[ -L "$INSTALL_DIR" ]]; then
    ok "Symlink detected at $INSTALL_DIR (developer mode)"
  elif [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Existing installation found — updating..."
    git -C "$INSTALL_DIR" fetch --tags --quiet
    if [[ -n "$LATEST_TAG" ]]; then
      git -C "$INSTALL_DIR" checkout --quiet "$LATEST_TAG" 2>/dev/null
      ok "Updated to $LATEST_TAG"
    else
      git -C "$INSTALL_DIR" pull --quiet
      ok "Updated via git pull"
    fi
  else
    ok "Installed at $INSTALL_DIR"
  fi
else
  info "Cloning $REPO..."
  mkdir -p "$PLUGINS_DIR"
  git clone --quiet "$REPO" "$INSTALL_DIR"
  if [[ -n "$LATEST_TAG" ]]; then
    git -C "$INSTALL_DIR" checkout --quiet "$LATEST_TAG" 2>/dev/null
    ok "Installed $LATEST_TAG to $INSTALL_DIR"
  else
    ok "Cloned to $INSTALL_DIR"
  fi
fi

# ── Read metadata from plugin.json ──────────────────────────────────────────

PLUGIN_JSON="$INSTALL_DIR/.claude-plugin/plugin.json"
if [[ -f "$PLUGIN_JSON" ]] && command -v jq &>/dev/null; then
  PLUGIN_VERSION=$(jq -r '.version // "0.0.0"' "$PLUGIN_JSON")
  PLUGIN_DESCRIPTION=$(jq -r '.description // ""' "$PLUGIN_JSON")
  ok "Plugin version: $PLUGIN_VERSION"
else
  PLUGIN_VERSION="0.1.0"
  PLUGIN_DESCRIPTION="A text adventure game engine for Claude Code"
  warn "Could not read plugin.json — using defaults"
fi

# ── Registration ────────────────────────────────────────────────────────────

header "Registration"

MARKETPLACE_DIR="$(dirname "$MARKETPLACE")"

# Determine author: git config > generic
DEFAULT_NAME="local"
DEFAULT_EMAIL="local@localhost"
if command -v git &>/dev/null; then
  GIT_NAME=$(git config user.name 2>/dev/null || true)
  GIT_EMAIL=$(git config user.email 2>/dev/null || true)
  [[ -n "$GIT_NAME" ]] && DEFAULT_NAME="$GIT_NAME"
  [[ -n "$GIT_EMAIL" ]] && DEFAULT_EMAIL="$GIT_EMAIL"
fi

# Create marketplace.json if it doesn't exist
if [[ ! -f "$MARKETPLACE" ]]; then
  mkdir -p "$MARKETPLACE_DIR"
  if command -v jq &>/dev/null; then
    jq -n \
      --arg name "$DEFAULT_NAME" \
      --arg email "$DEFAULT_EMAIL" \
      '{
        "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
        "name": "local",
        "description": "Local plugins",
        "owner": {"name": $name, "email": $email},
        "plugins": []
      }' > "$MARKETPLACE"
    ok "Created $MARKETPLACE"
  else
    cat > "$MARKETPLACE" <<MANIFEST
{
  "\$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "local",
  "description": "Local plugins",
  "owner": {"name": "$DEFAULT_NAME", "email": "$DEFAULT_EMAIL"},
  "plugins": []
}
MANIFEST
    ok "Created $MARKETPLACE"
  fi
fi

# Register plugin in marketplace
if grep -q "\"$PLUGIN_NAME\"" "$MARKETPLACE" 2>/dev/null; then
  ok "Already registered in marketplace.json"
else
  if command -v jq &>/dev/null; then
    TMPFILE="$(mktemp)"
    jq --arg name "$PLUGIN_NAME" \
       --arg version "$PLUGIN_VERSION" \
       --arg desc "$PLUGIN_DESCRIPTION" \
       '.plugins += [{
         "name": $name,
         "description": $desc,
         "version": $version,
         "source": ("./plugins/" + $name),
         "category": "games"
       }]' "$MARKETPLACE" > "$TMPFILE"
    mv "$TMPFILE" "$MARKETPLACE"
    ok "Registered in marketplace.json"
  else
    warn "jq not found — add the plugin entry to $MARKETPLACE manually"
  fi
fi

# ── MCP server dependencies ────────────────────────────────────────────────

header "MCP Server"

if command -v node &>/dev/null; then
  ok "node $(node --version)"
  if [[ -f "$INSTALL_DIR/mcp/package.json" ]]; then
    (cd "$INSTALL_DIR/mcp" && npm install --production --quiet 2>/dev/null)
    ok "MCP server dependencies installed"
  fi
else
  warn "node not found — MCP server won't work without Node.js"
fi

# ── Shorthand command ──────────────────────────────────────────────────────

header "Shorthand"

COMMANDS_DIR="$HOME/.claude/commands"
D_CMD="$COMMANDS_DIR/d.md"
mkdir -p "$COMMANDS_DIR"
cat > "$D_CMD" <<'CMD'
---
description: "Shorthand for /dungeon — play a text adventure game"
---

Use the Skill tool to invoke the `dungeon` skill with `$ARGUMENTS` as the args parameter.
CMD
ok "/d shorthand installed"

# ── Clear plugin cache ──────────────────────────────────────────────────────

CACHE_DIR="$HOME/.claude/plugins/cache/local/$PLUGIN_NAME"
if [[ -d "$CACHE_DIR" ]]; then
  rm -rf "$CACHE_DIR"
  ok "Cleared plugin cache (will rebuild on next launch)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────

header "Done"

ok "dungeon plugin installed"
echo ""
info "Next steps:"
info "  1. Restart Claude Code (or start a new session)"
info "  2. Type /dungeon to start a text adventure"
echo ""

#!/bin/sh
# Install dungeon — text adventure game for Claude Code.
# Usage: curl -fsSL https://raw.githubusercontent.com/punt-labs/dungeon/<SHA>/install.sh | sh
set -eu

# --- Colors (disabled when not a terminal) ---
if [ -t 1 ]; then
  BOLD='\033[1m' GREEN='\033[32m' YELLOW='\033[33m' NC='\033[0m'
else
  BOLD='' GREEN='' YELLOW='' NC=''
fi

info() { printf '%b==>%b %s\n' "$BOLD" "$NC" "$1"; }
ok()   { printf '  %b✓%b %s\n' "$GREEN" "$NC" "$1"; }
fail() { printf '  %b✗%b %s\n' "$YELLOW" "$NC" "$1"; exit 1; }

MARKETPLACE_REPO="punt-labs/claude-plugins"
MARKETPLACE_NAME="punt-labs"
PLUGIN_NAME="dungeon"

# --- Step 1: Claude Code CLI ---

info "Checking Claude Code..."

if command -v claude >/dev/null 2>&1; then
  ok "claude CLI found"
else
  fail "'claude' CLI not found. Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
fi

# --- Step 2: Register marketplace ---

info "Registering Punt Labs marketplace..."

if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
  ok "marketplace already registered"
  claude plugin marketplace update "$MARKETPLACE_NAME" 2>/dev/null || true
else
  claude plugin marketplace add "$MARKETPLACE_REPO" || fail "Failed to register marketplace"
  ok "marketplace registered"
fi

# --- Step 3: Install plugin ---

info "Installing $PLUGIN_NAME..."

claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}" || fail "Failed to install $PLUGIN_NAME"
ok "$PLUGIN_NAME installed"

# --- Done ---

printf '\n%b%b%s is ready!%b\n\n' "$GREEN" "$BOLD" "$PLUGIN_NAME" "$NC"
printf 'Restart Claude Code, then type /dungeon to start a text adventure.\n\n'

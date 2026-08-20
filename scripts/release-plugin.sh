#!/usr/bin/env bash
set -euo pipefail

# Prepare plugin for release: swap name to prod, remove -dev commands.
# The tagged commit has only prod artifacts; the marketplace cache clones from it.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_JSON="plugin/.claude-plugin/plugin.json"
COMMANDS_DIR="plugin/commands"

# Require a clean working tree so we don't accidentally stage local changes.
if [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit or stash changes before releasing." >&2
  exit 1
fi

# Swap plugin name from *-dev to prod
current_name="$(PLUGIN_PATH="${REPO_ROOT}/${PLUGIN_JSON}" python3 -c "import json, os; print(json.load(open(os.environ['PLUGIN_PATH']))['name'])")"
prod_name="${current_name%-dev}"

if [[ "$current_name" == "$prod_name" ]]; then
  echo "Plugin name is already '${prod_name}' (no -dev suffix)" >&2
  exit 1
fi

echo "Swapping plugin name: ${current_name} → ${prod_name}"
PLUGIN_PATH="${REPO_ROOT}/${PLUGIN_JSON}" PROD_NAME="$prod_name" python3 -c "
import json, pathlib, os
p = pathlib.Path(os.environ['PLUGIN_PATH'])
d = json.loads(p.read_text())
d['name'] = os.environ['PROD_NAME']
p.write_text(json.dumps(d, indent=2) + '\n')
"

git -C "$REPO_ROOT" add "$PLUGIN_JSON"

# Remove -dev commands if any exist (repo-relative paths for git).
#
# The absence of the commands directory is announced rather than swallowed.
# This previously read `find ... 2>/dev/null || true` inside a process
# substitution, which is doubly silent: `set -e` does not inspect a process
# substitution's exit status, and the redirect hid find's message. A wrong
# COMMANDS_DIR — a typo, or the plugin/ move having been done only halfway —
# therefore looked exactly like "no -dev commands to strip", and the release
# shipped with the dev command surface intact and reported success.
#
# find also writes to a regular file rather than a pipe, so it is a simple
# command that `set -e` does police: a genuine I/O error now aborts the release
# instead of being read as an empty result.
COMMANDS_ABS="${REPO_ROOT}/${COMMANDS_DIR}"
dev_files=()
if [[ -d "$COMMANDS_ABS" ]]; then
  dev_list="$(mktemp)"
  trap 'rm -f "$dev_list"' EXIT
  find "$COMMANDS_ABS" -name '*-dev.md' -print0 > "$dev_list"
  while IFS= read -r -d '' f; do
    dev_files+=("${f#"${REPO_ROOT}"/}")
  done < "$dev_list"
else
  echo "Note: ${COMMANDS_DIR} does not exist — no -dev commands to strip" >&2
fi

if [[ ${#dev_files[@]} -gt 0 ]]; then
  for f in "${dev_files[@]}"; do
    echo "Removing: $f"
  done
  git -C "$REPO_ROOT" rm "${dev_files[@]}"
fi

git -C "$REPO_ROOT" commit --no-verify -m "chore: prepare plugin for release [skip ci]"

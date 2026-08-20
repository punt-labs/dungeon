#!/usr/bin/env bash
# Suppress verbose MCP tool output in the UI panel.
#
# updatedMCPToolOutput: short summary shown in the tool-result panel.
# additionalContext: full tool response passed to the model as context.
#
# Without this hook, every recall/unfurl_scroll call shows the full file
# content with "ctrl+o to expand" — breaking game immersion.
#
# The override replaces what the model sees, so it is only ever emitted when
# there is a real tool result to put behind it. Anything unexpected exits 0
# without an override: the default panel shows and the model receives the
# genuine tool result. Suppression is a cosmetic nicety; a fabricated save file
# is a corrupted game.
set -euo pipefail

INPUT=$(cat)

# jq's status is load-bearing throughout this script, hence -e everywhere it is
# read. `jq -r` renders a missing path as the literal text "null", which is not
# distinguishable from real content by inspecting the output.
if ! TOOL=$(printf '%s' "$INPUT" | jq -re '.tool_name'); then
  echo "dungeon: suppress-output hook got input with no readable .tool_name; leaving output unsuppressed" >&2
  exit 0
fi

# The one authoritative list of tools this hook owns, matched on the suffix so
# it survives a server rename (the grimoire server was once named "game").
# Checked *before* tool_response is probed: another server's response has no
# reason to be an MCP content array, and the old order indexed into it first —
# printing a jq error for a tool this hook does not own.
if [[ ! "$TOOL" =~ __(recall|inscribe|obliterate|unfurl_scroll|quest_board|scry)$ ]]; then
  exit 0
fi

# tool_response is an MCP content array: [{type:"text",text:"..."}]
# (biff uses FastMCP which wraps as {"result":"..."} — different format)
#
# Every degenerate shape used to reach the model as content. With `jq -r`,
# tool_response of null, of [], or of an element without .text all produced the
# four-character string "null", and a FastMCP-shaped object produced "" — each
# published as additionalContext while the panel still read "state recalled".
# -e separates them from a real result: status 1 when the path yields null,
# status 5 when the shape makes indexing an error or the input will not parse.
# jq's own stderr is left to pass through — it names the offending shape, and it
# is the only explanation available if the status is one this script does not
# anticipate.
STATUS=0
RESULT=$(printf '%s' "$INPUT" | jq -re '.tool_response[0].text') || STATUS=$?

case "$STATUS" in
  0) ;;
  1)
    echo "dungeon: $TOOL returned no .tool_response[0].text (null, absent, empty array, or an element without text); leaving output unsuppressed" >&2
    exit 0
    ;;
  5)
    echo "dungeon: $TOOL returned a tool_response that is not an MCP content array; leaving output unsuppressed" >&2
    exit 0
    ;;
  *)
    echo "dungeon: could not read $TOOL's tool_response (jq exited $STATUS); leaving output unsuppressed" >&2
    exit 0
    ;;
esac

# An empty text is a real jq success, so status alone does not catch it, and no
# grimoire tool has an empty result to report: recall and unfurl_scroll and scry
# return file content, inscribe and obliterate return OK or NO_SAVE_FILE, and
# quest_board returns "" only when it found no adventures at all — a summary
# reading "quests listed" over nothing is exactly the lie this guard exists to
# prevent. Pass it through unsuppressed so the model sees the truth.
if [[ -z "$RESULT" ]]; then
  echo "dungeon: $TOOL returned an empty result; leaving output unsuppressed" >&2
  exit 0
fi

case "$TOOL" in
  *__recall)
    if [[ "$RESULT" == "NO_SAVE_FILE" ]]; then
      SUMMARY="no save"
    else
      SUMMARY="state recalled"
    fi
    ;;
  *__inscribe)
    SUMMARY="inscribed"
    ;;
  *__obliterate)
    SUMMARY="save obliterated"
    ;;
  *__unfurl_scroll)
    NAME=$(printf '%s' "$INPUT" | jq -r '.tool_input.name // "scroll"')
    SUMMARY="$NAME unfurled"
    ;;
  *__quest_board)
    SUMMARY="quests listed"
    ;;
  *__scry)
    SUMMARY="visions revealed"
    ;;
esac

jq -n --arg s "$SUMMARY" --arg ctx "$RESULT" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    updatedMCPToolOutput: $s,
    additionalContext: $ctx
  }
}'

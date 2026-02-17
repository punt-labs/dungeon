#!/usr/bin/env bash
# Suppress verbose MCP tool output in the UI panel.
#
# updatedMCPToolOutput: short summary shown in the tool-result panel.
# additionalContext: full tool response passed to the model as context.
#
# Without this hook, every load/read_script call shows the full file
# content with "ctrl+o to expand" — breaking game immersion.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
# tool_response is an MCP content array: [{type:"text",text:"..."}]
# (biff uses FastMCP which wraps as {"result":"..."} — different format)
RESULT=$(echo "$INPUT" | jq -r '.tool_response[0].text')

case "$TOOL" in
  *__load)
    if [[ "$RESULT" == "NO_SAVE_FILE" ]]; then
      SUMMARY="no save"
    else
      SUMMARY="state loaded"
    fi
    ;;
  *__save)
    SUMMARY="saved"
    ;;
  *__delete_save)
    SUMMARY="save deleted"
    ;;
  *__read_script)
    NAME=$(echo "$INPUT" | jq -r '.tool_input.name // "script"')
    SUMMARY="$NAME loaded"
    ;;
  *__list_scripts)
    SUMMARY="scripts listed"
    ;;
  *__read_assets)
    SUMMARY="assets loaded"
    ;;
  *)
    exit 0
    ;;
esac

jq -n --arg s "$SUMMARY" --arg ctx "$RESULT" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    updatedMCPToolOutput: $s,
    additionalContext: $ctx
  }
}'

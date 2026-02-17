#!/usr/bin/env bash
# Suppress verbose MCP tool output in the UI panel.
#
# Without this hook, every dungeon_load/dungeon_read_script call shows
# the full file content with "ctrl+o to expand" — breaking game immersion.
#
# Sets updatedMCPToolOutput to a minimal summary so the panel stays clean.
# The model still receives the full tool response for game logic.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

case "$TOOL" in
  *dungeon_load)
    RESULT=$(echo "$INPUT" | jq -r '.tool_response' | jq -r '.result // .')
    if [[ "$RESULT" == "NO_SAVE_FILE" ]]; then
      SUMMARY="no save"
    else
      SUMMARY="state loaded"
    fi
    ;;
  *dungeon_save)
    SUMMARY="saved"
    ;;
  *dungeon_delete_save)
    SUMMARY="save deleted"
    ;;
  *dungeon_read_script)
    NAME=$(echo "$INPUT" | jq -r '.tool_input.name // "script"')
    SUMMARY="$NAME loaded"
    ;;
  *dungeon_list_scripts)
    SUMMARY="scripts listed"
    ;;
  *dungeon_read_assets)
    SUMMARY="assets loaded"
    ;;
  *)
    exit 0
    ;;
esac

jq -n --arg s "$SUMMARY" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    updatedMCPToolOutput: $s
  }
}'

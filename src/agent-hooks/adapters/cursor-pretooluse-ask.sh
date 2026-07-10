#!/usr/bin/env bash
# Cursor preToolUse hook adapter for AskQuestion / AskUserQuestion.
# Normalizes Cursor hook JSON into the canonical agent-hooks format.

set -euo pipefail

core_dir="${AGENT_HOOKS_DIR:-$HOME/.local/share/agent-hooks}"
input=$(cat)

printf '%s' "$input" | jq -c '{
  message: (.agent_message // .message // "Waiting for your input"),
  cwd: (.workspace_roots[0] // .cwd // ""),
  session_id: ((.session_id // "") | tostring | .[0:8]),
  agent: "cursor"
}' | "$core_dir/notify-decision.sh"

exit 0

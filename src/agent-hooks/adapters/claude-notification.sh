#!/usr/bin/env bash
# Claude Code Notification hook adapter.
# Normalizes Claude hook JSON into the canonical agent-hooks format.

set -euo pipefail

core_dir="${AGENT_HOOKS_DIR:-$HOME/.local/share/agent-hooks}"
input=$(cat)

printf '%s' "$input" | jq -c '{
  message: (.message // "Waiting for your input"),
  cwd: (.cwd // ""),
  session_id: ((.session_id // "") | tostring | .[0:8]),
  agent: "claude"
}' | "$core_dir/notify-decision.sh"

exit 0

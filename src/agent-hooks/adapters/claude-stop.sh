#!/usr/bin/env bash
# Claude Code Stop hook: update status bar only (no desktop notification).

set -euo pipefail

core_dir="${AGENT_HOOKS_DIR:-$HOME/.local/share/agent-hooks}"
input=$(cat)

status=$(printf '%s' "$input" | jq -r '
  if .stop_hook_active == true then "completed"
  elif (.status // "") != "" then .status
  else "completed" end
')

case "$status" in
  error) bar_status=error ;;
  aborted) bar_status=idle ;;
  *) bar_status=ready ;;
esac

printf '%s' "$input" | jq -c --arg status "$bar_status" '{
  status: $status,
  cwd: (.cwd // ""),
  agent: "claude"
}' | "$core_dir/update-agent-status.sh"

exit 0

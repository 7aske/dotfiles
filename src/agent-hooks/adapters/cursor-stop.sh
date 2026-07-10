#!/usr/bin/env bash
# Cursor stop hook adapter.
# Normalizes Cursor hook JSON into the canonical agent-hooks format.

set -euo pipefail

core_dir="${AGENT_HOOKS_DIR:-$HOME/.local/share/agent-hooks}"
input=$(cat)

printf '%s' "$input" | jq -c '{
  status: (.status // "completed"),
  cwd: (.workspace_roots[0] // .cwd // ""),
  hook_event_name: (.hook_event_name // "stop"),
  loop_count: (.loop_count // 0),
  agent: "cursor"
}' | "$core_dir/notify-agent-done.sh"

printf '{}\n'
exit 0

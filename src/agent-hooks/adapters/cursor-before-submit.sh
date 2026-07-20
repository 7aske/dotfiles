#!/usr/bin/env bash
# Cursor beforeSubmitPrompt: mark session as working for the status bar.

set -euo pipefail

core_dir="${AGENT_HOOKS_DIR:-$HOME/.local/share/agent-hooks}"
input=$(cat)

printf '%s' "$input" | jq -c '{
  status: "working",
  cwd: (.workspace_roots[0] // .cwd // ""),
  agent: "cursor"
}' | "$core_dir/update-agent-status.sh"

printf '{}\n'
exit 0

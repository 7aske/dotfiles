#!/usr/bin/env bash
# Claude Code UserPromptSubmit: mark session as working for the status bar.

set -euo pipefail

core_dir="${AGENT_HOOKS_DIR:-$HOME/.local/share/agent-hooks}"
input=$(cat)

printf '%s' "$input" | jq -c '{
  status: "working",
  cwd: (.cwd // ""),
  agent: "claude"
}' | "$core_dir/update-agent-status.sh"

exit 0

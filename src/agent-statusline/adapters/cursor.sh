#!/usr/bin/env bash
# Cursor CLI statusLine adapter.
# Normalizes Cursor statusLine JSON into the canonical agent-statusline format.

set -euo pipefail

core_dir="${AGENT_STATUSLINE_DIR:-$HOME/.local/share/agent-statusline}"
input=$(cat)

printf '%s' "$input" | jq -c '{
  cwd: (.cwd // .workspace.current_dir // ""),
  model: (.model // {}),
  context_window: (.context_window // {})
}' | "$core_dir/statusline.sh"

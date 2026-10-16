#!/usr/bin/env bash
# Claude Code statusLine adapter.
# Normalizes Claude statusLine JSON into the canonical agent-statusline format.

set -euo pipefail

core_dir="${AGENT_STATUSLINE_DIR:-$HOME/.local/share/agent-statusline}"
input=$(cat)

# Feed rate_limits to the herdr usagebar plugin (sidebar $limit + toasts).
# Its own summary output is discarded; failures never break the statusline.
herdr_plugins="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/plugins/github"
for usagebar in "$herdr_plugins"/usagebar-*/bin/run-statusline.sh; do
  [ -f "$usagebar" ] || continue
  printf '%s' "$input" | bash "$usagebar" >/dev/null 2>&1 || true
  break
done

printf '%s' "$input" | jq -c '{
  cwd: (.cwd // .workspace.current_dir // ""),
  model: (.model // {}),
  context_window: (.context_window // {})
}' | "$core_dir/statusline.sh"

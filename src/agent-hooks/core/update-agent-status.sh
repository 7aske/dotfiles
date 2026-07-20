#!/usr/bin/env bash
# Persist agent session status for the i3status-rs agent block.
#
# Usage (stdin JSON):
#   { status, cwd?, session?, agent?, signal? }
# Or argv: update-agent-status.sh <status> [session]

set -euo pipefail

STATUS_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/agent-statusbar"
SIGNAL="${AGENT_STATUSBAR_SIGNAL:-11}"

mkdir -p "$STATUS_DIR"

if [ -t 0 ] || [ $# -ge 1 ]; then
  status="${1:-}"
  session="${2:-}"
  cwd=""
  agent=""
else
  input=$(cat)
  status=$(printf '%s' "$input" | jq -r '.status // empty')
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
  session=$(printf '%s' "$input" | jq -r '.session // empty')
  agent=$(printf '%s' "$input" | jq -r '.agent // empty')
fi

[ -n "$status" ] || exit 0

if [ -z "$session" ]; then
  base=$(basename "${cwd:-}")
  if [ -z "$base" ] || [ "$base" = "." ] || [ "$base" = "/" ] || [ "$base" = ".agent" ]; then
    base="default"
  fi
  session="agent-$base"
fi

now=$(date +%s)
tmp=$(mktemp)
jq -n \
  --arg status "$status" \
  --arg session "$session" \
  --arg cwd "${cwd:-}" \
  --arg agent "${agent:-}" \
  --argjson updated "$now" \
  '{status:$status, session:$session, cwd:$cwd, agent:$agent, updated:$updated}' >"$tmp"
mv "$tmp" "$STATUS_DIR/${session}.json"

# nudge the status bar (best-effort; hooks often run outside the GUI session)
pkill -SIGRTMIN+"$SIGNAL" i3status-rs 2>/dev/null || true

exit 0

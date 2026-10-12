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

# Nudge the status bar (best-effort; hooks may run outside the GUI session).
pkill -x -SIGRTMIN+"$SIGNAL" i3status-rs 2>/dev/null || true

# Ring the agent's tmux pane bell when it stops working (waiting/ready/error/idle),
# so tmux flags the window (tmux-dash turns its title red). Hooks run detached from
# the terminal with piped stdio, so write to the pane's tty looked up via TMUX_PANE.
if [ "$status" != working ] && [ -n "${TMUX_PANE:-}" ]; then
  tty=$(tmux display -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null) && [ -w "$tty" ] && printf '\a' >"$tty" || true
fi

exit 0

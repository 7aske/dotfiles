#!/usr/bin/env bash
# Bring the herdr client window to front and focus the agent's pane.
#
# Usage: herdr-open.sh [pane_id]
#   pane_id  herdr pane of the agent (HERDR_PANE_ID captured by the hook);
#            without it only the herdr window is raised.

set -uo pipefail

pane="${1:-}"

# Window of a running herdr client (the `herdr` process whose parent is the terminal).
herdr_wid() {
  local pid ppid
  for pid in $(pgrep -x herdr); do
    case "$(ps -o args= -p "$pid")" in *" server"*) continue ;; esac
    ppid=$(ps -o ppid= -p "$pid" | tr -d ' ')
    xdotool search --pid "$ppid" 2>/dev/null | head -n1 && return 0
  done
  return 1
}

if [ -n "$pane" ]; then
  herdr agent focus "$pane" >/dev/null 2>&1 \
    || herdr workspace focus "${pane%%:*}" >/dev/null 2>&1 || true
fi

if wid=$(herdr_wid) && [ -n "$wid" ]; then
  # i3 shows the window if it was moved to the scratchpad.
  i3-msg "[id=$wid] focus" >/dev/null 2>&1
else
  # Same command as rofi-actions / statusbar so wtoggle2 reuses the window later.
  exec wtoggle2 -d 90%x90% "kitty --override background_opacity=1 --class floating herdr"
fi

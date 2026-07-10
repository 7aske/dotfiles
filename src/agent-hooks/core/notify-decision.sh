#!/usr/bin/env bash
# Desktop notification when the agent is waiting for user input.
#
# stdin: canonical notification payload
#   { message, cwd, session_id?, agent }

set -euo pipefail

input=$(cat)
. "$(dirname "$0")/notify-env.sh"

message=$(printf '%s' "$input" | jq -r '.message // "Waiting for your input"')
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
agent=$(printf '%s' "$input" | jq -r '.agent // "claude"')

base=$(basename "$cwd")
[ "$base" = ".agent" ] && base="default"
export CC_DIR="$cwd"
export CC_SESSION="agent-$base"
export CC_MSG="$message"

case "$agent" in
  cursor)
    app_name="Cursor Agent"
    icon="/usr/share/pixmaps/co.anysphere.cursor.png"
    title="Cursor Agent — $CC_SESSION"
    ;;
  *)
    app_name="Claude Code"
    icon="/usr/share/icons/hicolor/256x256/apps/claude-desktop.png"
    title="Claude Code — $CC_SESSION"
    ;;
esac

body="$CC_MSG
$CC_DIR"
if [ -n "$session_id" ]; then
  body="${body}  (session ${session_id})"
fi

export NOTIFY_TITLE="$title"
export NOTIFY_BODY="$body"
export NOTIFY_ICON="$icon"
export NOTIFY_APP="$app_name"

setsid -f bash -c '
  action=$(notify-send -u critical -i "$NOTIFY_ICON" -a "$NOTIFY_APP" \
    -A "open=Open in tmux" \
    "$NOTIFY_TITLE" \
    "$NOTIFY_BODY")
  if [ "$action" = "open" ]; then
    instance="$CC_SESSION"
    wid=$(xdotool search --role "^tmux-${instance}$" 2>/dev/null | head -n1)
    if [ -n "$wid" ]; then
      i3-msg "[id=$wid] focus" >/dev/null 2>&1
    else
      exec kitty --name "$instance" --class floating \
        --override background_opacity=1 \
        fzf-agent "$instance"
    fi
  fi
' >/dev/null 2>&1

exit 0

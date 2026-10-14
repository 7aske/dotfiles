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

printf '%s' "$input" | jq -c --arg session "$CC_SESSION" \
  '{status:"waiting", cwd:(.cwd // ""), session:$session, agent:(.agent // "claude")}' \
  | "$(dirname "$0")/update-agent-status.sh" || true

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

body="$(pango_span "$yellow" "$CC_MSG")"
[ -n "$CC_DIR" ] && body="${body}
$(pango_span "$color8" "$CC_DIR")"
if [ -n "$session_id" ]; then
  body="${body}
$(pango_span "$color8" "(session ${session_id})")"
fi

export NOTIFY_TITLE="$title"
export NOTIFY_BODY="$body"
export NOTIFY_ICON="$icon"
export NOTIFY_APP="$app_name"
# Hooks run inside the agent's herdr pane; remember it for the "open" action.
export NOTIFY_HERDR_PANE="${HERDR_PANE_ID:-}"
export NOTIFY_HERDR_OPEN="$(cd "$(dirname "$0")" && pwd)/herdr-open.sh"

setsid -f bash -c '
  action=$(notify-send -u critical -i "$NOTIFY_ICON" -a "$NOTIFY_APP" \
    -A "open=Open in herdr" \
    "$NOTIFY_TITLE" \
    "$NOTIFY_BODY")
  if [ "$action" = "open" ]; then
    exec "$NOTIFY_HERDR_OPEN" "$NOTIFY_HERDR_PANE"
  fi
' >/dev/null 2>&1

exit 0

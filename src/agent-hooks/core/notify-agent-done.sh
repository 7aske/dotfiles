#!/usr/bin/env bash
# Desktop notification when the agent finishes a run.
#
# stdin: canonical stop payload
#   { status, cwd, hook_event_name?, loop_count?, agent }

set -euo pipefail

input=$(cat)
. "$(dirname "$0")/notify-env.sh"

status=$(printf '%s' "$input" | jq -r '.status // "completed"')
hook_event_name=$(printf '%s' "$input" | jq -r '.hook_event_name // "stop"')
loop_count=$(printf '%s' "$input" | jq -r '.loop_count // 0')
workspace=$(printf '%s' "$input" | jq -r '.cwd // ""')
agent=$(printf '%s' "$input" | jq -r '.agent // "cursor"')
project=$(basename "$workspace")
[ "$project" = ".agent" ] && project="default"

export CC_DIR="$workspace"
export CC_SESSION="agent-$project"

case "$status" in
  error) bar_status=error ;;
  aborted) bar_status=idle ;;
  *) bar_status=ready ;;
esac
printf '%s' "$input" | jq -c --arg session "$CC_SESSION" --arg status "$bar_status" \
  '{status:$status, cwd:(.cwd // ""), session:$session, agent:(.agent // "cursor")}' \
  | "$(dirname "$0")/update-agent-status.sh" || true

case "$agent" in
  cursor)
    app_name="Cursor Agent"
    icon="/usr/share/pixmaps/co.anysphere.cursor.png"
    ;;
  *)
    app_name="Claude Code"
    icon="/usr/share/icons/hicolor/256x256/apps/claude-desktop.png"
    ;;
esac

case "$status" in
  completed)
    urgency=normal
    title="${app_name} — done"
    body="$(pango_span "$green" "Finished in ${project}")"
    ;;
  error)
    urgency=critical
    title="${app_name} — error"
    body="$(pango_span "$red" "Stopped with an error in ${project}")"
    ;;
  aborted)
    urgency=low
    title="${app_name} — stopped"
    body="$(pango_span "$orange" "Run was interrupted in ${project}")"
    ;;
  *)
    urgency=normal
    title="${app_name} — ${status}"
    body="$(pango_span "$white" "$project")"
    ;;
esac

if [ -n "$workspace" ]; then
  body="${body}
$(pango_span "$color8" "$workspace")"
fi

if [ "$loop_count" != "0" ] && [ "$loop_count" != "null" ]; then
  body="${body}
$(pango_span "$color8" "(auto follow-up loop ${loop_count})")"
fi

log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/agent-hooks"
log_file="$log_dir/notify-agent-done.log"
mkdir -p "$log_dir"

export NOTIFY_TITLE="$title"
export NOTIFY_BODY="$body"
export NOTIFY_URGENCY="$urgency"
export NOTIFY_ICON="$icon"
export NOTIFY_APP="$app_name"

printf '%s event=%s status=%s display=%s\n' \
  "$(date -Is)" "$hook_event_name" "$status" "$DISPLAY" >>"$log_file"

setsid -f bash -c '
  action=$(notify-send -u "$NOTIFY_URGENCY" -i "$NOTIFY_ICON" -a "$NOTIFY_APP" \
    -A "open=Open in tmux" \
    "$NOTIFY_TITLE" \
    "$NOTIFY_BODY" 2>>"'"$log_file"'")
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
' >/dev/null 2>>"$log_file" &

exit 0

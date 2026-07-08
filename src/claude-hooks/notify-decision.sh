#!/usr/bin/env bash
# Claude Code `Notification` hook.
# Pops a desktop notification when a decision/input is waiting, with a
# clickable "Open in tmux" action that attaches to this session's tmux
# session inside a floating kitty window.
#
# stdin: the Notification hook JSON payload
#   { session_id, transcript_path, cwd, hook_event_name, message, notification_type }

input=$(cat)

export CC_MSG=$(printf '%s' "$input" | jq -r '.message // "Waiting for your input"')
export CC_DIR=$(printf '%s' "$input" | jq -r '.cwd // ""')
export CC_SID=$(printf '%s' "$input" | jq -r '.session_id // ""' | cut -c1-8)

# tmux session name: agent-<basename of cwd>, with ".agent" -> "default".
base=$(basename "$CC_DIR")
[ "$base" = ".agent" ] && base="default"
export CC_SESSION="agent-$base"

# Detach: notify-send -A implies --wait (blocks until clicked/dismissed),
# so run it in its own session to avoid blocking Claude Code's hook.
setsid -f bash -c '
  action=$(notify-send -u critical -i /usr/share/icons/hicolor/256x256/apps/claude-desktop.png -a "Claude Code" \
    -A "open=Open in tmux" \
    "Claude Code — $CC_SESSION" \
    "$CC_MSG
$CC_DIR  (session $CC_SID)")
  if [ "$action" = "open" ]; then
    # Unique per-session kitty instance (WM_CLASS name); class stays
    # "floating" so the i3 floating rule still applies.
    instance="$CC_SESSION"
    wid=$(xdotool search --role "^tmux-${instance}$" 2>/dev/null | head -n1)
    if [ -n "$wid" ]; then
      # Already open: switch to its workspace and focus it.
      i3-msg "[id=$wid] focus" >/dev/null 2>&1
    else
      exec kitty --name "$instance" --class floating  \
        --override background_opacity=1 \
        fzf-agent "$instance"
    fi
  fi
' >/dev/null 2>&1

exit 0

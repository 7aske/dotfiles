#!/usr/bin/env sh

sessions="$({ tmux ls -F#S; echo 'agent-default'; } | grep --color=none 'agent-' | sort | uniq)"

# if only one session is found, attach to it
if [ "$(echo "$sessions" | wc -l)" -eq 1 ]; then
    session="$sessions"
else
    session="$(echo "$sessions" | fzf --prompt 'Agent session: ')"
fi

if [ -z "$session" ]; then
    exit 1
fi

if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new -s "$session" -d -c "$HOME/.agent" "$AGENT"
fi

tmux a -t "$session"

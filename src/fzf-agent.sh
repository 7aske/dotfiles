#!/usr/bin/env sh

session="$({ tmux ls -F#S; echo 'agent-default'; } | grep --color=none 'agent-' | sort | uniq | fzf --prompt 'Agent session: ')"

if [ -z "$session" ]; then
    exit 1
fi

if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new -s "$session" -d -c "$HOME/.agent" "$AGENT"
fi

tmux a -t "$session"

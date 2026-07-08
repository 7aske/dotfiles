#!/usr/bin/env sh

[ -e "$HOME/.profile" ] && . "$HOME/.profile"

sessions="$({ tmux ls -F#S; echo 'agent-default'; } | grep --color=none 'agent-' | sort | uniq)"


if [ -n "$1" ]; then
    session="$1"
# if only one session is found, attach to it
elif [ "$(echo "$sessions" | wc -l)" -eq 1 ]; then
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

if [ -n "$WINDOWID" ]; then
    xprop -id "$WINDOWID" -f WM_WINDOW_ROLE 8s -set WM_WINDOW_ROLE "tmux-$session"
fi

tmux a -t "$session"

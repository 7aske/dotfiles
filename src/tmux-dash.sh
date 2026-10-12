#!/usr/bin/env bash
# tmux-dash: tile a live view of every agent-* tmux session
# tmux-dash --add SESSION: add SESSION to a running dash (called by tmux hooks)
DASH=dash
PREFIX=agent-
SELF="$(readlink -f "$0")"
PEEK="$(dirname "$SELF")/tmux-peek"
CONF="$HOME/.config/tmux/.tmux.conf"
tmux() { if [[ -f $CONF ]]; then command tmux -f "$CONF" "$@"; else command tmux "$@"; fi; }

# add_pane SESSION: split a mirror of SESSION into the dash, without stealing focus
add_pane() {
  local pane
  pane=$(tmux split-window -d -P -F '#{pane_id}' -t "$DASH" "$PEEK '$1'") || return
  tmux set -p -t "$pane" @peek "$1"
  tmux select-pane -t "$pane" -T "$1"
  # drop the "waiting" placeholder (a pane mirroring nothing), then re-tile
  tmux list-panes -t "$DASH" -F '#{pane_id} #{@peek}' | awk 'NF == 1 { print $1 }' |
    while read -r p; do tmux kill-pane -t "$p"; done
  tmux select-layout -t "$DASH" tiled
}

if [[ $1 == --add ]]; then
  s="$2"
  [[ $s == "$PREFIX"* ]] || exit 0
  tmux has-session -t "=$DASH" 2>/dev/null || exit 0
  tmux list-panes -t "$DASH" -F '#{@peek}' | grep -qxF "$s" && exit 0
  add_pane "$s"
  exit
fi

tmux kill-session -t "=$DASH" 2>/dev/null

# start with the placeholder, then add every existing agent session
tmux new-session -d -s "$DASH" -x 250 -y 60 "$PEEK"
tmux select-pane -t "$DASH" -T '(no agents)'
while read -r s; do
  [[ $s == "$PREFIX"* ]] && add_pane "$s"
done < <(tmux list-sessions -F '#S')

tmux set -t "$DASH" pane-border-status top
# red title with a bell marker when the agent rang the bell (see tmux-peek), else yellow for the active pane, cyan otherwise
tmux set -t "$DASH" pane-border-format '#{?#{@bell},#[fg=white#,bg=red#,bold] 🔔,#{?pane_active,#[fg=black#,bg=yellow#,bold],#[fg=black#,bg=cyan#,bold]}} #{pane_title} #[default]'
tmux set -t "$DASH" pane-border-lines heavy
tmux set -t "$DASH" mouse on
# re-tile whenever a pane goes away (killed by hand, or its session ended)
tmux set-hook -t "$DASH" after-kill-pane 'select-layout tiled'
tmux set-hook -t "$DASH" pane-exited 'select-layout tiled'
# auto-add new (or renamed-to) agent-* sessions; index 42 avoids clobbering other hooks
tmux set-hook -g 'session-created[42]' "run-shell -b \"$SELF --add #{q:hook_session_name}\""
tmux set-hook -g 'session-renamed[42]' "run-shell -b \"$SELF --add #{q:hook_session_name}\""

if [[ -n $TMUX ]]; then tmux switch-client -t "$DASH"; else tmux attach -t "$DASH"; fi

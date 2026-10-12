#!/usr/bin/env bash
# tmux-peek SESSION: live mirror of the first pane of a session's first window
# tmux-peek        : placeholder shown while the dash has no agent sessions
s="$1"
me="$TMUX_PANE"  # target our own dash pane explicitly; tmux's default is the dash's active pane
# hide cursor and disable autowrap so long lines are truncated, not wrapped
tput civis; printf '\033[?7l'
trap "tput cnorm; printf '\033[?7h'" EXIT

wait_for_agents() {
  printf '\033[H\033[Jwaiting for agent-* sessions...'
  exec sleep infinity
}

[[ -z $s ]] && wait_for_agents

# set_bell 0|1: flag this dash pane (styled by tmux-dash's border format) and redden its border
bell=0
set_bell() {
  (( $1 == bell )) && return
  bell=$1
  if (( bell )); then
    tmux set -p -t "$me" @bell 1 \; set -p -t "$me" pane-border-style fg=red \; set -p -t "$me" pane-active-border-style fg=red
  else
    tmux set -pu -t "$me" @bell \; set -pu -t "$me" pane-border-style \; set -pu -t "$me" pane-active-border-style
  fi
}

while true; do
  # always mirror the first pane of the first window ("=" = exact session name, "^" = lowest window)
  # tmux keeps the bell flag until the agent's window is viewed in an attached client
  read -r pane bellflag < <(tmux list-panes -t "=$s:^" -F '#{pane_id} #{window_bell_flag}' 2>/dev/null)
  set_bell "${bellflag:-0}"
  # $(...) strips trailing blank lines before tail, so a mostly-empty pane still shows its content
  if [[ -n $pane ]] && out=$(tmux capture-pane -ep -t "$pane" 2>/dev/null); then
    out=$(tail -n "$(tput lines)" <<<"$out")
  else
    # session is gone: close this pane (tmux-dash's hook re-tiles the rest),
    # unless it is the last one, which would end the dash session
    if (( $(tmux list-panes -t "$me" | wc -l) > 1 )); then exit 0; fi
    tmux set -p -t "$me" @peek '' \; select-pane -t "$me" -T '(no agents)'
    wait_for_agents
  fi
  printf '\033[H\033[J%s' "$out"
  sleep 1
done

#!/usr/bin/env bash

usage() {
    echo "i3btf <command>"
    echo "if running toggles process window visibility, if not runs it"
    exit 2
}

is_visible() {
    [ -z "$1" ] && return 2

    for vis in $visible; do
        for win in $(xdotool search --pid "$1"); do
            [ "$vis" = "$win" ] && return 0
        done
    done
    return 1
}

[ -z "$1" ] && usage

visible="$(xdotool search --all --onlyvisible --desktop "$(xprop -notype -root _NET_CURRENT_DESKTOP | cut -c 24-)" "" 2>/dev/null)"
program="$(basename $1)"
processes="$(pgrep "$program")"

if [ -n "$processes" ]; then
    for proc in $processes; do
        is_visible "$proc" && i3-msg "[class=(?i)$program] move container to scratchpad" 2>&1 >/dev/null && exit 0 
    done

    i3-msg "[class=(?i)$program] move container to workspace current floating enable focus" 2>&1 >/dev/null
else
    (
        i3-msg "exec --no-startup-id $1"  2>&1 >/dev/null
        sleep 1
        i3-msg "[class=(?i)$program] floating enable focus"  2>&1 >/dev/null
    ) &
fi

#!/usr/bin/env bash

# small script to manage startup programs

XPROFILE="$HOME/Code/sh/dotfiles/.xprofile"
MENU="${MENU:-"dmenu -l 20"}"
echo "$MENU"

get_cmd() {
    startup_list | grep "$1" | sed '1q' | awk '{print $1}'
}

startup_stop() {
    if [ -z "$1" ] && [ -n "$MENU" ]; then
        cmd="$(startup_list | $MENU | awk '{print $1}')"
    else
        cmd="$(echo "$1" | awk '{print $1}')"
    fi
    killall "$(get_cmd "$cmd")" && notif "$(get_cmd "$cmd") killed"
    return 0
}

startup_restart() {
    if [ -z "$1" ] && [ -n "$MENU" ]; then
        cmd="$(startup_list | $MENU | awk '{print $1}')"
    else
        cmd="$(echo "$1" | awk '{print $1}')"
    fi
    startup_stop "$cmd" && startup_start "$cmd"
}

startup_start() {
    if [ -z "$1" ] && [ -n "$MENU" ]; then
        cmd="$(startup_list | $MENU | awk '{print $1}')"
    else
        cmd="$(echo "$1" | awk '{print $1}')"
    fi

    pgrep "$cmd" >/dev/null 2>&1 && notif "$(get_cmd "$cmd") already running" && exit 0
    cmd="$(startup_list | grep "$cmd" | sed '1q')"
    echo "$cmd &"
    eval "($cmd &)" >/dev/null 2>&1 &&  notif "$(get_cmd "$cmd") started" && exit 0
    echo "startup: $(get_cmd "$cmd") failed" && exit 1
}

startup_add() {
    [ -z "$1" ] && return 1
    cmd="$(echo "$1" | awk '{print $1}')"
    [ -z "$(command -v "$cmd")" ] && notif "$cmd not found" && exit 1
    echo "$1 &" | tee -a "$XPROFILE"
}
startup_remove() {
    if [ -z "$1" ] && [ -n "$MENU" ]; then
        cmd="$(startup_list | $MENU | awk '{print $1}')"
    else
        cmd="$(echo "$1" | awk '{print $1}')"
    fi

    sed -i "s/^$cmd.*$//" "$XPROFILE"
}

startup_list() {
    grep "&$" "$XPROFILE" | sed 's/ &$//'
}

notif(){
    notify-send "$0" "$1"; echo "$0: $1" 
}

usage() {
    printf "usage: startup <command> [arg]\n"
    printf "commands:\n"
    printf "    %s%s\n" "stop    " "<prog>"
    printf "    %s%s\n" "start   " "<prog>"
    printf "    %s%s\n" "restart " "<prog>"
    printf "    %s%s\n" "add     " "<command>"
    printf "    %s%s\n" "remove  " "<prog>"
    printf "    %s\n" "list    "

    exit 2
}

[ -z "$1" ] && usage
[ "$1" = "-h" ] && usage
[ "$1" = "help" ] && usage

case "$1" in
"stop") startup_stop "${@:2}" ;;
"start") startup_start "${@:2}" ;;
"restart") startup_restart "${@:2}" ;;
"add") startup_add "${@:2}" ;;
"remove") startup_remove "${@:2}" ;;
"list") startup_list "${@:2}" ;;
esac || usage

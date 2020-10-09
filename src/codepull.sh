#!/usr/bin/env bash

[ ! -x "$(command -v git)" ] && echo -e "\e[1;31mgit: command not found\e[0m" && exit 2
[ -z "$CODE" ] && echo -e "\e[1;31m'CODE' env variable not set\e[0m" && exit 2

REPOS=("sh/dotfiles" "sh/autosetup" "uni" "sh/scripts")

usage() {
    echo "pullall.sh [options]"
    echo "options:"
    echo "  -A      pull all repos from 'CODE'"
    exit 1
}

git_pull() {
    echo -e "\e[32m$1\e[0m"
    [ ! -d "$CODE/$1/.git" ] && echo "$1: not a git repository" && return
    git -C "$CODE/$1" pull 2>/dev/null | while read -r OUTPUT; do
        if command -v "notify-send" 1>/dev/null; then
            notify-send -u low -i git "$1" "$OUTPUT"
        else
            echo "$1" "$OUTPUT"
        fi
    done &
}

if [ "$1" == "-A" ]; then
    for LANG in $(dir "$CODE"); do
        if grep -q "$LANG" "$CODE/.codeignore"; then continue; fi
        d="$CODE/$LANG"
        [ -d "$d/.git" ] && continue
        for REPO in $(dir "$d"); do
            git_pull "$LANG/$REPO"
        done
    done
elif [ -z "$1" ]; then
    for REPO in "${REPOS[@]}"; do
        if [ -d "$CODE/$REPO" ]; then
            git_pull "$REPO"
        fi
    done
else
    usage
fi

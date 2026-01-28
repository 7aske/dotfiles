#!/usr/bin/env bash

autocomplete() {
    local cur_word="${COMP_WORDS[COMP_CWORD]}"
    local layouts
    layouts=$(find "$HOME/.screenlayout" -type f -name "*.sh" -printf "%f\n")
    COMPREPLY=($(compgen -W "$layouts" -- "$cur_word"))
}
complete -F autocomplete screenlayout


SCREENLAYOUT_DIR="$HOME/.screenlayout"

if [ -n "$1" ]; then
    LAYOUT="$1"
else
    LAYOUT="$(basename "$(find "$SCREENLAYOUT_DIR" -type f -name "*.sh" -printf "%f\n" | rofi -dmenu -p "Select screen layout")")"
fi

if [ -n "$LAYOUT" ]; then
    notify-send -a screenlayout -i display -t 1000 "Screenlayout" "Applying screen layout: $LAYOUT"
    bash "$SCREENLAYOUT_DIR/$LAYOUT"
fi

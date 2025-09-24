#!/usr/bin/env bash

STATUSBAR_DIR="$HOME/.local/bin/statusbar"

STATUSBAR_FILE="$HOME/.cache/statusbar"

module="$(dir -1 "$STATUSBAR_DIR" | rofi -dmenu -i -p "Toggle statusbar module")"

if [ -n "$module" ]; then
    KLILL_FILE="$STATUSBAR_FILE"_"$module"_kill

    if [ -e "$KLILL_FILE" ]; then
        rm "$KLILL_FILE"
    else
        touch "$KLILL_FILE"
    fi
    i3-msg restart
fi

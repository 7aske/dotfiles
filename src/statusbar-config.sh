#!/usr/bin/env bash

STATUSBAR_DIR="$HOME/.local/bin/statusbar"

STATUSBAR_FILE="$HOME/.cache/statusbar"

module="$(for m in $(dir -1 "$STATUSBAR_DIR"); do
    if grep -E 'KILL_SWITCH|libbar_kill_switch' "$STATUSBAR_DIR/$m" &> /dev/null; then
        if [ "$m" = "libbar" ]; then
            continue
        fi
        KILL_FILE="$STATUSBAR_FILE"_"$m"_kill
        echo "($([ -e "$KILL_FILE" ] && echo "x" || echo "✓")) $m"
    fi
done | rofi -dmenu -i -p "Toggle statusbar module")"


if [ -n "$module" ]; then
    KILL_FILE="$STATUSBAR_FILE"_"$(echo "$module" | sed -n 's/([x|✓]) \(.*\)/\1/p')"_kill

    if [ -e "$KILL_FILE" ]; then
        rm "$KILL_FILE"
    else
        touch "$KILL_FILE"
    fi
    i3-msg restart
fi

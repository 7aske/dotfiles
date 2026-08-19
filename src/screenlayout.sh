#!/usr/bin/env bash

SCREENLAYOUT_DIR="$HOME/.screenlayout"
DEFAULT_LAYOUT_ICON="󰍺"

get_layout_icon() {
    local layout_path="$1"
    local icon

    # Layout scripts can define either:
    #   SCREENLAYOUT_ICON="󰡘"
    # or:
    #   # icon: 󰡘
    icon="$(sed -nE '
        s/^[[:space:]]*SCREENLAYOUT_ICON[[:space:]]*=[[:space:]]*["'"'"']?([^"'"'"']+)["'"'"']?[[:space:]]*$/\1/p
        t found
        s/^[[:space:]]*#[[:space:]]*icon[[:space:]]*:[[:space:]]*(.+)[[:space:]]*$/\1/p
        t found
        b
        :found
        q
    ' "$layout_path")"

    if [ -n "$icon" ]; then
        echo "$icon"
    else
        echo "$DEFAULT_LAYOUT_ICON"
    fi
}

if [ -n "$1" ]; then
    LAYOUT="$1"
else
    if [ ! -d "$SCREENLAYOUT_DIR" ]; then
        echo "Layout directory not found: $SCREENLAYOUT_DIR"
        exit 1
    fi

    readarray -t layouts < <(find "$SCREENLAYOUT_DIR" -type f -name "*.sh" -printf "%f\n" | sed 's/\.sh$//' | sort)

    if [ "${#layouts[@]}" -eq 0 ]; then
        echo "No layouts found in $SCREENLAYOUT_DIR"
        exit 1
    fi

    menu_entries=()
    for layout in "${layouts[@]}"; do
        layout_path="$SCREENLAYOUT_DIR/$layout.sh"
        menu_entries+=("$(get_layout_icon "$layout_path")"$'\t'"$layout")
    done

    selected="$(printf '%s\n' "${menu_entries[@]}" | rofi -dmenu -p "Select screen layout")"
    LAYOUT="${selected#*$'\t'}"
fi

if [ -z "$LAYOUT" ]; then
    echo "No layout selected"
    exit 1
fi

notify-send -a screenlayout -i display -t 2000 "Screenlayout" "Applying screen layout: $LAYOUT"
bash "$SCREENLAYOUT_DIR/$LAYOUT.sh"

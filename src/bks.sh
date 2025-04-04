#!/usr/bin/env bash

case "$BROWSER" in
    "brave-browser" | "brave")
        SELECTED_URL="$(cat "$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser/Default/Bookmarks" \
            | jq -r '.roots.bookmark_bar.children[] | if .children then (.children[] | select(.url) ) else . end | (.name + " (" + (.url) + ")")' \
            | rofi -i -dmenu \
            | sed -e 's/^.* (\(.*\))$/\1/')"
        ;;
    *) echo "$BROWSER is not supported."
        exit 1
        ;;
esac

if [ -z "$SELECTED_URL" ]; then
    exit 1
fi

xdg-open "$SELECTED_URL" &>/dev/null

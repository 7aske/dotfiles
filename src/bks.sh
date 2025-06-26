#!/usr/bin/env bash

BROWSER_FLAGS="${BROWSER_FLAGS:-"--new-window"}"


_brave_bks() {
    local flags="$XDG_CONFIG_HOME/brave-flags.conf"

    local profile="Default"

    if [ -e "$flags" ]; then
        profile="$(cat "$flags" | grep -E '^--profile-directory=' | cut -d'=' -f2)"
    fi

    SELECTED_URL="$(cat "$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser/$profile/Bookmarks" \
        | jq -r '.roots.bookmark_bar.children[] | if .children then (.children[] | select(.url) ) else . end | (.name + " (" + (.url) + ")")' \
        | rofi -i -dmenu \
        | sed -e 's/^.* (\(.*\))$/\1/')"
}

case "$BROWSER" in
    "brave-browser" | "brave")
        _brave_bks ;;
    *) echo "$BROWSER is not supported."
        exit 1
        ;;
esac

if [ -z "$SELECTED_URL" ]; then
    exit 1
fi

"$BROWSER" $BROWSER_FLAGS "$SELECTED_URL" &>/dev/null

#!/usr/bin/env bash

_brave_profile() {
    BRAVE_FLAGS="$XDG_CONFIG_HOME/brave-flags.conf"
    BRAVE_STATE="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser/Local State"

    local profile="$(jq -r '
    .profile.info_cache |
        to_entries[] |
        "\(.value.name)(\(.key))"
    ' "$BRAVE_STATE" | rofi -p "Brave profile" -dmenu | sed -E 's/^(.*?)\((.*)\)$/\2/')"

    if [ -z "$profile" ]; then
        exit 0
    fi

    echo "--profile-directory=$profile" > "$BRAVE_FLAGS"
}

case "$BROWSER" in
    brave|brave-browser) _brave_profile ;;
esac


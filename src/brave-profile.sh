#!/usr/bin/env bash

BRAVE_FLAGS="$XDG_CONFIG_HOME/brave-flags.conf"
BRAVE_STATE="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser/Local State"

PROFILE="$(jq -r '
.profile.info_cache |
    to_entries[] |
    "\(.value.name)(\(.key))"
' "$BRAVE_STATE" | rofi -p "Brave profile" -dmenu | sed -E 's/^(.*?)\((.*)\)$/\2/')"

if [ -z "$PROFILE" ]; then
    exit 0
fi

echo "--profile-directory=$PROFILE" > "$BRAVE_FLAGS"

#!/usr/bin/env bash

declare -a actions=()

if [ -x "$(command -v herdr)" ]; then
    while IFS= read -r action; do
        actions+=("$action")
    done < <(herdr plugin action list | jq -r '.result.actions[] | "󰳆 \(.plugin_id + ": " + .title)|herdr plugin action invoke \(.action_id) --plugin \(.plugin_id)"')
fi

menu="fzf"

choice=$(printf '%s\n' "${actions[@]}" | cut -d'|' -f1 | $menu) || exit 0
[ -z "$choice" ] && exit 0

for entry in "${actions[@]}"; do
    label=${entry%%|*}
    cmd=${entry#*|}
    if [ "$label" = "$choice" ]; then
        exec sh -c "$cmd"
    fi
done

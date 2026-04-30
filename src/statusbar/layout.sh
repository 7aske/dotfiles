#!/usr/bin/env bash

declare -A kb_mapping=(
    ["us (N/A)"]="EN"
    ["rs (latin)"]="SR"
    ["rs (N/A)"]="ЋИР"
)

case $BLOCK_BUTTON in
	1) notify-send -i keyboard "Keyboard Layout" "Toggle" && kblang -l us,rs-latin,rs -t ;;
	3) notify-send -i keyboard "Keyboard Layout" "$(setxkbmap -query)" ;;
esac


layout="$(setxkbmap -query | awk '
BEGIN { layout=""; variant="" }
{
    if ($1 == "layout:") {
        layout=$2
    }
    if ($1 == "variant:") {
        variant=$2
    }
}
END { 
    if (layout && variant) {
        print layout " (" variant ")"
    } else if (layout) {
        print layout " (N/A)"
    }
}')"

display="${kb_mapping["$layout"]}"

echo "${display:-$layout}"

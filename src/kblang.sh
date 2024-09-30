#!/usr/bin/env bash

declare -a variants
declare -a variant_keys

if [ -n "$KBLANG_VARIANTS" ]; then
    IFS=',' read -r -a variants <<< "$KBLANG_VARIANTS"
fi

_usage() {
    echo "usage: $(basename $0) [-h] [-l layouts] [-t]"
}

toggle=false
while getopts "h?l:t" opt; do
    case "$opt" in
        h|\?)
            _usage
            ;;
        t) toggle=true ;;
        l) unset variants
            IFS=',' read -r -a variants <<< "$OPTARG" ;;
    esac
done

shift $((OPTIND-1))

if $toggle; then
    selected_layout="$(setxkbmap -query | grep layout | awk '{print $2}')"
    selected_variant="$(setxkbmap -query | grep variant | awk '{print $2}')"
	length="${#variants[@]}"
	index=-1
	current="${variants[@]}"
	for i in "${!variants[@]}"; do
		index=$(($index + 1))
        IFS='-' read -r lay var <<< "${variants[$i]}"
        if [[ "$lay" = "$selected_layout" && ( "$var" = "$selected_variant" ) ]]; then
            break
        fi
	done

	new_index="$((($index + 1) % $length))"
    IFS='-' read -r layout variant <<< "${variants[$new_index]}"
    variant="${variant:-" "}"
fi

if [ -z "$layout" ]; then
	layout="$(cat <(echo "${variants[@]}" | tr ' ' '\n' | awk -F'-' '{print $1}' | sort | uniq) <(localectl list-x11-keymap-layouts --no-pager) | dmenu -fn 'Fira Code-10' -p "layout:")"
fi

if [ -z "$layout" ]; then
	exit 1
fi

if [ -z "$variant" ]; then 
    variant="$(cat <(echo " ") <(echo "${variants[@]}" | tr ' ' '\n' | awk -F'-' '{print $2}' | sort | uniq) <(localectl list-x11-keymap-variants "$layout") | dmenu -fn 'Fira Code-10' -p "$layout:")"
fi

if [ -n "$variant" ] && [ "$variant" != " " ]; then
	setxkbmap -layout "$layout" -variant "$variant"
    notify-send -i keyboard -t 500 "Keyboard Layout" "$layout $variant"
else
	setxkbmap -layout "$layout"
    notify-send -i keyboard -t 500 "Keyboard Layout" "$layout"
fi

[ -f "$HOME/.Xmodmap" ] && xmodmap "$HOME/.Xmodmap"

exit 0

#!/usr/bin/env bash

# preferred layouts to be shown first in layout dmenu prompt
declare -a quick_layouts
quick_layouts=("us" "rs")
declare -A variants
# preferred variants associated with given layouts to be
# shown first in variant dmenu prompt
variants=( ["rs"]="latin" ["us"]=" ")
declare -a variant_keys
variant_keys=( ${!variants[*]} )

if [ "$1" = "-t" ]; then
	selected="$(setxkbmap -query | grep layout | awk '{print $2}')"
	length="${#variants[@]}"
	index=-1
	current="${variants[@]}"
	for i in "${!variants[@]}"; do
		index=$(($index + 1))
		[[ "$i" = "${selected}" ]] && break
	done

	new_index="$((($index + 1) % $length))"
	layout="${variant_keys[$new_index]}"
	variant="${variants[$layout]}"
fi

if [ -z "$layout" ]; then
	layout="$(cat <(IFS=$'\n'; printf "%s\n" ${quick_layouts[@]}) <(localectl list-x11-keymap-layouts --no-pager) | dmenu -fn 'Fira Code-10' -p "layout:")"
fi

if [ -z "$layout" ]; then
	exit 1
fi

if [ -z "$variant" ]; then 
	variant="$(cat <(echo -e "${variants[$layout]}") <(localectl list-x11-keymap-variants "$layout") | dmenu -fn 'Fira Code-10' -p "$layout:")"
fi

if [ -n "$variant" ] && [ "$variant" != " " ]; then
	setxkbmap -layout "$layout" -variant "$variant"
else
	setxkbmap -layout "$layout"
fi

[ -f "$HOME/.Xmodmap" ] && xmodmap "$HOME/.Xmodmap"

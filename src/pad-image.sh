#!/usr/bin/env bash

bgcolor="${2:-white}"
root_dir="$1"

_convert() {
    echo "Padding $1 to color $2"
    parent_dir=$(dirname "$1")
    filename=$(basename "$1")
    ext="${filename##*.}"
    noext="${filename%.*}"
	ww=`convert $1 -ping -format "%w" info:`
	hh=`convert $1 -ping -format "%h" info:`
	max=$((ww > hh ? ww : hh))
    # max="$(echo "$max * 1.2" | bc)"
    # border="$(echo "$max * 0.1" | bc)"

	convert $1 -gravity center -background $2 -extent ${max}x${max} "$parent_dir/${noext}-padded.$ext"
	# convert -bordercolor white -border $border $1 -gravity center -background $2 -extent ${ww}x${hh} $1
}

if [ -z "$root_dir" ] || [ ! -e "$root_dir" ]; then
    echo "usage: $0 <dir/image> [color:-white]"
fi

if [ -d "$root_dir" ]; then
    for file in $(dir -1 $root_dir); do
        path="$root_dir/$file"
        _convert "$path" "$bgcolor"
    done
fi

if [ -f "$root_dir" ]; then
    _convert "$root_dir" "$bgcolor"
fi

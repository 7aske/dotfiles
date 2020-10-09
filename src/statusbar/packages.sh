#!/usr/bin/env sh

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

tempfile="/tmp/yup_prev"
count="$(yup -c)"

prev_count="$(cat "$tempfile")"

if (( $prev_count < $count )); then
	notify-send "updates available" "$(yup -l)"
fi
echo "$count" > "$tempfile"

case "$BLOCK_BUTTON" in
	1) notify-send "updates available" "$(yup -l)" ;; 
esac

if [ "$count" -le 15 ]; then
	color="${color7:-"#ffffff"}"
elif [ "$count" -le 40 ]; then
    color="${color3:-"#fef44e"}"
elif [ "$count" -le 75 ]; then
	color="${color5:-"#ff5252"}"
else
	color="${color1:-"#ff8144"}"
fi

echo " <span color=\"$color\">$count</span>"


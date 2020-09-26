#!/usr/bin/env sh

count="$(pacup -c)"

case "$BLOCK_BUTTON" in
	1) notify-send "updates available" "$(pacup -l)" ;; 
esac

if [ "$count" -le 15 ]; then
	color="#ffffff"
elif [ "$count" -le 40 ]; then
    color="#fef44e"
elif [ "$count" -le 75 ]; then
	color="#ff5252"
else
	color="#ff8144"
fi

echo "<span color=\"$color\">$count</span>"


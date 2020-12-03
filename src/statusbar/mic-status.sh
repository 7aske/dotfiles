#!/usr/bin/env sh


inputs="$(pacmd list-source-outputs | grep application.process.binary)"

case $BLOCK_BUTTON in
	1) notify-send -i audio-recorder "active inputs" "$(echo $inputs | cut -d= -f2 | sed -e 's/["\ ]//g')" ;;
esac

color="#BF616A"

if [ -n "$inputs" ]; then
	echo "<span color='$color'></span>"
fi

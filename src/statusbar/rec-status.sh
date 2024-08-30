#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) killall ffmpeg && notify-send "Screencam" "Recording stopped" ;;
esac

color="${color2:-"#A3BE8C"}"
muted_color="${color1:-"#BF616A"}"

if pgrep -x ffmpeg 1>/dev/null 2>/dev/null; then
	echo "<span color='$color'> </span>"
fi

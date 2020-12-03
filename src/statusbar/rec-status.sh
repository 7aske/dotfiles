#!/usr/bin/env sh

case $BLOCK_BUTTON in
	2) killall ffmpeg ;;
esac

color="#BF616A"

if pgrep -x ffmpeg 1>/dev/null 2>/dev/null; then
	echo "<span color='$color'> </span>"
fi

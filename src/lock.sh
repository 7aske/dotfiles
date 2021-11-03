#!/usr/bin/env bash

revert() {
  xset dpms 0 0 0
}

TMPBG="/tmp/screen.png"
scrot "$TMPBG"
convert "$TMPBG" -scale 10% -scale 1000% "$TMPBG"
convert -gravity center -font "Fira-Code-Bold-Nerd-Font-Complete-Mono" \
	-pointsize 256 -draw "text 0,0 ''" -channel RGBA -fill '#EBCB8B' \
	"$TMPBG" "$TMPBG"
trap revert HUP INT TERM
playerctl pause
xset +dpms dpms 5 5 5
i3lock -u -n -i "$TMPBG" $@
rm "$TMPBG"
revert


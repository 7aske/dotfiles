#!/usr/bin/env bash

# take screenshot
import -window root /tmp/screenshot.png

# blur it
convert /tmp/screenshot.png -blur 0x5 /tmp/screenshotblur.png
rm /tmp/screenshot.png

# lock the screen
betterlockscreen -u /tmp/screenshotblur.png -l dimblur -t locked "$@" &
sleep 10

exit 0

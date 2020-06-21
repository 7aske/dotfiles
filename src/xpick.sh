#!/usr/bin/env sh

color="$(xcolor)"

echo "$color" | xclip -sel c
notify-send --hint=int:transient:1 -t 1000  "xpick" "'$color' copied to clipboard"

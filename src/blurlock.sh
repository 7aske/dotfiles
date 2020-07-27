#!/usr/bin/env bash

blurred="$HOME/.config/wallpaper-blur.png" 
wall="$HOME/.config/wallpaper.png" 

if [ ! -f "$blurred" ]; then
	convert "$wall" -blur 0x5 "$blurred"
fi

# lock the screen
betterlockscreen -u "$blurred" -r "1920x1080" -l dim -t locked "$@" & 

exit 0

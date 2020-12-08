#!/usr/bin/env sh

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

inputs="$(pactl list source-outputs | grep application.process.binary)"

color="${color2:-"#A3BE8C"}"
muted_color="${color1:-"#BF616A"}"
icon=" "
muted_icon=" "

sources="$(pactl list sources short | wc -l)"
muted="$(pactl list sources | grep "Mute: yes" | wc -l)"

if [ $sources -eq $muted ] && [ $muted -gt 0 ]; then
	color="$muted_color"
	icon="$muted_icon"
fi

case $BLOCK_BUTTON in
	1) notify-send -i audio-recorder "toggled inputs" && patoggle sources ;;
	2) pavucontrol ;;
	3) notify-send -i audio-recorder "active inputs" "$(echo $inputs | cut -d= -f2 | sed -e 's/["\ ]//g')" ;;
esac


if [ -n "$inputs" ]; then
	echo "<span color='$color'>$icon</span>"
fi

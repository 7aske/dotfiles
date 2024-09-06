#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

case $BLOCK_BUTTON in
	1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
esac

temp="$(sensors | awk '/Package id 0:/{print substr($4, 2)} /Tdie|Tctl/{print substr($2, 2)}')"
temp_val="$(echo $temp | awk '{print substr($0, 1, length($0)-4)}')"

color="$color7"
if [ "$temp_val" -ge 70 ]; then
	color="$theme11"
    icon=""
elif [ "$temp_val" -ge 60 ]; then
	color="$theme12"
    icon=""
elif [ "$temp_val" -ge 50 ]; then
	color="$theme13"
    icon=""
elif [ "$temp_val" -ge 40 ]; then
	color="$theme15"
    icon=""
else
    icon=""
fi

if [ -e "$SWITCH" ]; then
	printf "<span color=\"%s\" size='large'>%s</span>\n" $color $icon
else
	printf "<span size='large'>$icon</span> <span color=\"%s\">%s</span>\n" $color $temp
fi

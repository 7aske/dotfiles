#!/usr/bin/env sh

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

case $BLOCK_BUTTON in
	1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
esac

temp="$(sensors | awk '/Package id 0:/{print substr($4, 2)} /Tdie/{print substr($2, 2)}')"
temp_val="$(echo $temp | awk '{print substr($0, 1, length($0)-4)}')"

color="$color7"
if [ "$temp_val" -ge 60 ]; then
	color="$theme11"
elif [ "$temp_val" -ge 50 ]; then
	color="$theme12"
elif [ "$temp_val" -ge 40 ]; then
	color="$theme13"
fi

printf "<span color=\"%s\">%s</span>\n" $color $temp

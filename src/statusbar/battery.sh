#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

SWITCH="$HOME/.cache/statusbar_$(basename $0)"

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

battery="$1"
[ -z "$battery" ] && battery="$(dir -1 /sys/class/power_supply | grep -E BAT\? | sed 1q)"
[ -z "$battery" ] && exit 1

status=$(cat /sys/class/power_supply/"$battery"/status)
capacity=$(cat /sys/class/power_supply/"$battery"/capacity) || exit

case $BLOCK_BUTTON in
	1) duration=$(acpi | awk '{print substr($5, 0, length($5) - 3)}')
		notify-send -a battery -i battery "Battery" "$([ "$status" = "Charging" ] && printf "Until charged" || printf "Remaining"): $duration" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) notify-send "󱟦 Battery module" "\n󰂂 : discharging
󰂑 : not charging
󰂄 : charging
: charged/stagnant charge
 : battery very low!" ;;
esac

warn=" "

if [ "$capacity" -eq 100 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰁹"
elif [ "$capacity" -ge 90 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰂂"
elif [ "$capacity" -ge 80 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰂁"
elif [ "$capacity" -ge 70 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰂀"
elif [ "$capacity" -ge 60 ]; then
    color="${color3:-"#EBCB8B"}"
	icon="󰁿"
elif [ "$capacity" -ge 50 ]; then
    color="${color3:-"#EBCB8B"}"
	icon="󰁾"
elif [ "$capacity" -ge 40 ]; then
	color="${theme12:-"#D08770"}"
	icon="󰁽"
elif [ "$capacity" -ge 30 ]; then
	color="${theme12:-"#D08770"}"
	icon="󰁼"
elif [ "$capacity" -ge 20 ]; then
	color="${color1:-"#BF616A"}"
	icon="󰁻"
	warn="  "
elif [ "$capacity" -ge 10 ]; then
	color="${color1:-"#BF616A"}"
	icon="󰁺"
	warn="  "
else
	color="${color1:-"#BF616A"}"
	icon="󰁺"
	warn="  "
fi

[ -z $warn ] && warn=" "

[ "$status" = "Charging" ] && color="${color2:-"#A3BE8C"}"
if ! [ "$status" = "Discharging" ]; then
	icon="$(echo "$status" | sed -e "s/,//;s/Discharging/󰂂/;s/Not [Cc]harging/󰂑/;s/Charging/󰂄/;s/Unknown//;s/Full//;s/ 0*/ /g;s/ :/ /g")"
fi


if [ -e "$SWITCH" ]; then
	echo "<span color='$color'>$icon$warn</span>"
else
	capacity="$(echo "$capacity" | sed -e 's/$/%/')"
	echo "$icon<span color='$color'> $capacity$warn$saver_icon</span>"
fi

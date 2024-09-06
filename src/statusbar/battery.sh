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
    1) if [ "$status" = "Not charging" ]; then
        notify-send -a battery -i battery "Battery" "$status: $capacity%"
    else
        duration=$(acpi | awk '$4 != "0%," {print substr($5, 0, length($5) - 3)}')
        notify-send -a battery -i battery "Battery" "$([ "$status" = "Charging" ] && printf "Until charged" || printf "Remaining"): $duration"
    fi ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) pkexec batconv >/dev/null 2>&1 ;;
esac

warn=" "

if [ "$capacity" -eq 100 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰁹"
    charging="󰂅"
elif [ "$capacity" -ge 90 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰂂"
    charging="󰂋"
elif [ "$capacity" -ge 80 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰂁"
    charging="󰂊"
elif [ "$capacity" -ge 70 ]; then
	color="${color7:-"#D8DEE9"}"
	icon="󰂀"
    charging="󰂉"
elif [ "$capacity" -ge 60 ]; then
    color="${color3:-"#EBCB8B"}"
	icon="󰁿"
    charging="󰂉"
elif [ "$capacity" -ge 50 ]; then
    color="${color3:-"#EBCB8B"}"
	icon="󰁾"
    charging="󰢝"
elif [ "$capacity" -ge 40 ]; then
	color="${theme12:-"#D08770"}"
	icon="󰁽"
    charging="󰂈"
elif [ "$capacity" -ge 30 ]; then
	color="${theme12:-"#D08770"}"
	icon="󰁼"
    charging="󰂇"
elif [ "$capacity" -ge 20 ]; then
	color="${color1:-"#BF616A"}"
	icon="󰁻"
    chrarging="󰂆"
	warn="  "
elif [ "$capacity" -ge 10 ]; then
	color="${color1:-"#BF616A"}"
	icon="󰁺"
    charging="󰢜"
	warn="  "
else
	color="${color1:-"#BF616A"}"
	icon="󰁺"
    charging="󰢟"
	warn="  "
fi

[ -z $warn ] && warn=" "

if [ "$status" = "Charging" ]; then
    color="${color2:-"#A3BE8C"}"
fi


icon="$(echo "$status" | sed -e "s/,//;s/Discharging/$icon/;s/Not [Cc]harging/󰚦/;s/Charging/$charging/;s/Unknown/󰂑/;s/Full//;s/ 0*/ /g;s/ :/ /g")"

setting=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
state=$(cat $setting)

if [ $state -eq 1 ]; then
    icon=""
fi


if [ -e "$SWITCH" ]; then
	echo "<span color='$color'>$icon</span><span color='$color' rise='-1pt'>$warn</span>"
else
	capacity="$(echo "$capacity" | sed -e 's/$/%/')"
	echo "$icon<span color='$color' rise='-1pt'> $capacity</span><span color='$color' rise='-1pt'>$warnsaver_icon</span>"
fi

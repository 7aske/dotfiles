#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.



SWITCH="$HOME/.cache/statusbar_$(basename $0)"
SIDETONE="$HOME/.cache/statusbar_headset_sidetone"

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

OUT="$(headsetcontrol -b | sed -n 's/.*\(Status\|Level\)/\1/p')"

status=$(echo "$OUT" | sed -n 's/.*Status: \([^ ]*\).*/\1/p')
capacity=$(echo "$OUT" | sed -n 's/.*Level: \([0-9]\+\)%/\1/p;s/BATTERY_//')

if [ -n "$BLOCK_BUTTON" ] && [ -z "$capacity" ]; then
    notify-send -a battery -i audio-headset "Headset" "Headset not connected"
	echo "󰟎 "
    exit 0
fi

case $BLOCK_BUTTON in
    1) notify-send -a battery -i battery "Battery" "$(echo "$OUT" | sed 's/BATTERY_AVAILABLE/Discharging/;s/BATTERY_CHARGING/Charging/')" ;;
    2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) [ -e "$SIDETONE" ] && rm "$SIDETONE" || touch "$SIDETONE";
        if [ -e "$SIDETONE" ]; then
            notify-send -i audio-headset "Headset" "Sidetone disabled"
            headsetcontrol -s 0 >/dev/null
        else
            notify-send -i audio-headset "Headset" "Sidetone enabled"
            headsetcontrol -s 64 >/dev/null
        fi ;;
esac

if [ -z "$capacity" ]; then
	echo "󰟎 "
    exit 0
fi

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

if [ "$status" = "BATTERY_CHARGING" ]; then
	icon="󰂄"
    color="${color2:-"#A3BE8C"}"
fi

if [ -e "$SWITCH" ]; then
	echo "<span color='$color'>󰋋 $icon$warn</span>"
else
	capacity="$(echo "$capacity" | sed -e 's/$/%/')"
	echo "󰋋 $icon<span color='$color'> $capacity$warn$saver_icon</span>"
fi

#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

SWITCH="$HOME/.cache/statusbar_$(basename $0)"

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

status=$(cat /sys/class/power_supply/"$1"/status)
capacity=$(cat /sys/class/power_supply/"$1"/capacity) || exit

case $BLOCK_BUTTON in
	1) 
		duration=$(acpi | awk '{print substr($5, 0, length($5) - 3)}')
		notify-send -a battery -i battery "Battery" "$([ "$status" = "Charging" ] && printf "Until charged" || printf "Remaining"): $duration" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) pgrep -x dunst >/dev/null && notify-send " Battery module" "\n : discharging
 : not charging
 : charging
: charged/stagnant charge
 : battery very low!" ;;
esac

saver_icon="  "
saver="$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode)"

if [ "$capacity" -ge 65 ]; then
	color="${color7:-"#D8DEE9"}"
elif [ "$capacity" -ge 40 ]; then
    color="${color3:-"#EBCB8B"}"
elif [ "$capacity" -ge 25 ]; then
	color="${theme12:-"#D08770"}"
else
	color="${color1:-"#BF616A"}"
	warn="  "
fi

[ -z $warn ] && warn=" "
[ "$saver" -eq 0 ] && saver_icon=""

[ "$status" = "Charging" ] && color="${color2:-"#A3BE8C"}"

if [ -e "$SWITCH" ]; then
	printf "<span color='%s'>%s%s</span>\n" \
		"$color" \
		"$(echo "$status" | sed -e "s/,//;s/Discharging//;s/Not Charging//;s/Charging//;s/Unknown//;s/Full//;s/ 0*/ /g;s/ :/ /g")" \
		"$warn"
else
	printf "<span color='%s'>%s%s%s%s</span>\n" \
		"$color" \
		"$(echo "$status" | sed -e "s/,//;s/Discharging//;s/Not Charging//;s/Charging//;s/Unknown//;s/Full//;s/ 0*/ /g;s/ :/ /g")" \
		"$warn" \
		"$(echo "$capacity" | sed -e 's/$/%/')" \
		"$saver_icon"
fi

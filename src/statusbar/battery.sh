#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

case $BLOCK_BUTTON in
    3) pgrep -x dunst >/dev/null && notify-send "🔋 Battery module" " : discharging
 : not charging
 : stagnant charge
 : charging
 : charged
 : battery very low!
- Text color reflects charge left" ;;
esac

capacity=$(cat /sys/class/power_supply/"$1"/capacity) || exit
duration=$(acpi | awk '{print substr($5, 0, length($5) - 3)}')
status=$(cat /sys/class/power_supply/"$1"/status)

if [ "$capacity" -ge 75 ]; then
    color="#77dd77"
elif [ "$capacity" -ge 50 ]; then
	color="#ffffff"
elif [ "$capacity" -ge 25 ]; then
	color="#ff5252"
else
	color="#ff8144"
	warn="❗"
fi

[ -z $warn ] && warn=" "

[ "$status" = "Charging" ] && color="#ffffff"

printf "<span color='%s'>%s%s%s</span>\n" "$color" "$(echo "$status" | sed -e "s/,//;s/Discharging//;s/Not Charging//;s/Charging//;s/Unknown//;s/Full//;s/ 0*/ /g;s/ :/ /g")" "$warn" "$(echo "$capacity" | sed -e 's/$/%/') $([ -n "$duration" ] && echo "($duration)")"

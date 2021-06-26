#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

case $BLOCK_BUTTON in
    3) pgrep -x dunst >/dev/null && notify-send " Battery module" "\n : discharging
 : not charging
 : charging
: charged/stagnant charge
 : battery very low!" ;;
esac

capacity=$(cat /sys/class/power_supply/"$1"/capacity) || exit
duration=$(acpi | awk '{print substr($5, 0, length($5) - 3)}')
saver_icon="  "
status=$(cat /sys/class/power_supply/"$1"/status)
saver="$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode)"

if [ "$capacity" -ge 75 ]; then
	color="${color7:-"#ffffff"}"
elif [ "$capacity" -ge 50 ]; then
    color="${color2:-"#77dd77"}"
elif [ "$capacity" -ge 25 ]; then
	color="${color3:-"#ff5252"}"
else
	color="${color1:-"#ff8144"}"
	warn="  "
fi

[ -z $warn ] && warn=" "
[ "$saver" -eq 0 ] && saver_icon=""

[ "$status" = "Charging" ] && color="#ffffff"

printf "<span color='%s'>%s%s%s%s</span>\n" \
	"$color" \
	"$(echo "$status" | sed -e "s/,//;s/Discharging//;s/Not Charging//;s/Charging//;s/Unknown//;s/Full//;s/ 0*/ /g;s/ :/ /g")" \
	"$warn" \
	"$(echo "$capacity" | sed -e 's/$/%/') $([ -n "$duration" ] && echo "($duration)")" \
	"$saver_icon"

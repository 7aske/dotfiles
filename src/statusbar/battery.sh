#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

SWITCH="$HOME/.cache/statusbar_$(basename $0)"

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

while getopts "b:j" opt; do
    case $opt in
        j) json=true ;;
        b) battery="$OPTARG" ;;
    esac
done

shift $((OPTIND-1))

_json() {
    echo '{"icon": "'${1:-"$(basename $0)"}'", "state":"'${2}'", "text":"'${3}'"}';
}

_span() {
    if [ -n "$3" ]; then
        echo "<span size='large'>$1</span> <span color='$2'>$3</span>"
    else
        echo "<span size='large' color='$2'>$1 </span>"
    fi
}

[ -z "$battery" ] && battery="$(dir -1 /sys/class/power_supply | grep -E BAT\? | sed 1q)"

if ! [ -e "/sys/class/power_supply/$battery/status" ]; then
    if [ $json = true ]; then
        _json "bat_not_available" "Critical"
    else
        _span "󱉞" "#BF616A"
    fi
    exit
fi

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

icons=( "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" )
charging_icons=( "󰢟" "󰢜" "󰂇" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" )
warning_icons=( "  " "  " "  " " " " " " " " " " " " " " " " " )
colors=( "${color1:-"#BF616A"}" "${color1:-"#BF616A"}" "${theme12:-"#D08770"}" "${theme12:-"#D08770"}" "${color3:-"#EBCB8B"}" "${color3:-"#EBCB8B"}" "${color3:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" )
states=( "Critical" "Critical" "Warning" "Warning" "Info" "Info" "Idle" "Idle" "Idle" "Idle" "Idle" )

bat_level=$(($capacity / 10))

color=${colors[$bat_level]}
icon=${icons[$bat_level]}
charging=${charging_icons[$bat_level]}
state=${states[$bat_level]}
warn=${warning_icons[$bat_level]}
json_icon="bat_${bat_level}"
json_charging_icon="bat_charging_${bat_level}"

if [ "$status" = "Charging" ]; then
    color="${color2:-"#A3BE8C"}"
    state="Good"
    icon=$charging
    $json_icon=$json_charging_icon
fi

icon="$(echo "$status" | sed -e "s/,//;s/Discharging/$icon/;s/Not [Cc]harging/󰚦/;s/Charging/$charging/;s/Unknown/󰂑/;s/Full//;s/ 0*/ /g;s/ :/ /g")"

setting=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
state=$(cat $setting)

if [ $state -eq 1 ]; then
    icon=""
    json_icon="bat_saver"
fi


if [ -e "$SWITCH" ]; then
    if [ $json = true ]; then
        _json "$json_icon" "$state"
    else
        echo "<span color='$color'>$icon</span><span color='$color' rise='-1pt'>$warn</span>"
    fi
else
	capacity="$(echo "$capacity" | sed -e 's/$/%/')"

    if [ $json = true ]; then
        _json "$json_icon" "$state" "$capacity"
    else
        echo "$icon<span color='$color' rise='-1pt'> $capacity</span><span color='$color' rise='-1pt'>$warnsaver_icon</span>"
    fi

fi

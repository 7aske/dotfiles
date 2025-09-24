#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

SWITCH="$HOME/.cache/statusbar_$(basename $0)"
SIDETONE="$HOME/.cache/statusbar_headset_sidetone"

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

OUT="$(headsetcontrol -b | sed -n 's/.*\(Status\|Level\)/\1/p')"

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
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

status=$(echo "$OUT" | sed -n 's/.*Status: \([^ ]*\).*/\1/p')
capacity=$(echo "$OUT" | sed -n 's/.*Level: \([0-9]\+\)%/\1/p;s/BATTERY_//')

if [ -n "$BLOCK_BUTTON" ] && [ -z "$capacity" ]; then
    notify-send -a battery -i audio-headset "Headset" "Headset not connected"
    if [ "$json" = "true" ]; then
        _json "headphones_not_connected" "Idle"
    else
        _span "󰟎" "#D8DEE9"
    fi
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
    if [ "$json" = "true" ]; then
        _json "headphones_not_connected" "Idle"
    else
        _span "󰟎" "#D8DEE9"
    fi
    exit 0
fi

icons=( "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" )
charging_icons=( "󰢟" "󰢜" "󰂇" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" )
warning_icons=( "  " "  " "  " " " " " " " " " " " " " " " " " )
colors=( "${color1:-"#BF616A"}" "${color1:-"#BF616A"}" "${theme12:-"#D08770"}" "${theme12:-"#D08770"}" "${color3:-"#EBCB8B"}" "${color3:-"#EBCB8B"}" "${color2:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" )
states=( "Critical" "Critical" "Warning" "Warning" "Info" "Info" "Idle" "Idle" "Idle" "Idle" "Idle" )

bat_level=$(($capacity / 10))

color=${colors[$bat_level]}
icon=${icons[$bat_level]}
charging=${charging_icons[$bat_level]}
state=${states[$bat_level]}
warn=${warning_icons[$bat_level]}
json_icon="bat_${bat_level}"
json_charging_icon="bat_charging_${bat_level}"

if [ "$status" = "BATTERY_CHARGING" ]; then
    color="${color2:-"#A3BE8C"}"
    state="Good"
    icon=$charging
    json_icon=$json_charging_icon
fi

if [ -e "$SWITCH" ]; then
    if [ "$json" = "true" ]; then
        if ! [ "$state" = "Critical" ]; then
            state="Idle"
        fi
        if [ "$state" = "Critical" ]; then
            color="$color0"
        fi

        _json "headphones" "$state" "<span color='$color'>$icon</span>"
    else
        echo "<span color='$color'>󰋋 $icon$warn</span>"
    fi
else
	capacity="$(echo "$capacity" | sed -e 's/$/%/')"
    if [ "$json" = "true" ]; then
        if ! [ "$state" = "Critical" ]; then
            state="Idle"
            color="$theme9"
        fi
        if [ "$state" = "Critical" ]; then
            color="$color0"
        fi

        _json "headphones" "$state" "<span color='$color' rise='-1pt'>$icon $capacity</span>"
    else
        echo "󰋋 <span color='$color'>$icon</span><span color='$color' rise='-1pt'> $capacity$warn</span>"
    fi

fi

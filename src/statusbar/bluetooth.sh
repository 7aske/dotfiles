#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename $0)"
[ -e "$HOME/.local/bin/statusbar/libbat" ] && source "$HOME/.local/bin/statusbar/libbat"
_toggle_switch() {
    [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill "-SIGRTMIN+${1:-'9'}" i3status-rs
}

case $BLOCK_BUTTON in
    1) notify-send -a bluetooth -i bluetooth "Bluetooth Devices" "$(bluetoothctl info)" ;;
    2) _toggle_switch 10 ;;
esac

ZWSP="​"

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

declare -A json_icons
json_icons[bluetooth]="bluetooth"
json_icons[input-keyboard]="keyboard"
declare -A icons
icons[bluetooth]="󰂯"
icons[input-keyboard]=" "

DEVICES="$(bluetoothctl devices Connected | awk '{print $2}')"

_output() {
    local text="$2"
    local icon_override
    if [ "$json" = "true" ]; then
        icon_override="${json_icons[$1]}"
        echo '{"icon": "'$icon_override'", "state":"'${state}'", "text":"'$text'"}';
    else
        icon_override="${icons[$1]}"
        echo "<span color='${color}'>$icon_override $text</span>"
    fi
}

bat_level=100
OUTPUT=""
for device in $DEVICES; do
    info="$(bluetoothctl info "$device")"
    connected="$(echo "$info" |  awk '$1 == "Connected:" {print $2}')"
    icon="$(echo "$info" | awk '$1 == "Icon:" {print $2}')"
    bat="$(echo "$info" | sed -n 's/^\s*Battery Percentage: .* (\(.*\))/\1/p')"
    if [ -z "$bat" ]; then
        continue
    fi

    OUTPUT+="${icons[$icon]}"
    if ! [ -e "$SWITCH" ]; then
        OUTPUT+=" $bat%"
    else
        OUTPUT+=" $(libbat_get_icon "$bat")"
    fi

    if [ $bat -lt $bat_level ]; then
        bat_level="$bat"
    fi
done

libbat_update "$bat_level"

_output "bluetooth" "${OUTPUT}"


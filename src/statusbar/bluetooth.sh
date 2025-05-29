#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename $0)"
_toggle_switch() {
    [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill "-SIGRTMIN+${1:-'9'}" i3status-rs
}

case $BLOCK_BUTTON in
    1) notify-send -a bluetooth -i bluetooth "Bluetooth Devices" "$(bluetoothctl info)" ;;
    2) _toggle_switch 10 ;;
esac

ZWSP="​"

declare -a colors
declare -a states
colors=( "${color1:-"#BF616A"}" "${color1:-"#BF616A"}" "${theme12:-"#D08770"}" "${theme12:-"#D08770"}" "${color3:-"#EBCB8B"}" "${color3:-"#EBCB8B"}" "${color2:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" )
states=( "Critical" "Critical" "Warning" "Warning" "Info" "Info" "Idle" "Idle" "Idle" "Idle" "Idle" )

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
    local color
    local text="$3"
    local icon
    if [ "$json" = "true" ]; then
        icon="${json_icons[$1]}"
        color=${states[$2]}
        echo '{"icon": "'$icon'", "state":"'${color:-"Idle"}'", "text":"'$text'"}';
    else
        icon="${icons[$1]}"
        color=${colors[$2]}
        echo "<span color='${color:-"#5E81AC"}'>$icon $text</span>"
    fi
}

bat_level=10
num_devices=0
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
    fi
    _bat_level="$((bat / 10))"
    if [ $_bat_level -lt $bat_level ]; then
        bat_level="$_bat_level"
    fi
    num_devices=$((num_devices + 1))
done

_output "bluetooth" "$bat_level" "${OUTPUT}"


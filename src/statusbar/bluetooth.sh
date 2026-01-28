#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbat" ] && source "$HOME/.local/bin/statusbar/libbat"
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && source "$HOME/.local/bin/statusbar/libbar"
}

# shellcheck disable=SC2034
{
    libbar_json_icons["bluetooth"]="bluetooth"
    libbar_json_icons["input-keyboard"]="keyboard"
    libbar_icons["bluetooth"]="󰂯"
    libbar_icons["input-keyboard"]=" "
}

libbar_getopts "$@"
shift $((OPTIND-1))

DEVICES="$(bluetoothctl devices Connected | awk '{print $2}')"

_bluetooth_device_info() {
    local device="$1"

    bluetoothctl info "$device" | awk '
$1 == "Alias:" {
    alias = substr($0, index($0,$2))
}
$1 == "Icon:" {
    icon = substr($0, index($0,$2))
}
$1 == "Battery" && $2 == "Percentage:" {
    battery = strtonum($3)
}
END {
    printf "%s\t%s\t%d", alias, icon, battery
}'
}

_bluetooth_show_devices() {
    for device in $DEVICES; do
        IFS=$'\t' read -r alias icon bat < <(_bluetooth_device_info "$device")
        if [ "$bat" -eq 0 ]; then
            continue
        fi

        printf "%s\t%s\t%s%%\n" "${libbar_icons[$icon]}" "$alias" "$bat"
    done | column -t -s $'\t'
}

case $BLOCK_BUTTON in
    1) notify-send -a bluetooth -i bluetooth "Bluetooth Devices" "$(_bluetooth_show_devices)" ;;
    2) libbar_toggle_switch 10 ;;
    3) blueman-manager & ;;
esac

_bluetooth_output() {
    local bat_level=100
    local output=""
    for device in $DEVICES; do
        IFS=$'\t' read -r alias icon bat < <(_bluetooth_device_info "$device")
        if [ "$bat" -eq 0 ]; then
            continue
        fi

        output+="${libbar_icons[$icon]}"
        if ! [ -e "$SWITCH" ]; then
            output+="$bat%"
        else
            output+="$(libbat_get_icon "$bat") "
        fi

        # finding the lowest bat level to output
        if [ "$bat" -lt "$bat_level" ]; then
            bat_level="$bat"
        fi

    done
    output="${output%% }"  # remove trailing space

    # To update colors and icons with the lowest found bat level
    libbat_update "$bat_level"

    libbar_output "bluetooth" "$output"
}

_bluetooth_output


#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"
SIDETONE="$HOME/.cache/statusbar_headset_sidetone"

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbat" ] && . "$HOME/.local/bin/statusbar/libbat"
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && . "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"

# shellcheck disable=SC2034
{
    # init libbar icons
    libbar_json_icons["headphones"]="headphones"
    libbar_json_icons["headphones_not_connected"]="headphones_not_connected"
    libbar_icons["headphones"]="󰋋"
    libbar_icons["headphones_not_connected"]="󰟎"
}

_headset_sidetone() {
    if [ -e "$SIDETONE" ]; then
        rm "$SIDETONE"

        notify-send -i audio-headset "Headset" "Sidetone enabled"
        headsetcontrol -s 64 >/dev/null
    else
        touch "$SIDETONE"

        notify-send -i audio-headset "Headset" "Sidetone disabled"
        headsetcontrol -s 0 >/dev/null
    fi
}

# headsetcontrol exits with code 1 where is no adapter present
read -r capacity status status_text < <(headsetcontrol -b | awk '
BEGIN {
    status_map["BATTERY_AVAILABLE"] = 0
    status_map["BATTERY_UNAVAILABLE"] = -1
    status_map["BATTERY_CHARGING"]  = 1
    status_text_map["BATTERY_AVAILABLE"] = "Discharging"
    status_text_map["BATTERY_UNAVAILABLE"] = "Disconnected"
    status_text_map["BATTERY_CHARGING"]  = "Charging"
    capacity = -1
    status = -1
    status_text = "Unavailable"
}
$0 == "No supported device found" {
    exit 1
}

$1 == "Level:" {
    sub(/%/, "", $2)
    capacity = $2
}

$1 == "Status:" {
    status = status_map[$2]
    if (status == "") {
        status = -1
    }
    status_text = status_text_map[$2]
    if (status_text == "") {
        status_text = "Disconnected"
    }
}

END {
    printf "%s %s %s", capacity, status, status_text
}')

if [ "$status_text" = "Unavailable" ]; then
    libbar_output "headphones_not_connected" ""
    exit 0
elif [ "$status_text" = "Disconnected" ]; then
    if [ -n "$BLOCK_BUTTON" ]; then
        notify-send -a battery -i audio-headset "Headset" "Headset not connected"
    fi

    # shellcheck disable=SC2154
    libbar_output "headphones_not_connected" "$ZWSP" "Warning" "$yellow"
    exit 0
fi

libbat_update "$capacity" "$status"

# shellcheck disable=SC2154
case $BLOCK_BUTTON in
    1) notify-send -a battery -i "$libbat_notif_icon" "Headset Battery" "Capacity: $capacity%\nStatus: $status_text" ;;
    2) libbar_toggle_switch ;;
    3) _headset_sidetone ;;
esac

if [ -e "$SWITCH" ]; then
    # shellcheck disable=SC2154
    libbar_output "headphones" "$libbat_icon"
else
    libbar_output "headphones" "$libbat_icon$capacity%"
fi

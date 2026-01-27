#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"
SIDETONE="$HOME/.cache/statusbar_headset_sidetone"

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbat" ] && . "$HOME/.local/bin/statusbar/libbat"
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && . "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"
shift $((OPTIND-1))

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
read -r capacity status < <(headsetcontrol -b | awk '
BEGIN {
    status_map["BATTERY_AVAILABLE"] = "discharging"
    status_map["BATTERY_UNAVAILABLE"] = "disconnected"
    status_map["BATTERY_CHARGING"]  = "charging"
    status_text_map["BATTERY_AVAILABLE"] = "Discharging"
    status_text_map["BATTERY_UNAVAILABLE"] = "Disconnected"
    status_text_map["BATTERY_CHARGING"]  = "Charging"
    capacity = -1
    status = "unknown"
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
        status = "unknown"
    }
}

END {
    printf "%s %s", capacity, status
}')

echo "$capacity $status" >&2

if [ "$status" == "unknown" ]; then
    libbar_output "headphones_not_connected" ""
    exit 0
elif [ "$status" == "disconnected" ]; then
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
    1) notify-send -a battery -i "$libbat_notif_icon" "Headset Battery" "Capacity: $capacity%\nStatus: $status" ;;
    2) libbar_toggle_switch ;;
    3) _headset_sidetone ;;
esac

if [ -e "$SWITCH" ]; then
    # shellcheck disable=SC2154
    libbar_output "headphones" "$libbat_icon"
else
    libbar_output "headphones" "$libbat_icon$capacity%"
fi

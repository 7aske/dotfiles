#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

SWITCH="$HOME/.cache/statusbar_$(basename $0)"
SIDETONE="$HOME/.cache/statusbar_headset_sidetone"

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"
[ -e "$HOME/.local/bin/statusbar/libbat" ] && source "$HOME/.local/bin/statusbar/libbat"

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

read capacity status < <(headsetcontrol -b | awk '
BEGIN {
    status_map["BATTERY_AVAILABLE"] = 0
    status_map["BATTERY_CHARGING"]  = 1
}

$1 == "Level:" {
    sub(/%/, "", $2)
    level = $2
}

$1 == "Status:" {
    status = status_map[$2]
}

END {
    printf "%s %s", level, status
}')

libbat_update "$capacity" "$status"

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
    if [ "$json" = "true" ]; then
        if ! [ "$state" = "Critical" ]; then
            state="Idle"
            color="$theme9"
        fi
        if [ "$state" = "Critical" ]; then
            color="$color0"
        fi

        _json "headphones" "$state" "<span color='$color' rise='-1pt'>$icon $capacity%</span>"
    else
        echo "󰋋 <span color='$color'>$icon</span><span color='$color' rise='-1pt'> $capacity%$warn</span>"
    fi

fi

#!/usr/bin/env bash

if [ -z "$KLIPPER_HOST" ]; then 
    echo "KLIPPER_HOST is not set"
    exit 0
fi

SWITCH="$HOME/.cache/statusbar_$(basename $0)"

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

text_icon_normal="󰹛"
text_icon_printing="󱇀"
json_icon_normal="3d_printer"
json_icon_printing="3d_printer_printing"

text_icon="$text_icon_printing"
json_icon="$json_icon_printing"

progress=$(curl -s $KLIPPER_HOST/printer/objects/query?display_status | jq -r '.result.status.display_status.progress')
print_stats=$(curl -s $KLIPPER_HOST/printer/objects/query?print_stats)
percent="$(echo "$progress * 100" | bc)"
print_duration=$(echo "$print_stats" | jq -r '.result.status.print_stats.print_duration')
remaining_duration="$(echo "($print_duration/$progress-$print_duration)" | bc)"
filename="$(echo "$print_stats" | jq -r '.result.status.print_stats.filename')"
status="$(echo "$print_stats" | jq -r '.result.status.print_stats.state')"

remaining_hours="$(echo "scale=0;$remaining_duration/3600" | bc)"
remaining_minutes="$(echo "scale=0;($remaining_duration%3600)/60" | bc)"
print_hours="$(echo "scale=0;$print_duration/3600" | bc)"
print_minutes="$(echo "scale=0;(${print_duration}%3600)/60" | bc)"

if [ "$remaining_hours" -eq 0  ]; then
    remaining_hours=""
else
    remaining_hours="${remaining_hours}h"
fi

if [ "$remaining_minutes" -eq 0 ]; then
    remaining_minutes=""
else
    remaining_minutes="${remaining_minutes}m"
fi

_notify_progress() {
    thumbnail="$(curl -s \
        "$KLIPPER_HOST/server/files/thumbnails?filename=$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$filename")" | jq -r '.result | max_by(.width) | .thumbnail_path')"
            thumbnail="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$thumbnail")"
            curl -s "$KLIPPER_HOST/server/files/gcodes/$thumbnail" > "/tmp/$thumbnail"
            answ="$(notify-send -i "/tmp/$thumbnail" \
                -A "open=Open klipper"  \
                -h "int:value:$percent" \
                "3D Printer" "File: $filename\n\nDuration: ${print_hours}h ${print_minutes}m\nRemaining: ${remaining_hours} ${remaining_minutes}\nProgress: ${percent%.*}%")"
            case "$answ" in
                "open")
                    xdg-open $KLIPPER_HOST
                    ;;
            esac
}

last_percentage="$([ -e "/tmp/$filename" ] && cat "/tmp/$filename" || echo 0)"
if ! [[ "$last_percentage" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
    last_percentage=0
fi

if [ "$(printf "%0.f > (%.0f + 10)\n" "$percent" "$last_percentage" | bc -l)" -eq "1" ] && [ "$status" = "printing" ]; then
    echo "$percent" > "/tmp/$filename"
    if [ -z "$BLOCK_BUTTON" ]; then
        _notify_progress &
    fi
fi


case $BLOCK_BUTTON in 
    1) xdg-open $KLIPPER_HOST ;;
    2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill -SIGRTMIN+9 i3status-rs ;;
    3) _notify_progress &;;
esac

_json() {
    echo '{"icon": "'${1}'", "state":"'${2:-"Idle"}'", "text":"'${3}'"}';
}

if [ "$status" != "printing" ]; then
    if [ -n "$json" ]; then
        _json "$json_icon" "Good" ""
    else
        text=""
    fi
    exit 0
fi


if [ -e "$SWITCH" ]; then
    text="$(printf "%d%% %s%s" "$percent" "$remaining_hours" "$remaining_minutes")"
else
    text="$(printf "%d%%" "$percent")"
fi

if [ -n "$json" ]; then
    _json "$json_icon" "Warning" "$text " 
else
    echo "$text_icon $text"
fi

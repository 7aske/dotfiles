#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename $0)"

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

declare -A json_icons
json_icons[printing]="3d_printer_printing"
json_icons[paused]="3d_printer"
json_icons[standby]="3d_printer"
json_icons[complete]="3d_printer"
json_icons[error]="3d_printer"
json_icons[canceled]="3d_printer"
declare -A icons
icons[printing]="󱇀"
icons[paused]="󰏤"
icons[standby]="󰐫"
icons[complete]=""
icons[error]=""
icons[canceled]="󰜺"
declare -A colors
colors[printing]="Warning"
colors[paused]="Warning"
colors[standby]="Idle"
colors[complete]="Good"
colors[error]="Critical"
colors[canceled]="Idle"

_output() {
    local color="${colors[$1]}"
    local text="$2"
    local icon
    if [ "$json" = "true" ]; then
        icon="${json_icons[$1]}"
        echo '{"icon": "'$icon'", "state":"'${color:-"Idle"}'", "text":"'$text'"}';
    else
        icon="${icons[$1]}"
        echo "$icon $text"
    fi
}

_format_time() {
    local formula="$1"
    local suffix="$2"
    local val="$(bc <<< "$formula")"

    if [ "$val" -eq 0 ]; then
        echo ""
    else
        echo "${val}${suffix}"
    fi
}

if [ -z "$KLIPPER_HOST" ]; then 
    _output "error" ""
    exit 0
fi


progress=$(curl -s $KLIPPER_HOST/printer/objects/query?display_status | jq -r '.result.status.display_status.progress')
print_stats=$(curl -s $KLIPPER_HOST/printer/objects/query?print_stats | jq -r '.result.status.print_stats')

print_duration="$(jq -r '.print_duration' <<< "$print_stats")"
filename="$(jq -r '.filename' <<< "$print_stats")"
status="$(jq -r '.state' <<< "$print_stats")"

percent="$(bc <<< "$progress * 100")"
remaining_duration="$(bc <<< "($print_duration/$progress-$print_duration)")"
remaining_hours="$(_format_time "scale=0;$remaining_duration/3600" "h")"
remaining_minutes="$(_format_time "scale=0;($remaining_duration%3600)/60" "m")"
print_hours="$(_format_time "scale=0;$print_duration/3600" "h")"
print_minutes="$(_format_time "scale=0;(${print_duration}%3600)/60" "m")"

_notify_progress() {
    local escaped_filename="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$filename")"
    local thumbnail="$(curl -s "$KLIPPER_HOST/server/files/thumbnails?filename=$escaped_filename" \
        | jq -r '.result | max_by(.width) | .thumbnail_path' \
        | xargs perl -MURI::Escape -e 'print uri_escape($ARGV[0]);')"
    [ -e "$thumbnail" ] || curl -s "$KLIPPER_HOST/server/files/gcodes/$thumbnail" > "/tmp/$thumbnail"
    local body="$(cat << EOF
Duration: ${print_hours} ${print_minutes}
Remaining: ${remaining_hours} ${remaining_minutes}
Progress: ${percent%.*}% 
EOF
)"
    local answ="$(notify-send -i "/tmp/$thumbnail" \
        -A "open=Open klipper"  \
        -h "int:value:$percent" \
        "$filename" "$body")"
    case "$answ" in
        "open") xdg-open "$KLIPPER_HOST" ;;
    esac
}

last_percentage="$([ -e "/tmp/$filename" ] && cat "/tmp/$filename" || echo 0)"
if ! [[ "$last_percentage" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
    last_percentage=0
fi

if [ "$(printf "%0.f > (%.0f + 5)\n" "$percent" "$last_percentage" | bc -l)" -eq "1" ] && [ "$status" = "printing" ]; then
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

if [ "$status" != "printing" ]; then
    _output "$status" "${status,}"
    exit 0
fi

if [ -e "$SWITCH" ]; then
    text="$(printf "%.0f%% %s%s" "$percent" "$remaining_hours" "$remaining_minutes")"
else
    text="$(printf "%.0f%%" "$percent")"
fi

_output "$status" "$text"

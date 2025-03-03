#!/usr/bin/env bash
# Klipper Statusbar Script
# -------------------------
# This script retrieves and displays the status of a Klipper 3D printer.
# It fetches progress, print duration, and estimated remaining time from the Klipper API
# and formats the output for use in a status bar or notification system.
# 
# Features:
# - Displays status as an icon and text, either as plain text or JSON.
# - Sends notifications on print progress.
# - Supports click actions to open the Klipper web interface or toggle status display.
#
# Dependencies:
# - bc
# - curl
# - jq
# - notify-send (for notifications)
# - xdg-open (to open the Klipper interface)
# - i3status-rs (if using i3status for status updates)
#
# Example Usage:
# - Run normally:
#     ./statusbar_klipper.sh
# - Output JSON format:
#     ./statusbar_klipper.sh -j
#
# Click Actions:
# - Left Click: Open Klipper web interface.
# - Middle Click: Toggle status display in i3status-rs.
# - Right Click: Show print progress notification.
#
# Ensure $KLIPPER_HOST is set to the correct Klipper API endpoint.
# e.g. KLIPPER_HOST="http://192.168.1.100:7125"
#
# Different icons and json_colors can be set for each status type.

SWITCH="$HOME/.cache/statusbar_$(basename $0)"
_toggle_switch() {
    [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill "-SIGRTMIN+${1:-'9'}" i3status-rs
}
ZWSP="​"

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

declare -A json_icons
json_icons[printing]="3d_printer_printing"
json_icons[paused]="3d_printer_paused"
json_icons[standby]="3d_printer_standby"
json_icons[complete]="3d_printer_complete"
json_icons[error]="3d_printer_error"
json_icons[canceled]="3d_printer_canceled"
declare -A icons
icons[printing]="󱇀"
icons[paused]="󰏤"
icons[standby]="󰐫"
icons[complete]=""
icons[error]=""
icons[canceled]="󰜺"
declare -A json_colors
json_colors[printing]="Warning"
json_colors[paused]="Warning"
json_colors[standby]="Idle"
json_colors[complete]="Good"
json_colors[error]="Critical"
json_colors[canceled]="Idle"
declare -A colors
colors[printing]="#EBCB8B"
colors[paused]="#EBCB8B"
colors[standby]="#5E81AC"
colors[complete]="#A3BE8C"
colors[error]="#BF616A"
colors[canceled]="#5E81AC"

_output() {
    local color
    local text="$2"
    local icon
    if [ "$json" = "true" ]; then
        color="${json_colors[$1]}"
        icon="${json_icons[$1]}"
        echo '{"icon": "'$icon'", "state":"'${color:-"Idle"}'", "text":"'$text'"}';
    else
        color="${colors[$1]}"
        icon="${icons[$1]}"
        echo "<span color='$color'>$icon $text</span>"
    fi
}

_format_time() {
    local formula="$1"
    local suffix="$2"
    local val="$(bc <<< "$formula")"

    if [ -z "$val" ] || [ "$val" -eq 0 ]; then
        echo ""
    else
        echo "${val}${suffix}"
    fi
}

KLIPPER_NOTIFY_THRESHOLD="${KLIPPER_NOTIFY_THRESHOLD:-5}"

if [ -z "$KLIPPER_HOST" ]; then 
    _output "error" ""
    exit 0
fi

progress=$(curl -s $KLIPPER_HOST/printer/objects/query?display_status | jq -r '.result.status.display_status.progress')
print_stats=$(curl -s $KLIPPER_HOST/printer/objects/query?print_stats | jq -r '.result.status.print_stats')

print_duration="$(jq -r '.print_duration' <<< "$print_stats")"
filename="$(jq -r '.filename' <<< "$print_stats")"
status="$(jq -r '.state' <<< "$print_stats")"
tmpfile="/tmp/$filename"

percent="$(bc <<< "$progress * 100")"
if [ "$(bc <<< "$progress==0||$print_duration==0")" -eq 0 ]; then
    remaining_duration="$(bc <<< "($print_duration/$progress-$print_duration)")"
else
    remaining_duration="0"
fi

remaining_hours="$(_format_time "scale=0;$remaining_duration/3600" "h")"
remaining_minutes="$(_format_time "scale=0;($remaining_duration%3600)/60" "m")"
print_hours="$(_format_time "scale=0;$print_duration/3600" "h")"
print_minutes="$(_format_time "scale=0;(${print_duration}%3600)/60" "m")"

_notify_progress() {
    local body
    local title="$filename"
    local args=""
    if [ -n "$filename" ]; then
        local escaped_filename="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$filename")"
        local thumbnail="$(curl -s "$KLIPPER_HOST/server/files/thumbnails?filename=$escaped_filename" \
            | jq -r '.result | max_by(.width) | .thumbnail_path' \
            | xargs -I% perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' '%')"
        [ -e "$thumbnail" ] || curl -s "$KLIPPER_HOST/server/files/gcodes/$thumbnail" > "/tmp/$thumbnail"
        body="$(cat << EOF
Duration: ${print_hours} ${print_minutes}
Remaining: ${remaining_hours} ${remaining_minutes}
Progress: ${percent%.*}% 
EOF
)"
        args="-h int:value:$percent"
    else
        title="Klipper"
        body="No print job"
    fi

    local answ="$(notify-send -i "/tmp/$thumbnail" \
        -A "open=Open klipper"  \
        -A "open=Open klipper"  \
        $args \
        "$title" "$body")"
    case "$answ" in
        "open") xdg-open "$KLIPPER_HOST" ;;
    esac
}

if [ -n "$filename" ] && [ -e "$tmpfile" ]; then
    last_percentage="$(cat "$tmpfile" || echo 0)"
    if ! [[ "$last_percentage" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
        last_percentage=0
    fi
else
    last_percentage=0
fi

if [ "$(printf "%0.f > (%.0f + $KLIPPER_NOTIFY_THRESHOLD)\n" "$percent" "$last_percentage" | bc -l)" -eq "1" ] && [ "$status" = "printing" ]; then
    echo "$percent" > "$tmpfile"
    if [ -z "$BLOCK_BUTTON" ]; then
        _notify_progress &
    fi
fi

case $BLOCK_BUTTON in 
    1) xdg-open $KLIPPER_HOST ;;
    2) _toggle_switch ;;
    3) _notify_progress &;;
esac

if [ "$status" == "printing" ]; then
    if [ -e "$SWITCH" ]; then
        text="$(printf "%.0f%% %s%s " "$percent" "$remaining_hours" "$remaining_minutes")"
    else
        text="$(printf "%.0f%% " "$percent")"
    fi
else
    if [ -e "$SWITCH" ]; then
        text="${status^}"
    else
        text="$ZWSP"
    fi
fi

_output "$status" "$text"

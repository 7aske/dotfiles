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

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"
KLIPPER_NOTIFY_THRESHOLD="${KLIPPER_NOTIFY_THRESHOLD:-5}"

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && source "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"
shift $((OPTIND-1))
libbar_kill_switch "$(basename "$0")"
#libbar_required_commands bc curl jq notify-send xdg-open
libbar_required_env_vars KLIPPER_HOST

# shellcheck disable=SC2034
{
    libbar_json_icons["printing"]="3d_printer_printing"
    libbar_json_icons["paused"]="3d_printer_paused"
    libbar_json_icons["standby"]="3d_printer_standby"
    libbar_json_icons["complete"]="3d_printer_complete"
    libbar_json_icons["error"]="3d_printer_error"
    libbar_json_icons["cancelled"]="3d_printer_cancelled"

    libbar_icons["printing"]="󱇀"
    libbar_icons["paused"]="󰏤"
    libbar_icons["standby"]="󰐫"
    libbar_icons["complete"]=""
    libbar_icons["error"]=""
    libbar_icons["cancelled"]="󰜺"

    libbar_json_colors["printing"]="Warning"
    libbar_json_colors["paused"]="Warning"
    libbar_json_colors["standby"]="Idle"
    libbar_json_colors["complete"]="Good"
    libbar_json_colors["error"]="Critical"
    libbar_json_colors["cancelled"]="Idle"

    libbar_colors["printing"]="#EBCB8B"
    libbar_colors["paused"]="#EBCB8B"
    libbar_colors["standby"]="#5E81AC"
    libbar_colors["complete"]="#A3BE8C"
    libbar_colors["error"]="#BF616A"
    libbar_colors["cancelled"]="#5E81AC"
}

klipper_format_time() {
    local formula="$1"
    local suffix="$2"
    local val; val="$(bc <<< "$formula")"

    if [ -z "$val" ] || [ "$val" -eq 0 ]; then
        echo ""
    else
        echo "${val}${suffix}"
    fi
}

progress=$(curl -s "$KLIPPER_HOST/printer/objects/query?display_status" | jq -r '.result.status.display_status.progress')
print_stats=$(curl -s "$KLIPPER_HOST/printer/objects/query?print_stats" | jq -r '.result.status.print_stats')

if [ -z "$progress" ] || [ -z "$print_stats" ]; then
    libbar_output "error" ""
    exit 0
fi

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

remaining_hours="$(klipper_format_time "scale=0;$remaining_duration/3600" "h")"
remaining_minutes="$(klipper_format_time "scale=0;($remaining_duration%3600)/60" "m")"
print_hours="$(klipper_format_time "scale=0;$print_duration/3600" "h")"
print_minutes="$(klipper_format_time "scale=0;(${print_duration}%3600)/60" "m")"

klipper_notify_progress() {
    local title="$filename"
    local args=""
    local escaped_filename
    local thumbnail
    local body
    if [ -n "$filename" ]; then
        escaped_filename="$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$filename")"
        thumbnail="$(curl -s "$KLIPPER_HOST/server/files/thumbnails?filename=$escaped_filename" \
            | jq -r '.result | max_by(.width) | .thumbnail_path' \
            | xargs -I% perl -MURI::Escape -e "print uri_escape(\$ARGV[0]);" '%')"
        if ! [ -e "$thumbnail" ]; then
            curl -s "$KLIPPER_HOST/server/files/gcodes/$thumbnail" > "/tmp/$thumbnail"
        fi
        body="$(cat << EOF
Duration: ${print_hours} ${print_minutes}
Remaining: ${remaining_hours} ${remaining_minutes}
Progress: ${percent%.*}% 
EOF
)"
        read -ra args <<< "-h int:value:$percent"
    else
        title="Klipper"
        body="No print job"
    fi

    local answ; answ="$(notify-send -i "/tmp/$thumbnail" \
        -A "open=Open klipper"  \
        -A "open=Open klipper"  \
        "${args[@]}" \
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
        klipper_notify_progress &
    fi
fi

case $BLOCK_BUTTON in 
    1) xdg-open "$KLIPPER_HOST" ;;
    2) libbar_toggle_switch ;;
    3) klipper_notify_progress & ;;
esac

if [ "$status" == "printing" ]; then
    if [ -e "$SWITCH" ]; then
        text="$(printf "%.0f%% %s%s " "$percent" "$remaining_hours" "$remaining_minutes")"
    else
        text="$(printf "%.0f%% " "$percent")"
    fi
else
    if [ -e "$SWITCH" ]; then
        text="${status^} "
    else
        text="$ZWSP"
    fi
fi

libbar_output "$status" "$text"

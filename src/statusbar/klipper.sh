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

# shellcheck disable=SC2034,SC2154
{
    libbar_json_icons["printing"]="3d_printer_printing"
    libbar_json_icons["heating"]="3d_printer_heating"
    libbar_json_icons["paused"]="3d_printer_paused"
    libbar_json_icons["error"]="3d_printer_error"
    libbar_json_icons["standby"]="3d_printer_standby"
    libbar_json_icons["complete"]="3d_printer_complete"
    libbar_json_icons["cancelled"]="3d_printer_cancelled"

    libbar_icons["printing"]="󰑤"
    libbar_icons["heating"]="󱢸"
    libbar_icons["paused"]="󰏤"
    libbar_icons["error"]=""
    libbar_icons["standby"]="󰐫"
    libbar_icons["complete"]=""
    libbar_icons["cancelled"]="󰜺"

    libbar_json_colors["printing"]="Good"
    libbar_json_colors["heating"]="Warning"
    libbar_json_colors["paused"]="Warning"
    libbar_json_colors["error"]="Critical"
    libbar_json_colors["standby"]="Idle"
    libbar_json_colors["complete"]="Idle"
    libbar_json_colors["cancelled"]="Idle"

    libbar_colors["printing"]="$green"
    libbar_colors["heating"]="$green"
    libbar_colors["paused"]="$yellow"
    libbar_colors["error"]="$red"
    libbar_colors["standby"]="$background"
    libbar_colors["complete"]="$background"
    libbar_colors["cancelled"]="$background"
}

klipper_format_time() {
    local seconds="$1"
    local unit="$2"
    local formula val
    if [ -z "$seconds" ] || [ -z "$unit" ]; then
        echo ""
    fi

    case "$unit" in
        h) formula="$seconds/3600" ;;
        m) formula="($seconds%3600)/60" ;;
        *) return 1 ;;
    esac

    val="$(bc <<< "scale=0; $formula")"

    (( val > 0 )) && printf '%s%s\n' "$val" "$unit" || echo ""
}

read -r temperature \
    target \
    can_extrude \
    bed_temperature \
    bed_target \
    progress percent \
    print_duration \
    filename \
    status \
    total_layer \
    current_layer \
    remaining_duration \
< <(curl -s "$KLIPPER_HOST/printer/objects/query?extruder&heater_bed&display_status&print_stats" | jq -r '.result.status | 
[
    (.extruder.temperature | round),
    (.extruder.target | round),
    .extruder.can_extrude,
    (.heater_bed.temperature | round),
    (.heater_bed.target | round),
    .display_status.progress,
    .display_status.progress * 100,
    .print_stats.print_duration,
    .print_stats.filename,
    .print_stats.state,
    .print_stats.info.total_layer,
    .print_stats.info.current_layer,
    if (.display_status.progress != null and .print_stats.print_duration != null)
    then (.print_stats.print_duration / .display_status.progress - .print_stats.print_duration)
    else 0
    end
] | @tsv')

if [ -z "$progress" ]; then
    libbar_output "error" ""
    exit 0
fi

if [ "$status" == "printing" ] && [ "$can_extrude" == "false" ] &&
    { [ "$temperature" -lt "$target" ] ||
        [ "$bed_temperature" -lt "$bed_target" ]; }; then
    status="heating"
fi
tmpfile="/tmp/$filename"

remaining_hours="$(klipper_format_time "$remaining_duration" h)"
remaining_minutes="$(klipper_format_time "$remaining_duration" m)"
print_hours="$(klipper_format_time "$print_duration" h)"
print_minutes="$(klipper_format_time "$print_duration" m)"

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
Duration:  ${print_hours} ${print_minutes}
Remaining: ${remaining_hours} ${remaining_minutes}
Progress:  ${percent%.*}%
Layers:    ${current_layer}/${total_layer}
EOF
)"
        read -ra args <<< "-h int:value:$percent"
    else
        title="Klipper"
        body="No print job"
    fi

    local answ; answ="$(notify-send -i "/tmp/$thumbnail" \
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
    1) klipper_notify_progress & ;;
    2) libbar_toggle_switch ;;
    3) xdg-open "$KLIPPER_HOST" ;;
esac

if [ "$status" == "heating" ]; then
    long_text="$(printf "%d/%d %d/%d " "$temperature" "$target" "$bed_temperature" "$bed_target")"
    short_text="$(printf "%d %d " "$temperature" "$bed_temperature")"
elif [ "$status" == "printing" ]; then
    long_text="$(printf "%.0f%% %s%s %d/%d " "$percent" "$remaining_hours" "$remaining_minutes" "$current_layer" "$total_layer")"
    short_text="$(printf "%.0f%% " "$percent")"
elif [ "$status" == "complete" ]; then
    long_text="${status^} ($print_hours$print_minutes) "
    short_text="$ZWSP"
else
    long_text="${status^} "
    short_text="$ZWSP"
fi

if [ -e "$SWITCH" ]; then
    libbar_output "$status" "$long_text"
else
    libbar_output "$status" "$short_text"
fi

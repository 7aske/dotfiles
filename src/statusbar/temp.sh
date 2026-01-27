#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename "$0")" 

# shellcheck disable=SC1091,SC3046
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && source "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"
shift $((OPTIND-1))
libbar_kill_switch "$(basename "$0")"
libbar_required_commands sensors

# shellcheck disable=SC2034,SC2154
{
    libbar_json_icons["temp_1"]="temp_1"
    libbar_icons["temp_1"]=""
    libbar_colors["temp_1"]="$color7"
    libbar_json_colors["temp_1"]="Idle"

    libbar_json_icons["temp_2"]="temp_2"
    libbar_icons["temp_2"]=""
    libbar_colors["temp_2"]="$theme15"
    libbar_json_colors["temp_2"]="Idle"

    libbar_json_icons["temp_3"]="temp_3"
    libbar_icons["temp_3"]=""
    libbar_colors["temp_3"]="$theme13"
    libbar_json_colors["temp_3"]="Info"

    libbar_json_icons["temp_4"]="temp_4"
    libbar_icons["temp_4"]=""
    libbar_colors["temp_4"]="$theme12"
    libbar_json_colors["temp_4"]="Warning"

    libbar_json_icons["temp_5"]="temp_5"
    libbar_icons["temp_5"]=""
    libbar_colors["temp_5"]="$theme11"
    libbar_json_colors["temp_5"]="Critical"
}

case $BLOCK_BUTTON in
	1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
	2) libbar_toggle_switch ;;
esac

read -r temp temp_val <<< "$(sensors | awk '
    {
        if ($0 ~ /Package id 0:/) {
            temp = substr($4, 2)
            temp_val = substr(temp, 1, length(temp)-4)
            exit
        } else if ($0 ~ /Tdie|Tctl/) {
            temp = substr($2, 2)
            temp_val = substr(temp, 1, length(temp)-4)
            exit
        }
    }
    END {
        print temp, temp_val
    }
')"

if [ "$temp_val" -ge 70 ]; then
    icon='temp_5'
elif [ "$temp_val" -ge 60 ]; then
    icon='temp_4'
elif [ "$temp_val" -ge 50 ]; then
    icon='temp_3'
elif [ "$temp_val" -ge 40 ]; then
    icon='temp_2'
else
    icon='temp_1'
fi

if [ -e "$SWITCH" ]; then
    libbar_output "$icon" "$ZWSP"
else
    libbar_output "$icon" "$temp"
fi

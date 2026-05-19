#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"

# shellcheck disable=SC1091,SC3046
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && source "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"
shift $((OPTIND-1))
libbar_kill_switch "$(basename "$0")"

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

# Read CPU temperature (millidegrees C) from sysfs. Portable across common x86/ACPI setups.
# Priority: known thermal zone types, then fuzzy type match, then labeled hwmon inputs.
temp_read_sysfs_millideg() {
    local tz type path t label name i
    local -a exact_types=(x86_pkg_temp Tctl Tdie cpu-thermal acpitz)

    for t in "${exact_types[@]}"; do
        for tz in /sys/class/thermal/thermal_zone*/; do
            [ -f "${tz}type" ] && [ -f "${tz}temp" ] || continue
            type=$(<"${tz}type")
            if [ "$type" = "$t" ]; then
                echo $(<"${tz}temp")
                return 0
            fi
        done
    done

    for tz in /sys/class/thermal/thermal_zone*/; do
        [ -f "${tz}type" ] && [ -f "${tz}temp" ] || continue
        type=$(<"${tz}type")
        case "$type" in
            *cpu*|*pkg*|*Package*|*x86*|*Core*|*CCD*)
                echo $(<"${tz}temp")
                return 0
                ;;
        esac
    done

    for path in /sys/class/hwmon/hwmon*/temp*_input; do
        [ -f "$path" ] || continue
        label="${path%_input}_label"
        name="${path%/temp*_input}/name"
        if [ -f "$label" ]; then
            label=$(<"$label")
        else
            label=""
        fi
        if [ -f "$name" ]; then
            name=$(<"$name")
        else
            name=""
        fi
        case "$label$name" in
            *Tctl*|*Tdie*|*Package*|*pkg*|*CPU*|*Core*|*CCD*)
                echo $(<"$path")
                return 0
                ;;
        esac
    done

    # Last resort: first thermal zone or first hwmon temp input
    for tz in /sys/class/thermal/thermal_zone*/; do
        [ -f "${tz}temp" ] || continue
        echo $(<"${tz}temp")
        return 0
    done
    for path in /sys/class/hwmon/hwmon*/temp*_input; do
        [ -f "$path" ] || continue
        echo $(<"$path")
        return 0
    done

    return 1
}

case $BLOCK_BUTTON in
    1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
    2) libbar_toggle_switch ;;
esac

millideg="$(temp_read_sysfs_millideg)" || {
    libbar_output "error" ""
    exit 1
}

temp_val=$((millideg / 1000))
temp="+${temp_val}.0°C"

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

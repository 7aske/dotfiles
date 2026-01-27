#!/usr/bin/env bash

# shellcheck disable=SC1091
[ -z "$DOTS_COLORS_SOURCED" ] && [ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"

red="${red:-"#BF616A"}"
white="${white:-"#D8DEE9"}"
green="${green:-"#A3BE8C"}"
blue="${blue:-"#5E81AC"}"
yellow="${yellow:-"#EBCB8B"}"
orange="${orange:-"#D08770"}"

declare -Ag libbat_icons
declare -Ag libbat_charging_icons
declare -Ag libbat_notif_icons
declare -ag libbat_warning_icons
declare -Ag libbat_colors
declare -Ag libbat_states
declare -g libbat_no_bat
declare -g libbat_saver
declare -g libbat_json_bat_not_available
declare -g libbat_json_saver
declare -g libbat_notif_saver
declare -g libbat_charging_color
declare -g libbat_charging_state
declare -g libbat_color # rgb color
declare -g libbat_icon # pango icon
declare -g libbat_charging_icon # charging true/false
declare -g libbat_state
declare -g libbat_warn
declare -g libbat_json_icon
declare -g libbat_json_charging_icon
declare -g libbat_notif_icon

libbat_no_bat="󱉞"
libbat_json_bat_not_available="bat_not_available"
libbat_saver=""
libbat_json_saver="bat_saver"
libbat_notif_saver="battery"
libbat_icons+=([0]="󰂎" [1]="󰁺" [2]="󰁻" [3]="󰁼" [4]="󰁽" [5]="󰁾" [6]="󰁿" [7]="󰂀" [8]="󰂁" [9]="󰂂" [10]="󰁹")
libbat_charging_icons+=([0]="󰢟" [1]="󰢜" [2]="󰂇" [3]="󰂇" [4]="󰂈" [5]="󰢝" [6]="󰂉" [7]="󰢞" [8]="󰂊" [9]="󰂋" [10]="󰂅")
libbat_warning_icons=( "  " "  " "  " " " " " " " " " " " " " " " " " )
# Corresponding to names of icons to be used in notify-send -i $icon from /usr/share/icons
libbat_notif_icons+=( 
    [0]="battery-000"
    [1]="battery-010"
    [2]="battery-020"
    [3]="battery-030"
    [4]="battery-040"
    [5]="battery-050"
    [6]="battery-060"
    [7]="battery-070"
    [8]="battery-080"
    [9]="battery-090"
    [10]="battery-100"
)
libbat_colors+=( 
    [0]="${red}"
    [1]="${red}"
    [2]="${orange}"
    [3]="${yellow}"
    [4]="${blue}"
    [5]="${white}"
    [6]="${white}"
    [7]="${white}"
    [8]="${white}"
    [9]="${white}"
    [10]="${white}"
)
libbat_states+=( 
    [0]="Critical"
    [1]="Critical"
    [2]="Warning"
    [3]="Warning"
    [4]="Info"
    [5]="Idle"
    [6]="Idle"
    [7]="Idle"
    [8]="Idle"
    [9]="Idle"
    [10]="Idle"
)
libbat_charging_color="$green"
libbat_charging_state="Good"

# args: capacity, status
# sets global: libbat_icon, libbat_json_icon, libbat_notif_icon libbat_color,
#              libbat_state, libbat_warn, libbat_charging_icon,
#              libbat_json_charging_icon, libbat_charging
libbat_update() {
    local capacity="$1"
    local charging_status="${2:-"discharging"}"
    local saver_state="${3:-0}"

    if [ -z "$capacity" ] || [ "$capacity" -eq -1 ]; then
        libbat_color=${libbat_colors[0]}
        libbat_state=${libbat_states[0]}
        libbat_icon=${libbat_no_bat}
        libbat_json_icon="${libbat_json_bat_not_available}"
        return 1
    fi

    local bat_index=$((capacity / 10))

    export libbat_icon=${libbat_icons[$bat_index]}
    export libbat_json_icon="bat_${bat_index}"
    export libbat_notif_icon=${libbat_notif_icons[$bat_index]}

    export libbat_color=${libbat_colors[$bat_index]}
    export libbat_state=${libbat_states[$bat_index]}
    export libbat_warn=${libbat_warning_icons[$bat_index]}

    export libbat_charging_icon=${libbat_charging_icons[$bat_index]}
    export libbat_json_charging_icon="bat_charging_${bat_index}"

    if [ "$charging_status" == "charging" ]; then
        export libbat_color="$libbat_charging_color"
        export libbat_state="$libbat_charging_state"

        export libbat_icon="${libbat_charging_icon}"
        export libbat_json_icon="${libbat_json_charging_icon:-"bat_charging_${bat_index}"}"
        export libbat_notif_icon="${libbat_notif_icon}-charging"
    fi

    if [ "$saver_state" -eq 1 ] && [ "$charging_status" != "discharging" ] && [ "$charging_status" != "charging" ]; then
        export libbat_color="$blue"
        export libbat_state="Idle"

        export libbat_json_icon="${libbat_json_saver}"
        export libbat_icon="${libbat_saver}"
        export libbat_notif_icon="${libbat_notif_saver}"
    fi

}

libbat_get_icon() {
    local level="$1"
    if [ "$level" -eq 0 ]; then
        echo -n "${libbat_icons[0]}"
    elif [ "$level" -gt 0 ]; then
        local index="$(((level + 5) / 10))"
        echo -n "${libbat_icons[$index]}"
    else
        echo -n "${libbat_no_bat}"
    fi
}

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"

declare -a libbat_icons
declare -a libbat_charging_icons
declare -a libbat_warning_icons
declare -a libbat_colors
declare -a libbat_states

libbat_icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
libbat_charging_icons=( "󰢟" "󰢜" "󰂇" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" )
libbat_warning_icons=( "  " "  " "  " " " " " " " " " " " " " " " " " )
libbat_colors=( 
    "${color1:-"#BF616A"}"
    "${color1:-"#BF616A"}"
    "${theme12:-"#D08770"}"
    "${theme12:-"#D08770"}"
    "${color3:-"#EBCB8B"}"
    "${color3:-"#EBCB8B"}"
    "${color2:-"#D8DEE9"}"
    "${color7:-"#D8DEE9"}"
    "${color7:-"#D8DEE9"}"
    "${color7:-"#D8DEE9"}"
    "${color7:-"#D8DEE9"}"
)
libbat_states=( 
    "Critical"
    "Critical"
    "Warning"
    "Warning"
    "Info"
    "Info"
    "Idle"
    "Idle"
    "Idle"
    "Idle"
    "Idle"
)
libbat_charging_color="${color2:-"#A3BE8C"}"
libbat_charging_state="Good"

# args: capacity status
# return: color icon charging state warn json_icon json_charging_icon
libbat_update() {
    if [ -z "$1" ]; then
        color=${libbat_colors[0]}
        state=${libbat_states[0]}
        return 1
    fi

    local status="${2:-0}"

    capacity="$1"
    bat_index=$((capacity / 10))

    color=${libbat_colors[$bat_index]}
    icon=${libbat_icons[$bat_index]}
    charging=${libbat_charging_icons[$bat_index]}
    state=${libbat_states[$bat_index]}
    warn=${libbat_warning_icons[$bat_index]}
    json_icon="bat_${bat_index}"
    json_charging_icon="bat_charging_${bat_index}"

    if [ "$status" -ne 0 ]; then
        color="$libbat_charging_color"
        state="$libbat_charging_state"
        icon=${libbat_charging_icons[$bat_index]}
        json_icon=${json_charging_icon:-"bat_charging_${bat_index}"}
    fi

}

libbat_get_icon() {
    local level="$1"
    local index="$((level / 10 + 1))"
    echo -n "${libbat_icons[$index]}"
}

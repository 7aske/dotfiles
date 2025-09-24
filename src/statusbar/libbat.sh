[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"

red="${red:-"#BF616A"}"
white="${white:-"#D8DEE9"}"
green="${green:-"#A3BE8C"}"
blue="${blue:-"#5E81AC"}"
yellow="${yellow:-"#EBCB8B"}"
orange="${orange:-"#D08770"}"

declare -A libbat_icons
declare -A libbat_charging_icons
declare -a libbat_warning_icons
declare -A libbat_colors
declare -A libbat_states

libbat_icons+=([0]="󰂎" [1]="󰁺" [2]="󰁻" [3]="󰁼" [4]="󰁽" [5]="󰁾" [6]="󰁿" [7]="󰂀" [8]="󰂁" [9]="󰂂" [10]="󰁹")
libbat_charging_icons+=([0]="󰢟" [1]="󰢜" [2]="󰂇" [3]="󰂇" [4]="󰂈" [5]="󰢝" [6]="󰂉" [7]="󰢞" [8]="󰂊" [9]="󰂋" [10]="󰂅")
libbat_warning_icons=( "  " "  " "  " " " " " " " " " " " " " " " " " )
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
    if [ $level -eq 0 ]; then
        echo -n "${libbat_icons[0]}"
    else
        local index="$(((level + 5) / 10))"
        echo -n "${libbat_icons[$index]}"
    fi

}

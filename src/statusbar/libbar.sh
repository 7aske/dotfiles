ZWSP="​"

[ -z "$DOTS_COLORS_SOURCED"] && [ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

# json icon name from i3status-rs
declare -A libbar_json_icons
# pango text icons
declare -A libbar_icons

libbar_getopts() {
    while getopts "j" opt; do
        case $opt in
            j) json=true ;;
        esac
    done

    shift $((OPTIND-1))
}

libbar_output() {
    local text="$2"
    local icon_override="$1"
    if [ "$json" = "true" ]; then
        if [ -n "${json_icons[$1]}" ]; then
            icon_override="${json_icons[$1]}"
        fi
        echo '{"icon": "'$icon_override'", "state":"'${state:-"Idle"}'", "text":"'$text'"}';
    else
        if [ -n "${icons[$1]}" ]; then
            icon_override="${icons[$1]}"
        fi
        echo "<span color='${color:-"#5E81AC"}'>$icon_override $text</span>"
    fi
}

libbar_toggle_switch() {
    [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill "-SIGRTMIN+${1:-'9'}" i3status-rs
}

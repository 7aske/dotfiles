export ZWSP="​"

# shellcheck disable=SC1091
{
    [ -z "$DOTS_COLORS_SOURCED" ] && [ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
    [ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"
}

# json icon name from i3status-rs
declare -A libbar_json_icons
# pango text icons
declare -A libbar_icons

libbar_getopts() {
    while getopts "j" opt; do
        case $opt in
            j) json=true ;;
            *) echo "Invalid option: -$OPTARG" >&2 ;;
        esac
    done

    shift $((OPTIND-1))
}

libbar_output() {
    if [ -z "$1" ]; then
        return 1
    fi

    local icon_override="$1"
    local text="$2"
    local state="$3"
    local color="$4"
    if [ -n "$libbat_state" ] && [ -z "$state" ]; then
        state="$libbat_state"
    fi
    if [ -n "$libbat_color" ] && [ -z "$color" ]; then
        color="$libbat_color"
    fi

    if [ "$json" = "true" ]; then
        if [ -n "${libbar_json_icons[$1]}" ]; then
            icon_override="${libbar_json_icons[$1]}"
        fi
        echo '{"icon": "'"$icon_override"'", "state":"'"${state:-"Idle"}"'", "text":"'"$text"'"}';
    else
        if [ -n "${libbar_icons[$1]}" ]; then
            icon_override="${libbar_icons[$1]}"
        fi
        echo "<span color='${color:-"#5E81AC"}'>$icon_override $text</span>"
    fi
}

libbar_toggle_switch() {
    if [ -z "$SWITCH" ]; then
        return 1
    fi

    if [ -e "$SWITCH" ]; then
        rm "$SWITCH" 
    else 
        touch "$SWITCH"
        pkill "-SIGRTMIN+${1:-'9'}" i3status-rs
    fi
}

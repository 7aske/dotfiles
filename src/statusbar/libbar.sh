export ZWSP="​"

# shellcheck disable=SC1091
{
    [ -z "$DOTS_COLORS_SOURCED" ] && [ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
    [ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"
}

# json icon name from i3status-rs
declare -A libbar_json_icons
libbar_json_icons["error"]="error"
# pango text icons
declare -A libbar_icons
libbar_icons["error"]=""
declare -A libbar_colors
declare -A libbar_json_colors

libbar_getopts() {
    while getopts "j" opt "$@"; do
        case $opt in
            j) json=true ;;
            *) echo "Invalid option: -$OPTARG" >&2 ;;
        esac
    done
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

        if [ -n "${libbar_json_colors[$1]}" ] && [ -z "$state" ]; then
            state="${libbar_json_colors[$1]}"
        fi

        echo '{"icon": "'"$icon_override"'", "state":"'"${state:-"Idle"}"'", "text":"'"$text"'"}';
    else
        if [ -n "${libbar_icons[$1]}" ]; then
            icon_override="${libbar_icons[$1]}"
        fi

        if [ -n "${libbar_colors[$1]}" ] && [ -z "$color" ]; then
            color="${libbar_colors[$1]}"
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

libbar_required_env_vars() {
    local missing_vars=()
    for var in "$@"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        local msg; msg="Missing environment variables: ${missing_vars[*]}"
        echo "$msg" >&2
        libbar_output "error" ""
        exit 1
    fi
}

libbar_required_commands() {
    local missing_cmds=()
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_cmds+=("$cmd")
        fi
    done

    if [ ${#missing_cmds[@]} -ne 0 ]; then
        local msg; msg="Missing commands: ${missing_cmds[*]}"
        echo "$msg" >&2
        libbar_output "error" ""
        exit 1
    fi
}

libbar_kill_switch() {
    if [ -z "$1" ]; then
        return 1
    fi

    export KILL_SWITCH="$HOME/.cache/statusbar_${1}_kill"
    if [ -e "$KILL_SWITCH" ]; then 
        libbar_output "error" ""
        exit 0
    fi
}


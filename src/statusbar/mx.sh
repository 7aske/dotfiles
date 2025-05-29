#!/usr/bin/env bash


SWITCH="$HOME/.cache/statusbar_$(basename $0)"
_toggle_switch() {
    [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill "-SIGRTMIN+${1:-'9'}" i3status-rs
}

case $BLOCK_BUTTON in
    1) solaar ;;
    2) _toggle_switch 10 ;;
esac

ZWSP="​"

declare -a colors
declare -a states
colors=( "${color1:-"#BF616A"}" "${color1:-"#BF616A"}" "${theme12:-"#D08770"}" "${theme12:-"#D08770"}" "${color3:-"#EBCB8B"}" "${color3:-"#EBCB8B"}" "${color2:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" "${color7:-"#D8DEE9"}" )
states=( "Critical" "Critical" "Warning" "Warning" "Info" "Info" "Idle" "Idle" "Idle" "Idle" "Idle" )

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

declare -A json_icons
json_icons[bluetooth]="bluetooth"
json_icons[signal]="signal"
json_icons[mouse]="mouse"
declare -A icons
icons[bluetooth]="󰂯"
icons[signal]="󰒢"
icons[mouse]="󰍽"

_output() {
    local color
    local text="$3"
    local icon
    if [ "$json" = "true" ]; then
        icon="${json_icons[$1]}"
        color=${states[$2]}
        echo '{"icon": "'$icon'", "state":"'${color:-"Idle"}'", "text":"'$text'"}';
    else
        icon="${icons[$1]}"
        color=${colors[$2]}
        echo "<span color='${color:-"#5E81AC"}'>$icon $text</span>"
    fi
}

command -v solaar > /dev/null || _output "mouse" 6 ""

bat_level="$(solaar show 2>/dev/null | sed -n 's/^\s*Battery: \(.*\)%.*$/\1/p' | head -n 1)"

if [ -z "$bat_level" ]; then
    _output "signal" 0 ""
    exit 0
fi

if [ -e "$SWITCH" ]; then
    OUTPUT="$ZWSP"
else
    OUTPUT="$bat_level%"
fi

_output "mouse" "$bat_level" "${OUTPUT}"



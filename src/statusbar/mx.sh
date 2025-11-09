#!/usr/bin/env bash

KILL_SWITCH="$HOME/.cache/statusbar_$(basename $0)_kill"
SWITCH="$HOME/.cache/statusbar_$(basename $0)"
[ -e "$HOME/.local/bin/statusbar/libbat" ] && source "$HOME/.local/bin/statusbar/libbat"
_toggle_switch() {
    [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill "-SIGRTMIN+${1:-'9'}" i3status-rs
}

case $BLOCK_BUTTON in
    1) solaar ;;
    2) _toggle_switch 10 ;;
esac

ZWSP="​"

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
icons[signal]="󰞃"
icons[mouse]="󰍽"

_output() {
    local text="$2"
    local icon_override
    if [ "$json" = "true" ]; then
        icon_override="${json_icons[$1]}"
        echo '{"icon": "'$icon_override'", "state":"'${state:-"Idle"}'", "text":"'$text'"}';
    else
        icon_override="${icons[$1]}"
        echo "<span color='${color:-"#5E81AC"}'>$icon_override $text</span>"
    fi
}

[ -e "$KILL_SWITCH" ] && _output "signal" "" && exit 0

if [ -z "$(command -v solaar 2>/dev/null)" ]; then
    _output "mouse" ""
    exit 0
fi

read -r bat_level bat_state <<< "$(solaar show 2>/dev/null | sed -n 's/^\s*Battery: \(.*\)%, BatteryStatus.\(RECHARGING\|DISCHARGING\|FULL\)\.*$/\1 \2/;s/DISCHARGING/0/p;s/\(RECHARGING\|FULL\)/1/p' | head -n 1)"

libbat_update "$bat_level" "$bat_state"

if [ $? -ne 0 ]; then
    _output "signal" "$ZWSP"
    exit 0
fi

if [ -e "$SWITCH" ]; then
    _output "mouse" "$icon"
else
    _output "mouse" "$bat_level%"
fi




#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbat" ] && source "$HOME/.local/bin/statusbar/libbat"
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && source "$HOME/.local/bin/statusbar/libbar"
}


case $BLOCK_BUTTON in
    1) solaar ;;
    2) libbar_toggle_switch 10 ;;
esac

# shellcheck disable=SC2034
{
    libbar_json_icons["bluetooth"]="bluetooth"
    libbar_json_icons["signal"]="signal"
    libbar_json_icons["mouse"]="mouse"
    libbar_icons["bluetooth"]="󰂯"
    libbar_icons["signal"]="󰞃"
    libbar_icons["mouse"]="󰍽"
}

libbar_getopts "$@"
shift $((OPTIND-1))
libbar_kill_switch "$(basename "$0")"
libbar_required_commands solaar

read -r capacity charging <<< "$(solaar show 2>/dev/null | sed -n 's/^\s*Battery: \(.*\)%, BatteryStatus.\(RECHARGING\|DISCHARGING\|FULL\)\.*$/\1 \2/;s/DISCHARGING/discharging/p;s/\(RECHARGING\|FULL\)/charging/p' | head -n 1)"

if ! libbat_update "$capacity" "$charging"; then
    libbar_output "signal" "$ZWSP"
    exit 0
fi

if [ -e "$SWITCH" ]; then
    # shellcheck disable=SC2154
    libbar_output "mouse" "$libbat_icon"
else
    libbar_output "mouse" "$capacity%"
fi

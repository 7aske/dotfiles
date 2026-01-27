#!/usr/bin/env sh
# Give a battery name (e.g. BAT0) as an argument.

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && . "$HOME/.local/bin/statusbar/libbar"
    [ -e "$HOME/.local/bin/statusbar/libbat" ] && . "$HOME/.local/bin/statusbar/libbat"
}

while getopts "b:j" opt; do
    case $opt in
        j) export json=true ;;
        b) battery="$OPTARG" ;;
        *) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
done
shift $((OPTIND-1))

libbar_kill_switch "$(basename "$0")"
# batconv is a script to automate battery conservation mode toggling
libbar_required_commands acpi batconv

# shellcheck disable=SC2034
#{
#}

[ -z "$battery" ] && battery="$(dir -1 /sys/class/power_supply | grep -E BAT\? | sed 1q)"

if ! [ -e "/sys/class/power_supply/$battery/status" ]; then
    # shellcheck disable=SC2154
    libbar_output "bat_not_available" "$ZWSP" "Critical" "${red}"
    exit 1
fi

capacity=$(cat /sys/class/power_supply/"$battery"/capacity) || exit 1
status="$(cat /sys/class/power_supply/"$battery"/status | sed -e "s/,//;s/Discharging/discharging/;s/Not [Cc]harging/not_charging/;s/Charging/charging/;s/Unknown/unknown/;s/Full/full/;s/ 0*/ /g;s/ :/ /g")"
conservation_mode="$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode 2>/dev/null || echo "0")"

case $BLOCK_BUTTON in
    1) if [ "$status" = "not_charging" ]; then
        notify-send -a battery -i battery "Battery" "$status: $capacity%"
    else
        duration=$(acpi | awk '$4 != "0%," {print substr($5, 0, length($5) - 3)}')
        notify-send -a battery -i battery "Battery" "$([ "$status" = "charging" ] && printf "Until charged" || printf "Remaining"): $duration"
    fi ;;
	2) libbar_toggle_switch 9 ;;
    3) pkexec batconv >/dev/null 2>&1 ;;
esac

libbat_update "$capacity" "$status" "$conservation_mode"

if [ -e "$SWITCH" ]; then
    # shellcheck disable=SC2154
    libbar_output "$libbat_json_icon" "$ZWSP$libbat_warn" "$libbat_state" "$libbat_color"
else
    libbar_output "$libbat_json_icon" " $capacity%$libbat_warn" "$libbat_state" "$libbat_color"
fi

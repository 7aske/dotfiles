#!/usr/bin/env sh

# Status bar module for disk space
# usage: disk.sh [-j] <mount_point>

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"

# shellcheck disable=SC1091,SC3046
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && source "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"
shift $((OPTIND-1))
libbar_kill_switch "$(basename "$0")"

[ -z "$1" ] && exit

# shellcheck disable=SC2034
{
    libbar_icons["disk"]="󰋊"
    libbar_json_icons["disk"]="disk"
}

case $BLOCK_BUTTON in
	1) gnome-disks ;;
	2) libbar_toggle_switch 9 ;;
	3) baobab ;;
esac

color="#81A1C1"
state="Idle"
usage="$(df "$1" | awk 'NR==2 {print $4}')"
formatted="$(numfmt --to iec --from-unit=1024 --format "%f" "$usage")"

if [ -n "$usage" ]; then
    # 10 GB
	if [ "$usage" -lt 10485760 ]; then
		color="#D08770"
        state="Warning"
        text="$formatted"
    # 5 GB
	elif [ "$usage" -lt 5242880 ]; then
		color="#BF616A"
        state="Critical"
        text="$formatted"
    else
        text=""
	fi
fi

if [ -e "$SWITCH" ] && [ -n "$text" ]; then
    text="$ZWSP"
fi

libbar_output "disk" "$text" "$state" "$color"

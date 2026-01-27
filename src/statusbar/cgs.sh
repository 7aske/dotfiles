#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename "$0")" 

[ -z "$CODE" ] && return 1

# shellcheck disable=SC1091,SC3046
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && source "$HOME/.local/bin/statusbar/libbar"
}

# shellcheck disable=SC2034
{
    libbar_json_icons["cgs"]="cgs"
    libbar_icons["cgs"]="󰊢"
}

case $BLOCK_BUTTON in
    1) 
		if [ "$(dunstctl is-paused)" = true ]; then
			cgs | awk -F ' ' '{for(i=1;i<=NF;i++){print $i}}' | \
				zenity --list \
				--column Lang \
				--column Name \
				--column Branch \
				--class=STATUSBAR_POPUP \
				--title="rgs" \
				--text="Dirty repositories:"
		else 
			notify-send -i git "Repositories" "$(cgs -mb)"
		fi ;;
	2) libbar_toggle_switch 7 ;;
    3) notify-send -i git "Repositories" "$(cgs -F)" ;;
esac

libbar_getopts "$@"
shift $((OPTIND-1))

repos="$(/usr/bin/cgs -b | wc -l)"

if [ "$repos" -ge 10 ]; then
    state="Critical"
	color="${color5:-"#ff5252"}"
elif [ "$repos" -ge 7 ]; then
    state="Warning"
	color="${color1:-"#ff8144"}"
elif [ "$repos" -ge 5 ]; then
    state="Info"
    color="${color3:-"#fef44e"}"
else
    state="Idle"
	color="${color7:-"#ffffff"}"
fi

if [ "$repos" -eq 0 ]; then
    libbar_output "cgs" ""
	exit 0
fi

if [ -e "$SWITCH" ]; then
    libbar_output "cgs" "$ZWSP" "$state" "$color"
else
    libbar_output "cgs" "$repos" "$state" "$color"
fi




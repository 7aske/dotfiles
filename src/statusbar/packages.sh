#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename "$0")" 

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && . "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"
shift $((OPTIND-1))
libbar_kill_switch "$(basename "$0")"
libbar_required_commands notify-send i3-msg dunstctl zenity

# shellcheck disable=SC2034
{
    libbar_icons["packages"]="󰏔"
    libbar_json_icons["packages"]="update"
}

count="$(yay -Qu | wc -l)"

do_update(){
	i3-msg "exec --no-startup-id setsid -f $TERMINAL -c floating -e yay -Syyu" 2>/dev/null 1>/dev/null
}

case "$BLOCK_BUTTON" in
	1) 
		if [ "$(dunstctl is-paused)" = true ]; then
			yay -Qu | awk -F ' ' '{for(i=1;i<=NF;i++){ if (i < 3) {print $i}}}' | \
				zenity --list \
				--column Name \
				--column Current \
				--column Updated \
				--class=STATUSBAR_POPUP \
				--title=Packages \
				--text="Available updates:"
		else 
            notify-send -i package -u low "updates available" "$(yay -Qu | awk -F ' ' '{for(i=1;i<=NF;i++){ if (i == 1) {printf "<span foreground='"'$white'"'>%s</span> ", $i} else if (i == 2) { printf "<span foreground='"'$red'"'>%s</span> ", $i } else if (i == 4) {printf "<b><span foreground='"'$green'"'>%s</span></b>\n", $i}}}' | column -o ' ' -t)"
		fi ;;
	2) libbar_toggle_switch 1 ;;
	3) do_update ;;
esac 2>/dev/null 1>/dev/null

if [ "$count" -le 15 ]; then
    state="Idle"
	color="${color7:-"#ffffff"}"
elif [ "$count" -le 40 ]; then
    state="Info"
    color="${color3:-"#fef44e"}"
elif [ "$count" -le 75 ]; then
    state="Critical"
	color="${color5:-"#ff5252"}"
else
    state="Warning"
	color="${color1:-"#ff8144"}"
fi

if [ "$count" -eq 0 ]; then
    libbar_output "packages" ""
	exit 0
fi

if [ -e "$SWITCH" ]; then
    libbar_output "packages" "$ZWSP" "$state" "$color"
else
    libbar_output "packages" "$count" "$state" "$color"
fi

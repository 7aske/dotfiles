#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

tempfile="/tmp/yup_prev"
count="$(yup -c)"

prev_count="$(cat "$tempfile")"

if (( $prev_count < $count )); then
	notify-send -i package -u low "updates available" "$(yup -l)"
fi
echo "$count" > "$tempfile"

do_update(){
	i3-msg "exec --no-startup-id setsid -f $TERMINAL -c floating -e yup" 2>/dev/null 1>/dev/null
}

case "$BLOCK_BUTTON" in
	1) 
		if [ $(dunstctl is-paused) = true ]; then
			yup -l | awk -F ' ' '{for(i=1;i<=NF;i++){ if (i != 3) {print $i}}}' | \
				zenity --list \
				--column Name \
				--column Current \
				--column Updated \
				--class=STATUSBAR_POPUP \
				--title=yup \
				--text="Available updates:"
		else 
			notify-send -i package -u low "updates available" "$(yup -l)"
		fi ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
	3) do_update ;;
esac 2>/dev/null 1>/dev/null

if [ "$count" -le 15 ]; then
	color="${color7:-"#ffffff"}"
elif [ "$count" -le 40 ]; then
    color="${color3:-"#fef44e"}"
elif [ "$count" -le 75 ]; then
	color="${color5:-"#ff5252"}"
else
	color="${color1:-"#ff8144"}"
fi

if [ $count -eq 0 ]; then
	exit 0
fi

if [ -e "$SWITCH" ]; then
	echo "<span color=\"$color\">󰏔 </span>"
else
	echo "󰏔 <span color=\"$color\">$count</span>"
fi


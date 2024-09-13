#!/usr/bin/env sh

ICON='󰊢'

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

[ -z "$CODE" ] && return 1
[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

case $BLOCK_BUTTON in
    1) 
		if [ $(dunstctl is-paused) = true ]; then
			cgs | awk -F ' ' '{for(i=1;i<=NF;i++){print $i}}' | \
				zenity --list \
				--column Lang \
				--column Name \
				--column Branch \
				--class=STATUSBAR_POPUP \
				--title="rgs"
				--text="Dirty repositories:"
		else 
			notify-send -i git "Repositories" "$(cgs -mb)"
		fi ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) notify-send -i git "Repositories" "$(cgs -F)" ;;
esac

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

_json() {
    echo '{"icon": "'${1}'", "state":"'${2:-"Idle"}'", "text":"'${3}'"}';
}

_span() {
    if [ -n "$3" ]; then
        echo "<span size='large'>$1</span> <span color='$2'>$3</span>"
    else
        echo "<span size='large' color='$2'>$1 </span>"
    fi
}

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

if [ $repos -eq 0 ]; then
    if [ "$json" = true ]; then
        _json "" "" ""
    fi

	exit 0
fi

if [ -e "$SWITCH" ]; then
    if [ "$json" = true ]; then
        _json "" "$state" "$ICON"
    else
        _span "$ICON" "$color"
    fi
else
    if [ "$json" = true ]; then
        _json "cgs" "$state" "$repos"
    else
        _span "$ICON" "$color" "$repos"
    fi
fi




#!/usr/bin/env bash

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

case "$BLOCK_BUTTON" in
	1) wtoggle2 -d60%x60% -T newsboat  2>&1; sleep 1 >/dev/null ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
	3) newsboat -x reload 2>/dev/null >/dev/null;;
esac

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

shift $((OPTIND - 1))

_json() {
    echo '{"icon": "'${1:-"$(basename $0)"}'", "state":"'${2}'", "text":"'${3}'"}';
}

_span() {
    if [ -n "$3" ]; then
        echo "<span size='large'>$1</span> <span color='$2'>$3</span>"
    else
        echo "<span size='large' color='$2'>$1 </span>"
    fi
}

state="Idle"
color="$theme10"
UNREAD="$(newsboat -x print-unread | awk '{print $1}')"
if [ "$UNREAD" = "Error:" ]; then
    if [ "$json" = "true" ]; then
        _json "news" "$state" " "
    else
        _span " " "$color"
    fi
    exit 0
fi


if [ $UNREAD -gt 50 ]; then
    state="Critical"
    color="$theme12"
elif [ $UNREAD -gt 20 ]; then
    state="Warning"
    color="$color13"
elif [ $UNREAD -gt 10 ]; then
    state="Info"
    color="$theme15"
fi

if [ "$UNREAD" -eq 0 ] || [ -e "$SWITCH" ]; then
    UNREAD=""
fi

if [ "$json" = "true" ]; then
    _json "news" "$state" "$UNREAD"
else
    _span " " "$color" "$UNREAD"
fi

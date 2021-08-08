#!/usr/bin/env sh

. "$HOME/.profile"
[ -e  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

NOTIFY_ARGS="--hint=int:transient:1 -t 750"

if [ "$(playerctl "--player=$PLAYER" status 2>&1)" = "No players found" ]; then
	ANY_PLAYER="$(playerctl --list-all | cut -d'.' -f1 | head -1)"
	if [ -n "$ANY_PLAYER" ]; then
		PLAYER="$ANY_PLAYER"
	fi
fi

PLAYER_ARG="--player=$PLAYER,%any"
PLAYER_STATUS="$(playerctl "$PLAYER_ARG" status 2>&1)"
if [ "$PLAYER_STATUS" = "No players found" ] && [ -n "$BLOCK_BUTTON" ]; then
    notify-send -i "$PLAYER" "$PLAYER" "starting"
    i3-msg "exec --no-startup-id $PLAYER" >/dev/null 2>&1
	exit 0
fi


case $BLOCK_BUTTON in
1)
    playerctl next "$PLAYER_ARG"
    notify-send "$NOTIFY_ARGS" -i "$PLAYER" "playerctl" "next song"
    ;;
2)
    playerctl play-pause "$PLAYER_ARG"
	notify-send "$NOTIFY_ARGS" -i "$PLAYER" "playerctl" "$([ "$PLAYER_STATUS" == "Playing" ] && echo "Paused" || echo "Playing")"
    ;;
3)
    playerctl previous "$PLAYER_ARG"
    notify-send "$NOTIFY_ARGS" -i "$PLAYER" "playerctl" "prev song"
    ;;
4)
    playerctl "$PLAYER_ARG" volume "0.05+"
	vol="$(playerctl "$PLAYER_ARG" volume)"
	vol=$(echo "$vol * 100" | bc -l)
    notify-send "$NOTIFY_ARGS" -h "int:value:$vol" -h "string:synchronous:volume" -i "$PLAYER" "playerctl" "volume +5%"
    ;;
5)
    playerctl "$PLAYER_ARG" volume "0.05-"
	vol="$(playerctl "$PLAYER_ARG" volume)"
	vol=$(echo "$vol * 100" | bc -l)
    notify-send "$NOTIFY_ARGS" -h "int:value:$vol" -h "string:synchronous:volume" -i "$PLAYER" "playerctl" "volume -5%"
    ;;
esac

color="$color7"

case "$PLAYER_STATUS" in
	"Playing")
		icon="喇"
		color="$color2"
		text="$(playerctl "$PLAYER_ARG" metadata title | cut -c -30 | iconv -c)"
		;;
	"No players found")
		icon=""
		;;
	"Stopped")
		icon=""
		;;
	"Paused")
		icon=""
		text="$(playerctl "$PLAYER_ARG" metadata title | cut -c -30 | iconv -c)"
		;;
esac

printf "<span color='$color'>%s %s</span>\n" "$icon" "$text"

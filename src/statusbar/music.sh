#!/usr/bin/env sh

. "$HOME/.profile"

if [ "$(playerctl "--player=$PLAYER" status 2>&1)" = "No players found" ]; then
	PLAYER="$(playerctl --list-all | cut -d'.' -f1 | head -1)"
fi

PLAYER_ARG="--player=$PLAYER,%any"
PLAYER_STATUS="$(playerctl "$PLAYER_ARG" status 2>&1)"
if [ "$PLAYER_STATUS" = "No players found" ] && [ -n "$BLOCK_BUTTON" ]; then
    notify-send -i "$PLAYER" "$PLAYER" "starting"
    i3-msg "exec --no-startup-id $PLAYER" >/dev/null 2>&1
fi


case $BLOCK_BUTTON in
1)
    playerctl next "$PLAYER_ARG"
    notify-send -i $PLAYER "playerctl" "next song"
    ;;
2)
    playerctl play-pause "$PLAYER_ARG"
    notify-send -i $PLAYER "playerctl" "$(playerctl "$PLAYER_ARG" status 2>&1)"
    ;;
3)
    playerctl previous "$PLAYER_ARG"
    notify-send -i $PLAYER "playerctl" "prev song"
    ;;
4)
    playerctl "$PLAYER_ARG" volume "0.05+"
    notify-send -i $PLAYER "playerctl" "volume +5%"
    ;;
5)
    playerctl "$PLAYER_ARG" volume "0.05-"
    notify-send -i $PLAYER "playerctl" "volume -5%"
    ;;
esac

case "$PLAYER_STATUS" in
	"Playing")
		icon="喇 "
		text="$(playerctl "$PLAYER_ARG" metadata title | cut -c -30 | iconv -c)"
		;;
	"No players found")
		icon=" "
		;;
	"Stopped")
		icon=" "
		;;
	"Paused")
		icon=" "
		text="$(playerctl "$PLAYER_ARG" metadata title | cut -c -30 | iconv -c)"
		;;
esac

printf "%s %s\n" "$icon" "$text"

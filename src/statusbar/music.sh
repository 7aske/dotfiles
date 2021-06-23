#!/usr/bin/env sh

. "$HOME/.profile"

if [ -n "$1" ]; then
    PLAYER="$1"
elif [ -z "$PLAYER" ]; then
    # default player
    PLAYER="spotify"
fi

PLAYER_ARG="--player=$PLAYER,%any,chromium"
PLAYER_STATUS="$(playerctl "$PLAYER_ARG" status 2>&1)"

if [ "$PLAYER_STATUS" = "No players found" ] && [ -n "$BLOCK_BUTTON" ]; then
    notify-send -i "$PLAYER" "$PLAYER" "starting"
    i3-msg "exec --no-startup-id $PLAYER" >/dev/null 2>&1
fi


case $BLOCK_BUTTON in
1)
    playerctl next "$PLAYER_ARG"
    notify-send -i none "playerctl" "next song"
    ;;
2)
    playerctl play-pause "$PLAYER_ARG"
    notify-send -i none "playerctl" "$(playerctl "$PLAYER_ARG" status 2>&1)"
    ;;
3)
    playerctl previous "$PLAYER_ARG"
    notify-send -i none "playerctl" "prev song"
    ;;
4)
    playerctl "$PLAYER_ARG" volume "0.05+"
    notify-send -i none "playerctl" "volume +5%"
    ;;
5)
    playerctl "$PLAYER_ARG" volume "0.05-"
    notify-send -i none "playerctl" "volume -5%"
    ;;
esac

case "$PLAYER_STATUS" in
"Playing")
    printf "喇 %s\n" "$(playerctl "$PLAYER_ARG" metadata title | cut -c -30 | iconv -c)"
    ;;
"No players found")
    echo " "
    ;;
"Stopped")
    echo " "
    ;;
"Paused")
    printf " %s\n" "$(playerctl "$PLAYER_ARG" metadata title | cut -c -30 | iconv -c)"
    ;;
esac

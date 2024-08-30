#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

[ -e "$HOME/.profile" ] && . "$HOME/.profile"
[ -e  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

NOTIFY_ARGS="-a playerctl -t 500"

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

curr_vol=""
case $BLOCK_BUTTON in
1)
    playerctl next "$PLAYER_ARG"
    notify-send $NOTIFY_ARGS -i "$PLAYER" "playerctl" "next song"
    ;;
2)
    playerctl play-pause "$PLAYER_ARG"
	notify-send $NOTIFY_ARGS -i "$PLAYER" "playerctl" "$([ "$PLAYER_STATUS" == "Playing" ] && echo "Paused" || echo "Playing")"
    ;;
3)
    playerctl previous "$PLAYER_ARG"
    notify-send $NOTIFY_ARGS -i "$PLAYER" "playerctl" "prev song"
    ;;
4)
	if [[ "$PLAYER_ARG" =~ "chromium" ]]; then
		if ( pgrep "brave" >/dev/null ); then
			padefault volume-specific "brave" "+5%"
		else
			padefault volume-specific "chromium" "+5%"
		fi
	elif [[ "$PLAYER_ARG" =~ "spotify" ]]; then
		padefault volume-specific "spotify" "+5%"
	else
		playerctl "$PLAYER_ARG" volume "0.05+"
		vol="$(playerctl "$PLAYER_ARG" volume)"
		vol=$(echo "$vol * 100" | bc -l)
		notify-send $NOTIFY_ARGS -h "int:value:$vol" -h "string:synchronous:volume" -i "$PLAYER" "playerctl" "volume +5%"
	fi
    ;;
5)
	if [[ "$PLAYER_ARG" =~ "chromium" ]]; then
		if ( pgrep "brave" >/dev/null ); then
			padefault volume-specific "brave" "-5%"
		else
			padefault volume-specific "chromium" "-5%"
		fi
	elif [[ "$PLAYER_ARG" =~ "spotify" ]]; then
		padefault volume-specific "spotify" "-5%"
	else
		playerctl "$PLAYER_ARG" volume "0.05-"
		vol="$(playerctl "$PLAYER_ARG" volume)"
		vol=$(echo "$vol * 100" | bc -l)
		notify-send $NOTIFY_ARGS -h "int:value:$vol" -h "string:synchronous:volume" -i "$PLAYER" "playerctl" "volume -5%"
	fi
    ;;
6) playerctl "$PLAYER_ARG" position "5+" ;;
7) playerctl "$PLAYER_ARG" position "5-" ;;
esac

color="$color7"
case "$PLAYER_STATUS" in
	"Playing")
		icon="󰐌"
		case "$PLAYER" in
			spotify) icon="" ;;
		esac
		color="$color2"
		text="$(playerctl "$PLAYER_ARG" metadata title | cut -c -30 | iconv -c | sed 's_&_&amp;_g; s_<_&lt;_g; s_>_&gt;_g;')"
		;;
	"No players found")
		icon="󰎆"
		;;
	"Stopped")
		icon=""
		text=""
		;;
	"Paused")
		icon=""
		text=""
		;;
esac

if [ -e "$SWITCH" ]; then
	text=""
fi

printf "<span size='large' color='$color'>%s</span> <span color='$color'>%s</span>\n" "$icon" "$text"

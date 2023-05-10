#!/usr/bin/env sh

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

case $BLOCK_BUTTON in
	1) pavucontrol -t 3 2>&1 >/dev/null;;
	2) padefault ma     2>&1 >/dev/null;;
	3) padefault toggle 2>&1 >/dev/null;;
	4) padefault volume +5% 2>&1 >/dev/null;;
	5) padefault volume -5% 2>&1 >/dev/null;;
esac

default_sink=$(pactl info | grep "Default Sink:" | cut -d ' ' -f3)

padef_get_vol() {
	sink="${1:-"$default_sink"}"
	pactl list sinks | grep -A7 "^[[:space:]]Name: $sink" | \
		tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
}

_is_any_muted() {
	target="${1:-"sink"}"
	for mute in $(pactl list "${target}s" | grep Mute | awk '{print $2}'); do
		if [ "$mute" == "yes" ]; then
			return 0
		fi
	done
	return 1

}

VOLUME="$(padef_get_vol)"

ICON_LOW="󰕿"
ICON_MED="󰖀"
ICON_HIGH="󰕾"
ICON_MUTED="󰖁"

if [ "$VOLUME" -ge 90 ]; then
	ICON=$ICON_HIGH
	color="${color1:-"#BF616A"}"
elif [ "$VOLUME" -ge 66 ]; then
	ICON=$ICON_HIGH
	color="${color3:-"#D08770"}"
elif [ "$VOLUME" -ge 33 ]; then
	ICON=$ICON_MED
    color="${color2:-"#EBCB8B"}"
else
	ICON=$ICON_LOW
	color="${color7:-"#D8DEE9"}"
fi

if _is_any_muted; then
	ICON=$ICON_MUTED
	color="${color1:-"#BF616A"}"
	echo "<span color=\"$color\" size='large'> $ICON </span>"
	exit 0
fi

echo "<span size='x-large'>$ICON</span> <span rise='2pt' color=\"$color\">$VOLUME%</span>"

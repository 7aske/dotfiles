#!/usr/bin/env sh

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

inputs="$(pactl list source-outputs | grep application.process.binary)"

case $BLOCK_BUTTON in
	1) pavucontrol -t 4 2>&1 >/dev/null;;
	2) padefault mute-all-src ;;
	3) notify-send -i audio-recorder "active inputs" "$(echo $inputs | cut -d= -f2 | sed -e 's/["\ ]//g')" ;;
	4) padefault mic-volume +5% 2>&1 >/dev/null;;
	5) padefault mic-volume -5% 2>&1 >/dev/null;;
esac

color="${foreground:-"#D8DEE9"}"
muted_color="${color1:-"#BF616A"}"
icon=" "
muted_icon="  "

sources="$(pactl list sources short | grep -vc "monitor")"
muted="$(pactl list sources | grep -B6 "Mute: yes" | grep "Name:" | grep -vc "monitor")"

default_sink=$(pactl info | grep "Default Source:" | cut -d ' ' -f3)

padef_get_vol() {
	sink="${1:-"$default_sink"}"
	pactl list sources | grep -A7 "^[[:space:]]Name: $sink" | \
		tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
}

VOLUME="$(padef_get_vol)"

if [ $sources -eq $muted ] && [ $muted -gt 0 ]; then
	color="$muted_color"
	icon="$muted_icon"
fi

if [ -z "$inputs" ]; then
	exit 0
fi

echo "<span size='medium' color='$color'>$icon</span><span color=\"$color\">$VOLUME%</span>"

#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

case $BLOCK_BUTTON in
	1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
esac

while getopts "j" opt; do
    case $opt in
        j) json=true ;;
    esac
done

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

temp="$(sensors | awk '/Package id 0:/{print substr($4, 2)} /Tdie|Tctl/{print substr($2, 2)}')"
temp_val="$(echo $temp | awk '{print substr($0, 1, length($0)-4)}')"

color="$color7"
if [ "$temp_val" -ge 70 ]; then
	color="$theme11"
    icon=""
    state="Critical"
    json_icon='temp_5'
elif [ "$temp_val" -ge 60 ]; then
	color="$theme12"
    icon=""
    state="Warning"
    json_icon='temp_4'
elif [ "$temp_val" -ge 50 ]; then
	color="$theme13"
    icon=""
    state="Info"
    json_icon='temp_3'
elif [ "$temp_val" -ge 40 ]; then
	color="$theme15"
    icon=""
    state="Idle"
    json_icon='temp_2'
else
    icon=""
    state="Idle"
    json_icon='temp_1'
fi

if [ -e "$SWITCH" ]; then
    if [ -n "$json" ]; then
        _json "$json_icon" "$state"
    else
        _span "$icon" "$color"
    fi
else
    if [ -n "$json" ]; then
        _json "$json_icon" "$state" "$temp"
    else
        _span "$icon" "$color" "$temp"
    fi
fi

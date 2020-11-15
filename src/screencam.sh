#!/usr/bin/env bash

# based on script made by discharge97
# https://github.com/discharge97/dotfiles/blob/master/bin/sharescreen.sh

usage() {
	echo "usage: $0 <screen> -[nf]"
	echo "    -f <fps>    set fps (default: 30)"
	echo "    -n <num>    select screen by number"
	echo "    -d <dev>    video loopback device"
	exit 2
}

FPS="30"
SCR_NUM=""
DEVICE="/dev/video0"

opts="f:n:h"
while getopts $opts opt; do
	case "${opt}" in
		f) FPS="$OPTARG";;
		n) SCR_NUM="$OPTARG";;
		d) DEVICE="$OPTARG";;
		h) usage ;;
	esac
done
shift $((OPTIND-1))

if [ ! -e "$DEVICE" ]; then
	echo "error: $DEVICE: no such file or directory"
fi

SCREEN="$1"
if [ -z "$SCR_NUM" ]; then
	SCREEN_PATTERN="$SCREEN"
else
	SCREEN_PATTERN="^ $SCR_NUM: "
fi

SCREEN_INFO="$(xrandr --listactivemonitors | sed -n '1!p' | grep -E "$SCREEN_PATTERN")"
if [ -z "$SCREEN_INFO" ]; then
	usage
fi

SCREEN_PARAMS="$(echo "$SCREEN_INFO"| awk '{
	split($3,param,"/")
	width=param[1]

	split($3,param,"/")
	split(param[2], param, "x")
	height=param[2]

	split($3,param,"/")
	split(param[3], param, "+")
	xoff=param[2]
	yoff=param[3]

	print " " width " " height " " xoff " " yoff
}')"
PARAMS_ARR=($SCREEN_PARAMS)

ffmpeg -f x11grab -r $FPS -s "${PARAMS_ARR[0]}x${PARAMS_ARR[1]}" -i $DISPLAY+"${PARAMS_ARR[2]}","${PARAMS_ARR[3]}" -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 "$DEVICE"


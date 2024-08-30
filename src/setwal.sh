#!/usr/bin/env sh

WALLPAPERS="${WALLPAPERS:-$HOME/Pictures/wallpaper}"
DEFAULT_WALLPAPER="${DEFAULT_WALLPAPER:-$HOME/.config/wallpaper}"
DEFAULT_SCREENSAVER="${DEFAULT_SCREENSAVER:-$HOME/.config/screensaver}"
WAL_BACKEND="${WAL_BACKEND:-wal}"
CMD="$(basename "$0")"

[ -z "$(command -v wal)" ] && echo "wal: command not found" && exit 2
[ -z "$(command -v sxiv)" ] && echo "sxiv: command not found" && exit 2

invalid_opt() {
    printf "%s: invalid argument '%s'\nTry '%s -h' for more information.\n" "$CMD" "$1" "$CMD"
	exit 1
}

setwal_usage() {
    echo "usage: $CMD [option]"
    echo "options:"
    printf "  %-14s%s\n" "-w <file>" "sets file as wallpaper"
    printf "  %-14s%s\n" "-l" "set on from wallpapers dir"
    printf "  %-14s%s\n" "-R" "sets a random wallpaper"
    printf "  %-14s%s\n" "-r" "reload current wallpaper"
    printf "  %-14s%s\n" "-h, --help" "shows this message"
    exit 2
}

random_wallpaper() {
    PICTURE="$(find "$WALLPAPERS" -printf "$WALLPAPERS/%f\n" | shuf -n 1)"
    set_wallpaper_wal "$PICTURE"
	exit 0
}

reload_wallpaper() {
    set_wallpaper_wal "$DEFAULT_WALLPAPER"
	exit 0
}

list_wallpapers() {
    PICTURE="$(find "$WALLPAPERS" -printf "$WALLPAPERS/%f\n" | sxiv -tio | sed '1q')"
    set_wallpaper "$PICTURE"
	exit 0
}

set_wallpaper() {
    if echo "$1" | grep '^/' >/dev/null; then
        PICTURE="$1"
    else
        PICTURE="$(pwd)/$1"
    fi
	[ -z "$PICTURE" ] && exit 1
    [ ! -L "$PICTURE" ] && ln -sf "$PICTURE" "$DEFAULT_WALLPAPER"
	feh --bg-fill "$PICTURE"
	set_screensaver &
}

set_screensaver() {
	convert "$DEFAULT_WALLPAPER" -blur 0x60 "$DEFAULT_SCREENSAVER"
}

set_wallpaper_wal() {
    if echo "$1" | grep '^/' >/dev/null; then
        PICTURE="$1"
    else
        PICTURE="$(pwd)/$1"
    fi
	[ -z "$PICTURE" ] && exit 1
    [ ! -L "$PICTURE" ] && ln -sf "$PICTURE" "$DEFAULT_WALLPAPER"
	echo "$PICTURE"
    wal --backend "$WAL_BACKEND" -i "$PICTURE" &
	set_screensaver &
}

OPTIND=1
wallpaper=""

while getopts "h?rRlw:" opt; do
    case "$opt" in
    h|\?)
        setwal_usage ;;
    r)
		reload_wallpaper ;;
    R)
		random_wallpaper ;;
    w)
		wallpaper=$OPTARG ;;
	l)
		list_wallpapers ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift


if [ -n "$wallpaper" ]; then
	set_wallpaper_wal "$wallpaper"
elif [ -n "$1" ]; then
	set_wallpaper "$1"
else
    sxiv -t "$WALLPAPERS" &
fi


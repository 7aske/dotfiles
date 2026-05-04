#!/usr/bin/env sh

UNI_NAME="nikola_tasic_3698"
PRINT=0

while getopts "p" arg; do
	case $arg in
		p) PRINT=1 ;;
	esac
done

shift $((OPTIND - 1))


usage() {
    echo "mkuni <dz|v> [num]"
    exit 2
}

uni_get_name() {
    case "$2" in
        v|p)
            echo "$1-$2$(printf "%02d" "$3")"
            ;;
        *)
            echo "$1-$2$(printf "%02d" "$3")-$UNI_NAME"
            ;;
    esac
}

[ -z "$1" ] && usage

SUBJECT="$(basename `pwd`)"

if [ -z "$2" ]; then
    NUM="$(ls -1 | grep -E "$1[0-9]+" | sed -r "s/.*($1)([0-9]+).*/\2/" | sed  -n '$p' 2>/dev/null)"

    [ -z "$NUM" ] && NUM="00"

	NUM="$(echo "$NUM + 1" | bc -l)"
else
    NUM="$2"
fi

NAME="$(uni_get_name "$SUBJECT" "$1" "$NUM")"
if (( $PRINT )); then
	echo "$NAME"
else
	mkdir -v "$NAME"
fi

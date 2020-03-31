#!/usr/bin/env sh

UNI_NAME="nikola_tasic_3698"


usage() {
    echo "mkuni <dz|v> [num]"
    exit 2
}

uni_mkdir() {
    set -v
    case "$2" in
        "v")
            mkdir -v "$1-$2$(printf "%02d" "$3")"
            ;;
        *)
            mkdir -v "$1-$2$(printf "%02d" "$3")-$UNI_NAME"
            ;;
    esac
    set +v
}

[ -z "$1" ] && usage

SUBJECT="$(basename `pwd`)"

if [ -z "$2" ]; then
    NUM="$(ls -1 | grep -E "$1[0-9]+" | sed -r "s/.*($1)([0-9]+).*/\2/" | sed  -n '$p' 2>/dev/null)"

    [ -z "$NUM" ] && NUM="00"

    NUM=$(($NUM + 1))
else
    NUM="$2"
fi

uni_mkdir "$SUBJECT" "$1" "$NUM"

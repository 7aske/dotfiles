#!/usr/bin/env bash

PROG_NAME="$(basename $0)"

if [ -z "$CODE" ]; then
	"$PROG_NAME: CODE env variable not defined"
	exit 3
fi

AR_FOLDER="${AR_FOLDER:-"$CODE/old"}"

if [ ! -e "$CODE" ]; then
	echo "$PROG_NAME: CODE=$CODE: no such file or directory"
	exit 3
fi

if [ ! -e "$AR_FOLDER" ]; then
	echo "$PROG_NAME: $AR_FOLDER: no such file or directory"
	exit 3
fi

_usage() {
	echo "$PROG_NAME: codea <repo> [options]"
	echo "options:"
	echo -ne "\t-d <dir>    output dir"
	echo
	exit 1
}

OUT=""
DIR="$AR_FOLDER"

while getopts ":hd:" arg; do
	case $arg in
		d) DIR="$OPTARG" ;;
		:) echo "$PROG_NAME: option -$OPTARG requires an argument"
			exit 2 ;;
	esac
done

shift $((OPTIND - 1))

REPO="$1"

if [ -z "$REPO" ]; then
	_usage
fi

if [ ! -e "$REPO" ]; then
	echo "$PROG_NAME: $REPO: no such file or directory"
	exit 3
fi

if [ ! -e "$DIR" ]; then
	echo "$PROG_NAME: $DIR: no such file or directory"
	exit 3
fi

BASE="$(basename `pwd`)"
case $BASE in
	work|isum) DIR="$DIR/$BASE/$REPO" ;;
	*) DIR="$DIR/projs/$REPO" ;;
esac

mv -iv "$REPO" "$DIR"


#!/usr/bin/env sh

[ -z "$CODE" ] && echo "'CODE' not set" && exit 0

FORCE=0

while getopts ":f" ARG; do
	case $ARG in
		f) FORCE=1 ;;
		:) echo "codesync: -$arg requires and argument"
			exit 2;;
	esac
done

FOLDERS="$(find "$CODE" -type d \
	\(\
		-name out                 -prune -o\
		-name target              -prune -o\
		-name dist                -prune -o\
		-name cmake-build-release -prune -o\
		-name cmake-build-debug   -prune -o\
		-name node_modules        -prune -o\
		-name __pycache__         -prune -o\
		-name build               -prune \
	\) -a \! \
	\(\
		-path $CODE/work*         -prune -o\
		-path \*/lib/\*           -prune -o\
		-path \*nvim/plugged\*    -prune -o\
		-path \*neovim\*          -prune   \
	\) -prune -printf "%p\n")"

for F in $FOLDERS; do 
	echo $F
	POSSIBLY_SAVED=$(du -sb $F | awk '{ print $1 }')
	if [ -w "$F" ] && ( [ -O "$F" ] || [ -G "$F" ] ); then
		if [ "$(basename "$F")" == "__pycache__" ] || (( $FORCE )); then
			rm -rf "$F"
		else
			rm -rI "$F"
		fi
	fi
	if [ ! -e "$F" ]; then
		SAVED=$((SAVED + POSSIBLY_SAVED))
	fi
done

if [ "$SAVED" -eq 0 ]; then
	echo "Nothing to clean"
else
	echo "Cleaned and saved $(numfmt --to iec --format "%f" "$SAVED")" 
fi



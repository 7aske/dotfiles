#!/usr/bin/env sh

[ -z "$CODE" ] && echo "'CODE' not set" && exit 0

FOLDERS="$(find "$CODE" -type d \(\
	-name out                 -prune -o\
	-name target              -prune -o\
	-name dist                -prune -o\
	-name cmake-build-release -prune -o\
	-name cmake-build-debug   -prune -o\
	-name node_modules        -prune -o\
	-name __pycache__         -prune -o\
	-name build               -prune -a\
	\! -path \*neovim\*       -prune   \
	\) -prune -printf "%p\n")"

for F in $FOLDERS; do 
	echo $F
	if [ -w "$F" ] && ( [ -O "$F" ] || [ -G "$F" ] ); then
		rm -rI "$F"
	fi
done



#!/usr/bin/env sh

[ -z "$CODE" ] && echo "'CODE' not set" && exit 0

find "$CODE" -type d \(\
	-name out -prune -or\
	-name target -prune -or\
	-name dist -prune -or\
	-name cmake-build-release -prune -or\
	-name cmake-build-debug -prune -or\
	-name node_modules -prune -or\
	-name build -prune -or\
	-name __pycache__ -prune\
	\) -exec rm -rf {} \;



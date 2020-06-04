#!/usr/bin/env bash

file=$(readlink -f "$1")
dir=$(dirname "$file")
base="${file%.*}"

case "$file" in
	*\.[rR]md) Rscript -e "rmarkdown::render('$file', quiet=TRUE)" ;;
	*\.md) pandoc "$file" --pdf-engine=xelatex -o "$base".pdf ;;
	*config.h) sudo make install ;;
	*\.c) cc "$file" -o "$base" && "$base" ;;
	*\.py) python "$file" ;;
	*\.go) go run "$file" ;;
	*) sed 1q "$file" | grep "^#!/" | sed "s/^#!//" | xargs -r -I % "$file" ;;
esac

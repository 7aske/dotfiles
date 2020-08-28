#!/usr/bin/env bash

file=$(readlink -f "$1")
dir=$(dirname "$file")
base="${file%.*}"

case "$file" in
	*\.kemd)
		Rscript -e "rmarkdown::render('$file', quiet=TRUE)"
		wkhtmltopdf "$base.html" "$base.pdf"
		rm "$base.html"
		;;
	*config.h) sudo make install ;;
	*\.c) cc "$file" -o "$base" && "$base" ;;
	*\.py) python "$file" ;;
	*\.go) go run "$file" ;;
	*) sed 1q "$file" | grep "^#!/" | sed "s/^#!//" | xargs -r -I % "$file" ;;
esac

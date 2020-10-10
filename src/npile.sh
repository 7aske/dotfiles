#!/usr/bin/env bash

file=$(readlink -f "$1")
dir=$(dirname "$file")
base="${file%.*}"

case "$file" in
	*\.md)
		Rscript -e "rmarkdown::render('$file', quiet=TRUE)"
		pdf_filename="$base.pdf"
		html_filename="$base.html"
		QT_STYLE_OVERRIDE='Windows' wkhtmltopdf "$html_filename" "$pdf_filename"
		rm "$html_filename"
		(pgrep -fi  "$pdf_filename" 2>&1>/dev/null) || (zathura "$pdf_filename" &)
		;;
	*config.h) sudo make install ;;
	*\.c) cc "$file" -o "$base" && "$base" ;;
	*\.py) python "$file" ;;
	*\.go) go run "$file" ;;
	*) sed 1q "$file" | grep "^#!/" | sed "s/^#!//" | xargs -r -I % "$file" ;;
esac

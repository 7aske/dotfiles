#!/usr/bin/env bash

file=$(readlink -f "$1")
dir=$(dirname "$file")
base="${file%.*}"
MD_COMPLIER="${MD_COMPILER:-"pandoc"}"

function _compile_md_pandoc(){
	pandoc \
		--pdf-engine=pdflatex \
        -V 'mainfont:NotoSans-Regular' \
        -V 'sansfont:NotoSans-Regular' \
        -V 'monofont:FiraCode-Regular' \
		-o "$base.pdf" \
		"$base.md"
	(pgrep -fi  "$base.pdf" 2>&1>/dev/null) || (zathura "$base.pdf" &)
}

function _compile_md_r(){
	Rscript -e "rmarkdown::render('$file', quiet=TRUE)"
	pdf_filename="$base.pdf"
	html_filename="$base.html"
	QT_STYLE_OVERRIDE='Windows' wkhtmltopdf "$html_filename" "$pdf_filename"
	rm "$html_filename"
	(pgrep -fi  "$pdf_filename" 2>&1>/dev/null) || (zathura "$pdf_filename" &)
}

function _compile_tex(){
	pdflatex "$file"
	(pgrep -fi  "$base.pdf" 2>&1>/dev/null) || (zathura "$base.pdf" &)
}

case "$file" in
	*\.tex) _compile_tex ;;
	*\.md)
		case "$MD_COMPLIER" in
			"pandoc")  _compile_md_pandoc ;;
			"r")       _compile_md_r ;;
		esac ;;
	*config.h) sudo make install ;;
	*\.c) cc "$file" -o "$base" && "$base" ;;
	*\.py) python "$file" ;;
	*\.go) go run "$file" ;;
	*) sed 1q "$file" | grep "^#!/" | sed "s/^#!//" | xargs -r -I % "$file" ;;
esac

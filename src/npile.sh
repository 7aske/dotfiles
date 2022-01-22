#!/usr/bin/env bash

file=$(readlink -f "$1")
dir=$(dirname "$file")
base="${file%.*}"
MD_COMPLIER="${MD_COMPILER:-"markdown-pdf"}"

function _compile_md_pandoc(){
	pandoc \
		--pdf-engine=xelatex \
		-V "mainfont=DejaVuSans" \
		-V "sansfont=OpenSans-Regular" \
		-V "monofont=FiraCode-Regular" \
		-V "documentclass=book" \
		-V "margin-left=20mm" \
		-V "margin-right=20mm" \
		-V "margin-top=20mm" \
		-V "margin-bottom=20mm" \
		-V "pagestyle=empty" \
		-f gfm \
		--highlight-style=tango \
		--strip-comments \
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

function _compile_markdown_pdf(){
	pdf_filename="$base.pdf"
	html_filename="$base.html"
	opts=""
	if [ -e "remarkable.json" ]; then
		opts="$opts -m remarkable.json"
	fi
	markdown-pdf -m '{"html":true,"xhtmlOut":true,"breaks":true}'  -o "$pdf_filename" "$file"
}

function _compile_tex(){
	pdflatex "$file"
	(pgrep -fi  "$base.pdf" 2>&1>/dev/null) || (zathura "$base.pdf" &)
}

case "$file" in
	*\.tex) _compile_tex ;;
	*\.md)
		case "$MD_COMPLIER" in
			"markdown-pdf") _compile_markdown_pdf ;;
			"pandoc")       _compile_md_pandoc ;;
			"r")            _compile_md_r ;;
		esac ;;
	*config.h) sudo make install ;;
	*\.c) cc "$file" -o "$base" && "$base" ;;
	*\.py) python "$file" ;;
	*\.go) go run "$file" ;;
	*) sed 1q "$file" | grep "^#!/" | sed "s/^#!//" | xargs -r -I % "$file" ;;
esac

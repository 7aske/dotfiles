#!/usr/bin/env bash

CCHECK_PATTERN="${CCHECK_PATTERN:-"@(Refactor|Bug|DeadCode|Incomplete|Cleanup|Warning|CopyPast[ae]|Temporary|Optimization|Note|Todo|Hack)"}"
#printf '\e]8;;http://example.com\e\\This is a link\e]8;;\e\\\n'

_PWD="$(pwd)"
if $(git rev-parse --is-inside-work-tree 2>/dev/null); then
	for file in $(git ls-files); do
		match="$(grep --color=always -En "$CCHECK_PATTERN" "$file")"
		if [ -n "$match" ]; then
			IFS=$'\n'
			for line in $match; do
				printf "\e[35mfile://$_PWD/$file\e[0m:${line}\n"
			done
			IFS=$' '
		fi
	done
else
	for file in $(find . -type f); do
		match="$(grep --color=always -En "$CCHECK_PATTERN" "$file")"
		if [ -n "$match" ]; then
			IFS=$'\n'
			for line in $match; do
				printf "\e[35mfile://$_PWD/$file\e[0m:${line}\n"
			done
			IFS=$' '
		fi
	done
fi

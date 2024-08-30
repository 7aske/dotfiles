#!/usr/bin/env bash

WORKSPACES="$(i3-msg -t get_workspaces | jq | grep name | sed 's/.*:\ \"\(.*\)\".*/\1/g' | sort -r)"

for i in {1..9}; do 
	if [[ ! "$WORKSPACES" =~ "$i" ]]; then
		i3-msg workspace $i
		exit 0
	fi
done

exit 1

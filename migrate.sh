#!/usr/bin/env bash

for file in $(dir -1 "$HOME/.config"); do
    src="$HOME/.config/$file"
    dest="$(readlink "$src")"
    if [ -L "$src" ]; then
        echo "Moving $src"
        rm "$HOME/.config/$file"
        ln -s "$(echo "$dest" | sed -e 's/\.config/config/')" "$src" 
    fi
done


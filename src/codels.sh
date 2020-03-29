#!/usr/bin/env sh
. "$HOME/.profile"

# lists all (2 levels deep) git repositories from 'CODE' dir

if [ -z "$CODE" ]; then
    echo "'CODE' env not set"
    exit 1
fi

is_repo() {
    dir -1 -A "$1" | grep -q ".git" >/dev/null 2>&1
}

for file in $(dir -1 "$CODE"); do
    if is_repo "$CODE/$file"; then
        echo "$CODE/$file"
    else
        for sub in $(dir -1 "$CODE/$file"); do
            if [ -d "$CODE/$file/$sub" ]; then
                if is_repo "$CODE/$file/$sub"; then
                    echo "$CODE/$file/$sub"
                fi
            fi
        done
    fi
done

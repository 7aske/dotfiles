#!/usr/bin/env sh

# converts https github remote to ssh one

remote="$(git remote -v | grep -v "git@" | grep push | awk '{print $2}' | awk -F '/' '{print  "git@"$3":"$4"/"$5}')"

if [ -n "$remote" ]; then
    git remote set-url origin "$remote" 
fi

#!/usr/bin/env bash

lvl1="$(dir -1 -d "$CODE"/* 2> /dev/null | sort | fzf --reverse --cycle)"
declare lvl2
if [ -n "$lvl1" ]; then
    lvl2="$(dir -1 -d "$lvl1"/* 2> /dev/null | sort | fzf --reverse --cycle)"
    if [ -z "$lvl2" ]; then
        echo "$lvl1"
    else
        echo "$lvl2"
    fi
else
    echo "$CODE"
fi


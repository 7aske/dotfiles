#!/usr/bin/env sh


echo $(/usr/bin/cgs -d | fzf --reverse --cycle)

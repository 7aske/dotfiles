#!/usr/bin/env sh


echo $(/usr/bin/cgs -d | fzf --preview 'git -c color.status=always -C {} status' --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' --reverse --cycle)

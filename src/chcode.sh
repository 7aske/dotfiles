#!/usr/bin/env bash

fd . $CODE -t d -d 2 2> /dev/null | fzf --reverse --cycle


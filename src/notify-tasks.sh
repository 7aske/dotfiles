#!/usr/bin/env bash

answ="$(notify-send -i notes-panel -t 60000 -a tasks "Tasks" "$(task list)" -A "open=Open taskwarrior")"
case "$answ" in
    "open") wtoggle2 -T -d60%x60% taskwarrior-tui ;;
esac


#!/usr/bin/env bash

SERVICE="$1"

[ -z "$SERVICE" ] && echo "usage: $0 <service>" && exit 1

if systemctl --user is-active --quiet "$SERVICE"; then
    systemctl --user stop "$SERVICE"
else
    systemctl --user start "$SERVICE"
fi


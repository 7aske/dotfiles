#!/usr/bin/env bash

DNS_SERVER="pioneer.local"

menu="rofi -dmenu -p device"
if [ -t 1 ]; then
    menu="fzf"
fi

ssh "$DNS_SERVER" "rg --only-matching --no-line-number '\w{2}(:\w\w){5},\d{1,3}(\.\d{1,3}){3},.*,infinite' infra/pihole/etc-pihole/pihole.toml" |
    awk -F, '{print $3 " " $1 " " $2}' | \
    $menu | \
    awk '{print $2}' | \
    xargs -r -I% ssh "$DNS_SERVER" 'wakeonlan % '

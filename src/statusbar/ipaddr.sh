#!/usr/bin/env sh
case $BLOCK_BUTTON in
    1) notify-send "Public IP" "$(curl -s api.ipify.org)" ;;
esac

ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -1


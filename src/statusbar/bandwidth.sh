#!/usr/bin/env sh

case $BLOCK_BUTTON in
    1) notify-send "Public IP" "$(curl -s api.ipify.org)" ;;
    3) notify-send "Local IP" "$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -1)" ;;
esac




iface="$(ip link | grep -e "BROADCAST" | sed 1q | awk '{print $2}' | cut -d ':' -f1)"


SLP=2
RX="$(cat /sys/class/net/"$iface"/statistics/rx_bytes)"
TX="$(cat /sys/class/net/"$iface"/statistics/tx_bytes)"

sleep $SLP

RX2="$(cat /sys/class/net/"$iface"/statistics/rx_bytes)"
TX2="$(cat /sys/class/net/"$iface"/statistics/tx_bytes)"

RRX="$(((RX2 - RX) / 1000 / SLP))"
RTX="$(((TX2 - TX) / 1000 / SLP))"

echo " $(printf '%5dk' $RRX)" "祝$(printf '%5dk' $RTX)"

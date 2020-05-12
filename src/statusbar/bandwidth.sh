#!/usr/bin/env sh

iface="$(ip link | grep -e "BROADCAST.*default" | grep -v "vbox" | awk '{print $2}' | cut -d ':' -f1)"


SLP=2
RX="$(cat /sys/class/net/"$iface"/statistics/rx_bytes)"
TX="$(cat /sys/class/net/"$iface"/statistics/tx_bytes)"

sleep $SLP

RX2="$(cat /sys/class/net/"$iface"/statistics/rx_bytes)"
TX2="$(cat /sys/class/net/"$iface"/statistics/tx_bytes)"

RRX="$(((RX2 - RX) / 1000 / SLP))"
RTX="$(((TX2 - TX) / 1000 / SLP))"

echo "🔻$(printf '%5dk' $RRX)" "🔺$(printf '%5dk' $RTX)"

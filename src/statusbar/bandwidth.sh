#!/usr/bin/env sh

_bc() {
	echo "scale=${2:-"2"}; $1" | bc
}

case $BLOCK_BUTTON in
    1) notify-send -i modem "Public IP" "$(curl -s api.ipify.org)" ;;
    3) notify-send -i network-wired "Local IP" "$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -1)" ;;
esac

IFACE="$(ip link | grep -e "BROADCAST" | sed 1q | awk '{print $2}' | cut -d ':' -f1)"

SLEEP=1

TIME_START=$(echo '('`date +"%s.%N"` ' * 1000000)/1' | bc)

RX_OLD="$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes)"
TX_OLD="$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes)"

sleep $SLEEP

RX_NEW="$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes)"
TX_NEW="$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes)"

RX_DELTA=$((RX_NEW - RX_OLD))
TX_DELTA=$((TX_NEW - TX_OLD))

TIME_END=$(echo '('`date +"%s.%N"` ' * 1000000)/1' | bc)

TIME_DELTA="$(_bc "$((TIME_END - TIME_START)) / 1000000")"

if [ $RX_DELTA -gt 1048576 ]; then
	RX_OUT="$(_bc "$RX_DELTA / 1048576 / $TIME_DELTA")M"
elif [ $RX_DELTA -gt 1024 ]; then
	RX_OUT="$(_bc "$RX_DELTA / 1024 / $TIME_DELTA" 0)k"
else
	RX_OUT="$(_bc "$RX_DELTA / $TIME_DELTA" 0)"
fi

if [ $TX_DELTA -gt 1048576 ]; then
	TX_OUT="$(_bc "$TX_DELTA / 1048576 / $TIME_DELTA")M"
elif [ $TX_DELTA -gt 1024 ]; then
	TX_OUT="$(_bc "$TX_DELTA / 1024 / $TIME_DELTA" 0)k"
else
	TX_OUT="$(_bc "$TX_DELTA / $TIME_DELTA" 0)"

fi

echo " $(printf '%5s' $RX_OUT)" "祝$(printf '%5s' $TX_OUT)"

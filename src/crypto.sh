#!/usr/bin/env bash


# i3blocks statusbar killswitch
SWITCH="$HOME/.cache/statusbar_$(basename $0)" 
case $BLOCK_BUTTON in
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
esac

if [ -e "$SWITCH" ]; then
	exit 0;
fi

# Associative array of crypto currency names
declare -A CRYPTO_MAP

for coin in ${CRYPTO}; do
	display="${coin%%:*}"
	value="${coin##*:}"
	CRYPTO_MAP+=([$display]=$value)
done

LOOP=false
TIMEOUT=2
FORMAT="%4s: %9s$"
while getopts ":t:f:l" ARG; do
	case $ARG in
		l) LOOP=true       ;;
		t) TIMEOUT=$OPTARG ;;
		f) FORMAT=$OPTARG  ;;
	esac
done

shift $((OPTIND - 1))

for coin in $@; do
	display="${coin%%:*}"
	value="${coin##*:}"
	CRYPTO_MAP+=([$display]=$value)
done

COIN="$@"

if [ -z "$COIN" ] && [ ! $LOOP ]; then
	exit 1
fi

api_url="https://api.coingecko.com/api/v3/coins"

coin_info() {
	data="$(curl -s "$api_url/${CRYPTO_MAP[$1]}")"
	price="$(echo "$data" | jq -r ".market_data.current_price.usd")"
	[ "$price" == "null" ] && return 1
	printf  "$FORMAT\n" "$1" "$price"
}

if [ -z "$COIN" ]; then
	while true; do
		for coin in ${!CRYPTO_MAP[@]}; do
			coin_info "$coin"
			sleep $TIMEOUT
		done
		if ! $LOOP; then
			exit 0
		fi
	done
else
	while true; do
		for coin in $COIN; do
			coin_info "${coin%%:*}"
			sleep $TIMEOUT
		done
		if ! $LOOP; then
			exit 0
		fi
	done
fi

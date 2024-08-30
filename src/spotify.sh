#!/usr/bin/env sh 

# https://github.com/abba23/spotify-adblock-linux

if [ -e "/usr/local/lib/spotify-adblock.so" ]; then
	LD_PRELOAD="/usr/local/lib/spotify-adblock.so" /usr/bin/spotify
elif [ -e "/usr/lib/spotify-adblock.so" ]; then
	LD_PRELOAD="/usr/lib/spotify-adblock.so" /usr/bin/spotify
else
	/usr/bin/spotify
fi


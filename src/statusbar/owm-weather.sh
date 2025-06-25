#!/bin/bash

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -e "$HOME/.config/owm.sh" ] && . "$HOME/.config/owm.sh"

WEATHER_CACHE="/tmp/weather.tmp"
WEATHER_JSON="/tmp/weather.json"
LATLON_CACHE="/tmp/latlon.tmp"
SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

[ -z "$OPENWEATHERMAP_API_KEY" ] && echo "<span size='x-large'>󰼯 </span>" && exit 0

[ -e "$HOME/.config/owm.sh" ] && . "$HOME/.config/owm.sh"

if [ -z "$OPENWEATHERMAP_CITY_ID" ]; then
    if [ -e "$LATLON_CACHE" ]; then
        lon_lat=$(cat "$LATLON_CACHE")
    else
        # get current lon lat from ipinfo.io
        #lon_lat=$(curl -s ipinfo.io/loc)
        lon_lat=$(curl https://ipapi.co/json/ | \
            jq -r '. | [.latitude,.longitude|tostring] | join(",")')
        if [ -z "$lon_lat" ]; then
            echo "<span size='x-large'>󰼯 </span>"
            exit 0
        fi
        echo "$lon_lat" > "$LATLON_CACHE"
    fi

    OPENWEATHERMAP_LAT=$(echo "$lon_lat" | cut -d ',' -f 1)
    OPENWEATHERMAP_LON=$(echo "$lon_lat" | cut -d ',' -f 2)
fi

case $BLOCK_BUTTON in
    1) [ -e "$WEATHER_CACHE" ] && notify-send -i weather -a weather -t 10000 "OpenWeatherMap" "$(cat $WEATHER_CACHE)" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) xdg-open "https://openweathermap.org/city" ;;
esac

BASE_URL="http://api.openweathermap.org/data/2.5/weather"
if [ -n "$OPENWEATHERMAP_LAT" ] && [ -n "$OPENWEATHERMAP_LON" ]; then
    URL="${BASE_URL}?lat=${OPENWEATHERMAP_LAT}&lon=${OPENWEATHERMAP_LON}&appid=${OPENWEATHERMAP_API_KEY}&units=metric"
else
    URL="${BASE_URL}?id=${OPENWEATHERMAP_CITY_ID}&appid=${OPENWEATHERMAP_API_KEY}&units=metric"
fi

resp_code=1
if [ -z "$BLOCK_BUTTON" ]; then
    response=$(curl -s $URL)
    resp_code=$?
    echo $response > "$WEATHER_JSON"

    echo "Location:    $(echo $response | jq -r '.name')" > "$WEATHER_CACHE"
    echo "Temperature: $(echo $response | jq -r '.main.temp' | numfmt --format '%.0f' )°C" >> "$WEATHER_CACHE"
    echo "Weather:     $(echo $response | jq -r '.weather[0].description')" >> "$WEATHER_CACHE"
    echo "Humidity:    $(echo $response | jq -r '.main.humidity')%" >> "$WEATHER_CACHE"
    echo "Wind:        $(echo $response | jq -r '.wind.speed')m/s" >> "$WEATHER_CACHE"
    echo "Pressure:    $(echo $response | jq -r '.main.pressure')hPa" >> "$WEATHER_CACHE"
    echo "Sunrise:     $(date -d @$(echo $response | jq -r '.sys.sunrise') +'%T')" >> "$WEATHER_CACHE"
    echo "Sunset:      $(date -d @$(echo $response | jq -r '.sys.sunset') +'%T')" >> "$WEATHER_CACHE"
    echo
    echo "Last update: $(date +%T)" >> "$WEATHER_CACHE"
fi

if [ $resp_code -ne 0 ]; then
    response=$(cat "$WEATHER_JSON")
    resp_code=0
fi


declare -A ICONS

ICONS["01d"]=""
ICONS["01n"]="󰖔"
ICONS["02d"]=""
ICONS["02n"]=""
ICONS["03d"]="󰖐"
ICONS["03n"]="󰖐"
ICONS["04d"]=""
ICONS["04n"]=""
ICONS["09d"]=""
ICONS["09n"]=""
ICONS["10d"]=""
ICONS["10n"]=""
ICONS["11d"]=""
ICONS["11n"]=""
ICONS["13d"]=""
ICONS["13n"]=""
ICONS["50d"]=""
ICONS["50n"]=""
ICONS["unknown"]="󱘖 "

declare -A COLORS

COLORS["01d"]="$theme13"
COLORS["01n"]="$theme9"
COLORS["02d"]="$theme4"
COLORS["02n"]="$theme9"
COLORS["03d"]="$theme4"
COLORS["03n"]="$theme4"
COLORS["04d"]="$theme4"
COLORS["04n"]="$theme4"
COLORS["09d"]="$theme4"
COLORS["09n"]="$theme9"
COLORS["10d"]="$theme4"
COLORS["10n"]="$theme9"
COLORS["11d"]="$theme4"
COLORS["11n"]="$theme9"
COLORS["13d"]="$theme4"
COLORS["13n"]="$theme9"
COLORS["50d"]="$theme3"
COLORS["50n"]="$theme3"
COLORS["unknown"]="$theme12"

if [ $resp_code -eq 0 ]; then
    temperature=$(echo $response | jq -r '.main.temp' | numfmt --format '%.0f')
    weather_icon="$(echo $response | jq -r '.weather[0].icon')"
    description=$(echo $response | jq -r '.weather[0].description')
    color=${COLORS["$weather_icon"]}
    icon=${ICONS["$weather_icon"]}

    if [ -e "$SWITCH" ]; then
        echo "<span size='large' color='$color'>${icon} </span>"
    else
        echo "<span>${temperature}</span><span size='large'></span> <span size='large' color='$color'>${icon} </span>"
    fi

else
    echo ${ICONS["unknown"]}
fi


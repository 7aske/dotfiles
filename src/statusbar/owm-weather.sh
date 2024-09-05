#!/bin/bash

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"

WEATHER_CACHE="$HOME/.cache/weather.tmp"
WEATHER_JSON="$HOME/.cache/weather.json"
SWITCH="$HOME/.cache/statusbar_$(basename $0)" 
case $BLOCK_BUTTON in
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
esac

BASE_URL="http://api.openweathermap.org/data/2.5/weather"
URL="${BASE_URL}?id=${OPENWEATHERMAP_CITY_ID}&appid=${OPENWEATHERMAP_API_KEY}&units=metric"

resp_code=1
if [ -z "$BLOCK_BUTTON" ]; then
    response=$(curl -s $URL)
    resp_code=$?
    echo $response > "$WEATHER_JSON"

    echo "Location: $(echo $response | jq -r '.name')" > "$WEATHER_CACHE"
    echo "Temperature: $(echo $response | jq -r '.main.temp' | numfmt --format '%.0f' )°C" >> "$WEATHER_CACHE"
    echo "Weather: $(echo $response | jq -r '.weather[0].description')" >> "$WEATHER_CACHE"
    echo "Humidity: $(echo $response | jq -r '.main.humidity')%" >> "$WEATHER_CACHE"
    echo "Wind: $(echo $response | jq -r '.wind.speed')m/s" >> "$WEATHER_CACHE"
    echo "Pressure: $(echo $response | jq -r '.main.pressure')hPa" >> "$WEATHER_CACHE"
    echo "Last update: $(date)" >> "$WEATHER_CACHE"
else
    response=$(cat "$WEATHER_JSON")
    resp_code=0
fi


case $BLOCK_BUTTON in
    1) [ -e "$WEATHER_CACHE" ] && notify-send -i weather -a weather -t 10000 "OpenWeatherMap" "$(cat $WEATHER_CACHE)" ;;
    3) xdg-open "https://openweathermap.org/city/$OPENWEATHERMAP_CITY_ID" ;;
esac

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

if [ $resp_code -eq 0 ]; then
    temperature=$(echo $response | jq -r '.main.temp' | numfmt --format '%.0f')
    icon="$(echo $response | jq -r '.weather[0].icon')"
    description=$(echo $response | jq -r '.weather[0].description')
    color=${COLORS["$icon"]}
    icon=${ICONS["$icon"]}

    if [ -e "$SWITCH" ]; then
        echo "<span size='large' color='$color'>${icon} </span>"
    else
        echo "<span>${temperature}</span><span size='large'></span> <span size='large' color='$color'>${icon} </span>"
    fi

else
    echo ${ICONS["unknown"]}
fi


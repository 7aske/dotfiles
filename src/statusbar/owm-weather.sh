#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename "$0")" 
WEATHER_JSON="/tmp/weather.json"
LATLON_CACHE="/tmp/latlon.tmp"
BASE_URL="http://api.openweathermap.org/data/2.5/weather"

# shellcheck disable=SC1091
{
    [ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
    [ -e "$HOME/.config/owm.sh" ] && . "$HOME/.config/owm.sh"
}


# shellcheck disable=SC2154
{
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

    declare -A NOTIFY_ICONS
    NOTIFY_ICONS["01d"]="weather-clear"
    NOTIFY_ICONS["01n"]="weather-clear-night"
    NOTIFY_ICONS["02d"]="weather-few-clouds"
    NOTIFY_ICONS["02n"]="weather-few-clouds-night"
    NOTIFY_ICONS["03d"]="weather-clouds"
    NOTIFY_ICONS["03n"]="weather-clouds-night"
    NOTIFY_ICONS["04d"]="weather-overcast"
    NOTIFY_ICONS["04n"]="weather-overcast"
    NOTIFY_ICONS["09d"]="weather-showers-scattered"
    NOTIFY_ICONS["09n"]="weather-showers-scattered-night"
    NOTIFY_ICONS["10d"]="weather-showers"
    NOTIFY_ICONS["10n"]="weather-showers-night"
    NOTIFY_ICONS["11d"]="weather-storm"
    NOTIFY_ICONS["11n"]="weather-storm-night"
    NOTIFY_ICONS["13d"]="weather-snow"
    NOTIFY_ICONS["13n"]="weather-snow-night"
    NOTIFY_ICONS["50d"]="weather-fog"
    NOTIFY_ICONS["50n"]="weather-fog"
    NOTIFY_ICONS["unknown"]="weather-severe-alert"

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
}


[ -z "$OPENWEATHERMAP_API_KEY" ] && echo "<span size='x-large'>󰼯 </span>" && exit 0
if [ -z "$OPENWEATHERMAP_CITY_ID" ]; then
    if [ -e "$LATLON_CACHE" ]; then
        lat_lon=$(cat "$LATLON_CACHE")
    else
        lat_lon=$(curl https://ipapi.co/json/ | \
            jq -r '. | [.latitude,.longitude|tostring] | join(" ")')
        if [ -z "$lat_lon" ]; then
            echo "<span size='x-large'>󰼯 </span>"
            exit 0
        fi
        echo "$lat_lon" > "$LATLON_CACHE"
    fi

    read -r OPENWEATHERMAP_LAT OPENWEATHERMAP_LON < <(cat "$LATLON_CACHE")
fi

if [ -n "$OPENWEATHERMAP_LAT" ] && [ -n "$OPENWEATHERMAP_LON" ]; then
    URL="${BASE_URL}?lat=${OPENWEATHERMAP_LAT}&lon=${OPENWEATHERMAP_LON}&appid=${OPENWEATHERMAP_API_KEY}&units=metric"
else
    URL="${BASE_URL}?id=${OPENWEATHERMAP_CITY_ID}&appid=${OPENWEATHERMAP_API_KEY}&units=metric"
fi

owm_weather_notify() {
    local body
    local icon_key
    if [ -e "$WEATHER_JSON" ]; then
        body="$(jq -r '
        . as $w |
        "Location:    \($w.name)",
        "Temperature: \($w.main.temp | round)°C",
        "Feels like:  \($w.main.feels_like | round)°C",
        "Weather:     \($w.weather[0].description)",
        "Humidity:    \($w.main.humidity)%",
        "Wind:        \($w.wind.speed)m/s",
        "Pressure:    \($w.main.pressure)hPa",
        "Time:        \(( $w.dt + $w.timezone ) | strftime("%T"))",
        "Sunrise:     \(( $w.sys.sunrise + $w.timezone ) | strftime("%T"))",
        "Sunset:      \(( $w.sys.sunset  + $w.timezone ) | strftime("%T"))",
        "",
        "Last update: '"$(date +"%T" -d @"$(stat -c %Y "$WEATHER_JSON" 2>/dev/null || echo 0 )")"'"
        ' "$WEATHER_JSON")"
        icon_key=$(cat "$WEATHER_JSON" | jq -r '.weather[0].icon')
        notify-send -i "${NOTIFY_ICONS["$icon_key"]}" -a weather -t 10000 "OpenWeatherMap" "$body"
    else
        notify-send -a weather -i "${NOTIFY_ICONS["unknown"]}" "OpenWeatherMap" "No weather data available."
    fi
    exit 0
}

case $BLOCK_BUTTON in
    1) owm_weather_notify ;;
	2) if [ -e "$SWITCH" ]; then rm "$SWITCH"; else touch "$SWITCH"; fi ;;
    3) xdg-open "https://old.openweathermap.org/city/$OPENWEATHERMAP_CITY_ID" ;;
esac

resp_code=1
last_update_time="$(cut -d ' ' -f1 <<< "$(stat -c %Y "$WEATHER_JSON" 2>/dev/null || echo 0)")"
if [ -z "$BLOCK_BUTTON" ] || [ $(( $(date +%s) - last_update_time )) -ge 300 ]; then
    response=$(curl -s "$URL")
    resp_code=$?
    echo "$response" > "$WEATHER_JSON"
fi

if [ $resp_code -ne 0 ] && ! [ -e "$WEATHER_JSON" ]; then
    echo "${ICONS["unknown"]}"
    exit 0
elif [ $resp_code -ne 0 ]; then
    response=$(cat "$WEATHER_JSON")
fi


read -r temperature weather_icon < <(
    jq -r '[(.main.temp | round), .weather[0].icon] | @tsv' <<< "$response"
)

output="<span size='large' color='${COLORS["$weather_icon"]}'>${ICONS["$weather_icon"]}</span>"
if ! [ -e "$SWITCH" ]; then
    output="$temperature<span size='large'></span> $output"
fi

echo "$output"

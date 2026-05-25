#!/usr/bin/env bash
# Example LocalSend hook: upload GPS activity files to Strava.
#
# Credentials live in ~/.strava (chmod 600), one KEY=value per line:
#   client_id=...
#   client_secret=...
#   refresh_token=...
# The refresh token must include activity:write scope.
#
# This hook only runs for .fit, .gpx, .tcx (and .gz variants).

set -euo pipefail

file_path=$1
file_name=${file_path##*/}

_strava_data_type() {
    local ext="${file_name##*.}"
    ext="${ext,,}"
    case "$ext" in
        fit)  echo fit ;;
        gpx)  echo gpx ;;
        tcx)  echo tcx ;;
        gz)
            local base="${file_name%.gz}"
            local inner="${base##*.}"
            inner="${inner,,}"
            case "$inner" in
                fit) echo fit.gz ;;
                gpx) echo gpx.gz ;;
                tcx) echo tcx.gz ;;
                *)   return 1 ;;
            esac
            ;;
        *) return 1 ;;
    esac
}

data_type="$(_strava_data_type)" || exit 0

[ -f "$file_path" ] || exit 0

strava_cfg="${HOME}/.strava"
[ -r "$strava_cfg" ] || {
    echo "strava-upload: missing ${strava_cfg}" >&2
    exit 0
}

# shellcheck disable=SC1090
source "$strava_cfg"

: "${client_id:?client_id required in ~/.strava}"
: "${client_secret:?client_secret required in ~/.strava}"
: "${refresh_token:?refresh_token required in ~/.strava}"

token_json=$(
    curl -sf -X POST "https://www.strava.com/oauth/token" \
        -d "client_id=${client_id}" \
        -d "client_secret=${client_secret}" \
        -d "grant_type=refresh_token" \
        -d "refresh_token=${refresh_token}"
) || {
    echo "strava-upload: token refresh failed" >&2
    exit 1
}

if command -v jq >/dev/null 2>&1; then
    access_token=$(printf '%s' "$token_json" | jq -r '.access_token // empty')
else
    access_token=$(printf '%s' "$token_json" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
fi

[ -n "$access_token" ] || {
    echo "strava-upload: no access_token in refresh response" >&2
    exit 1
}

upload_json=$(
    curl -sf -X POST "https://www.strava.com/api/v3/uploads" \
        -H "Authorization: Bearer ${access_token}" \
        -F "file=@${file_path}" \
        -F "data_type=${data_type}"
) || {
    echo "strava-upload: upload request failed" >&2
    exit 1
}

if command -v jq >/dev/null 2>&1; then
    upload_id=$(printf '%s' "$upload_json" | jq -r '.id // empty')
else
    upload_id=$(printf '%s' "$upload_json" | sed -n 's/.*"id":\([0-9]*\).*/\1/p')
fi

msg="Queued ${file_name} on Strava"
[ -n "$upload_id" ] && msg="${msg} (upload ${upload_id})"

if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low "Strava" "$msg"
fi

echo "strava-upload: ${msg}"

#!/usr/bin/env bash
# i3status-rs block: herdr agent statuses (working / blocked / done / idle).

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"
SIGNAL=11

# shellcheck disable=SC1091
{
    [ -e "$HOME/.local/bin/statusbar/libbar" ] && . "$HOME/.local/bin/statusbar/libbar"
}

libbar_getopts "$@"
shift $((OPTIND - 1))

# shellcheck disable=SC2034
{
    libbar_json_icons["agent"]="agent"
    libbar_json_icons["agent_working"]="agent_working"
    libbar_json_icons["agent_waiting"]="agent_waiting"
    libbar_json_icons["agent_ready"]="agent_ready"
    libbar_json_icons["agent_idle"]="agent_idle"
    libbar_json_icons["agent_error"]="agent_error"
    libbar_icons["agent"]="󰚩"
    libbar_icons["agent_working"]="󰔟"
    libbar_icons["agent_waiting"]="󰍩"
    libbar_icons["agent_ready"]="󰄬"
    libbar_icons["agent_idle"]="󰒲"
    libbar_icons["agent_error"]="󰅙"
}

# Map herdr agent_status → bar status used by icons / priority.
_normalize_status() {
    case "$1" in
        blocked) printf 'waiting' ;;
        done) printf 'ready' ;;
        working|waiting|ready|idle|error) printf '%s' "$1" ;;
        unknown|"") printf 'idle' ;;
        *) printf 'idle' ;;
    esac
}

# Lines: status<TAB>name<TAB>kind<TAB>pane_id
_collect() {
    local agents workspaces

    command -v herdr >/dev/null 2>&1 || return 0
    command -v jq >/dev/null 2>&1 || return 0

    agents=$(herdr agent list 2>/dev/null) || return 0
    printf '%s' "$agents" | jq -e '.result.agents' >/dev/null 2>&1 || return 0

    workspaces=$(herdr workspace list 2>/dev/null) || workspaces='{"result":{"workspaces":[]}}'

    jq -n -r \
        --slurpfile a <(printf '%s\n' "$agents") \
        --slurpfile w <(printf '%s\n' "$workspaces") \
        '
        ($w[0].result.workspaces // []) as $ws
        | ($a[0].result.agents // [])[]
        | . as $a
        | (
            ($ws[] | select(.workspace_id == $a.workspace_id) | .label // empty)
            // (if ($a.cwd // "") != "" then ($a.cwd | split("/") | last) else empty end)
            // ($a.agent // "agent")
          ) as $name
        | "\($a.agent_status // "unknown")\t\($name)\t\($a.agent // "?")\t\($a.pane_id // "")"
        ' | while IFS=$'\t' read -r raw name kind pane; do
        [ -n "$raw" ] || continue
        printf '%s\t%s\t%s\t%s\n' "$(_normalize_status "$raw")" "$name" "$kind" "$pane"
    done
}

_priority_state() {
    case "$1" in
        waiting) printf 'Warning' ;;
        error) printf 'Critical' ;;
        working) printf 'Info' ;;
        ready) printf 'Good' ;;
        *) printf 'Idle' ;;
    esac
}

_icon_for_status() {
    case "$1" in
        waiting) printf 'agent_waiting' ;;
        error) printf 'agent_error' ;;
        working) printf 'agent_working' ;;
        ready) printf 'agent_ready' ;;
        idle) printf 'agent_idle' ;;
        *) printf 'agent' ;;
    esac
}

_glyph_for_status() {
    case "$1" in
        waiting) printf '%s' "${libbar_icons[agent_waiting]}" ;;
        error) printf '%s' "${libbar_icons[agent_error]}" ;;
        working) printf '%s' "${libbar_icons[agent_working]}" ;;
        ready) printf '%s' "${libbar_icons[agent_ready]}" ;;
        idle) printf '%s' "${libbar_icons[agent_idle]}" ;;
        *) printf '%s' "${libbar_icons[agent]}" ;;
    esac
}

_summary() {
    local data="$1"
    local total=0 waiting=0 working=0 ready=0 idle=0 error=0 kinds=0
    local status name kind pane worst=idle text icon state color parts
    local -a detail=()

    while IFS=$'\t' read -r status name kind pane; do
        [ -n "$status" ] || continue
        total=$((total + 1))
        case "$status" in
            waiting) waiting=$((waiting + 1)) ;;
            working) working=$((working + 1)) ;;
            ready) ready=$((ready + 1)) ;;
            error) error=$((error + 1)) ;;
            *) idle=$((idle + 1)) ;;
        esac
        detail+=("$(_glyph_for_status "$status") $name")
        case "$status" in
            waiting) worst=waiting ;;
            error) [ "$worst" != waiting ] && worst=error ;;
            working) case "$worst" in waiting|error) ;; *) worst=working ;; esac ;;
            ready) case "$worst" in waiting|error|working) ;; *) worst=ready ;; esac ;;
            idle) case "$worst" in waiting|error|working|ready) ;; *) worst=idle ;; esac ;;
        esac
    done <<<"$data"

    if [ "$total" -eq 0 ]; then
        libbar_output "agent" ""
        return
    fi

    if [ -e "$SWITCH" ]; then
        text="$total"
    else
        kinds=0
        [ "$working" -gt 0 ] && kinds=$((kinds + 1))
        [ "$waiting" -gt 0 ] && kinds=$((kinds + 1))
        [ "$ready" -gt 0 ] && kinds=$((kinds + 1))
        [ "$idle" -gt 0 ] && kinds=$((kinds + 1))
        [ "$error" -gt 0 ] && kinds=$((kinds + 1))

        if [ "$kinds" -le 1 ]; then
            text="$total"
        else
            parts=""
            [ "$working" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status working) $working"
            [ "$waiting" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status waiting) $waiting"
            [ "$ready" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status ready) $ready"
            [ "$idle" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status idle) $idle"
            [ "$error" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status error) $error"
            text="$parts"
        fi
    fi

    if [ -e "$SWITCH" ] || [ "$kinds" -eq 1 ]; then
        icon=$(_icon_for_status "$worst")
    else
        icon="agent"
    fi

    state=$(_priority_state "$worst")
    case "$state" in
        Warning) color="${color3:-"#EBCB8B"}" ;;
        Critical) color="${color1:-"#BF616A"}" ;;
        Info) color="${color4:-"#5E81AC"}" ;;
        Good) color="${color2:-"#A3BE8C"}" ;;
        *) color="${color7:-"#D8DEE9"}" ;;
    esac

    libbar_output "$icon" "$text" "$state" "$color"
}

_status_color() {
    case "$1" in
        waiting) printf '%s' "${yellow:-${color3:-#EBCB8B}}" ;;
        working) printf '%s' "${blue:-${color4:-#81A1C1}}" ;;
        ready) printf '%s' "${green:-${color2:-#A3BE8C}}" ;;
        error) printf '%s' "${red:-${color1:-#BF616A}}" ;;
        *) printf '%s' "${white:-${color7:-#D8DEE9}}" ;;
    esac
}

_pango_escape() {
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

_show_detail() {
    local data detail status name kind pane color glyph
    data=$(_collect)
    detail=$(while IFS=$'\t' read -r status name kind pane; do
        [ -n "$status" ] || continue
        color=$(_status_color "$status")
        glyph=$(_glyph_for_status "$status")
        printf '<span foreground="%s">%s</span>  <span foreground="%s"><b>%s</b></span>  <span foreground="%s">%s</span>  <span foreground="%s">(%s)</span>\n' \
            "$color" "$glyph" \
            "${white:-#D8DEE9}" "$(_pango_escape "$name")" \
            "${color8:-#4C566A}" "$(_pango_escape "$kind")" \
            "$color" "$(_pango_escape "$status")"
    done <<<"$data")

    if [ -z "$detail" ]; then
        notify-send -a agent -i terminal "Herdr agents" \
            "<span foreground='${color8:-#4C566A}'>No running agents</span>"
        return
    fi
    notify-send -a agent -i terminal "Herdr agents" "$detail"
}

_open_herdr() {
    i3-msg 'exec --no-startup-id wtoggle2 -d 90%x90% "kitty --override background_opacity=1 --class floating herdr"' >/dev/null 2>&1
}

case $BLOCK_BUTTON in
    1) _show_detail ;;
    2) libbar_toggle_switch "$SIGNAL" ;;
    3) _open_herdr ;;
esac

data=$(_collect)
_summary "$data"

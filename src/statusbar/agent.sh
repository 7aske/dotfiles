#!/usr/bin/env bash
# i3status-rs block: running agent tmux sessions (cursor-agent / claude).
# Discovers sessions named agent-*, filters by $AGENT, reports count + status.

SWITCH="$HOME/.cache/statusbar_$(basename "$0")"
STATUS_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/agent-statusbar"
AGENT_BIN="${AGENT:-cursor-agent}"
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

_agent_kind() {
    case "$AGENT_BIN" in
        cursor-agent|cursor) printf 'cursor' ;;
        claude|claude-code) printf 'claude' ;;
        *) printf '%s' "$AGENT_BIN" ;;
    esac
}

_agent_match_proc() {
    local pane_pid="$1"
    local cmdline

    cmdline=$(tr '\0' ' ' <"/proc/$pane_pid/cmdline" 2>/dev/null || true)
    case "$AGENT_BIN" in
        cursor-agent|cursor)
            [[ "$cmdline" == *cursor-agent* ]] || [[ "$cmdline" == */opt/cursor-agent/* ]]
            ;;
        claude|claude-code)
            [[ "$cmdline" == *claude* ]] && [[ "$cmdline" != *cursor-agent* ]]
            ;;
        *)
            [[ "$cmdline" == *"$AGENT_BIN:"* ]]
            ;;
    esac
}

_status_from_hooks() {
    local session="$1"
    local file="$STATUS_DIR/${session}.json"
    local status updated now age

    [ -f "$file" ] || return 1

    status=$(jq -r '.status // empty' "$file" 2>/dev/null) || return 1
    updated=$(jq -r '.updated // 0' "$file" 2>/dev/null) || return 1
    now=$(date +%s)
    age=$((now - updated))

    # TTLs: waiting only briefly (AskQuestion); working must outlive poll interval
    case "$status" in
        waiting)
            [ "$age" -lt 300 ] || return 1
            printf '%s' "$status"
            ;;
        error)
            [ "$age" -lt 600 ] || return 1
            printf '%s' "$status"
            ;;
        ready|done)
            [ "$age" -lt 120 ] || return 1
            printf 'ready'
            ;;
        working)
            [ "$age" -lt 180 ] || return 1
            printf '%s' "$status"
            ;;
        *)
            return 1
            ;;
    esac
}

# Find the pane running $AGENT_BIN in a session (not a side nvim/shell pane).
_agent_pane() {
    local session="$1"
    local target pid cmd

    while IFS='|' read -r target pid; do
        [ -n "$pid" ] || continue
        if _agent_match_proc "$pid"; then
            printf '%s|%s\n' "$target" "$pid"
            return 0
        fi
        # worker may be child of a shell pane
        cmd=$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || true)
        if [[ "$cmd" == *"$AGENT_BIN"* ]] || pgrep -P "$pid" -a 2>/dev/null | grep -q -- "$AGENT_BIN"; then
            printf '%s|%s\n' "$target" "$pid"
            return 0
        fi
    done < <(tmux list-panes -s -t "$session" -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}' 2>/dev/null)

    return 1
}

_status_from_pane() {
    local target="$1"
    local pane bottom

    # Only the bottom chrome matters — scrollback still contains old "Running"/"Searching".
    pane=$(tmux capture-pane -t "$target" -p -S -12 2>/dev/null || true)
    bottom=$(printf '%s\n' "$pane" | grep -v '^[[:space:]]*$' | tail -8)

    if [ -z "$bottom" ]; then
        printf 'idle'
        return
    fi

    # Active turn: spinner or status verb in the bottom chrome.
    # Do NOT key off "ctrl+c to stop" — Cursor shows that on the follow-up line too.
    if printf '%s' "$bottom" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|⣾|⣽|⣻|⢿|⡿|⣟|⣯|⣷|⠰|⠠'; then
        printf 'working'
        return
    fi
    if printf '%s' "$bottom" | grep -qiE '(^|[[:space:]])(Searching|Thinking|Planning|Reading|Running|Compacting|Generating|Working)[[:space:]]+[0-9]'; then
        printf 'working'
        return
    fi
    if printf '%s' "$bottom" | grep -qiE 'esc to interrupt|Esc to interrupt|ctrl\+c to cancel'; then
        printf 'working'
        return
    fi

    # Permission / ask prompts
    if printf '%s' "$bottom" | grep -qiE 'Do you want|Allow this|Waiting for your|needs your (input|approval)|AskQuestion|Approve this'; then
        printf 'waiting'
        return
    fi

    # Post-turn ready vs cold idle (Cursor)
    if printf '%s' "$bottom" | grep -q 'Add a follow-up'; then
        printf 'ready'
        return
    fi
    if printf '%s' "$bottom" | grep -q 'Plan, search, build anything'; then
        printf 'idle'
        return
    fi

    printf 'idle'
}

# Merge hook file + live pane. Pane is ground truth for working/ready/idle;
# hook "waiting" only wins when the pane doesn't clearly contradict it.
_merge_status() {
    local hook_status="$1"
    local pane_status="$2"

    case "$pane_status" in
        working) printf 'working'; return ;;
        ready)
            # live ready beats stale waiting from smoke tests / old asks
            printf 'ready'
            return
            ;;
        idle)
            if [ "$hook_status" = "error" ]; then
                printf 'error'
            elif [ "$hook_status" = "ready" ]; then
                printf 'ready'
            else
                # pane idle beats stale waiting/working hook files
                printf 'idle'
            fi
            return
            ;;
        waiting)
            printf 'waiting'
            return
            ;;
    esac

    # fallback
    if [ -n "$hook_status" ]; then
        printf '%s' "$hook_status"
    else
        printf '%s' "${pane_status:-idle}"
    fi
}

_list_sessions() {
    tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -E '^agent-' || true
}

_collect() {
    local session pane_info pane_target pane_pid hook_status pane_status status name
    local -a lines=()

    while IFS= read -r session; do
        [ -n "$session" ] || continue
        pane_info=$(_agent_pane "$session" || true)
        [ -n "$pane_info" ] || continue
        pane_target=${pane_info%%|*}
        pane_pid=${pane_info#*|}
        [ -n "$pane_pid" ] || continue
        _agent_match_proc "$pane_pid" || continue

        hook_status=$(_status_from_hooks "$session" || true)
        pane_status=$(_status_from_pane "$pane_target")
        status=$(_merge_status "$hook_status" "$pane_status")

        name="${session#agent-}"
        lines+=("$status	$name")
    done < <(_list_sessions)

    printf '%s\n' "${lines[@]}"
}

_priority_state() {
    # worst → best for bar coloring
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

_label_for_status() {
    case "$1" in
        waiting) printf 'wait' ;;
        working) printf 'run' ;;
        ready) printf 'ready' ;;
        error) printf 'err' ;;
        idle) printf 'idle' ;;
        *) printf '%s' "$1" ;;
    esac
}

_summary() {
    local data="$1"
    local total=0 waiting=0 working=0 ready=0 idle=0 error=0 kinds=0
    local status name worst=idle text icon state color parts
    local -a detail=()

    while IFS=$'\t' read -r status name; do
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
            # single status → count only; $icon carries the meaning
            text="$total"
        else
            # icon + count per status (no leading total — that made "2 1 1")
            parts=""
            [ "$working" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status working) $working"
            [ "$waiting" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status waiting) $waiting"
            [ "$ready" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status ready) $ready"
            [ "$idle" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status idle) $idle"
            [ "$error" -gt 0 ] && parts+="${parts:+ }$(_glyph_for_status error) $error"
            text="$parts"
        fi
    fi

    if [ -e "$SWITCH" ] || [ "$kinds" -eq 1 ] ; then
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

    AGENT_DETAIL=$(printf '%s\n' "${detail[@]}")
    AGENT_TOTAL=$total
    export AGENT_DETAIL AGENT_TOTAL

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
    local data detail kind status name color glyph
    kind=$(_agent_kind)
    data=$(_collect)
    detail=$(while IFS=$'\t' read -r status name; do
        [ -n "$status" ] || continue
        color=$(_status_color "$status")
        glyph=$(_glyph_for_status "$status")
        printf '<span foreground="%s">%s</span>  <span foreground="%s"><b>%s</b></span>  <span foreground="%s">(%s)</span>\n' \
            "$color" "$glyph" \
            "${white:-#D8DEE9}" "$(_pango_escape "$name")" \
            "$color" "$(_pango_escape "$status")"
    done <<<"$data")

    if [ -z "$detail" ]; then
        notify-send -a agent -i terminal "Agents ($kind)" \
            "<span foreground='${color8:-#4C566A}'>No running agent sessions</span>"
        return
    fi
    notify-send -a agent -i terminal "Agents ($kind)" "$detail"
}

case $BLOCK_BUTTON in
    1) _show_detail ;;
    2) libbar_toggle_switch "$SIGNAL" ;;
    3) i3-msg "exec --no-startup-id wtoggle2 -d 90%x90% \"kitty --override background_opacity=1 --class floating fzf-agent\"" >/dev/null 2>&1 ;;
esac

data=$(_collect)
_summary "$data"

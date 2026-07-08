#!/usr/bin/env bash

. "$HOME/.profile"

[ -e "$HOME/.profile" ] && . "$HOME/.profile"
[ -z "$(command -v cgs)" ] && echo "cgs: not found" && exit 1
[ -z "$(command -v fzf)" ] && echo "fzf: not found" && exit 1

_code="$(cgs -C)"

export FZF_DEFAULT_OPTS="
--preview 'git -c color.status=always -C \"$_code\"/{} status --short; git -c color.status=always -C \"$_code\"/{} diff --color=always HEAD'
--bind 'ctrl-e:execute('$TERMFILE' \"$_code\"/{})'
--bind 'ctrl-r:execute(git -C \"$_code\"/{} reset --hard HEAD)'
--bind 'ctrl-p:execute(git -C \"$_code\"/{} pull)'
--bind 'ctrl-g:execute(cd \"$_code\"/{} && lazygit)'
--header \"Select a project to open. (Ctrl-e) $TERMFILE (Ctrl-g) lazygit (Ctrl-l) git clean (Ctrl-p) git pull\"
--preview-window 'right,70%,border-left,+{2}+3/3,~3'
--reverse --cycle
"

available_types=("term" "agent" "cursor" "vim" "vscode" "jetbrains" "idea" "pycharm" "clion" "studio" "goland" "webstorm" "rider")
available_menus=("dmenu" "rofi" "fzf")

_usage() {
    echo -e "usage: codeopen -[htmg]"
    echo -e "\t-h          show this help message and exit"
    echo -e "\t-t <type>   available types: ${available_types[*]}"
    echo -e "\t-m <menu>   available menus: ${available_menus[*]}"
    echo -e "\t-g          show only dirty repos"
}

dirty=false
class=""
while getopts "hc:m:t:g" arg; do
    case ${arg} in
    g) dirty=true ;;
    c) class="$OPTARG" ;;
    h)
        _usage
        exit 0
        ;;
    t)
        TYPE="$OPTARG"
        ;;
    m)
        MENU="$OPTARG"
        ;;
    ?)
        echo "Invalid option: -${OPTARG}."
        exit 2
        ;;
    esac
done

shift $((OPTIND - 1))

menu_command="fzf"
if [ "$MENU" = "dmenu" ]; then
    menu_command="dmenu -l 10 -f -i -p ${TYPE:-type}:"
elif [ "$MENU" = "rofi" ]; then
    menu_command="rofi -dmenu -sort -i -matching fuzzy -p ${TYPE:-type}"
fi

if [ -z "$TYPE" ]; then
    _args="$FZF_DEFAULT_OPTS"
    FZF_DEFAULT_OPTS=""
    TYPE="$(echo ${available_types[*]} | tr ' ' '\n' | $menu_command)"
    FZF_DEFAULT_OPTS="$_args"
fi

if [ -z "$TYPE" ]; then
    exit 1
fi

PROJ=""

_select_project() {
    # use grep to remove $_code prefix
    if [ $dirty = true ]; then
        SELECTED="$(eval "cgs -md -sm | grep -oP '^$_code/\K.*' | $menu_command")"
    else
        SELECTED="$(eval "cgs -ad | grep -oP '^$_code/\K.*' | $menu_command")"
    fi
        PROJ="$_code/$SELECTED"

    if [ ! -e "$PROJ" ]; then
        exit 0
    fi

    if [ -L "$PROJ" ]; then
        PROJ="$(readlink -f "$PROJ")"
    fi
    
    if ! ( git -C "$PROJ" rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        exit 1
    fi
}

_open_term() {
    if [ -t 1 ]; then
        cd "$PROJ" || exit 1
        if [ -n "$1" ]; then
            exec $1
        else
            exec $SHELL
        fi
        exit 0
    fi

    arguments=("-d" "$PROJ")

    if [ "$TERMINAL" = "st" ]; then
        if [ -n "$class" ]; then
            arguments+=("-c" "$class")
        fi
    else
        if [ -n "$class" ]; then
            arguments+=("--class" "$class")
        fi
    fi

    if [ -n "$1" ]; then
        arguments+=("-e" "$1")
    fi

    notify-send -i terminal "codeopen" "opening $PROJ in $TERMINAL" &
    $TERMINAL "${arguments[@]}"
}

_open_vscode() {
    _select_project

    for cmd in vscodium code-insiders code; do
        if [ -x "$(command -v $cmd)" ]; then
            CMD="$cmd"
            break
        fi
    done

    if [ -z "$CMD" ]; then
        errmsg="vscodium: command not found\ncode-insiders: command not found\ncode: command not found"
        echo -e "$errmsg"
        notify-send -i system-error "codeopen" "$errmsg"
        exit 1
    fi

    notify-send -i code "codeopen" "opening $PROJ"
    $CMD "$PROJ"
}

_open_cursor() {
    _select_project
    if [ -x "$(command -v cursor)" ]; then
        CMD="cursor"
    else
        errmsg="cursor: command not found"
        echo -e "$errmsg"
        notify-send -i system-error "codeopen" "$errmsg"
        exit 1
    fi

    notify-send -i code "codeopen" "opening $PROJ"
    $CMD "$PROJ"
}

_open_agent() {
    _select_project
    local session_name

    if [ -x "$(command -v $AGENT)" ]; then
        CMD="$AGENT"
    else
        errmsg="$AGENT: comand not found"
        echo -e "$errmsg"
        notify-send -i system-error "codeopen" "$errmsg"
        exit 1
    fi

    session_name="agent-$(basename "$PROJ")"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        notify-send -i terminal "codeopen" "attaching to existing session for $PROJ"
    else
        notify-send -i terminal "codeopen" "opening $PROJ"
        tmux new-session -d -s "$session_name" -c "$PROJ" $AGENT || return 1
    fi

    $TERMINAL -d "$PROJ" -e tmux attach-session -t "$session_name"
}

_open_vim() {
    _select_project

    if [ -x "$(command -v nvim)" ]; then
        CMD=nvim
    elif [ -x "$(command -v vim)" ]; then
        CMD=vim
    else
        errmsg="nvim: command not found\nnvim: command not found"
        echo -e "$errmsg"
        notify-send -i system-error "codeopen" "$errmsg"
        exit 1
    fi

    if [ -t 1 ]; then
        $CMD "$PROJ"
    else
        notify-send -i "$CMD" "codeopen" "opening $PROJ"
        $TERMINAL -e $CMD "$PROJ"
    fi
}

_open_jetbrains() {
    _select_project

    BIN_DIR="$HOME/.local/bin"

    if [ -z "$1" ]; then
        CMD=$(for file in $(dir -1 "$BIN_DIR"); do grep -q "JetBrains" "$BIN_DIR/$file" && echo "$BIN_DIR/$file"; done | $menu_command)
        [ -z "$CMD" ] && exit 1
        notify-send -i "$(basename "$CMD")" "codeopen" "opening $PROJ"
        setsid "$(basename "$CMD")" "$PROJ" 2>/dev/null >/dev/null &
    else
        setsid "$1" "$PROJ" 2>/dev/null >/dev/null &
    fi
}

_open_lazygit() {
    _select_project

    if [ -x "$(command -v lazygit)" ]; then
        _open_term lazygit
    else
        errmsg="lazygit: command not found"
        echo -e "$errmsg"
        notify-send "codeopen" "$errmsg"
        exit 1
    fi
}

case "$TYPE" in
    "term") _select_project; _open_term ;;
    "cursor") _open_cursor ;;
    "agent") _open_agent ;;
    "vscode") _open_vscode ;;
    "vim") _open_vim ;;
    "jetbrains") _open_jetbrains ;;
    "idea") _open_jetbrains idea ;;
    "clion") _open_jetbrains clion ;;
    "goland") _open_jetbrains goland ;;
    "pycharm") _open_jetbrains pycharm ;;
    "webstorm") _open_jetbrains webstorm ;;
    "rider") _open_jetbrains rider ;;
    "studio" | "android") _open_jetbrains studio ;;
    "lazygit") _open_lazygit ;;
    *) _select_project; _open_term;;
esac

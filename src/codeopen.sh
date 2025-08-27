#!/usr/bin/env bash

. "$HOME/.profile"

[ -e "$HOME/.profile" ] && . "$HOME/.profile"
[ -z "$CODE" ] && echo "'CODE' env not set" && exit 1
[ -z "$(command -v cgs)" ] && echo "cgs: not found" && exit 1
[ -z "$(command -v fzf)" ] && echo "fzf: not found" && exit 1

available_types=("term" "vscode" "vim" "jetbrains" "idea" "pycharm" "clion" "studio" "goland" "webstorm" "rider")
available_menus=("dmenu" "rofi")

_usage() {
    echo -e "usage: codeopen -[tm]"
    echo -e "\t-t <type>   available types: ${available_types[*]}"
    echo -e "\t-m <menu>   available menus: ${available_menus[*]}"
}

# list of arguments expected in the input
optstring="hm:t:"

while getopts ${optstring} arg; do
    case ${arg} in
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
    if [ -n "$1" ]; then
        TYPE="$1"
    else
        TYPE="$(echo ${available_types[*]} | tr ' ' '\n' | $menu_command)"
    fi
fi

PROJ=""


_select_project() {
    # use grep to remove $CODE prefix
    if [ "$1" == "dirty" ]; then
        PROJ="$(eval "cgs -m -sm | tac | $menu_command" | awk -v code="$CODE" '{print code "/" $1 "/" $2}')"
    else
        SELECTED="$(eval "cgs -ad | grep -oP '^$CODE/\K.*' | $menu_command")"
        PROJ="$CODE/$SELECTED"
    fi

    if [ ! -e "$PROJ" ]; then
        exit 0
    fi

    if [ -L "$PROJ" ]; then
        PROJ="$(readlink -f "$PROJ")"
    fi
    
    if ! ( git -C "$PROJ" rev-parse HEAD 2>&1 >/dev/null ); then
        exit 1
    fi
}

_open_term() {
    if [ -t 1 ]; then
        if [ -n "$1" ]; then
            cd "$PROJ" && $1
        else
            cd "$PROJ"
            exec $SHELL
        fi
    else
        if [ "$TERMINAL" = "st" ]; then
            # 7aske 'st' build with '-d' option to chdir at start
            notify-send -i terminal "codeopen" "opening $PROJ in $TERMINAL" &
            $TERMINAL -d "$PROJ" $([ -n "$1" ] && echo "-e $1")
        else
            notify-send -i terminal "codeopen" "opening $PROJ in $TERMINAL" &
            $TERMINAL -cd "$PROJ" $([ -n "$1" ] && echo "-e $1")
        fi
    fi
}

_open_vscode() {
    _select_project

    if [ -x "$(command -v vscodium)" ]; then
        CMD="vscodium"
    elif [ -x "$(command -v code-insiders)" ]; then
        CMD="code-insiders"
    elif [ -x "$(command -v code)" ]; then
        CMD="code"
    else
        errmsg="vscodium: command not found\ncode-insiders: command not found\ncode: command not found"
        echo -e "$errmsg"
        notify-send "codeopen" "$errmsg"
        exit 1
    fi
    notify-send -i code "codeopen" "opening $PROJ"
    $CMD "$PROJ"
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
        notify-send "codeopen" "$errmsg"
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
        setsid $(basename $CMD) "$PROJ" 2>/dev/null >/dev/null &
    else
        setsid "$1" "$PROJ" 2>/dev/null >/dev/null &
    fi
}

_open_lazygit() {
    _select_project dirty

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
    *) _select_project; _open_term $TYPE ;;
esac

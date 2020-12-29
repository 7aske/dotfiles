#!/usr/bin/env sh

. "$HOME/.profile"

TYPE="${TYPE:-"term"}"

[ -z "$CODE" ] && echo "'CODE' env not set" && exit 1
[ -z "$(command -v cgs)" ] && echo "cgs: not found" && exit 1

if [ "$MENU" = "dmenu" ]; then
    PROJ="$(cgs -a -i | dmenu -l 10 -f -i -p 'repo:')"
elif [ "$MENU" = "rofi" ]; then
    PROJ="$(cgs -a -i | rofi -dmenu -p "repo")"
else
    PROJ="$(cgs -a -i | fzf)"
fi

if [ -n "$PROJ" ]; then
    case "$TYPE" in
    "term")
        if [ "$TERMINAL" = "st" ]; then
            # 7aske 'st' build with '-d' option to chdir at start
            notify-send -i terminal "codeopen" "opening $PROJ"
            $TERMINAL -d "$PROJ"
        else
            notify-send -i terminal "codeopen" "opening $PROJ"
            $TERMINAL -cd "$PROJ"
        fi
        ;;

    "vscode")
        if [ -x "$(command -v vscodium)" ]; then
            CMD=vscodium
        elif [ -x "$(command -v code-insiders)" ]; then
            CMD=code-insiders
        elif [ -x "$(command -v code)" ]; then
            CMD=code
        else
            echo "vscodium: not found"
            echo "code-insiders: not found"
            echo "code: not found"
            [ -x "$(command -v notify-send)" ] && notify-send "codeopen" "vscodium: not found\ncode-insiders: not found\ncode: not found"
            exit 1
        fi
        notify-send -i code "codeopen" "opening $PROJ"
        $CMD "$PROJ"
        ;;
    "jetbrains")
        BIN_DIR="$HOME/.local/bin"
		IDEMENU="dmenu -l 10 -f -i -p 'ide:'"
		if [ "$MENU" = "rofi" ]; then
			IDEMENU="rofi -dmenu -p 'ide'"
		fi
        CMD=$(for file in $(dir -1 "$BIN_DIR"); do grep -q "JetBrains" "$BIN_DIR/$file" && echo "$BIN_DIR/$file"; done | $IDEMENU)
        [ -z "$CMD" ] && exit 1
        notify-send -i "$(basename "$CMD")" "codeopen" "opening $PROJ"
        $CMD "$PROJ"
        ;;
    "vim")
        if [ -x "$(command -v nvim)" ]; then
            CMD=nvim
        elif [ -x "$(command -v vim)" ]; then
            CMD=vim
        else
            echo "nvim: not found"
            echo "vim: not found"
            [ -x "$(command -v notify-send)" ] && notify-send "codeopen" "nvim: not found\nnvim: not found"
            exit 1
        fi
        notify-send -i "$CMD" "codeopen" "opening $PROJ"
        $TERMINAL -e $CMD "$PROJ"
        ;;
    *)
        notify-send "codeopen" "$TYPE opening $PROJ"
        $TYPE "$PROJ"
        ;;
    esac
fi

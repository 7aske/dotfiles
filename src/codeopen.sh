#!/usr/bin/env sh

. "$HOME/.profile"

if [ -z "$CODE" ]; then
    echo "'CODE' env not set" && exit 1
fi

[ -z "$(command -v codels)" ] && echo "codels: not found" && exit 1
 
if [ -n "$ROFI" ]; then
    PROJ="$(codels | rofi -dmenu)"
else
    PROJ="$(codels | fzf)"
fi

if [ -n "$PROJ" ]; then
    case "$TYPE" in
    "term")
        $TERMINAL -cd "$PROJ" && notify-send "codeopen" "opening $PROJ"
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
        $CMD "$PROJ" && notify-send "codeopen" "opening $PROJ"
        ;;
    "jetbrains") 
        BIN_DIR="$HOME/.local/bin" 
        CMD=$(for file in $(dir -1 "$BIN_DIR"); do grep -q "JetBrains" "$BIN_DIR/$file" && echo "$BIN_DIR/$file"; done | rofi -dmenu)
        [ -z "$CMD" ] && exit 1
        $CMD "$PROJ" && notify-send "codeopen" "opening $PROJ"
    ;;
        *)
        echo "'TYPE' env not set"
        exit 1
        ;;
    esac
fi

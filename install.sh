#!/usr/bin/env bash

BASH_COMP_DIR=src/bash-completions
ZSH_COMP_DIR=src/zsh-completions
BASH_COMP_OUTPUT_DIR="$HOME/.bash_completion.d"
ZSH_COMP_OUTPUT_DIR="$HOME/.zsh/completions"

usage() {
    echo "install.sh <input> <output>" && exit 2
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage

[ ! -e "$2" ] && mkdir -p "$2"

for f in "$1"/*.sh; do
    base=$(basename "$f"  | cut -d "." -f 1)
    
    cp -v "$f" "$2/$base" || echo "error: unable to copy $f to $2"
    chmod u+x "$2/$base"

    # install bash completion if exists
    if [ -e "$BASH_COMP_DIR/$base.sh" ]; then
        mkdir -p "$BASH_COMP_OUTPUT_DIR"
        cp -v "$BASH_COMP_DIR/$base.sh" "$BASH_COMP_OUTPUT_DIR/$base.sh" || echo "error: unable to copy $BASH_COMP_DIR/$base.sh to $BASH_COMP_OUTPUT_DIR"
        chmod u+x "$BASH_COMP_OUTPUT_DIR/$base.sh"
    fi

    # install zsh completion if exists
    if [ -e "$ZSH_COMP_DIR/_$base" ]; then
        mkdir -p "$ZSH_COMP_OUTPUT_DIR"
        cp -v "$ZSH_COMP_DIR/_$base" "$ZSH_COMP_OUTPUT_DIR/_$base" || echo "error: unable to copy $ZSH_COMP_DIR/_$base to $ZSH_COMP_OUTPUT_DIR"
        chmod u+x "$ZSH_COMP_OUTPUT_DIR/_$base"
    fi

done


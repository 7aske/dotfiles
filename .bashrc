#!/bin/bash

export CODE="$HOME/.local/src"
export HISTSIZE=
export HISTFILESIZE=
export LESSHISTSIZE=0


function bashrc() {
    $EDITOR "$CODE/sh/bashrc/.bashrc" && $EDITOR "$HOME/.bashrc" && source "$HOME/.bashrc"
}

# git utils
function gr() {
    echo "Password:"
    read -r -s password
    echo
    curl -u 7aske:"$password" https://api.github.com/user/repos -d "{\"name\":\"$1\"}"
    git init
    git remote add origin https://github.com/7aske/"$1".git
}

function clone() {
    if [ "$#" -eq 2 ]; then
        git clone https://github.com/"$1"/"$2"
    else
        git clone https://github.com/7aske/"$1"
    fi
}

function gitreset() { git reset --hard HEAD; }

function commit() { git add . && git commit -m "$@"; }

function drycommit() { git commit --branch --dry-run; }

function push() { git push origin "$(git branch | grep -e "^[\*]" | awk '{print $2}')"; }

function pull() { git pull origin "$(git branch | grep -e "^[\*]" | awk '{print $2}')"; }

function dpi() {
    val=$([ ! -z "$1" ] && echo "$1" || echo 96)
    if [ "$DESKTOP_SESSION" == "gnome" ]; then
        dconf write /org/gnome/desktop/interface/text-scaling-factor $(echo "scale=1; $val/96" | bc) 2> /dev/null
    elif [ "$DESKTOP_SESSION" == "xfce" ]; then
        xfconf-query -c xsettings -p /Xft/DPI -s "$val" 2> /dev/null
    fi
}

alias cls='clear -x'
alias autoremove='sudo pacman -R $(pacman -Qdtq)'
alias pacman='sudo pacman'
alias v='nvim'
alias n='nano'
alias ci='code-insiders'
function c { vscodium $@ || codium $@ || /usr/bin/code $@; }
function chrome { google-chrome-stable $@ || chromium $@; }
alias bat='bat -p --paging never --theme=base16'
alias myip='curl -s api.ipify.org'
alias grep='grep --color=auto'
alias wget='wget --hsts-file=~/.config/wget/.wget-hsts'
alias cpwd='pwd | xclip -sel c'
alias diff="diff --color=auto"
# navigation
alias conf='builtin cd $HOME/.config/&& ls'
alias dow='builtin cd $HOME/Downloads&& ls'
alias sha='builtin cd $HOME/Share&& ls'
alias doc='builtin cd $HOME/Documents&& ls'
alias pic='builtin cd $HOME/Pictures&& ls'
alias dro='builtin cd $HOME/Dropbox&& ls'
alias pub='builtin cd $HOME/Public&& ls'
alias shr='builtin cd /usr/share&& ls'
alias etc='builtin cd /etc&& ls'
alias lcl='builtin cd $HOME/.local&& ls'
alias chc='cd "$(chcode)"'
alias chgs='cd "$(codegs)" && echo -e "\ngit status -s\n"; git status -s'
# misc
alias rsrc='source ~/.bashrc'
alias ascii='man ascii'
# ls
alias ls='ls --color=auto -lph --group-directories-first'
alias la='ls --color=auto -lAph --group-directories-first'

# personal utils
alias gs='/usr/bin/cgs'
function hist () {
    cmd="$(history | sort -r | fzf | sed -e 's/[0-9 ]\+//')"
    eval "$cmd" 
}
# laptop misc
alias backl='xbacklight -set'
alias bell='xset -b'

# eg. cd ... to jump back two directories
function cd() {
    case $1 in
    ..)
        builtin cd .. && ls
        ;;
    ...)
        builtin cd ../.. && ls
        ;;
    ....)
        builtin cd ../../.. && ls
        ;;
    .....)
        builtin cd ../../../../ && ls
        ;;
    *)
        builtin cd "$@" && ls
        ;;
    esac
}
alias cdb="cd $OLDPWD"

function open() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
    Linux*) machine=Linux ;;
    Darwin*) machine=Mac ;;
    CYGWIN*) machine=Cygwin ;;
    MINGW*) machine=MinGw ;;
    *) machine="UNKNOWN:${unameOut}" ;;
    esac
    if test "${machine}" = 'Linux'; then
        (xdg-open "$@" >/dev/null 2>&1 &)
    elif test "${machine}" = 'Cygwin' || test "${machine}" = 'MinGw'; then
        explorer "$@" &
    elif test "${machine}" = 'Mac'; then
        open "$@"
    else
        echo 'Unsupported OS'
    fi
}

function code() {
    builtin cd "$CODE"/"$1"/"$2" && ls
}

compl_code() {
    COMPREPLY=()
    local word="${COMP_WORDS[COMP_CWORD]}"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$(dir $CODE)" -- "$word"))
    else
        local words=("${COMP_WORDS[@]}")
        unset "words[0]"
        unset "words[$COMP_CWORD]"
        local completions=$(dir -F "$CODE"/"${words[*]}")
        COMPREPLY=($(compgen -W "$completions" -- "$word"))
    fi
}
if [[ "$SHELL" = "bash" ]]; then
    complete -F compl_code code
fi

# PS1 setup
if [[ "$(id -u)" == "0" ]]; then
    export PS1='\[\033[01;31m\]\u\[\033[01;37m\] \W \[\033[01;32m\]\[\033[01;33m\]$(git branch 2>/dev/null | sed -n "s/* \(.*\)/\1 /p")\[\033[01;31m\]\$\[\033[00m\] '
else
    export PS1='\[\033[01;34m\]\u\[\033[01;37m\] \W \[\033[01;32m\]\[\033[01;33m\]$(git branch 2>/dev/null | sed -n "s/* \(.*\)/\1 /p")\[\033[01;34m\]\$\[\033[00m\] '
fi

if grep SSH_CLIENT <(env) &>/dev/null; then
    #clear -x
    #neofetch --config ~/.config/neofetch/config_ssh.conf 2>/dev/null
    if [[ "$(id -u)" == "0" ]]; then
        export PS1='\[\033[01;31m\]\u@\h\[\033[01;37m\] \W \[\033[01;32m\]\[\033[01;33m\]$(git branch 2>/dev/null | sed -n "s/* \(.*\)/\1 /p")\[\033[01;31m\]\$\[\033[00m\] '
    else
        export PS1='\[\033[01;35m\]\u@\h\[\033[01;37m\] \W \[\033[01;32m\]\[\033[01;33m\]$(git branch 2>/dev/null | sed -n "s/* \(.*\)/\1 /p")\[\033[01;35m\]\$\[\033[00m\] '
    fi
fi
# bind 'set editing-mode vi'
# bind 'set show-mode-in-prompt on'
# bind 'set vi-ins-mode-string "+"'
# bind 'set vi-cmd-mode-string ":"'
# bind 'set keymap vi-insert'

